package middleware

import (
	"miku_music/utils"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

func JWTAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. 获取 Authorization Header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"code": 1, "msg": "请求未携带token,请先登录"})
			c.Abort() // 终止后续操作
			return
		}

		// 2. 检查格式是否为 "Bearer <token>"
		parts := strings.SplitN(authHeader, " ", 2)
		if !(len(parts) == 2 && parts[0] == "Bearer") {
			c.JSON(http.StatusUnauthorized, gin.H{"code": 1, "msg": "Token格式错误"})
			c.Abort()
			return
		}

		// 3. 解析并验证 Access Token（内部已包含 jwtKey 校验与 TokenType=="access" 判断）
		tokenString := parts[1]
		claims, err := utils.ParseAccessToken(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"code": 1, "msg": "无效的或已过期的Token: " + err.Error()})
			c.Abort()
			return
		}

		// 4. 将解析出来的用户信息存入上下文 (Context)，方便后续 Handler 直接使用
		c.Set("userID", claims.UserID)
		c.Set("username", claims.Username)

		c.Next() // 验证通过，继续执行后续逻辑
	}
}
