import express from 'express';
import Meting from '@meting/core';

const app = express();

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
});

app.get('/api/search', async (req, res) => {
  const { keyword } = req.query;

  if (!keyword) {
    return res.status(400).json({ error: '请输入搜索关键词' });
  }

  let allResults = [];

  try {
    const neteaseMeting = new Meting('netease');
    neteaseMeting.format(false);

    const neteaseRaw = await neteaseMeting.search(keyword);

    let parsedRaw;

    // ✨ 核心修复：不管它是 Buffer 还是 String 还是 Object，强行转成字符串再解析
    try {
      const rawString = neteaseRaw.toString();
      parsedRaw = JSON.parse(rawString);
    } catch (e) {
      // 如果本来就是个对象，解析失败了，就直接赋值
      parsedRaw = neteaseRaw;
    }

    // 再次安全获取歌曲数组
    const neteaseSongs = parsedRaw?.result?.songs
      || parsedRaw?.songs
      || parsedRaw?.data
      || [];

    const cleanedNetease = neteaseSongs.map(song => ({
      id: String(song.id),
      title: song.name || '未知歌名',
      author: song.ar?.map(artist => artist.name).join(', ') || song.artists?.map(a => a.name).join(', ') || '未知歌手',
      pic: song.al?.picUrl || song.album?.picUrl || '',
      url: `https://music.163.com/song/media/outer/url?id=${song.id}.mp3`,
      source: 'netease'
    }));

    allResults = [...allResults, ...cleanedNetease];
    console.log(`🚀 【成功突破】网易云最终清洗出 ${cleanedNetease.length} 首歌曲！`);

  } catch (err) {
    console.error('❌ 网易云彻底报废:', err.message);
  }

  res.json({
    code: 200,
    count: allResults.length,
    data: allResults
  });
});

// ✨ 核心新增：动态获取音乐真实播放链接接口
app.get('/api/url', async (req, res) => {
  const { id, source = 'netease' } = req.query;

  if (!id) {
    return res.status(400).json({ error: '缺少歌曲 ID' });
  }

  try {
    // 1. 初始化对应平台的 Meting 实例
    const meting = new Meting(source);
    meting.format(false); // 拿最底层最真实的原始数据

    // 2. 调用 meting.url 方法直接获取播放地址数据
    const urlRaw = await meting.url(id);

    let parsedUrlData = urlRaw;
    if (typeof urlRaw === 'string') {
      parsedUrlData = JSON.parse(urlRaw);
    }

    // 3. 提取真实的播放 URL (网易云和QQ音乐在新版底层返回的结构通常在 data[0].url 中)
    let realUrl = parsedUrlData?.data?.[0]?.url
      || parsedUrlData?.url
      || '';

    // 如果解析出来的 url 不带协议头（比如以 // 开头），帮它补全
    if (realUrl && realUrl.startsWith('//')) {
      realUrl = `https:${realUrl}`;
    }

    if (!realUrl) {
      return res.status(404).json({ code: 404, message: '无法获取该歌曲的有效播放地址(可能因版权或VIP限制)' });
    }

    console.log(`🎵 成功为歌曲 ${id} 动态生成真实播放链接！`);

    res.json({
      code: 200,
      url: realUrl
    });

  } catch (err) {
    console.error(`❌ 获取歌曲 [${id}] 真实URL失败:`, err.message);
    res.status(500).json({ error: '获取播放链接失败' });
  }
});

app.get('/api/lyric', async (req, res) => {
  const { id, source = 'netease' } = req.query;

  if (!id) {
    return res.status(400).json({ error: '缺少歌曲 ID' });
  }

  try {
    const meting = new Meting(source);
    meting.format(false); // 保持原始数据格式

    // 调用 meting.lyric 方法获取歌词数据
    const lyricRaw = await meting.lyric(id);

    let parsedLyricData = lyricRaw;
    if (typeof lyricRaw === 'string') {
      try {
        parsedLyricData = JSON.parse(lyricRaw);
      } catch (e) {
        // 如果是纯文本形式，则不处理
      }
    }

    // 解析网易云返回的歌词结构 (通常在 lrc.lyric 中)
    let lyric = parsedLyricData?.lrc?.lyric
      || parsedLyricData?.lyric
      || '';

    // 翻译歌词（可选：部分外文歌曲网易云会提供中文翻译）
    let tlyric = parsedLyricData?.tlyric?.lyric || '';

    if (!lyric) {
      return res.status(404).json({ code: 404, message: '未找到该歌曲的歌词' });
    }

    console.log(`📝 成功获取歌曲 [${id}] 的歌词！`);

    res.json({
      code: 200,
      lyric: lyric,     // 包含时间戳的原始歌词文本
      tlyric: tlyric    // 翻译歌词（没有则为空字符串）
    });

  } catch (err) {
    console.error(`❌ 获取歌曲 [${id}] 歌词失败:`, err.message);
    res.status(500).json({ error: '获取歌词失败' });
  }
});

app.listen(3000, () => {
  console.log('服务已在 http://localhost:3000 重新启航');
});
