package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

// SMTPConfig 邮件服务配置
// 用于发送邮箱验证码
type SMTPConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	From     string
}

type Config struct {
	DBDriver string
	DBSource string // MySql DSN
	Port     string
	SMTP     SMTPConfig
}

func Load() (*Config, error) {

	_ = godotenv.Load() //加载.env文件,不存在时忽略

	cfg := &Config{
		DBDriver: getEnv("DB_DRIVER", "mysql"),
		DBSource: getEnv("DB_SOURCE", ""),
		Port:     getEnv("PORT", "8080"),
		SMTP: SMTPConfig{
			Host:     getEnv("SMTP_HOST", ""),
			Port:     getEnv("SMTP_PORT", "587"),
			User:     getEnv("SMTP_USER", ""),
			Password: getEnv("SMTP_PASSWORD", ""),
			From:     getEnv("SMTP_FROM", ""),
		},
	}

	if cfg.DBSource == "" {
		return nil, fmt.Errorf("缺少环境变量: DB_SOURCE")
	}
	return cfg, nil
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
