import express from 'express';
import cors from 'cors';
import Meting from '@meting/core';

const app = express();

// ✨ 优化：替换掉原有的手动 Header 跨域，一劳永逸支持所有请求类型（如 OPTIONS/POST）
app.use(cors());

// 公共辅助函数：统一清洗网易云等平台的歌曲数据结构
function cleanSongData(song, source = 'netease') {
  return {
    id: String(song.id),
    title: song.name || '未知歌名',
    // 兼容 ar (网易云新版) 或 artists (旧版/QQ音乐)
    author: song.ar?.map(artist => artist.name).join(', ') || song.artists?.map(a => a.name).join(', ') || '未知歌手',
    // 兼容 al.picUrl (网易云新版) 或 album.picUrl (旧版/QQ音乐)
    pic: song.al?.picUrl || song.album?.picUrl || '',
    // ✨ 优化建议：不要在列表中写死外链，让前端动态请求 /api/url 获取最新、最高音质的 CDN
    url: `/api/url?id=${song.id}&source=${source}`,
    source: source
  };
}

// 公共辅助函数：安全解析 Meting 返回的各类（Buffer/String/Object）原始数据
function parseRawData(rawData) {
  if (!rawData) return null;
  try {
    const rawString = rawData.toString();
    return JSON.parse(rawString);
  } catch (e) {
    return rawData; // 如果本来就是个对象或者解析失败，直接返回原数据
  }
}

// ✨ 新增：排行榜 ID 映射配置（以网易云音乐为例）
const TOP_LISTS = {
  netease: {
    hot: '3778678',      // 热歌榜
    new: '3779629',      // 新歌榜
    soaring: '19723756',  // 飙升榜
    original: '2884035'   // 原创榜
  },
  // 如果未来扩展 QQ 音乐，可以在这里追加其对应的排行榜 ID
  tencent: {
    hot: '26',
    new: '27'
  }
};

// ✨ 新增：6. 排行榜接口
app.get('/api/toplist', async (req, res) => {
  // type 可选值: hot(热歌), new(新歌), soaring(飙升), original(原创)
  const { type = 'hot', source = 'netease', limit } = req.query;

  // 1. 安全校验：检查该平台下是否存在该类型的排行榜
  const platformLists = TOP_LISTS[source];
  if (!platformLists) {
    return res.status(400).json({ error: `暂不支持平台: ${source}` });
  }

  const playlistId = platformLists[type];
  if (!playlistId) {
    return res.status(400).json({ error: `未找到该类型的排行榜: ${type}。可选值: hot, new, soaring, original` });
  }

  try {
    const meting = new Meting(source);
    meting.format(false);

    // 2. 排行榜本质就是官方歌单，直接调用 meting.playlist()
    const playlistRaw = await meting.playlist(playlistId);
    const parsedRaw = parseRawData(playlistRaw);

    // 3. 复用你原有的歌单歌曲提取与清洗逻辑
    const rawSongs = parsedRaw?.playlist?.tracks || parsedRaw?.tracks || parsedRaw?.data || [];
    let cleanedSongs = rawSongs.map(song => cleanSongData(song, source));

    // ✨ 优化：支持前端通过 limit 参数控制返回的歌曲数量（例如：只要前10首做首页推荐）
    if (limit && !isNaN(limit)) {
      cleanedSongs = cleanedSongs.slice(0, parseInt(limit));
    }

    // 4. 返回规范的数据
    res.json({
      code: 200,
      title: parsedRaw?.playlist?.name || '未知排行榜',
      description: parsedRaw?.playlist?.description || '',
      cover: parsedRaw?.playlist?.coverImgUrl || '', // 排行榜封面图
      count: cleanedSongs.length,
      data: cleanedSongs
    });
  } catch (err) {
    console.error(`❌ 获取 [${source}] 排行榜 [${type}] 失败:`, err.message);
    res.status(500).json({ error: '获取排行榜失败' });
  }
});

