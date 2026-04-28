package handler

import (
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
	if err := c.ShouldBind(&music); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "参数错误"})
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
	lyricFileName := newUUID + ".lrc"
	lyricURL, err := utils.UploadFileToOSS(lyricFile, "lyric/"+lyricFileName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  err,
		})
	}

	//将地址填充到绑定的结构体中
	music.OssKey = audioURL
	music.LyricUrl = lyricURL

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
