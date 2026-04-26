package model

import "gorm.io/gorm"

type User struct {
	gorm.Model
	AvatarURL string `gorm:"type:varchar(255);comment:头像"`
	Email string `gorm:"type:varchar(255);comment:邮箱"`
	Username string `gorm:"type:varchar(50);not null"`
	Password string `gorm:"type:varchar(255);not null"`
}