// 1. 搜索接口
app.get('/api/search', async (req, res) => {
  const { keyword } = req.query;
  if (!keyword) return res.status(400).json({ error: '请输入搜索关键词' });

  try {
    const neteaseMeting = new Meting('netease');
    neteaseMeting.format(false);

    const neteaseRaw = await neteaseMeting.search(keyword);
    const parsedRaw = parseRawData(neteaseRaw);

    // 完美匹配你发来的数据结构：parsedRaw?.result?.songs 或 parsedRaw?.songs
    const neteaseSongs = parsedRaw?.result?.songs || parsedRaw?.songs || [];
    const cleanedNetease = neteaseSongs.map(song => cleanSongData(song, 'netease'));

    res.json({
      code: 200,
      count: cleanedNetease.length,
      data: cleanedNetease
    });
  } catch (err) {
    console.error('❌ 搜索失败:', err.message);
    res.status(500).json({ error: '搜索失败' });
  }
});

// ✨ 新增：2. 歌曲详情接口 (专门处理你提供的那段数据)
app.get('/api/song', async (req, res) => {
  const { id, source = 'netease' } = req.query;
  if (!id) return res.status(400).json({ error: '缺少歌曲 ID' });

  try {
    const meting = new Meting(source);
    meting.format(false);

    const songRaw = await meting.song(id);
    const parsedRaw = parseRawData(songRaw);

    // 匹配你发来的结构：如果是单个或多个歌曲详情，网易云外层是 parsedRaw.songs 数组
    const songs = parsedRaw?.songs || parsedRaw?.data || [];

    if (songs.length === 0) {
      return res.status(404).json({ code: 404, message: '未找到该歌曲详情' });
    }

    // 清洗单首歌曲数据
    const cleanedSong = cleanSongData(songs[0], source);

    res.json({
      code: 200,
      data: cleanedSong
    });
  } catch (err) {
    console.error(`❌ 获取歌曲 [${id}] 详情失败:`, err.message);
    res.status(500).json({ error: '获取歌曲详情失败' });
  }
});

// ✨ 新增：3. 歌单详情接口 (批量拉取整个歌单的歌曲)
app.get('/api/playlist', async (req, res) => {
  const { id, source = 'netease' } = req.query;
  if (!id) return res.status(400).json({ error: '缺少歌单 ID' });

  try {
    const meting = new Meting(source);
    meting.format(false);

    const playlistRaw = await meting.playlist(id);
    const parsedRaw = parseRawData(playlistRaw);

    // 网易云歌单内的歌曲通常包裹在 playlist.tracks 中
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

// 4. 获取播放链接接口
app.get('/api/url', async (req, res) => {
  const { id, source = 'netease' } = req.query;
  if (!id) return res.status(400).json({ error: '缺少歌曲 ID' });

  try {
    const meting = new Meting(source);
    meting.format(false);

    const urlRaw = await meting.url(id);
    const parsedUrlData = parseRawData(urlRaw);

    let realUrl = parsedUrlData?.data?.[0]?.url || parsedUrlData?.url || '';

    if (realUrl && realUrl.startsWith('//')) {
      realUrl = `https:${realUrl}`;
    }

    if (!realUrl) {
      return res.status(404).json({ code: 404, message: '无法获取有效的播放地址' });
    }

    res.json({ code: 200, url: realUrl });
  } catch (err) {
    console.error(`❌ 获取歌曲 [${id}] URL失败:`, err.message);
    res.status(500).json({ error: '获取播放链接失败' });
  }
});

// 5. 歌词接口
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

    if (!lyric) {
      return res.status(404).json({ code: 404, message: '未找到该歌曲的歌词' });
    }

    res.json({ code: 200, lyric, tlyric });
  } catch (err) {
    console.error(`❌ 获取歌曲 [${id}] 歌词失败:`, err.message);
    res.status(500).json({ error: '获取歌词失败' });
  }
});

app.listen(3000, () => {
  console.log('🚀 音乐聚合服务已在 http://localhost:3000 全力运行');
});
