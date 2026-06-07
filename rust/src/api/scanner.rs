use jwalk::WalkDirGeneric;
use std::path::{Path, PathBuf};

// 1. 引入自动生成的 StreamSink
use crate::{api::audio_info::get_audio_info, frb_generated::StreamSink};

// 使用 #[frb] 宏标记，让 FRB 自动为 Dart 生成对应的类
#[derive(Debug, Clone)]
pub struct AudioMetadata {
    pub title: String,
    pub artist: String,
    pub album: String,
    
    pub duration_seconds: u32,
    pub path: String,
}

fn is_audio_file(path: &Path) -> bool {
    path.extension()
        .and_then(|ext| ext.to_str())
        .map(|ext| {
            matches!(
                ext.to_lowercase().as_str(),
                "mp3" | "flac" | "m4a" | "wav" | "ogg"
            )
        })
        .unwrap_or(false)
}

/// 并行递归扫描 `dir_path`，通过 StreamSink 实时推送到 Flutter Dart 端
pub fn scan_directory_parallel(dir_path: String, sink: StreamSink<AudioMetadata>) {
    let root = PathBuf::from(&dir_path);
    if !root.exists() {
        eprintln!("[scanner] 路径不存在: {}", dir_path);
        return;
    }

    // 注意：jwalk 内部是在多线程池中运行的
    WalkDirGeneric::<((), bool)>::new(root)
        .skip_hidden(true)
        .into_iter()
        .filter_map(|entry| entry.ok())
        .filter(|entry| entry.file_type().is_file())
        .for_each(|entry| {
            let path = entry.path();
            if !is_audio_file(&path) {
                return;
            }
            //如果路径里包含乱码或非法字符，它不会报错崩溃，而是自动把乱码替换成一个特殊的占位符（通常是 ``），从而保证转换百分之百能成功。
            let path_str = path.to_string_lossy().into_owned();

            if let Ok(info) = get_audio_info(&path_str) {
                let metadata = AudioMetadata {
                    title: info.title,
                    artist: info.artist,
                    album: info.album,
                    duration_seconds: info.duration_seconds,
                    path: path_str,
                };

                // 通过 FRB 的 sink 直接发送给 Dart，安全且支持跨线程
                let _ = sink.add(metadata);
            };
        });

    // 扫描结束时，关闭 sink，Dart 端的 Stream 就会收到 done 事件
    drop(sink);
}
