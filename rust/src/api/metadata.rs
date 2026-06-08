use serde::{Deserialize, Serialize};
use std::path::Path;

/// Represents the metadata.json file stored alongside downloaded songs.
/// Contains local file paths to the downloaded audio, lyrics, and cover image.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SongMetadata {
    pub id: String,
    pub title: String,
    pub author: String,
    pub source: String,
    /// Local path to the downloaded audio file (e.g. .../歌曲名 - 歌手名.mp3)
    pub audio_path: String,
    /// Local path to the downloaded lyrics file, if available (e.g. .../歌曲名 - 歌手名.lrc)
    #[serde(default)]
    pub lyric_path: Option<String>,
    /// Local path to the downloaded cover image, if available (e.g. .../cover.jpg)
    #[serde(default)]
    pub cover_path: Option<String>,
}

/// Read and parse a metadata.json file from the given directory path.
///
/// Looks for `metadata.json` inside the provided directory (typically a
/// song-specific folder like `M3Music/歌曲名 - 歌手名/`).
///
/// # Arguments
/// * `dir_path` - Path to the directory containing metadata.json
///
/// # Returns
/// * `Ok(SongMetadata)` on successful parse
/// * `Err(String)` describing what went wrong
pub fn read_metadata(dir_path: String) -> Result<SongMetadata, String> {
    let metadata_path = Path::new(&dir_path).join("metadata.json");

    let content = std::fs::read_to_string(&metadata_path).map_err(|e| {
        format!(
            "无法读取 metadata.json 文件 '{}': {}",
            metadata_path.display(),
            e
        )
    })?;

    let metadata: SongMetadata = serde_json::from_str(&content).map_err(|e| {
        format!(
            "无法解析 metadata.json 文件 '{}': {}",
            metadata_path.display(),
            e
        )
    })?;

    Ok(metadata)
}
