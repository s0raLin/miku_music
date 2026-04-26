package utils

import (
	"context"
	"fmt"
	"github.com/aliyun/alibabacloud-oss-go-sdk-v2/oss"
	"github.com/aliyun/alibabacloud-oss-go-sdk-v2/oss/credentials"
	"mime/multipart"
)

var ossClient *oss.Client
var bucketName = ""
var region = ""

func init() {
	//初始化OSS客户端
	cfg := oss.LoadDefaultConfig().WithCredentialsProvider(credentials.NewEnvironmentVariableCredentialsProvider()).WithRegion(region)
	ossClient = oss.NewClient(cfg)
}

func OSSUpload(file *multipart.FileHeader) (string, error) {
	f, err := file.Open()
	if err != nil {
		return "", fmt.Errorf("打开文件失败: %v", err)
	}
	defer f.Close() //关闭流

	objectName := fmt.Sprintf("%s", file.Filename)

	//准备上传请求
	request := &oss.PutObjectRequest{
		Bucket: oss.Ptr(bucketName),
		Key:    oss.Ptr(objectName),
		Body:   f, // 直接将接收到的文件流传给 OSS
	}

	//执行上传到OSS
	_, err = ossClient.PutObject(context.TODO(), request)
	if err != nil {

		return "", fmt.Errorf("OSS 上传失败: %v", err)
	}

	// 5. 返回结果
	// 注意：如果 Bucket 是私有的，这个 URL 需要加签名才能访问
	fileURL := fmt.Sprintf("https://%s.%s.aliyuncs.com/%s", bucketName, region, objectName)

	return fileURL, nil
}
