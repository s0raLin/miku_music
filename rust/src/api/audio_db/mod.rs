pub mod favorites;
pub mod history;
pub mod playlists;
pub mod songs;

use std::sync::Mutex;

use rusqlite::Connection;

pub struct DbManager {
    conn: Mutex<Connection>,
}

#[derive(Debug, Clone)]
pub struct MusicInfo {
    pub id: String,
    pub title: String,
    pub artist: Option<String>, // 健壮性优化：本地歌可能没有艺术家信息
    pub album: Option<String>,
    pub duration_ms: i64,
    pub cover_path: Option<String>,
    pub lyrics: Option<String>,
    pub path: String,
}

#[derive(Debug, Clone)]
pub struct PlaylistInfo {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub cover_path: Option<String>,
    pub is_system: i32, // 0: 用户自建, 1: 系统歌单
    pub ids: Vec<String>,
    pub created_at: i64,
    pub updated_at: i64,
}

impl DbManager {
    pub fn new(db_path: String) -> Result<Self, rusqlite::Error> {
        let conn = Connection::open(&db_path)?;

        let init_sql = include_str!("../../migrations/init.sql");
        conn.execute_batch(init_sql)?;

        let now = chrono::Utc::now().timestamp();
        conn.execute(
            "INSERT OR IGNORE INTO playlists (id, name, description, is_system, created_at, updated_at)
             VALUES ('system_favorites', '我喜欢', '系统内置收藏夹', 1, ?1, ?1);",
            rusqlite::params![now],
        )?;
        Ok(DbManager {
            conn: Mutex::new(conn),
        })
    }
}
