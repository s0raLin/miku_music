package repository

import (
	"fmt"
	"log"
	"miku_music/config"
	"miku_music/internal/model"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

func Init(cfg *config.Config) *gorm.DB {
	var dialector gorm.Dialector
	switch cfg.DBDriver {
	case "mysql":
		dialector = mysql.Open(cfg.DBSource)
	default:
		log.Fatalf("数据库类型无效")
	}
	db, err := gorm.Open(dialector, &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})

	if err != nil {
		log.Fatalf("无法连接数据库: %v", err)
	}

	// 连接池配置（MySQL 推荐）
	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("failed to get sql.DB: %v", err)
	}
	sqlDB.SetMaxIdleConns(10)           // 最大空闲连接数
	sqlDB.SetMaxOpenConns(100)          // 最大打开连接数
	sqlDB.SetConnMaxLifetime(time.Hour) // 连接最大存活时间

	// 自动建表
	err = db.AutoMigrate(
		&model.User{},
		&model.MusicInfo{},
		&model.PlayList{},
	)

	fmt.Printf("Mysql 连接成功")
	DB = db
	return db
}
