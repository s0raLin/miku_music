use super::{DbManager, MusicInfo};
use rusqlite::{params, Result};

impl DbManager {
    /// 记录一次播放历史，并自动执行“滑动窗口”裁剪
    pub fn add_to_history(&self, music_id: &str) -> Result<()> {
        let mut conn = self.conn.lock().unwrap();
        let tx = conn.transaction()?;

        // 1. 记录或覆盖最新播放时间
        tx.execute(
            "INSERT OR REPLACE INTO play_history (music_id, played_at) VALUES (?1, ?2);",
            params![music_id, chrono::Utc::now().timestamp()],
        )?;

        // 2. 核心裁剪：删掉排名 200 之外的所有旧播放记录
        tx.execute(
            "DELETE FROM play_history WHERE music_id NOT IN (
                SELECT music_id FROM play_history ORDER BY played_at DESC LIMIT 200
             );",
            [],
        )?;

        tx.commit()?;
        Ok(())
    }

    /// 获取最近播放的历史歌曲列表
    pub fn get_play_history(&self) -> Result<Vec<MusicInfo>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT m.id, m.title, m.artist, m.album, m.duration_ms, m.cover_path, m.lyrics, m.path
             FROM play_history h
             INNER JOIN songs m ON h.music_id = m.id
             ORDER BY h.played_at DESC;"
        )?;

        let rows = stmt.query_map([], |row| {
            Ok(MusicInfo {
                id: row.get(0)?, title: row.get(1)?, artist: row.get(2)?,
                album: row.get(3)?, duration_ms: row.get(4)?, cover_path: row.get(5)?,
                lyrics: row.get(6)?, path: row.get(7)?,
            })
        })?;

        let mut history = Vec::new();
        for item in rows { history.push(item?); }
        Ok(history)
    }

    /// 清空播放历史
    pub fn clear_history(&self) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute("DELETE FROM play_history;", [])?;
        Ok(())
    }
}
