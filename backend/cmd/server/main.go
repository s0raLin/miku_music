package main

import (
	"log"
	"miku_music/config"
	"miku_music/internal/repository"
	"miku_music/router"

	"github.com/gin-gonic/gin"
)

func globalCORE() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Headers", "Authorization, Content-Type")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	}
}
func main() {

	cfg, err := config.Load()
	if err != nil {
		log.Fatal("配置加载失败", err)
	}

	// 数据库初始化
	repository.Init(cfg)

	r := gin.Default()

	// 全局 CORS（Flutter 调试时跨域用）
	r.Use(globalCORE())

	//把所有路由注册交给router包（传入配置）
	router.Setup(r, cfg)

	// 启动
	log.Println("Server running on", cfg.Port)
	if err := r.Run(":" + cfg.Port); err != nil {
		log.Fatal("服务器启动失败")
	}
}
