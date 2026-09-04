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
    cover_path TEXT,
    is_system INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 3. 歌单-歌曲 交叉连接表
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


-- 5. 队列快照历史主表
CREATE TABLE IF NOT EXISTS queue_snapshots (
    id TEXT PRIMARY KEY,
    current_index INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL
);
-- 6. 队列快照 - 歌曲明细表（无外键约束）
CREATE TABLE IF NOT EXISTS queue_snapshot_songs (
    snapshot_id TEXT NOT NULL,
    music_id TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    PRIMARY KEY (snapshot_id, sort_order)
);
-- 索引优化：加速按时间倒序查询历史快照与关联明细查找
CREATE INDEX IF NOT EXISTS idx_queue_snapshots_created_at ON queue_snapshots(created_at);
CREATE INDEX IF NOT EXISTS idx_queue_snapshot_songs_snapshot_id ON queue_snapshot_songs(snapshot_id);
