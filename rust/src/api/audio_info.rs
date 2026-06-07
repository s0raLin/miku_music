use std::{path::Path, sync::OnceLock};

// use chrono::Duration;
use lofty::{
    file::{AudioFile, TaggedFileExt},
    probe::Probe,
    tag::Accessor,
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
    let mut cover_art = tag
        .pictures()
        .iter()
        .find(|pic| matches!(pic.pic_type(), lofty::picture::PictureType::CoverFront))
        .or_else(|| tag.pictures().first())
        .map(|pic| pic.data().to_vec());

    // ─── 如果音频内部没有嵌封面，去同级目录下找 cover.jpg ───
    if cover_art.is_none() {
        cover_art = get_external_cover(path);
    }

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

pub fn get_external_cover(audio_path: &str) -> Option<Vec<u8>> {
    // 1. 获取音频文件所在的父目录
    let audio_path_obj = Path::new(audio_path);
    let parent_dir = audio_path_obj.parent()?;

    // 2. 定义常见的外置封面文件名（按优先级排序，不区分大小写更安全，这里列出常见组合）
    let possible_names = [
        "cover.jpg",
        "cover.png",
        "cover.jpeg",
        "Folder.jpg", // 很多 Windows 音乐软件喜欢导出的格式
        "folder.jpg",
    ];

    // 3. 遍历并检查哪个文件存在
    for name in &possible_names {
        let cover_path = parent_dir.join(name);
        if cover_path.is_file() {
            // 读取图片文件的原始字节
            if let Ok(bytes) = std::fs::read(&cover_path) {
                return Some(bytes);
            }
        }
    }

    // 4. 如果没找到固定命名的 cover，还可以做一层高级兜底：
    // 寻找跟音频同名但后缀是图片的文件（例如：Music.mp3 -> Music.jpg）
    if let Some(file_stem) = audio_path_obj.file_stem() {
        for ext in &["jpg", "png", "jpeg"] {
            let sibling_cover = parent_dir.join(file_stem).with_extension(ext);
            if sibling_cover.is_file() {
                if let Ok(bytes) = std::fs::read(&sibling_cover) {
                    return Some(bytes);
                }
            }
        }
    }

    None
}

// 声明一个全局只编译一次的正则表达式对象
static LRC_REGEX: OnceLock<Regex> = OnceLock::new();
impl AudioInfo {
    pub fn parse_lrc(lrc_content: Option<String>) -> Vec<LyricLine> {
        let content = match lrc_content {
            Some(value) => value,
            None => return Vec::new(),
        };

        // 使用命名捕获组：?<min> 分钟，?<sec> 秒，?<ms> 毫秒，?<text> 歌词文本
        let re = LRC_REGEX.get_or_init(|| {
            Regex::new(r"\[(?P<min>\d+):(?P<sec>\d+)(?:[.:](?P<ms>\d+))?\](?P<text>.*)").unwrap()
        });

        let mut lyrics = Vec::new();
        for line in content.lines() {
            if let Some(caps) = re.captures(line) {
                // 1. 安全提取分钟和秒
                let min: i32 = caps
                    .name("min")
                    .map(|m| m.as_str().parse().unwrap_or(0))
                    .unwrap_or(0);
                let sec: i32 = caps
                    .name("sec")
                    .map(|m| m.as_str().parse().unwrap_or(0))
                    .unwrap_or(0);

                // 2. 提取并计算毫秒
                let mut ms: i32 = 0;
                if let Some(ms_match) = caps.name("ms") {
                    let ms_str = ms_match.as_str();
                    if let Ok(raw_ms) = ms_str.parse::<i32>() {
                        // 适配 .83 -> 830ms, .5 -> 500ms 等不同长度的写法
                        match ms_str.len() {
                            1 => ms = raw_ms * 100,
                            2 => ms = raw_ms * 10,
                            _ => ms = raw_ms,
                        }
                    }
                }

                // 3. 通过名字精确拿到歌词文本，绝不会错位！
                let text = caps
                    .name("text")
                    .map(|m| m.as_str().trim().to_string())
                    .unwrap_or_default();

                // 4. 计算总时间
                let time_ms = (min * 60_000) + (sec * 1000) + ms;

                lyrics.push(LyricLine { time_ms, text });
            }
        }

        lyrics.sort_by_key(|line| line.time_ms);
        lyrics
    }
}
