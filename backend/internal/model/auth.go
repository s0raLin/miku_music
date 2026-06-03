package model

import (
	"time"

	"gorm.io/gorm"
)

// User 用户模型
// 支持邮箱+密码登录 或 邮箱+验证码登录
// 密码使用 bcrypt 哈希存储，序列化时不会暴露到 JSON
type User struct {
	gorm.Model
	AvatarURL    string `gorm:"type:varchar(255);comment:头像OSS地址" json:"avatar"`
	Email        string `gorm:"type:varchar(255);uniqueIndex;comment:邮箱(唯一)" json:"email"`
	Username     string `gorm:"type:varchar(50);not null" json:"username"`
	PasswordHash string `gorm:"column:password;type:varchar(255);comment:bcrypt密码哈希" json:"-"` // 映射到旧 password 列

	UploadMusics     []MusicInfo `gorm:"many2many:user_uploads_music;"`
	UplaodsPlayLists []PlayList  `gorm:"many2many:user_uploads_playlist"`
}

// EmailVerification 邮箱验证码记录
// 用于注册和登录时的邮箱验证流程
type EmailVerification struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Email     string    `gorm:"type:varchar(255);index;comment:目标邮箱" json:"email"`
	Code      string    `gorm:"type:varchar(10);comment:6位验证码" json:"-"`
	Purpose   string    `gorm:"type:varchar(20);comment:用途: register/login" json:"purpose"`
	Used      bool      `gorm:"default:false;comment:是否已使用" json:"used"`
	ExpiresAt time.Time `gorm:"comment:过期时间" json:"expires_at"`
	CreatedAt time.Time `json:"created_at"`
}
