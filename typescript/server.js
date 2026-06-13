import express from 'express';
import cors from 'cors';
import Meting from '@meting/core';

const app = express();

// 一劳永逸支持所有请求类型跨域
app.use(cors());

// ==================== 🛠️ 数据清洗辅助函数 ====================

// 1. 清洗单曲数据结构
function cleanSongData(song, source = 'netease') {
  return {
    id: String(song.id),
    title: song.name || '未知歌名',
    author: song.ar?.map(artist => artist.name).join(', ') || song.artists?.map(a => a.name).join(', ') || '未知歌手',
    pic: song.al?.picUrl || song.album?.picUrl || '',
    url: `/api/url?id=${song.id}&source=${source}`,
    source: source
  };
}

// 2. 清洗歌单简要数据结构
function cleanPlaylistData(playlist, source = 'netease') {
  return {
    id: String(playlist.id),
    title: playlist.name || '未知歌单',
    creator: playlist.creator?.nickname || '未知创建者',
    pic: playlist.coverImgUrl || playlist.picUrl || '',
    playCount: playlist.playCount || 0,
    trackCount: playlist.trackCount || 0,
    source: source
  };
}

// ✨ 新增 3. 清洗专辑简要数据结构
function cleanAlbumData(album, source = 'netease') {
  return {
    id: String(album.id),
    title: album.name || '未知专辑',
    author: album.artist?.name || album.artists?.map(a => a.name).join(', ') || '未知歌手',
    pic: album.picUrl || album.blurPicUrl || '',
    publishTime: album.publishTime || null,
    size: album.size || 0, // 专辑内歌曲数量
    source: source
  };
}

// ✨ 新增 4. 清洗歌手简要数据结构
function cleanArtistData(artist, source = 'netease') {
  return {
    id: String(artist.id),
    name: artist.name || '未知歌手',
    pic: artist.picUrl || artist.img1v1Url || '',
    albumSize: artist.albumSize || 0,
    musicSize: artist.musicSize || 0,
    source: source
  };
}

// 安全解析 Meting 返回的各类原始数据
function parseRawData(rawData) {
  if (!rawData) return null;
  try {
    const rawString = rawData.toString();
    return JSON.parse(rawString);
  } catch (e) {
    return rawData;
  }
}

// 排行榜 ID 映射配置
const TOP_LISTS = {
  netease: {
    hot: '3778678',
    new: '3779629',
    soaring: '19723756',
    original: '2884035'
  },
  tencent: {
    hot: '26',
    new: '27'
  }
};

// ==================== 🛣️ 路由接口 ====================

// ✨ 完美重构：多功能万能搜索接口（支持单曲、歌手、专辑、歌单）
app.get('/api/search', async (req, res) => {
  // type 可选值: song(单曲), artist(歌手), album(专辑), playlist(歌单)
  const { keyword, type = 'song', source = 'netease', limit = 20 } = req.query;

  if (!keyword) return res.status(400).json({ error: '请输入搜索关键词' });

  // 映射前端易读的 type 到 Meting 内部的数字 type
  const typeMapping = {
    song: 1,
    album: 10,
    artist: 100,
    playlist: 1000
  };

  const metingType = typeMapping[type];
  if (!metingType) {
    return res.status(400).json({ error: `不支持的搜索类型: ${type}。可选值: song, artist, album, playlist` });
  }

  try {
    const meting = new Meting(source);
    meting.format(false);

    // 调用 Meting 进行搜索，传入类型和数量限制
    const rawData = await meting.search(keyword, {
      type: metingType,
      limit: parseInt(limit) || 20
    });

    const parsedRaw = parseRawData(rawData);
    const resultObj = parsedRaw?.result || parsedRaw; // 兼容不同平台的返回外层

    let cleanedData = [];

    // 根据不同类型，提取各自的字段并调用对应的清洗函数
    switch (type) {
      case 'song':
        const songs = resultObj?.songs || resultObj?.data || [];
        cleanedData = songs.map(item => cleanSongData(item, source));
        break;
      case 'album':
        const albums = resultObj?.albums || resultObj?.data || [];
        cleanedData = albums.map(item => cleanAlbumData(item, source));
        break;
      case 'artist':
        const artists = resultObj?.artists || resultObj?.data || [];
        cleanedData = artists.map(item => cleanArtistData(item, source));
        break;
      case 'playlist':
        const playlists = resultObj?.playlists || resultObj?.data || [];
        cleanedData = playlists.map(item => cleanPlaylistData(item, source));
        break;
    }

    res.json({
      code: 200,
      type: type,
      count: cleanedData.length,
      data: cleanedData
    });
  } catch (err) {
    console.error(`❌ 搜索 [${source}] ${type} 失败:`, err.message);
    res.status(500).json({ error: '搜索失败' });
  }
});

// 保留的原有独立搜索歌单接口（为了向下兼容你之前的前端调用，内部直接复用新逻辑）
app.get('/api/search/playlist', (req, res) => {
  req.query.type = 'playlist';
  app._router.handle(req, res);
});

