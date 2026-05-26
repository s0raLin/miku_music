use std::{sync::OnceLock};


// use chrono::Duration;
use lofty::{
    file::{AudioFile, TaggedFileExt},
    probe::Probe,
    tag::{Accessor},
};

use regex::Regex;

/// 从音频文件中读取到的完整元数据
#[derive(Debug, Clone)]
pub struct AudioInfo {
    pub title: String,
    pub artist: String,
    pub album: String,
    pub duration_seconds: u32,
    /// 封面图片的原始字节（JPEG / PNG），若无则为 None
    pub cover_art: Option<Vec<u8>>,
}

pub struct LyricLine {
    pub time_ms: i32,
    pub text: String,
}

/// 读取任意受支持音频格式（MP3 / FLAC / M4A / OGG …）的完整元数据。
///
/// # 错误
/// 返回 `Err(String)` 描述第一个遇到的错误。
pub fn get_audio_info(path: &str) -> Result<AudioInfo, String> {
    // 1. 自动探测格式并读取文件（lofty 通过文件头而非后缀名判断格式）
    let tagged_file = Probe::open(path)
        .map_err(|e| format!("无法打开文件 '{}': {}", path, e))?
        .read()
        .map_err(|e| format!("无法读取元数据 '{}': {}", path, e))?;

    // 2. 获取主标签；若无主标签则退而求其次取第一个
    let tag = tagged_file
        .primary_tag()
        .or_else(|| tagged_file.first_tag())
        .ok_or_else(|| format!("文件 '{}' 不包含任何有效的元数据标签", path))?;

    // 3. 读取时长（来自音频流属性，与标签无关）
    let duration_seconds = tagged_file.properties().duration().as_secs() as u32;

    // 4. 提取封面图片（优先 CoverFront，否则取第一张）
    let cover_art = tag
        .pictures()
        .iter()
        .find(|pic| matches!(pic.pic_type(), lofty::picture::PictureType::CoverFront))
        .or_else(|| tag.pictures().first())
        .map(|pic| pic.data().to_vec());

    // 5. 准备好从文件名提取兜底歌名
    let file_stem = std::path::Path::new(path)
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("未知歌曲")
        .to_string();

    Ok(AudioInfo {
        title: tag.title().map(|s| s.into_owned()).unwrap_or(file_stem),
        artist: tag
            .artist()
            .map(|s| s.into_owned())
            .unwrap_or_else(|| "未知歌手".to_string()),
        album: tag
            .album()
            .map(|s| s.into_owned())
            .unwrap_or_else(|| "未知专辑".to_string()),
        duration_seconds,
        cover_art,
    })
}

// 声明一个全局只编译一次的正则表达式对象
static LRC_REGEX: OnceLock<Regex> = OnceLock::new();
impl AudioInfo {
    pub fn parse_lrc(lrc_content: Option<String>) -> Vec<LyricLine> {
        let content = match lrc_content {
            Some(value) => value,
            None => return Vec::new(),
        };

        // 获取或初始化正则
        let re = LRC_REGEX.get_or_init(|| Regex::new(r"\[(\d+):(\d+(?:\.\d+)?)\](.*)").unwrap());

        let mut lyrics = Vec::new();
        for line in content.lines() {
            if let Some(caps) = re.captures(line) {
                let min = caps.get(1).unwrap().as_str().parse().unwrap_or(0);
                let sec = caps.get(2).unwrap().as_str().parse().unwrap_or(0.0);

                let text = caps.get(3).unwrap().as_str().trim().to_string();

                let time_ms = (min * 60_000) + (sec * 1000.0) as i32;
                // let duration = Duration::milliseconds(total_ms);

                lyrics.push(LyricLine {
                    time_ms,
                    text,
                });
            }
        }

        lyrics.sort_by_key(|line| line.time_ms);

        lyrics
    }
}
