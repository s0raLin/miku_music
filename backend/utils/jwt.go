package utils

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID    uint   `json:"user_id"`
	Username  string `json:"username"`
	TokenType string `json:"token_type"` // "access" 或 "refresh"
	jwt.RegisteredClaims
}

var jwtKey = []byte("your_secret_key") // 建议后续改为从 config 加载

// Token 过期时间常量配置
const (
	AccessTokenDuration = 2 * time.Hour // Access Token: 建议设为短效（例如 2 小时）
	RefreshTokenDuration = 30 * 24 * time.Hour // Refresh Token: 建议设为长效（例如 30 天）
	Issuer               = "miku_music"
)

// GenerateTokenPair 签发 Access Token 和 Refresh Token 双令牌
func GenerateTokenPair(userID uint, username string) (accessToken string, refreshToken string, err error) {
	now := time.Now()

	// 1. 生成短效 Access Token
	accessClaims := Claims{
		UserID:    userID,
		Username:  username,
		TokenType: "access",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(AccessTokenDuration)),
			IssuedAt:  jwt.NewNumericDate(now),
			Issuer:    Issuer,
		},
	}
	accessToken, err = jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims).SignedString(jwtKey)
	if err != nil {
		return "", "", err
	}

	// 2. 生成长效 Refresh Token
	refreshClaims := Claims{
		UserID:    userID,
		Username:  username,
		TokenType: "refresh",
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(RefreshTokenDuration)),
			IssuedAt:  jwt.NewNumericDate(now),
			Issuer:    Issuer,
		},
	}
	refreshToken, err = jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims).SignedString(jwtKey)
	if err != nil {
		return "", "", err
	}

	return accessToken, refreshToken, nil
}

// ParseAccessToken 解析并校验 Access Token（供中间件使用）
func ParseAccessToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return jwtKey, nil
	})

	if err != nil || !token.Valid {
		return nil, errors.New("令牌无效或已过期")
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || claims.TokenType != "access" {
		return nil, errors.New("非法的 Access Token 类型")
	}

	return claims, nil
}

// ParseRefreshToken 解析并校验 Refresh Token（供刷新 Token 接口使用）
func ParseRefreshToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return jwtKey, nil
	})

	if err != nil || !token.Valid {
		return nil, errors.New("令牌无效或已过期")
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || claims.TokenType != "refresh" {
		return nil, errors.New("非法的 Refresh Token 类型")
	}

	return claims, nil
}

// GenerateToken 保留单 Token 生成函数，兼容旧代码调用
func GenerateToken(userID uint, username string) (string, error) {
	accessToken, _, err := GenerateTokenPair(userID, username)
	return accessToken, err
}
