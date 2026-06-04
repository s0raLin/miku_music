# Stage 1: Build
FROM golang:1.26-alpine AS builder

ENV GOPROXY=https://goproxy.cn,direct
ENV GO111MODULE=on

RUN apk add --no-cache gcc musl-dev

WORKDIR /app

# 先复制依赖文件，利用 Docker 缓存层
COPY go.mod go.sum ./

# 然后再下载依赖
RUN go mod download



# 复制源码并编译
COPY . .
RUN CGO_ENABLED=1 GOOS=linux go build -a -ldflags '-s -w -extldflags "-static"' -o /app/server ./cmd/server

# Stage 2: Runtime
FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata

# 设置时区
ENV TZ=Asia/Shanghai

WORKDIR /app

# 从构建阶段拷贝二进制文件
COPY --from=builder /app/server .

# 暴露端口（默认8080，可通过 PORT 环境变量覆盖）
EXPOSE 8080

# 运行服务
CMD ["./server"]
