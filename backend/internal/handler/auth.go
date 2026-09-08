package handler

import (
	"fmt"
	"miku_music/config"
	"miku_music/internal/model"
	"miku_music/internal/repository"
	"miku_music/internal/service"
	"miku_music/utils"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// AuthHandler 认证相关的 HTTP 处理器
// 支持邮箱验证码登录/注册 和 邮箱密码登录
type AuthHandler struct {
	emailService *service.EmailService
}

func NewAuthHandler(cfg config.SMTPConfig) *AuthHandler {
	return &AuthHandler{
		emailService: service.NewEmailService(cfg),
	}
}

// ──────────────────────────── 请求/响应结构体 ────────────────────────────

type SendCodeReq struct {
	Email   string `json:"email" binding:"required,email"`                  // 目标邮箱
	Purpose string `json:"purpose" binding:"required,oneof=register login"` // 用途: register 或 login
}

type RegisterReq struct {
	Email    string `json:"email" binding:"required,email"`    // 邮箱
	Code     string `json:"code" binding:"required,len=6"`     // 6位验证码
	Username string `json:"username" binding:"required,min=1"` // 用户名
	Password string `json:"password" binding:"required,min=6"` // 密码(至少6位)
}

type LoginByCodeReq struct {
	Email string `json:"email" binding:"required,email"` // 邮箱
	Code  string `json:"code" binding:"required,len=6"`  // 6位验证码
}

type LoginByPasswordReq struct {
	Email    string `json:"email" binding:"required,email"`    // 邮箱
	Password string `json:"password" binding:"required,min=6"` // 密码
}

type RefreshTokenReq struct {
	RefreshToken string `json:"refresh_token" binding:"required"` // 刷新 Token
}

// ──────────────────────────── 发送验证码 ────────────────────────────

// SendVerificationCode 发送邮箱验证码
// POST /api/auth/send-code
func (h *AuthHandler) SendVerificationCode(c *gin.Context) {
	var req SendCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "参数错误: " + err.Error()})
		return
	}

	// 注册场景：检查邮箱是否已被注册
	if req.Purpose == "register" {
		var existing model.User
		if result := repository.DB.Where("email = ?", req.Email).First(&existing); result.Error == nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "该邮箱已被注册"})
			return
		}
	}

	// 登录场景：检查邮箱是否已注册
	if req.Purpose == "login" {
		var existing model.User
		if result := repository.DB.Where("email = ?", req.Email).First(&existing); result.Error != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "该邮箱尚未注册"})
			return
		}
	}

	// 生成6位验证码
	code := h.emailService.GenerateCode()

	// 保存验证码到数据库（10分钟有效）
	verification := model.EmailVerification{
		Email:     req.Email,
		Code:      code,
		Purpose:   req.Purpose,
		Used:      false,
		ExpiresAt: time.Now().Add(10 * time.Minute),
		CreatedAt: time.Now(),
	}
	if err := repository.DB.Create(&verification).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "验证码保存失败"})
		return
	}

	// 发送邮件
	var sendErr error
	if req.Purpose == "login" {
		sendErr = h.emailService.SendLoginCode(req.Email, code)
	} else {
		sendErr = h.emailService.SendRegisterCode(req.Email, code)
	}

	if sendErr != nil {
		fmt.Printf("邮件发送失败: %v\n", sendErr)
		// 开发模式下仍然返回成功（验证码已打印到控制台）
		c.JSON(http.StatusOK, gin.H{
			"code": 0,
			"msg":  fmt.Sprintf("验证码已发送到 %s（如未收到请查看服务器日志）", req.Email),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  fmt.Sprintf("验证码已发送到 %s，10分钟内有效", req.Email),
	})
}

// ──────────────────────────── 验证验证码 ────────────────────────────

// verifyCode 验证邮箱验证码是否有效（内部辅助函数）
func verifyCode(email, code, purpose string) bool {
	var verification model.EmailVerification
	result := repository.DB.Where(
		"email = ? AND code = ? AND purpose = ? AND used = ? AND expires_at > ?",
		email, code, purpose, false, time.Now(),
	).Order("created_at DESC").First(&verification)

	if result.Error != nil {
		return false
	}

	// 标记为已使用
	repository.DB.Model(&verification).Update("used", true)
	return true
}

