package model

import "gorm.io/gorm"

type User struct {
	gorm.Model
	AvatarURL string `gorm:"type:varchar(255);comment:头像" json:"avatar"`
	Email     string `gorm:"type:varchar(255);comment:邮箱" json:"email"`
	Username  string `gorm:"type:varchar(50);not null" json:"username"`
	Password  string `gorm:"type:varchar(255);not null" json:"password"`
}
