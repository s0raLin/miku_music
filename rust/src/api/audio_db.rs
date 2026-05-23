use std::sync::Mutex;

use rusqlite::{params, Connection, Result};

pub struct DbManager {
    conn: Mutex<Connection>,
}

#[derive(Debug, Clone)]
pub struct MusicInfo {
    pub id: String,
    pub title: String,
    pub artist: String,
    pub album: Option<String>,
    pub duration_ms: i64,
    pub cover_path: Option<String>, // 变成封面的本地绝对路径
    pub lyrics: Option<String>,
    pub path: String,
}

impl DbManager {
    /// 初始化数据库并建表
    pub fn new(db_path: &str) -> Result<Self> {
        let conn = Connection::open(db_path)?;

        // 开启外键支持
        conn.execute("PRAGMA foreign_keys = ON;", [])?;

        // 创建歌曲表
        conn.execute(
            "CREATE TABLE IF NOT EXISTS songs (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              artist TEXT,
              album TEXT,
              duration_ms INTEGER,
              cover_path TEXT,
              lyrics TEXT,
              path TEXT NOT NULL
            );",
            [],
        )?;
        // 用 Mutex 把 Connection 锁在里面
        Ok(DbManager {
            conn: Mutex::new(conn),
        })
    }

    /// 插入一首新歌
    pub fn insert_song(&self, music: MusicInfo) -> Result<()> {
        //每次使用前先获取锁
        let conn = self.conn.lock().unwrap();

        conn.execute(
            "INSERT OR REPLACE INTO songs (id, title, artist, album, duration_ms, cover_path, lyrics, path) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8);",
            params![
              &music.id,
              &music.title,
              &music.artist,
              &music.album,
              &music.duration_ms,
              &music.cover_path,
              &music.lyrics,
              &music.path,
            ],
        )?;
        Ok(())
    }

    pub fn get_song(&self, id: String) -> Result<Option<MusicInfo>> {
        let conn = self.conn.lock().unwrap();

        let mut stmt = conn.prepare(
            "SELECT id, title, artist, album, duration_ms, cover_path, lyrics, path
             FROM songs
             WHERE id = ?1;",
        )?;

        let mut rows = stmt.query(params![id])?;

        if let Some(row) = rows.next()? {
            // 查到了，构建 MusicInfo 并返回
            Ok(Some(MusicInfo {
                id: row.get(0)?,
                title: row.get(1)?,
                artist: row.get(2)?,
                album: row.get(3)?,
                duration_ms: row.get(4)?,
                cover_path: row.get(5)?,
                lyrics: row.get(6)?,
                path: row.get(7)?,
            }))
        } else {
            //没查到对应ID
            Ok(None)
        }
    }
}