// 排行榜接口
app.get('/api/toplist', async (req, res) => {
  const { type = 'hot', source = 'netease', limit } = req.query;
  const platformLists = TOP_LISTS[source];
  if (!platformLists) return res.status(400).json({ error: `暂不支持平台: ${source}` });

  const playlistId = platformLists[type];
  if (!playlistId) return res.status(400).json({ error: `未找到该类型的排行榜: ${type}` });

  try {
    const meting = new Meting(source);
    meting.format(false);

    const playlistRaw = await meting.playlist(playlistId);
    const parsedRaw = parseRawData(playlistRaw);
    const rawSongs = parsedRaw?.playlist?.tracks || parsedRaw?.tracks || parsedRaw?.data || [];
    let cleanedSongs = rawSongs.map(song => cleanSongData(song, source));

    if (limit && !isNaN(limit)) {
      cleanedSongs = cleanedSongs.slice(0, parseInt(limit));
    }

    res.json({
      code: 200,
      title: parsedRaw?.playlist?.name || '未知排行榜',
      description: parsedRaw?.playlist?.description || '',
      cover: parsedRaw?.playlist?.coverImgUrl || '',
      count: cleanedSongs.length,
      data: cleanedSongs
    });
  } catch (err) {
    console.error(`❌ 获取 [${source}] 排行榜 [${type}] 失败:`, err.message);
    res.status(500).json({ error: '获取排行榜失败' });
  }
});

// 歌曲详情接口
app.get('/api/song', async (req, res) => {
  const { id, source = 'netease' } = req.query;
  if (!id) return res.status(400).json({ error: '缺少歌曲 ID' });

  try {
    const meting = new Meting(source);
    meting.format(false);

    const songRaw = await meting.song(id);
    const parsedRaw = parseRawData(songRaw);
    const songs = parsedRaw?.songs || parsedRaw?.data || [];

    if (songs.length === 0) return res.status(404).json({ code: 404, message: '未找到该歌曲详情' });

    res.json({ code: 200, data: cleanSongData(songs[0], source) });
  } catch (err) {
    console.error(`❌ 获取歌曲 [${id}] 详情失败:`, err.message);
    res.status(500).json({ error: '获取歌曲详情失败' });
  }
});

// 歌单详情接口
app.get('/api/playlist', async (req, res) => {
  const { id, source = 'netease' } = req.query;
  if (!id) return res.status(400).json({ error: '缺少歌单 ID' });

  try {
    const meting = new Meting(source);
    meting.format(false);

    const playlistRaw = await meting.playlist(id);
    const parsedRaw = parseRawData(playlistRaw);
    const rawSongs = parsedRaw?.playlist?.tracks || parsedRaw?.tracks || parsedRaw?.data || [];
    const cleanedSongs = rawSongs.map(song => cleanSongData(song, source));

    res.json({
      code: 200,
      count: cleanedSongs.length,
      playlistName: parsedRaw?.playlist?.name || '未知歌单',
      data: cleanedSongs
    });
  } catch (err) {
    console.error(`❌ 获取歌单 [${id}] 失败:`, err.message);
    res.status(500).json({ error: '获取歌单失败' });
  }
});

// 获取播放链接接口
app.get('/api/url', async (req, res) => {
  const { id, source = 'netease' } = req.query;
  if (!id) return res.status(400).json({ error: '缺少歌曲 ID' });

  try {
    const meting = new Meting(source);
    meting.format(false);

    const urlRaw = await meting.url(id);
    const parsedUrlData = parseRawData(urlRaw);
    let realUrl = parsedUrlData?.data?.[0]?.url || parsedUrlData?.url || '';

    if (realUrl && realUrl.startsWith('//')) realUrl = `https:${realUrl}`;
    if (!realUrl) return res.status(404).json({ code: 404, message: '无法获取有效的播放地址' });

    res.json({ code: 200, url: realUrl });
  } catch (err) {
    console.error(`❌ 获取歌曲 [${id}] URL失败:`, err.message);
    res.status(500).json({ error: '获取播放链接失败' });
  }
});

// 歌词接口
app.get('/api/lyric', async (req, res) => {
  const { id, source = 'netease' } = req.query;
  if (!id) return res.status(400).json({ error: '缺少歌曲 ID' });

  try {
    const meting = new Meting(source);
    meting.format(false);

    const lyricRaw = await meting.lyric(id);
    const parsedLyricData = parseRawData(lyricRaw);
    let lyric = parsedLyricData?.lrc?.lyric || parsedLyricData?.lyric || '';
    let tlyric = parsedLyricData?.tlyric?.lyric || '';

    if (!lyric) return res.status(404).json({ code: 404, message: '未找到该歌曲的歌词' });

    res.json({ code: 200, lyric, tlyric });
  } catch (err) {
    console.error(`❌ 获取歌曲 [${id}] 歌词失败:`, err.message);
    res.status(500).json({ error: '获取歌词失败' });
  }
});

app.listen(3000, () => {
  console.log('🚀 音乐聚合服务已在 http://localhost:3000 全力运行');
});
