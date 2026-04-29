package handler

import (
	"fmt"
	"miku_music/internal/model"
	"miku_music/internal/repository"
	"miku_music/utils"
	"sync"

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

		// CoverBase64 string `form:"cover"` // 封面图base64
	}
	var err error
	if err = c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "参数错误"})
		return
	}

	// 获取上传的文件
	audioFile, err := c.FormFile("audio")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "请上传音乐文件"})
		return
	}

	var wg sync.WaitGroup
	//生成uuid
	newUUID := uuid.New().String()
	//上传音乐
	wg.Add(1)
	var audioURL string
	var audioErr error
	go func() {
		defer wg.Done()
		file, _ := audioFile.Open()
		defer file.Close()
		//提取文件后缀名
		ext := filepath.Ext(audioFile.Filename)
		audioURL, audioErr = utils.OSSUpload(file, "audio/"+newUUID+ext)
	}()

	// 获取歌词文件(可选)
	var lyricURL string
	var lyricErr error
	lyricFile, err := c.FormFile("lyric")
	if err == nil && lyricFile != nil {
		wg.Add(1)
		go func() {
			defer wg.Done()
			file, _ := lyricFile.Open()
			defer file.Close()
			lyricURL, lyricErr = utils.OSSUpload(file, "lyric/"+newUUID+".lrc")
		}()
	}

	//获取封面文件
	var coverURL string
	var coverErr error
	coverFile, err := c.FormFile("cover")
	fmt.Println(coverFile)
	if err == nil && coverFile != nil {
		wg.Add(1)
		go func() {
			defer wg.Done()
			file, _ := coverFile.Open()
			defer file.Close()
			coverURL, coverErr = utils.OSSUpload(file, "cover/"+newUUID+".jpg")
		}()
	}

	wg.Wait() //等待完成

	if audioErr != nil || lyricErr != nil || coverErr != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  "上传失败",
		})
		return
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