// ──────────────────────────── 注册 ────────────────────────────

// Register 邮箱注册
// POST /api/auth/register
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "参数错误: " + err.Error()})
		return
	}

	// 验证验证码
	if !verifyCode(req.Email, req.Code, "register") {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "验证码错误或已过期"})
		return
	}

	// 再次检查邮箱是否已被注册（防止并发）
	var existing model.User
	if result := repository.DB.Unscoped().Where("email = ?", req.Email).First(&existing); result.Error == nil {
		if existing.DeletedAt.Valid {
			// 用户已注销，重新激活
			existing.DeletedAt = gorm.DeletedAt{}
			existing.Username = req.Username
			hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
			existing.PasswordHash = string(hashedPassword)
			if err := repository.DB.Unscoped().Save(&existing).Error; err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "用户重新激活失败"})
				return
			}
		} else {
			c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "该邮箱已被注册"})
			return
		}
	} else {
		// 密码 bcrypt 哈希
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "密码加密失败"})
			return
		}

		// 创建用户
		user := model.User{
			Email:        req.Email,
			Username:     req.Username,
			PasswordHash: string(hashedPassword),
		}

		if err := repository.DB.Create(&user).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "用户创建失败: " + err.Error()})
			return
		}
		existing = user
	}

	// 生成双 Token
	accessToken, refreshToken, err := utils.GenerateTokenPair(existing.ID, existing.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "令牌生成失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "注册成功",
		"data": gin.H{
			"access_token":  accessToken,
			"refresh_token": refreshToken,
			"user":          existing,
		},
	})
}

// ──────────────────────────── 邮箱+验证码登录 ────────────────────────────

// LoginByCode 邮箱验证码登录
// POST /api/auth/login-by-code
func (h *AuthHandler) LoginByCode(c *gin.Context) {
	var req LoginByCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "参数错误: " + err.Error()})
		return
	}

	// 验证验证码
	if !verifyCode(req.Email, req.Code, "login") {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "验证码错误或已过期"})
		return
	}

	// 查找用户
	var user model.User
	if err := repository.DB.Where("email = ?", req.Email).First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "该邮箱尚未注册"})
		return
	}

	// 生成双 Token
	accessToken, refreshToken, err := utils.GenerateTokenPair(user.ID, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "令牌生成失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "登录成功",
		"data": gin.H{
			"access_token":  accessToken,
			"refresh_token": refreshToken,
			"user":          user,
		},
	})
}

// ──────────────────────────── 邮箱+密码登录 ────────────────────────────

// LoginByPassword 邮箱密码登录
// POST /api/auth/login-by-password
func (h *AuthHandler) LoginByPassword(c *gin.Context) {
	var req LoginByPasswordReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "参数错误: " + err.Error()})
		return
	}

	// 查找用户
	var user model.User
	if err := repository.DB.Where("email = ?", req.Email).First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "邮箱或密码错误"})
		return
	}

	// 验证 bcrypt 密码
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "邮箱或密码错误"})
		return
	}

	// 生成双 Token
	accessToken, refreshToken, err := utils.GenerateTokenPair(user.ID, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "令牌生成失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "登录成功",
		"data": gin.H{
			"access_token":  accessToken,
			"refresh_token": refreshToken,
			"user":          user,
		},
	})
}

// ──────────────────────────── 刷新令牌 ────────────────────────────

// RefreshToken 用 Refresh Token 换取新的 Access Token 与 Refresh Token
// POST /api/auth/refresh
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req RefreshTokenReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "参数错误: " + err.Error()})
		return
	}

	// 1. 校验 Refresh Token 是否有效
	claims, err := utils.ParseRefreshToken(req.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 1, "msg": "刷新令牌已失效，请重新登录"})
		return
	}

	// 2. 检查用户状态（防止已被注销或删除）
	var user model.User
	if err := repository.DB.Where("id = ?", claims.UserID).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 1, "msg": "用户不存在或已被禁用"})
		return
	}

	// 3. 重新签发双 Token
	newAccessToken, newRefreshToken, err := utils.GenerateTokenPair(user.ID, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "令牌生成失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "刷新成功",
		"data": gin.H{
			"access_token":  newAccessToken,
			"refresh_token": newRefreshToken,
		},
	})
}

