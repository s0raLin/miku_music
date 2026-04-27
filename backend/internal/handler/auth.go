package handler

import (
	"miku_music/internal/model"
	"miku_music/internal/repository"
	"miku_music/utils"
	"net/http"

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

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": err.Error()})
		return
	}
	if req.Username == "" || req.Password == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": 1,
			"msg":  "用户名或密码不能为空",
		})
		return
	}

	var user model.User
	if err := repository.DB.Where("username = ? ", req.Username).First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": 1,
			"msg":  "用户名或密码错误", //找不到用户
		})
		return
	}
	if req.Password != user.Password {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": 1,
			"msg":  "用户名或密码错误",
		})
		return
	}

	token, err := utils.GenerateToken(user.ID, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  "生成令牌失败",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "登录成功",
		"data": gin.H{"token": token, "user": user},
	})
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req struct {
		Username string `form:"username"`
		Password string `form:"password"`
		Email    string `form:"email"`
	}

	var user model.User
	if err := c.ShouldBind(&req); err != nil {

		c.JSON(http.StatusBadRequest, gin.H{
			"code": 1,
			"msg":  "用户绑定失败",
		})
		return
	}
	user.Username = req.Username
	user.Password = req.Password
	user.Email = req.Email

	//文件单独提取
	avatar, err := c.FormFile("avatar")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  "图片上传失败",
		})
		return
	}

	avatarURL, err := utils.OSSUpload(avatar, avatar.Filename)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  "用户头像上传失败",
		})
		return
	}
	user.AvatarURL = avatarURL

	//保存信息到数据库
	if err := repository.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  "用户信息保存失败",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "已注册",
	})
}
