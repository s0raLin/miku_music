use super::{DbManager, MusicInfo, PlaylistInfo};
use rusqlite::{params, Result};

impl DbManager {
    // ─────────────────────────────────────────────
    // 1. 歌单自身的增删改查 (CRUD)
    // ─────────────────────────────────────────────

    /// 创建一个新歌单（让 Rust 自动生成唯一 ID 并返回给前端）
    pub fn create_playlist(
        &self,
        name: &str,
        description: Option<String>,
        cover_path: Option<String>, // 创建歌单时允许附带封面路径
        is_system: bool,
    ) -> Result<String> { // 🌟 建议返回 String (ID)，方便 Dart 创建完后直接拿着 ID 跳转
        let conn = self.conn.lock().unwrap();
        let now = chrono::Utc::now().timestamp();
        let generated_id = uuid::Uuid::new_v4().to_string();

        // 🌟 修复：SQL 显式指定 7 个字段
        conn.execute(
            "INSERT INTO playlists (id, name, description, cover_path, is_system, created_at, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7);",
            params![
                &generated_id,
                name,
                description,
                cover_path,
                if is_system { 1 } else { 0 },
                now,
                now
            ],
        )?;
        Ok(generated_id)
    }

    /// 修改歌单信息
    pub fn update_playlist(
        &self,
        id: &str, // 🌟 必须传入歌单 ID，否则不知道更新谁！
        name: &str,
        description: Option<String>,
        cover_path: Option<String>,
    ) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        let now = chrono::Utc::now().timestamp();

        // 🌟 修复：补上了缺少的逗号，并且带上了精准的 WHERE 子句
        conn.execute(
            "UPDATE playlists SET name = ?1, description = ?2, cover_path = ?3, updated_at = ?4 WHERE id = ?5;",
            params![name, description, cover_path, now, id],
        )?;
        Ok(())
    }

    /// 删除指定歌单
    /// ⚠️ 无外键约束，必须手动用事务清除该歌单下的关联映射记录
    pub fn delete_playlist(&self, playlist_id: &str) -> Result<()> {
        let mut conn = self.conn.lock().unwrap();
        let tx = conn.transaction()?;

        tx.execute("DELETE FROM playlists WHERE id = ?1;", params![playlist_id])?;
        tx.execute(
            "DELETE FROM playlist_songs WHERE playlist_id = ?1;",
            params![playlist_id],
        )?;

        tx.commit()?;
        Ok(())
    }

    /// 获取所有歌单（包括自建和系统歌单）
    pub fn get_all_playlists(&self) -> Result<Vec<PlaylistInfo>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT id, name, description, cover_path, is_system, created_at, updated_at FROM playlists ORDER BY created_at DESC;")?;

        let rows = stmt.query_map([], |row| {
            // 🌟 修复：拉直并完美对齐 0 ~ 6 的所有映射下标！
            Ok(PlaylistInfo {
                id: row.get(0)?,
                name: row.get(1)?,
                description: row.get(2)?,
                cover_path: row.get(3)?,
                is_system: row.get(4)?, // 从 3 修正为 4
                created_at: row.get(5)?, // 从 4 修正为 5
                updated_at: row.get(6)?, // 从 5 修正为 6
            })
        })?;

        let mut list = Vec::new();
        for item in rows {
            list.push(item?);
        }
        Ok(list)
    }

    // ─────────────────────────────────────────────
    // 2. 歌单与歌曲的连接操作 (Many-to-Many)
    // ─────────────────────────────────────────────

    /// 向歌单中添加一首歌曲（附带排序权重）
    pub fn add_song_to_playlist(&self, playlist_id: &str, music_id: &str) -> Result<()> {
        let conn = self.conn.lock().unwrap();

        // 先查出当前歌单里最大的 sort_order，让新歌排在末尾
        let mut stmt = conn.prepare(
            "SELECT COALESCE(MAX(sort_order), 0) FROM playlist_songs WHERE playlist_id = ?1;",
        )?;
        let mut rows = stmt.query(params![playlist_id])?;
        let max_order: i32 = if let Some(row) = rows.next()? {
            row.get(0)?
        } else {
            0
        };

        conn.execute(
            "INSERT OR IGNORE INTO playlist_songs (playlist_id, music_id, sort_order) VALUES (?1, ?2, ?3);",
            params![playlist_id, music_id, max_order + 1],
        )?;
        Ok(())
    }

    /// 获取某个歌单内所有歌曲的 ID 列表（轻量级查询）
    pub fn get_song_ids_in_playlist(&self, playlist_id: &str) -> Result<Vec<String>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT music_id FROM playlist_songs WHERE playlist_id = ?1 ORDER BY sort_order ASC;"
        )?;

        let ids = stmt.query_map([playlist_id], |row| row.get::<_, String>(0))?
            .collect::<Result<Vec<_>, _>>()?;

        Ok(ids)
    }

    /// 从指定歌单中移除一首歌曲
    pub fn remove_song_from_playlist(&self, playlist_id: &str, music_id: &str) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute(
            "DELETE FROM playlist_songs WHERE playlist_id = ?1 AND music_id = ?2;",
            params![playlist_id, music_id],
        )?;
        Ok(())
    }

    /// 核心查询：基于 INNER JOIN 获取特定歌单内的所有歌曲
    /// ✨ 即使数据由于没有外键产生了残留不一致，INNER JOIN 也会自动过滤非法的 music_id
    pub fn get_songs_in_playlist(&self, playlist_id: &str) -> Result<Vec<MusicInfo>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            "SELECT m.id, m.title, m.artist, m.album, m.duration_ms, m.cover_path, m.lyrics, m.path
             FROM playlist_songs ps
             INNER JOIN songs m ON ps.music_id = m.id
             WHERE ps.playlist_id = ?1
             ORDER BY ps.sort_order ASC;",
        )?;

        let rows = stmt.query_map(params![playlist_id], |row| {
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

        let mut songs = Vec::new();
        for song in rows {
            songs.push(song?);
        }
        Ok(songs)
    }
}