// ──────────────────────────── 兼容旧版登录(用户名+密码) ────────────────────────────

// Login 兼容旧版的用户名+密码登录
// POST /api/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": err.Error()})
		return
	}

	if req.Username == "" || req.Password == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "用户名或密码不能为空"})
		return
	}

	var user model.User
	if err := repository.DB.Where("username = ?", req.Username).First(&user).Error; err != nil {
		if err2 := repository.DB.Where("email = ?", req.Username).First(&user).Error; err2 != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "用户名或密码错误"})
			return
		}
	}

	if user.PasswordHash != "" {
		if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "用户名或密码错误"})
			return
		}
	}

	accessToken, refreshToken, err := utils.GenerateTokenPair(user.ID, user.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "生成令牌失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "登录成功",
		"data": gin.H{
			"access_token":  accessToken,
			"refresh_token": refreshToken,
			"user":          user,
		},
	})
}

// ──────────────────────────── 上传头像 ────────────────────────────

// UploadAvatar 上传用户头像到OSS
// POST /api/auth/avatar
func (h *AuthHandler) UploadAvatar(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 1, "msg": "未登录"})
		return
	}

	avatar, err := c.FormFile("avatar")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "请选择头像文件"})
		return
	}

	avatarURL, err := utils.UploadFileToOSS(avatar, fmt.Sprintf("avatar/user_%v_%d", userID, time.Now().Unix()))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "头像上传失败"})
		return
	}

	uid := userID.(uint)
	if err := repository.DB.Model(&model.User{}).Where("id = ?", uid).Update("avatar_url", avatarURL).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "头像保存失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "头像上传成功",
		"data": gin.H{"avatar_url": avatarURL},
	})
}

// ──────────────────────────── 修改密码 ────────────────────────────

type ChangePasswordReq struct {
	OldPassword string `json:"old_password" binding:"required"`       // 旧密码
	NewPassword string `json:"new_password" binding:"required,min=6"` // 新密码(至少6位)
}

// ChangePassword 修改密码
// POST /api/auth/change-password
func (h *AuthHandler) ChangePassword(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 1, "msg": "未登录"})
		return
	}

	var req ChangePasswordReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "参数错误: " + err.Error()})
		return
	}

	var user model.User
	if err := repository.DB.Where("id = ?", userID).First(&user).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "用户不存在"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.OldPassword)); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "旧密码错误"})
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "密码加密失败"})
		return
	}

	if err := repository.DB.Model(&user).Update("password_hash", string(hashedPassword)).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "密码更新失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"code": 0, "msg": "密码修改成功"})
}

// ──────────────────────────── 注销账号 ────────────────────────────

// DeleteAccount 注销当前登录用户账号
// POST /api/auth/delete-account
func (h *AuthHandler) DeleteAccount(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 1, "msg": "未登录"})
		return
	}

	if err := repository.DB.Delete(&model.User{}, userID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "账号注销失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"code": 0, "msg": "账号已注销"})
}

// ──────────────────────────── 更新个性签名 ────────────────────────────

type UpdateSignatureReq struct {
	Signature string `json:"signature" binding:"required,max=255"` // 个性签名
}

// UpdateSignature 更新当前登录用户的个性签名
// POST /api/auth/update-signature
func (h *AuthHandler) UpdateSignature(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 1, "msg": "未登录"})
		return
	}

	var req UpdateSignatureReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 1, "msg": "参数错误: " + err.Error()})
		return
	}

	uid := userID.(uint)
	if err := repository.DB.Model(&model.User{}).Where("id = ?", uid).Update("signature", req.Signature).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 1, "msg": "签名保存失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"code": 0, "msg": "签名更新成功"})
}
