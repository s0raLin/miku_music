-- migrations/init.sql

-- 1. 歌曲主表
CREATE TABLE IF NOT EXISTS songs (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    artist TEXT,
    album TEXT,
    path TEXT NOT NULL,
    duration_ms INTEGER NOT NULL,
    lyrics TEXT,
    cover_path TEXT,
    updated_at INTEGER NOT NULL
);

-- 2. 歌单主表
CREATE TABLE IF NOT EXISTS playlists (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    is_system INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 3. 歌单-歌曲 交叉连接表（无外键版）
CREATE TABLE IF NOT EXISTS playlist_songs (
    playlist_id TEXT,
    music_id TEXT,
    sort_order INTEGER,
    PRIMARY KEY (playlist_id, music_id)
);

-- 4. 播放历史表
CREATE TABLE IF NOT EXISTS play_history (
    music_id TEXT PRIMARY KEY,
    played_at INTEGER NOT NULL
);

