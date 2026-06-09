use std::{fs, path::Path, sync::OnceLock};

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
    /// 从 metadata.json 的 lyric_path 中读取的 LRC 歌词内容（如有）
    pub lrc_content: Option<String>,
}

pub struct LyricLine {
    pub time_ms: i32,
    pub text: String,
}

/// 尝试读取音频文件同级目录下的 metadata.json，作为元数据的备选来源
fn try_read_metadata_json(audio_path: &str) -> Option<crate::api::metadata::SongMetadata> {
    let parent_dir = Path::new(audio_path).parent()?;
    let dir_str = parent_dir.to_string_lossy().to_string();
    crate::api::metadata::read_metadata(dir_str).ok()
}

/// 读取任意受支持音频格式（MP3 / FLAC / M4A / OGG …）的完整元数据。
/// 当音频内嵌标签缺失时，优先使用同级目录下的 `metadata.json` 作为备选。
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
    let embedded_cover = tag
        .pictures()
        .iter()
        .find(|pic| matches!(pic.pic_type(), lofty::picture::PictureType::CoverFront))
        .or_else(|| tag.pictures().first())
        .map(|pic| pic.data().to_vec());

    // 5. 尝试读取 metadata.json 作为备选
    let metadata_json = try_read_metadata_json(path);

    // 6. 封面优先级：内嵌封面 > metadata.json cover_path > 同级目录图片文件
    let cover_art = match &embedded_cover {
        Some(_) => embedded_cover,
        None => {
            // 尝试从 metadata.json 的 cover_path 读取封面
            let from_meta = metadata_json
                .as_ref()
                .and_then(|m| m.cover_path.as_ref())
                .and_then(|cp| fs::read(cp).ok());
            if from_meta.is_some() {
                from_meta
            } else {
                get_external_cover(path)
            }
        }
    };

    // 7. 从文件名提取兜底歌名
    let file_stem = std::path::Path::new(path)
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("未知歌曲")
        .to_string();

    // 8. 标题优先级：内嵌标签 > metadata.json title > 文件名
    let title = tag
        .title()
        .map(|s| s.into_owned())
        .or_else(|| metadata_json.as_ref().map(|m| m.title.clone()))
        .unwrap_or(file_stem);

    // 9. 歌手优先级：内嵌标签 > metadata.json author
    let artist = tag
        .artist()
        .map(|s| s.into_owned())
        .or_else(|| metadata_json.as_ref().map(|m| m.author.clone()))
        .unwrap_or_else(|| "未知歌手".to_string());

    // 10. 专辑优先级：内嵌标签 > metadata.json source
    let album = tag
        .album()
        .map(|s| s.into_owned())
        .or_else(|| metadata_json.as_ref().map(|m| m.source.clone()))
        .unwrap_or_else(|| "未知专辑".to_string());

    // 11. 读取 LRC 歌词：优先从 metadata.json 的 lyric_path 读取
    let lrc_content = metadata_json
        .as_ref()
        .and_then(|m| m.lyric_path.as_ref())
        .and_then(|lp| fs::read_to_string(lp).ok());

    Ok(AudioInfo {
        title,
        artist,
        album,
        duration_seconds,
        cover_art,
        lrc_content,
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
            if let Ok(bytes) = fs::read(&cover_path) {
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
                if let Ok(bytes) = fs::read(&sibling_cover) {
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

/// 读取歌词文件内容，用于 Dart 端获取 metadata.json 中 lyric_path 指向的完整 LRC 文本。
///
/// # Arguments
/// * `lyric_path` - LRC 文件的完整路径
///
/// # Returns
/// * `Ok(Some(String))` - 读取到的 LRC 文本内容
/// * `Ok(None)` - 文件不存在或读取失败
/// * `Err(String)` - 路径参数为空
pub fn read_lrc_file(lyric_path: String) -> Result<Option<String>, String> {
    if lyric_path.is_empty() {
        return Err("lyric_path 不能为空".to_string());
    }
    match fs::read_to_string(&lyric_path) {
        Ok(content) => Ok(Some(content)),
        Err(e) => {
            eprintln!(
                "[audio_info] 无法读取歌词文件 '{}': {}",
                lyric_path, e
            );
            Ok(None)
        }
    }
}
