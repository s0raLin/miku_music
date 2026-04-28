package model

import (
	"time"

	"gorm.io/gorm"
)

type PlayList struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	Name        string `gorm:"size:255;not null" json:"name"`
	Description string `json:"description"`
	UserID      uint   `json:"user_id"` // 创建者ID

	Musics    []MusicInfo    `gorm:"many2many:playlist_musics;" json:"songs"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}
