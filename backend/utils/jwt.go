package utils

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID uint `json:"user_id"`
	Username string
	jwt.RegisteredClaims
}

var jwtKey = []byte("your_secret_key")

func GenerateToken(userID uint, username string) (string, error) {
	// v5 使用 jwt.NewNumericDate 来处理时间
	claims := Claims{
		UserID: userID,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
		// 过期时间：30天
		ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)),
			// 签发时间
			IssuedAt: jwt.NewNumericDate(time.Now()),
			// 签发者
			Issuer: "miku_music",
		},
	}

	// 创建 token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// 签名并获得字符串格式的令牌
	return token.SignedString(jwtKey)
}
