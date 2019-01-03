############################
# STEP 1 build executable binary
############################

# 指定 GO 版本号
ARG GO_VERSION=1.11.1

# 指定构建环境
FROM golang:${GO_VERSION}-alpine AS builder

# 创建用户 appuser
RUN adduser -D -g '' appuser

# 复制源码并指定工作目录
RUN mkdir -p /src/myapp
COPY . /src/myapp
WORKDIR /src/myapp

# 为 go build 设置环境变量:
# * CGO_ENABLED=0 表示构建一个静态链接的可执行程序
# * GOOS=linux GOARCH=amd64 表示指定linux 64位的运行环境
# * GOPROXY=https://goproxy.io 指定代理地址
# * GOFLAGS=-mod=vendor 在执行 `go build` 强制查看 `/vendor` 目录
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOFLAGS=-mod=vendor

# 构建可执行文件
RUN go build -a -installsuffix cgo -ldflags="-w -s" -o /src/myapp/monitor

############################
# STEP 2 build a small image
############################

# 构建最小镜像
FROM scratch AS final

# 设置系统语言
ENV LANG en_US.UTF-8

# 从 builder 中导入用户及组相关文件
COPY --from=builder /etc/passwd /etc/passwd

# 将构建的可执行文件复制到新镜像中
COPY --from=builder /src/myapp/config /config
COPY --from=builder /src/myapp/monitor /monitor

# 端口申明
EXPOSE 8000

# 运行
ENTRYPOINT [ "/monitor" ]