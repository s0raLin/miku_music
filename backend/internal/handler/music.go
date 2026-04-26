package handler

import (
	"miku_music/internal/model"
	"miku_music/utils"
	"net/http"

	"github.com/gin-gonic/gin"
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
	file, err := c.FormFile("audio")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "请上传音乐文件"})
	}

	fileURL, err := utils.OSSUpload(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  err,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "上传成功",
		"data": fileURL,
	})
}
