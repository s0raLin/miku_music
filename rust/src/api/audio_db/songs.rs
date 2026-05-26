use super::{DbManager, MusicInfo};
use rusqlite::{params, Result};

impl DbManager {
    /// 插入或更新单首歌曲
    pub fn insert_song(&self, music: &MusicInfo) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute(
            "INSERT OR REPLACE INTO songs (id, title, artist, album, duration_ms, cover_path, lyrics, path, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9);",
            params![
                music.id, music.title, music.artist, music.album,
                music.duration_ms, music.cover_path, music.lyrics, music.path,
                chrono::Utc::now().timestamp()
            ],
        )?;
        Ok(())
    }

    /// 批量增量扫描歌曲（高效率事务处理）
    pub fn insert_songs_bulk(&self, songs: &[MusicInfo]) -> Result<()> {
        let mut conn = self.conn.lock().unwrap();
        let tx = conn.transaction()?;
        let now = chrono::Utc::now().timestamp();
        {
            let mut stmt = tx.prepare(
                "INSERT OR REPLACE INTO songs (id, title, artist, album, duration_ms, cover_path, lyrics, path, updated_at)
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9);"
            )?;
            for music in songs {
                stmt.execute(params![
                    music.id, music.title, music.artist, music.album,
                    music.duration_ms, music.cover_path, music.lyrics, music.path, now
                ])?;
            }
        }
        tx.commit()?;
        Ok(())
    }

    /// 获取单首歌曲
    pub fn get_song(&self, id: &str) -> Result<Option<MusicInfo>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT id, title, artist, album, duration_ms, cover_path, lyrics, path FROM songs WHERE id = ?1;"
        )?;
        let mut rows = stmt.query(params![id])?;

        if let Some(row) = rows.next()? {
            Ok(Some(MusicInfo {
                id: row.get(0)?, title: row.get(1)?, artist: row.get(2)?,
                album: row.get(3)?, duration_ms: row.get(4)?, cover_path: row.get(5)?,
                lyrics: row.get(6)?, path: row.get(7)?,
            }))
        } else {
            Ok(None)
        }
    }

    /// 核心逻辑：从媒体库彻底删除歌曲
    /// ⚠️ 由于无外键约束，需要手动清理交叉连接表和播放历史
    pub fn delete_song_completely(&self, music_id: &str) -> Result<()> {
        let mut conn = self.conn.lock().unwrap();
        let tx = conn.transaction()?;

        tx.execute("DELETE FROM songs WHERE id = ?1;", params![music_id])?;
        tx.execute("DELETE FROM playlist_songs WHERE music_id = ?1;", params![music_id])?;
        tx.execute("DELETE FROM play_history WHERE music_id = ?1;", params![music_id])?;

        tx.commit()?;
        Ok(())
    }
}
