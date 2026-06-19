use std::{fs, path::Path, sync::OnceLock};

// use chrono::Duration;
use lofty::{
    file::{AudioFile, TaggedFileExt},
    probe::Probe,
    tag::Accessor,
};

use quick_xml::events::Event;
use quick_xml::Reader;
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
    /// 从 metadata.json 的 lyric_path 中读取的歌词原始文本内容（如有）
    pub lyric_raw_content: Option<String>,
}

/// 逐词高亮所需的单个词信息
#[derive(Debug, Clone)]
pub struct LyricWord {
    pub text: String,
    pub start_ms: i32,
    pub end_ms: i32,
}

/// 一行歌词（支持逐词时间戳）
#[derive(Debug, Clone)]
pub struct LyricLine {
    pub time_ms: i32,
    /// 整行持续时长（ms），TTML 可提供，LRC 填 0
    pub duration_ms: i32,
    pub text: String,
    /// 逐词信息，仅 TTML 格式提供；LRC 格式为空
    pub words: Vec<LyricWord>,
}

/// 歌词格式枚举
#[derive(Debug, Clone, PartialEq)]
pub enum LyricFormat {
    Lrc,
    Ttml,
    Unknown,
}

/// 根据内容自动检测歌词格式
pub fn detect_lyric_format(content: &str) -> LyricFormat {
    let trimmed = content.trim();
    // TTML 以 XML 声明或 <tt 开头
    if trimmed.starts_with("<?xml") || trimmed.starts_with("<tt") {
        return LyricFormat::Ttml;
    }
    // LRC 以 [mm:ss 时间标签开头
    if Regex::new(r"^\[\d+:\d+")
        .map(|re| re.is_match(trimmed))
        .unwrap_or(false)
    {
        return LyricFormat::Lrc;
    }
    LyricFormat::Unknown
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

    // 11. 读取歌词原始文本：优先从 metadata.json 的 lyric_path 读取
    let lyric_raw_content = metadata_json
        .as_ref()
        .and_then(|m| m.lyric_path.as_ref())
        .and_then(|lp| fs::read_to_string(lp).ok());

    Ok(AudioInfo {
        title,
        artist,
        album,
        duration_seconds,
        cover_art,
        lyric_raw_content,
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
    /// 根据原始歌词内容自动检测格式（LRC 或 TTML）并解析。
    /// 返回解析后的 `Vec<LyricLine>`，TTML 格式会携带逐词信息。
    pub fn parse_lyrics(lyric_raw_content: Option<String>) -> Vec<LyricLine> {
        let content = match lyric_raw_content {
            Some(value) if !value.trim().is_empty() => value,
            _ => return Vec::new(),
        };

        match detect_lyric_format(&content) {
            LyricFormat::Ttml => Self::parse_ttml(&content),
            LyricFormat::Lrc => Self::parse_lrc_inner(&content),
            LyricFormat::Unknown => {
                // fallback: try LRC anyway
                Self::parse_lrc_inner(&content)
            }
        }
    }

    /// 解析 LRC 格式歌词（内部方法）
    fn parse_lrc_inner(content: &str) -> Vec<LyricLine> {
        let re = LRC_REGEX.get_or_init(|| {
            Regex::new(r"\[(?P<min>\d+):(?P<sec>\d+)(?:[.:](?P<ms>\d+))?\](?P<text>.*)").unwrap()
        });

        let mut lyrics = Vec::new();
        for line in content.lines() {
            if let Some(caps) = re.captures(line) {
                let min: i32 = caps
                    .name("min")
                    .map(|m| m.as_str().parse().unwrap_or(0))
                    .unwrap_or(0);
                let sec: i32 = caps
                    .name("sec")
                    .map(|m| m.as_str().parse().unwrap_or(0))
                    .unwrap_or(0);

                let mut ms: i32 = 0;
                if let Some(ms_match) = caps.name("ms") {
                    let ms_str = ms_match.as_str();
                    if let Ok(raw_ms) = ms_str.parse::<i32>() {
                        match ms_str.len() {
                            1 => ms = raw_ms * 100,
                            2 => ms = raw_ms * 10,
                            _ => ms = raw_ms,
                        }
                    }
                }

                let text = caps
                    .name("text")
                    .map(|m| m.as_str().trim().to_string())
                    .unwrap_or_default();

                let time_ms = (min * 60_000) + (sec * 1000) + ms;

                lyrics.push(LyricLine {
                    time_ms,
                    duration_ms: 0,
                    text,
                    words: Vec::new(),
                });
            }
        }

        lyrics.sort_by_key(|line| line.time_ms);
        lyrics
    }

    /// 解析 TTML (IMSC) 格式歌词（逐词高亮支持）
    fn parse_ttml(content: &str) -> Vec<LyricLine> {
        let mut reader = Reader::from_str(content);
        reader.config_mut().trim_text(true);

        let mut lyrics: Vec<LyricLine> = Vec::new();
        let mut current_line: Option<LyricLine> = None;

        let mut buf = Vec::new();

        loop {
            match reader.read_event_into(&mut buf) {
                Ok(Event::Start(ref e)) => {
                    let tag_name = String::from_utf8_lossy(e.name().as_ref()).to_string();

                    match tag_name.as_str() {
                        "p" => {
                            // <p begin="..." end="..."> → 一行歌词
                            let begin_str = extract_attr(e, b"begin");
                            let end_str = extract_attr(e, b"end");
                            let time_ms = parse_ttml_time(&begin_str);
                            let end_ms = parse_ttml_time(&end_str);
                            let duration_ms = if end_ms > time_ms {
                                end_ms - time_ms
                            } else {
                                0
                            };

                            current_line = Some(LyricLine {
                                time_ms,
                                duration_ms,
                                text: String::new(),
                                words: Vec::new(),
                            });
                        }
                        "span" => {
                            // <span begin="..." end="...">word</span>
                            if let Some(ref mut line) = current_line {
                                let word_begin = extract_attr(e, b"begin");
                                let word_end = extract_attr(e, b"end");
                                let start_ms = parse_ttml_time(&word_begin);
                                let end_ms = parse_ttml_time(&word_end);

                                // 读取 span 内的文本
                                let text = reader
                                    .read_text(e.name().clone())
                                    .ok()
                                    .map(|bt| {
                                        String::from_utf8_lossy(bt.as_ref())
                                            .trim()
                                            .to_string()
                                    })
                                    .unwrap_or_default();

                                if !text.is_empty() {
                                    line.words.push(LyricWord {
                                        text: text.clone(),
                                        start_ms,
                                        end_ms,
                                    });
                                    line.text.push_str(&text);
                                }
                            }
                        }
                        _ => {}
                    }
                }
                Ok(Event::Text(ref e)) => {
                    // 处理 <p> 标签内的纯文本（非 span 包裹的文本）
                    let text = String::from_utf8_lossy(e.as_ref())
                        .trim()
                        .to_string();
                    if text.is_empty() {
                        buf.clear();
                        continue;
                    }

                    if let Some(ref mut line) = current_line {
                        // 如果该行还没有 words，说明没有 span 标签，使用整行作为一个词
                        if line.words.is_empty() {
                            line.text = text.clone();
                            line.words.push(LyricWord {
                                text: text,
                                start_ms: line.time_ms,
                                end_ms: line.time_ms + line.duration_ms,
                            });
                        }
                        // 否则已在 span 中处理，不需要额外处理
                    }
                }
                Ok(Event::End(ref e)) => {
                    let tag_name = String::from_utf8_lossy(e.name().as_ref()).to_string();
                    if tag_name == "p" {
                        if let Some(line) = current_line.take() {
                            if !line.text.trim().is_empty() {
                                lyrics.push(line);
                            }
                        }
                    }
                }
                Ok(Event::Eof) => break,
                Err(e) => {
                    eprintln!("[ttml] XML parse error: {}", e);
                    break;
                }
                _ => {}
            }
            buf.clear();
        }

        // 按开始时间排序
        lyrics.sort_by_key(|line| line.time_ms);
        lyrics
    }
}

/// 从 XML 属性中提取值
fn extract_attr(e: &quick_xml::events::BytesStart, attr_name: &[u8]) -> String {
    e.attributes()
        .filter_map(|a| a.ok())
        .find(|a| a.key.as_ref() == attr_name)
        .map(|a| String::from_utf8_lossy(&a.value).to_string())
        .unwrap_or_default()
}

/// 解析 TTML 时间格式，如 "00:01:23.456" 或 "01:23.456" → 毫秒
fn parse_ttml_time(time_str: &str) -> i32 {
    if time_str.is_empty() {
        return 0;
    }

    // 格式: hh:mm:ss.ms 或 mm:ss.ms
    let parts: Vec<&str> = time_str.split(':').collect();
    match parts.len() {
        3 => {
            // hh:mm:ss.ms
            let h: i32 = parts[0].parse().unwrap_or(0);
            let m: i32 = parts[1].parse().unwrap_or(0);
            let s_parts: Vec<&str> = parts[2].split('.').collect();
            let s: i32 = s_parts.get(0).and_then(|v| v.parse().ok()).unwrap_or(0);
            let ms: i32 = if s_parts.len() > 1 {
                let ms_str = s_parts[1];
                let raw: i32 = ms_str.parse().unwrap_or(0);
                match ms_str.len() {
                    1 => raw * 100,
                    2 => raw * 10,
                    _ => raw,
                }
            } else {
                0
            };
            h * 3_600_000 + m * 60_000 + s * 1000 + ms
        }
        2 => {
            // mm:ss.ms
            let m: i32 = parts[0].parse().unwrap_or(0);
            let s_parts: Vec<&str> = parts[1].split('.').collect();
            let s: i32 = s_parts.get(0).and_then(|v| v.parse().ok()).unwrap_or(0);
            let ms: i32 = if s_parts.len() > 1 {
                let ms_str = s_parts[1];
                let raw: i32 = ms_str.parse().unwrap_or(0);
                match ms_str.len() {
                    1 => raw * 100,
                    2 => raw * 10,
                    _ => raw,
                }
            } else {
                0
            };
            m * 60_000 + s * 1000 + ms
        }
        _ => 0,
    }
}

/// 读取歌词文件内容，用于 Dart 端获取 metadata.json 中 lyric_path 指向的完整歌词文本。
///
/// # Arguments
/// * `lyric_path` - 歌词文件的完整路径（支持 .lrc / .ttml / .xml）
///
/// # Returns
/// * `Ok(Some(String))` - 读取到的歌词文本内容
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
