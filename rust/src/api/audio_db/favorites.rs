use rusqlite::params;

use crate::api::audio_db::{DbManager, MusicInfo};

const SYSTEM_FAVORITES_ID: &str = "system_favorites";

impl DbManager {
    /// 1. 检查某首歌曲是否已被收藏
    pub fn is_song_favorited(&self, music_id: &str) -> Result<bool, rusqlite::Error> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT 1 FROM playlist_songs WHERE playlist_id = ?1 AND music_id = ?2 LIMIT 1;",
        )?;
        let exists = stmt.exists(params![SYSTEM_FAVORITES_ID, music_id])?;
        Ok(exists)
    }

    /// 2. 切换收藏状态 (Toggle 逻辑)
    /// 如果已收藏则取消收藏，如果未收藏则加入收藏
    pub fn toggle_song_favorite(&self, music_id: &str) -> Result<bool, rusqlite::Error> {
        let conn = self.conn.lock().unwrap();

        // 检查当前状态
        let mut stmt = conn.prepare(
            "SELECT 1 FROM playlist_songs WHERE playlist_id = ?1 AND music_id = ?2 LIMIT 1;",
        )?;
        let is_fav = stmt.exists(params![SYSTEM_FAVORITES_ID, music_id])?;

        if is_fav {
            // 已收藏，执行取消操作
            conn.execute(
                "DELETE FROM playlist_songs WHERE playlist_id = ?1 AND music_id = ?2;",
                params![SYSTEM_FAVORITES_ID, music_id],
            )?;
            Ok(false) // 返回 false 代表当前是未收藏状态
        } else {
            // 未收藏，算一下当前收藏夹的最大排序权重，塞到最后
            let mut order_stmt = conn.prepare(
                "SELECT COALESCE(MAX(sort_order), 0) FROM playlist_songs WHERE playlist_id = ?1;",
            )?;
            let mut rows = order_stmt.query(params![SYSTEM_FAVORITES_ID])?;
            let max_order: i32 = if let Some(row) = rows.next()? {
                row.get(0)?
            } else {
                0
            };

            conn.execute(
                "INSERT INTO playlist_songs (playlist_id, music_id, sort_order) VALUES (?1, ?2, ?3);",
                params![SYSTEM_FAVORITES_ID, music_id, max_order + 1],
            )?;
            Ok(true) // 返回 true 代表当前是已收藏状态
        }
    }

    /// 3. 获取所有收藏的歌曲列表
    /// ✨ 同样利用 INNER JOIN 自动屏蔽掉无外键可能带来的脏数据
    pub fn get_favorite_songs(&self) -> Result<Vec<MusicInfo>, rusqlite::Error> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT m.id, m.title, m.artist, m.album, m.duration_ms, m.cover_path, m.lyrics, m.path
             FROM playlist_songs ps
             INNER JOIN songs m ON ps.music_id = m.id
             WHERE ps.playlist_id = ?1
             ORDER BY ps.sort_order DESC;", // 最新收藏的排在最前面
        )?;

        let rows = stmt.query_map(params![SYSTEM_FAVORITES_ID], |row| {
            Ok(MusicInfo {
                id: row.get(0)?,
                title: row.get(1)?,
                artist: row.get(2)?,
                album: row.get(3)?,
                duration_ms: row.get(4)?,
                cover_path: row.get(5)?,
                lyrics: row.get(6)?,
                path: row.get(7)?,
            })
        })?;

        let mut fav_songs = Vec::new();
        for song in rows {
            fav_songs.push(song?);
        }
        Ok(fav_songs)
    }
}
