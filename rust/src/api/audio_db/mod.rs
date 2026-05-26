pub mod songs;
pub mod playlists;
pub mod history;
pub mod favorites;

use std::sync::Mutex;

use rusqlite::Connection;

pub struct DbManager {
    conn: Mutex<Connection>,
}

#[derive(Debug, Clone)]
pub struct MusicInfo {
    pub id: String,
    pub title: String,
    pub artist: Option<String>,    // 健壮性优化：本地歌可能没有艺术家信息
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
    pub is_system: i32, // 0: 用户自建, 1: 系统歌单
    pub created_at: i64,
    pub updated_at: i64,
}
