package router

import (
	"miku_music/internal/handler"

	"github.com/gin-gonic/gin"
)

func Setup(r *gin.Engine) *gin.Engine {
	authHandler := handler.NewAuthHandler()
	musicHandler := handler.NewMusicHandler()

	//限制上传大小
	r.MaxMultipartMemory = 8 << 20 // 8MB

	//公开路由
	public := r.Group("/api")
	{

		auth := public.Group("/auth")
		{
			auth.POST("/login", authHandler.Login)
			auth.POST("/register", authHandler.Register)
		}
	}

	// 需要鉴权的路由
	sandBox := r.Group("/api")
	{
		music := sandBox.Group("/music")
		{
			music.POST("", musicHandler.AddMusic)
			music.GET("", musicHandler.ListMusics)
		}

		playList := sandBox.Group("/playlist")
		{
			playList.POST("")
		}
	}
	return r
}
