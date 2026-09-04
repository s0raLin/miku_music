import express from 'express';
import cors from 'cors';
import http from 'http';
import https from 'https';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const NeteaseCloudMusicApi = require('NeteaseCloudMusicApi');

const app = express();

app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());

const {
  login_qr_key,
  login_qr_create,
  login_qr_check,
  user_account,
  cloudsearch,
  song_url_v1,
  lyric,
  playlist_detail,
  register_anonimous
} = NeteaseCloudMusicApi;

let globalGuestCookie = '';

// 初始化获取游客 Cookie
const initGuestCookie = async () => {
  try {
    const anonRes = await register_anonimous();
    globalGuestCookie = anonRes.body.cookie || '';
    console.log('✅ 游客 Cookie 初始化成功');
  } catch (e) {
    console.error('❌ 游客 Cookie 获取失败:', e.message);
  }
};
initGuestCookie();

const getQueryConfig = async (req) => {
  let cookie = req.headers.cookie || req.query.cookie || '';
  if (!cookie) {
    if (!globalGuestCookie) await initGuestCookie();
    cookie = globalGuestCookie;
  }
  return {
    cookie,
    realIP: '116.25.146.177', // 伪装国内 IP 防止海外/海外服务器被封锁
  };
};

// ==================== 路由逻辑 ====================

// 1. 获取 QR Key
app.get('/api/login/qr/key', async (req, res) => {
  try {
    const config = await getQueryConfig(req);
    const result = await login_qr_key(config);
    res.json(result.body);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. 生成二维码
app.get('/api/login/qr/create', async (req, res) => {
  try {
    const config = await getQueryConfig(req);
    const result = await login_qr_create({
      key: req.query.key,
      qrimg: true,
      ...config
    });
    res.json(result.body);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 3. 检查扫码状态
app.get('/api/login/qr/check', async (req, res) => {
  try {
    const config = await getQueryConfig(req);
    const result = await login_qr_check({
      key: req.query.key,
      ...config
    });

    if (result.headers && result.headers['set-cookie']) {
      res.setHeader('Set-Cookie', result.headers['set-cookie']);
    }

    res.json(result.body);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 4. 获取音频链接 API (多音质降级兼容)
app.get('/api/url', async (req, res) => {
  const { id } = req.query;
  if (!id) return res.status(400).json({ error: '缺少歌曲 ID' });

  const levels = ['standard', 'higher', 'exhigh', 'lossless'];
  const config = await getQueryConfig(req);

  for (const level of levels) {
    try {
      const result = await song_url_v1({ id, level, ...config });
      const songData = result.body.data?.[0];

      if (songData && songData.url) {
        console.log(`[URL Success] ID: ${id} | Level: ${level} | URL: ${songData.url}`);
        return res.json({
          code: 200,
          url: songData.url,
          level: songData.level,
          size: songData.size
        });
      }
    } catch (e) {
      // 循环继续尝试下一个音质级别
    }
  }

  console.warn(`[URL Failed] ID: ${id} 无法获取可用音源 (无版权或未登录VIP)`);
  res.status(404).json({ code: 404, message: '未获取到有效音源，可能需要VIP账号登录或无版权' });
});

// 5. 新增：音频中转代理 (解决移动端防盗链/HTTP明文/DNS解混淆问题)
app.get('/api/stream', async (req, res) => {
  const { url } = req.query;
  if (!url) return res.status(400).send('Missing target url');

  const client = url.startsWith('https') ? https : http;

  client.get(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://music.163.com/',
    }
  }, (streamRes) => {
    if (streamRes.statusCode >= 300 && streamRes.statusCode < 400 && streamRes.headers.location) {
      // 处理 CDN 302 重定向
      return res.redirect(`/api/stream?url=${encodeURIComponent(streamRes.headers.location)}`);
    }

    res.setHeader('Content-Type', streamRes.headers['content-type'] || 'audio/mpeg');
    if (streamRes.headers['content-length']) {
      res.setHeader('Content-Length', streamRes.headers['content-length']);
    }
    streamRes.pipe(res);
  }).on('error', (err) => {
    res.status(500).send('Stream error: ' + err.message);
  });
});

// 6. 搜索接口
app.get('/api/search', async (req, res) => {
  const { keyword, limit = 30, type = 1 } = req.query;
  if (!keyword) return res.status(400).json({ code: 400, message: 'Keyword is required' });

  try {
    const config = await getQueryConfig(req);
    const result = await cloudsearch({
      keywords: keyword,
      limit: parseInt(limit, 10),
      type: parseInt(type, 10),
      ...config
    });

    const body = result.body;

    if (parseInt(type, 10) === 1) {
      const songs = (body.result?.songs || []).map((song) => ({
        id: String(song.id),
        title: song.name,
        author: song.ar?.map((a) => a.name).join('/') || '未知歌手',
        pic: song.al?.picUrl || '',
        url: '',
        source: 'netease',
      }));
      return res.json({ code: 200, data: songs });
    }

    if (parseInt(type, 10) === 1000) {
      const playlists = (body.result?.playlists || []).map((pl) => ({
        id: String(pl.id),
        title: pl.name,
        creator: pl.creator?.nickname || '未知创建者',
        coverUrl: pl.coverImgUrl || '',
        trackCount: pl.trackCount || 0,
        playCount: pl.playCount || 0,
      }));
      return res.json({ code: 200, data: playlists });
    }

    res.json({ code: 200, data: [] });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message });
  }
});

// 7. 歌词接口
app.get('/api/lyric', async (req, res) => {
  const { id } = req.query;
  if (!id) return res.status(400).json({ error: '缺少歌曲 ID' });

  try {
    const config = await getQueryConfig(req);
    const result = await lyric({ id, ...config });
    res.json({
      code: 200,
      lyric: result.body.lrc?.lyric || '',
      tlyric: result.body.tlyric?.lyric || '',
    });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message });
  }
});

// 8. 歌单详情接口
app.get('/api/playlist', async (req, res) => {
  const { id } = req.query;
  if (!id) return res.status(400).json({ error: '缺少歌单 ID' });

  try {
    const config = await getQueryConfig(req);
    const result = await playlist_detail({ id, ...config });
    const playlist = result.body.playlist;
    const songs = (playlist?.tracks || []).map((song) => ({
      id: String(song.id),
      title: song.name,
      author: song.ar?.map((a) => a.name).join('/') || '未知歌手',
      pic: song.al?.picUrl || '',
      url: '',
      source: 'netease',
    }));

    res.json({
      code: 200,
      playlistName: playlist?.name || '未知歌单',
      count: songs.length,
      data: songs,
    });
  } catch (err) {
    res.status(500).json({ code: 500, message: err.message });
  }
});

app.listen(3000, () => {
  console.log('🚀 服务已成功运行在 http://localhost:3000');
});
