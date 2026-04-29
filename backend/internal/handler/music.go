package handler

import (
	"encoding/base64"
	"log"
	"miku_music/internal/model"
	"miku_music/internal/repository"
	"miku_music/utils"

	"net/http"
	"path/filepath"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type MusicHandler struct{}

func NewMusicHandler() *MusicHandler {
	return &MusicHandler{}
}

func (s *MusicHandler) AddMusic(c *gin.Context) {
	var music model.MusicInfo

	var req struct {

		// 基础元数据
		Title    string `form:"title"`    // 歌曲标题，加索引方便搜索
		Artist   string `form:"artist"`   // 歌手/作者
		Album    string `form:"album"`    // 专辑
		Duration int    `form:"duration"` // 时长：存整数（秒）

		CoverBase64 string `form:"cover"` // 封面图base64
	}

	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "参数错误"})
		return
	}

	// 获取上传的文件
	audioFile, err := c.FormFile("audio")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "请上传音乐文件"})
		return
	}

	//提取文件后缀名
	ext := filepath.Ext(audioFile.Filename)
	//生成uuid
	newUUID := uuid.New().String()

	audioFileName := newUUID + ext

	//上传音乐
	audioURL, err := utils.UploadFileToOSS(audioFile, "audio/"+audioFileName)
	if err != nil {
		log.Printf("OSS 报错详情: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  err,
		})
		return
	}

	// 获取歌词文件(可选)
	lyricFile, err := c.FormFile("lyric")
	var lyricURL string
	if err == nil && lyricFile != nil {
		u, err := utils.UploadFileToOSS(lyricFile, "lyric/"+newUUID+".lrc")
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"code": 1,
				"msg":  "歌词文件上传失败",
			})
			return
		}
		lyricURL = u
	}

	//获取封面文件
	var coverURL string
	cover, err := base64.StdEncoding.DecodeString(req.CoverBase64)
	if err == nil && cover != nil {
		u, err := utils.UploadBytesToOSS(cover, "cover/"+newUUID+".jpg")
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"code": 1,
				"msg":  "封面上传失败",
			})
			return
		}
		coverURL = u
	}

	// 将 req 的数据填充到数据库模型 music 中
	music.Title = req.Title
	music.Artist = req.Artist
	music.Album = req.Album
	music.Duration = req.Duration
	//将地址填充到绑定的结构体中
	music.OssKey = audioURL
	music.LyricUrl = lyricURL
	music.CoverUrl = coverURL

	//保存到数据库
	if err := repository.DB.Create(&music).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  "保存记录失败",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "上传成功",
		"data": music,
	})
}

func (s *MusicHandler) AddMusics(c *gin.Context) {
	var req struct {
		Name        string `json:"name"`
		UserID      uint   `json:"user"`
		Description string `json:"description"`
		MusicIDs    []uint `json:"music_ids"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": 1,
			"msg":  "无效的JSON数据",
		})
		return
	}

	var musics []model.MusicInfo
	if err := repository.DB.Find(&musics, req.MusicIDs).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": 1,
			"msg":  "上传失败",
		})
		return
	}

	playlist := model.PlayList{
		Name:        req.Name,
		UserID:      req.UserID,
		Description: req.Description,
		Musics:      musics,
	}

	if err := repository.DB.Create(&playlist).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": 1,
			"msg":  "歌单数据库保存失败",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "上传成功",
	})
}

func (s *MusicHandler) ListMusics(c *gin.Context) {
	var musics []model.MusicInfo

	if err := repository.DB.Find(&musics).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": 1,
			"msg":  "查找失败",
		})
	}
	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "查找成功",
		"data": musics,
	})
}
