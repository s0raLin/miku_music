package router

import (
	"miku_music/config"
	"miku_music/internal/handler"

	"github.com/gin-gonic/gin"
)

// Setup 注册所有路由
// cfg 用于传递给需要配置的 handler（如 AuthHandler 需要 SMTP 配置）
func Setup(r *gin.Engine, cfg *config.Config) *gin.Engine {
	authHandler := handler.NewAuthHandler(cfg.SMTP)
	musicHandler := handler.NewMusicHandler()
	uploadSignHandler := handler.NewUploadSignHandler()

	// 限制上传大小
	r.MaxMultipartMemory = 8 << 20 // 8MB

	// ── 公开路由（无需登录） ──
	public := r.Group("/api")
	{
		auth := public.Group("/auth")
		{
			// 发送邮箱验证码（注册/登录通用）
			auth.POST("/send-code", authHandler.SendVerificationCode)

			// 邮箱验证码注册（验证通过后自动创建用户并返回JWT）
			auth.POST("/register", authHandler.Register)

			// 邮箱+验证码登录
			auth.POST("/login-by-code", authHandler.LoginByCode)

			// 邮箱+密码登录
			auth.POST("/login-by-password", authHandler.LoginByPassword)

			// 兼容旧版用户名密码登录
			auth.POST("/login", authHandler.Login)
		}
	}

	// ── 需要鉴权的路由 ──
	sandBox := r.Group("/api")
	// TODO: 添加 JWT 中间件
	// sandBox.Use(middleware.JWTAuth())
	{
		auth := sandBox.Group("/auth")
		{
			// 上传/更新头像（需要登录）
			auth.POST("/avatar", authHandler.UploadAvatar)
		}

		music := sandBox.Group("/music")
		{
			music.POST("", musicHandler.AddMusic)
			music.GET("", musicHandler.ListMusics)
		}

		playList := sandBox.Group("/playlist")
		{
			playList.POST("")
		}

		uploadSign := sandBox.Group("/upload-sign")
		{
			uploadSign.POST("", uploadSignHandler.GetUploadUrl)
		}
	}
	return r
}
