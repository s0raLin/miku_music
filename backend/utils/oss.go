package utils

import (
	"context"
	"fmt"
	"log"
	"mime/multipart"

	"github.com/aliyun/alibabacloud-oss-go-sdk-v2/oss"
	"github.com/aliyun/alibabacloud-oss-go-sdk-v2/oss/credentials"
)

/*
Go SDK V2 客户端初始化配置说明：

1. 签名版本：Go SDK V2 默认使用 V4 签名，提供更高的安全性
2. Region配置：初始化 Client 时，您需要指定阿里云通用 Region ID 作为发起请求地域的标识
3. Endpoint配置：
   - 可以通过 Endpoint 参数，自定义服务请求的访问域名
   - 当不指定时，SDK 默认根据 Region 信息，构造公网访问域名
4. 协议配置：
   - SDK 构造访问域名时默认采用 HTTPS 协议
   - 如需采用 HTTP 协议，请在指定域名时指定为 HTTP
*/

func OSSUpload(file *multipart.FileHeader, fileName string) (string, error) {
	bucketName := "cangli"
	region := "cn-beijing"

	f, err := file.Open()
	if err != nil {
		return "", fmt.Errorf("无法读取用户上传的文件内容: %v", err)
	}
	defer f.Close()

	//拼接生成新的文件名(路径+UUID+后缀)
	objectKey := fmt.Sprintf("miku_music/%s", fileName)

	// 方式一：只填写Region（推荐）
	cfg := oss.LoadDefaultConfig().
		WithCredentialsProvider(credentials.NewEnvironmentVariableCredentialsProvider()).
		WithRegion(region) // 填写Bucket所在地域

	// 创建OSS客户端
	client := oss.NewClient(cfg)

	// 定义要上传的字符串内容
	// body := strings.NewReader("hi oss")

	// 创建上传对象的请求
	request := &oss.PutObjectRequest{
		Bucket: oss.Ptr(bucketName), // 存储空间名称
		Key:    oss.Ptr(objectKey),  // 对象名称
		Body:   f,                   // 要上传的字符串内容
	}

	// 发送上传对象的请求
	result, err := client.PutObject(context.TODO(), request)
	if err != nil {

		return "", fmt.Errorf("failed to put object %v", err)
	}

	// 打印上传对象的结果
	log.Printf("Status: %#v\n", result.Status)
	log.Printf("RequestId: %#v\n", result.ResultCommon.Headers.Get("X-Oss-Request-Id"))
	log.Printf("ETag: %#v\n", *result.ETag)

	//"https://" + bucketName + ".oss-" + endpoint + "/" + path, nil
	fileURL := fmt.Sprintf("https://%s.oss-%s.aliyuncs.com/%s", bucketName, region, objectKey)
	return fileURL, nil
}
