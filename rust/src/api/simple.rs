use std::path::Path;

use lofty::{
    file::{AudioFile, TaggedFileExt},
    probe::Probe,
    tag::Accessor,
};

pub struct FlacAudioInfo {
    pub title: String,
    pub artist: String,
    pub album: String,
    pub duration_seconds: u32,
    pub picture: Option<Vec<u8>>,
}


pub fn get_audio_info(path: String) -> Result<FlacAudioInfo, String> {
    // 1. 自动探测并读取文件（它自己会通过文件头或后缀判断是 MP3 还是 FLAC）
    let tagged_file = Probe::open(&path)
        .map_err(|e| format!("无法打开文件: {}", e))?
        .read()
        .map_err(|e| format!("无法读取元数据: {}", e))?;

    // 2. 获取主标签（无论是 ID3 还是 Vorbis，都被抽象成了统一的 Tag）
    let tag = tagged_file
        .primary_tag()
        .or_else(|| tagged_file.first_tag())
        .ok_or_else(|| "该音频文件不包含任何有效的元数据标签".to_string())?;

    // 3. 获取音频流的基础属性（如时长）
    let properties = tagged_file.properties();
    let duration = properties.duration().as_secs() as u32;

    // 4. 提取封面（同样被统一抽象为了 Picture）
    // lofty 内部的 PictureType::CoverFront 对应各格式的正向封面
    let picture_bytes = tag
        .pictures()
        .iter()
        .find(|pic| matches!(pic.pic_type(), lofty::picture::PictureType::CoverFront))
        .or_else(|| tag.pictures().first())
        .map(|pic| pic.data().to_vec());

    Ok(FlacAudioInfo {
        // lofty 提供了统一的 get_string 方法或对应的文本域映射
        title: tag
            .title()
            .map(|s| s.into_owned())
            .unwrap_or_else(|| "未知歌曲".to_string()),
        artist: tag
            .artist()
            .map(|s| s.into_owned())
            .unwrap_or_else(|| "未知歌手".to_string()),
        album: tag
            .album()
            .map(|s| s.into_owned())
            .unwrap_or_else(|| "未知专辑".to_string()),
        duration_seconds: duration,
        picture: picture_bytes,
    })
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

