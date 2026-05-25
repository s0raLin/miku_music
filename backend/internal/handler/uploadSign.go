package handler

import (
	"context"
	"fmt"
	"net/http"

	"github.com/aliyun/alibabacloud-oss-go-sdk-v2/oss"
	"github.com/aliyun/alibabacloud-oss-go-sdk-v2/oss/credentials"

	"github.com/gin-gonic/gin"
)

type UploadSignHandler struct{}

func NewUploadSignHandler() *UploadSignHandler {
	return &UploadSignHandler{}
}

func (s *UploadSignHandler) GetUploadUrl(c *gin.Context) {
	var req struct {
		// binding:"required" 确保当前端没传这个字段时，会自动报错拦截
		UserId   string `json:"user_id" binding:"required"`
		FileName string `json:"file_name" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": 1,
			"msg":  "文件名不能为空",
		})
		return
	}

	bucketName := "cangli"
	region := "cn-beijing"
	objectName := fmt.Sprintf("user/%s/%s", req.UserId, req.FileName)
	cfg := oss.LoadDefaultConfig().
		WithCredentialsProvider(credentials.NewEnvironmentVariableCredentialsProvider()).
		WithRegion(region) // 填写Bucket所在地域

	// 初始化 OSS 客户端
	client := oss.NewClient(cfg)

	presignReq := &oss.PutObjectRequest{
		Bucket: &bucketName,
		Key:    &objectName,
	}

	// 4. 调用 Presign 生成带签名的 URL
	ctx := context.Background() // v2 SDK 的方法几乎都需要传入 Context
	result, err := client.Presign(ctx, presignReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": 1,
			"msg":  "获取SignedURL失败: " + err.Error(),
		})
		return
	}

	// 返回这个带有签名参数的完整 URL 给前端
	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "获取SignedURL成功",
		"data": result.URL,
	})
}
