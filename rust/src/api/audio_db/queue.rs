use crate::api::audio_db::QueueSnapshot;

use super::DbManager;
use rusqlite::{params, Result};

impl DbManager {
    /// 保存一个队列快照，并在 Rust 侧控制滑动窗口（保存上限 max_limit）。
    ///
    /// 关键修复：前端会传入该“逻辑队列”的稳定唯一 ID（[snapshot_id]）。
    /// - 当 [snapshot_id] 非空时，按该 ID 做 upsert：同一队列被反复保存时
    ///   只更新同一条记录，而不会因为歌曲顺序变化/新增歌曲而重复插入历史。
    /// - 当 [snapshot_id] 为空时，才生成一个全新的 UUID（兼容旧的调用方）。
    pub fn save_queue_snapshot(
        &self,
        songs: &[String],
        current_index: i64,
        max_limit: i64,
        snapshot_id: String,
    ) -> Result<String> {
        if songs.is_empty() {
            return Ok(String::new());
        }

        let mut conn = self.conn.lock().unwrap();
        let tx = conn.transaction()?;

        // 优先复用前端传入的稳定 ID；为空则生成全新 ID
        let snapshot_id = if snapshot_id.trim().is_empty() {
            uuid::Uuid::new_v4().to_string()
        } else {
            snapshot_id
        };
        let now = chrono::Utc::now().timestamp_millis();

        // 1. 主表 upsert：同一逻辑队列复用同一 ID，避免重复插入
        //    （SQLite 的 INSERT OR REPLACE 会先删后插，主表无外键引用，安全）
        tx.execute(
            "INSERT OR REPLACE INTO queue_snapshots (id, current_index, created_at) VALUES (?1, ?2, ?3);",
            params![snapshot_id, current_index, now],
        )?;

        // 2. 先清空该快照旧的歌曲明细，再重新批量写入
        //    （保证顺序变化 / 新增 / 删除歌曲都能被正确覆盖，而不是叠加成脏数据）
        tx.execute(
            "DELETE FROM queue_snapshot_songs WHERE snapshot_id = ?1;",
            params![snapshot_id],
        )?;
        {
            let mut stmt = tx.prepare(
                "INSERT INTO queue_snapshot_songs (snapshot_id, music_id, sort_order) VALUES (?1, ?2, ?3);",
            )?;
            for (order, music_id) in songs.iter().enumerate() {
                stmt.execute(params![snapshot_id, music_id, order as i64])?;
            }
        }

        // 3. 检查当前快照总数
        let total_count: i64 = tx.query_row(
            "SELECT COUNT(*) FROM queue_snapshots;",
            [],
            |row| row.get(0),
        )?;

        // 4. 滑动窗口裁剪 (直接按 i64 比较和计算)
        if total_count > max_limit {
            let overflow = total_count - max_limit;

            // 查出超限的快照 ID 列表
            let expired_ids: Vec<String> = {
                let mut stmt = tx.prepare(
                    "SELECT id FROM queue_snapshots ORDER BY created_at ASC LIMIT ?1;",
                )?;
                let rows = stmt.query_map(params![overflow], |row| row.get(0))?;
                rows.collect::<Result<Vec<String>, _>>()?
            };

            // 手动清理无外键关联的明细表与主表
            for id in &expired_ids {
                tx.execute(
                    "DELETE FROM queue_snapshot_songs WHERE snapshot_id = ?1;",
                    params![id],
                )?;
                tx.execute(
                    "DELETE FROM queue_snapshots WHERE id = ?1;",
                    params![id],
                )?;
            }
        }

        tx.commit()?;
        Ok(snapshot_id)
    }

    /// 获取队列快照历史列表
    pub fn get_queue_history(&self, limit: i64) -> Result<Vec<QueueSnapshot>> { // 👈 改为 i64
        let conn = self.conn.lock().unwrap();

        // 1. 先查出主表快照列表 (可以直接传入 limit)
        let mut stmt = conn.prepare(
            "SELECT id, current_index, created_at FROM queue_snapshots ORDER BY created_at DESC LIMIT ?1;",
        )?;

        let snapshot_rows = stmt.query_map(params![limit], |row| {
            Ok((
                row.get::<_, String>(0)?,
                row.get::<_, i64>(1)?, // 👈 直接提取 i64，无需 as usize
                row.get::<_, i64>(2)?,
            ))
        })?;

        let mut history = Vec::new();

        // 2. 填充每个快照对应的 songs 数组
        for item in snapshot_rows {
            let (id, current_index, created_at) = item?;

            let mut song_stmt = conn.prepare(
                "SELECT music_id FROM queue_snapshot_songs WHERE snapshot_id = ?1 ORDER BY sort_order ASC;",
            )?;

            let songs = song_stmt
                .query_map(params![id], |row| row.get::<_, String>(0))?
                .collect::<Result<Vec<String>, _>>()?;

            history.push(QueueSnapshot {
                id,
                songs,
                current_index, // 👈 结构体对应字段定义也建议同步调整为 i64
                created_at,
            });
        }

        Ok(history)
    }

    pub fn delete_queue_snapshot(&self, snapshot_id: &str) -> Result<()> {
        let mut conn = self.conn.lock().unwrap();
        let tx = conn.transaction()?;

        tx.execute(
            "DELETE FROM queue_snapshot_songs WHERE snapshot_id = ?1;",
            params![snapshot_id],
        )?;
        tx.execute(
            "DELETE FROM queue_snapshots WHERE id = ?1;",
            params![snapshot_id],
        )?;

        tx.commit()?;
        Ok(())
    }

    pub fn clear_queue_history(&self) -> Result<()> {
        let mut conn = self.conn.lock().unwrap();
        let tx = conn.transaction()?;

        tx.execute("DELETE FROM queue_snapshot_songs;", [])?;
        tx.execute("DELETE FROM queue_snapshots;", [])?;

        tx.commit()?;
        Ok(())
    }
}
