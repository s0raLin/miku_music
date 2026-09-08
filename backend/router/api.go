package router

import (
	"miku_music/config"
	"miku_music/internal/handler"
	"miku_music/middleware"

	"github.com/gin-gonic/gin"
)

// Setup 注册所有路由
// cfg 用于传递给需要配置的 handler（如 AuthHandler 需要 SMTP 配置）
func Setup(r *gin.Engine, cfg *config.Config) *gin.Engine {
	authHandler := handler.NewAuthHandler(cfg.SMTP)
	musicHandler := handler.NewMusicHandler()
	uploadSignHandler := handler.NewUploadSignHandler()

	// 限制上传大小为 8MB
	r.MaxMultipartMemory = 8 << 20

	// 根 API 路由组
	api := r.Group("/api")

	// ──────────────────────────── 公开路由（无需登录） ────────────────────────────
	publicAuth := api.Group("/auth")
	{
		// 发送邮箱验证码（注册/登录通用）
		publicAuth.POST("/send-code", authHandler.SendVerificationCode)

		// 邮箱验证码注册（验证通过后自动创建用户并签发 Token Pair）
		publicAuth.POST("/register", authHandler.Register)

		// 邮箱+验证码登录
		publicAuth.POST("/login-by-code", authHandler.LoginByCode)

		// 邮箱+密码登录
		publicAuth.POST("/login-by-password", authHandler.LoginByPassword)

		// 刷新 Token（用 Refresh Token 换取新的 Access/Refresh Token）
		publicAuth.POST("/refresh", authHandler.RefreshToken)

		// 兼容旧版用户名密码登录
		publicAuth.POST("/login", authHandler.Login)
	}

	// ──────────────────────────── 需要鉴权的路由 ────────────────────────────
	protected := api.Group("")
	protected.Use(middleware.JWTAuth())
	{
		// 认证相关操作
		auth := protected.Group("/auth")
		{
			// 上传/更新头像
			auth.POST("/avatar", authHandler.UploadAvatar)

			// 修改密码
			auth.POST("/change-password", authHandler.ChangePassword)

			// 注销账号
			auth.POST("/delete-account", authHandler.DeleteAccount)

			// 更新个性签名
			auth.POST("/update-signature", authHandler.UpdateSignature)
		}

		// 音乐库管理
		music := protected.Group("/music")
		{
			music.POST("", musicHandler.AddMusic)
			music.GET("", musicHandler.ListMusics)
		}

		// 歌单管理
		// playlist := protected.Group("/playlist")
		// {
		// 	// TODO: 实现 PlaylistHandler 并绑定对应逻辑
		// 	// playlist.POST("", playlistHandler.CreatePlaylist)
		// }

		// 客户端直接上传预签名（Aliyun OSS）
		uploadSign := protected.Group("/upload-sign")
		{
			uploadSign.POST("", uploadSignHandler.GetUploadUrl)
		}
	}

	return r
}
