use std::path::Path;

use id3::TagLike;
use metaflac::block::PictureType;

pub struct FlacAudioInfo {
    pub title: String,
    pub artist: String,
    pub album: String,
    pub duration_seconds: u32,
    pub picture: Option<Vec<u8>>,
}

pub fn parse_flac_file(path: String) -> Result<FlacAudioInfo, String> {
    let path_obj = Path::new(&path);

    let extension = path_obj
        .extension()
        .and_then(|ext| ext.to_str())
        .map(|ext| ext.to_lowercase())
        .unwrap_or_default();

    match extension.as_str() {
        "flac" => {
            let tag = metaflac::Tag::read_from_path(&path)
                .map_err(|e| format!("无法读取音频文件 {}", e))?;

            let vorbis = tag
                .vorbis_comments()
                .ok_or_else(|| "该音频文件不包含有效的元数据块".to_string())?;

            let stream_info = tag
                .get_streaminfo()
                .ok_or_else(|| "无法获取音频流信息".to_string())?;

            let duration = if stream_info.sample_rate > 0 {
                (stream_info.total_samples / stream_info.sample_rate as u64) as u32
            } else {
                0
            };

            // 在所有图片块中，优先寻找 FrontCover（前封面）
            let picture_bytes = tag
                .pictures()
                .find(|pic| matches!(pic.picture_type, PictureType::CoverFront)) // 找到正向封面
                .or_else(|| tag.pictures().next()) // 如果没有就拿第一张图
                .map(|pic| pic.data.clone()); //复制出图片字节流Vec<u8>

            Ok(FlacAudioInfo {
                title: vorbis.title().map(|v| v[0].clone()).unwrap_or_default(),
                artist: vorbis.artist().map(|v| v[0].clone()).unwrap_or_default(),
                album: vorbis.album().map(|v| v[0].clone()).unwrap_or_default(),
                duration_seconds: duration,
                picture: picture_bytes, //塞入封面数据
            })
        }
        "mp3" => {
            // 读取 MP3 的 ID3 标签
            let tag =
                id3::Tag::read_from_path(&path).map_err(|e| format!("无法读取 MP3 文件: {}", e))?;

            // 获取音频时长（从计算好的属性中获取，或者有些库可以通过其他方式拿，id3 库需要开启特定的 feature 或者读取元数据）
            // 如果只是纯 id3 库，可以用较新版提供的机制，或者保守给个 0
            // 这里我们通过 tag.duration() 直接获取（前提是包含相应帧）
            let duration = tag.duration().unwrap_or(0);

            // 提取 MP3 里的封面（寻找 FrontCover 类型）
            let picture_bytes = tag
                .pictures()
                .find(|pic| matches!(pic.picture_type, id3::frame::PictureType::CoverFront))
                .or_else(|| tag.pictures().next())
                .map(|pic| pic.data.clone());

            Ok(FlacAudioInfo {
                // id3 提供了直接拿 title() 和 artist() 的方法
                title: tag.title().map(String::from).unwrap_or_default(),
                artist: tag.artist().map(String::from).unwrap_or_default(),
                album: tag.album().map(String::from).unwrap_or_default(),
                duration_seconds: duration,
                picture: picture_bytes,
            })
        }
        //暂不支持的其他格式
        _ => Err(format!("目前暂不支持 .{} 格式的音频解析", extension)),
    }
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
