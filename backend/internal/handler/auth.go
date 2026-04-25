package handler

import (
	"miku_music/internal/model"
	"net/http"
	"os"
	"path/filepath"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct{}

func NewAuthHandler() *AuthHandler {
	return &AuthHandler{}
}

func (s *AuthHandler) Login(c *gin.Context) {
	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}

	if err := c.ShouldBind(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "ok",
		"data": gin.H{"token": "jwt.token"},
	})
}

func (h *AuthHandler) Register(c *gin.Context) {

	var user model.User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": 1,
			"msg":  "用户绑定失败",
		})
	}

	//文件单独提取
	avatar, err := c.FormFile("avatar")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": 1,
			"msg":  "图片上传失败",
		})
	}

	//存储
	savePath := filepath.Join("uploads", "avatars", avatar.Filename)

	if err := os.MkdirAll(filepath.Dir(savePath), 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  "目录失败",
		})
		return
	}
	//保存头像到目录
	if err := c.SaveUploadedFile(avatar, savePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  "文件保存失败",
		})
	}

	//保存信息到数据库

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "已注册",
	})
}
