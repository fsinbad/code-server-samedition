#!/bin/bash

# 容器名称
CONTAINER_NAME="code-server-origin"

echo "开始在容器 $CONTAINER_NAME 中安装 iFlow CLI..."

# 1. 配置 npm 镜像
echo "步骤 1: 配置 npm 国内镜像"
docker exec -it $CONTAINER_NAME /bin/bash -l -c 'npm config set registry https://registry.npmmirror.com'

# 2. 安装 iFlow CLI
echo "步骤 2: 安装 iFlow CLI"
docker exec -it $CONTAINER_NAME /bin/bash -l -c 'npm install -g @iflow-ai/iflow-cli'

# 3. 验证安装
echo "步骤 3: 验证安装"
docker exec -it $CONTAINER_NAME /bin/bash -l -c 'iflow --version'

echo "iFlow CLI 安装完成！"
echo "使用 'docker exec -it $CONTAINER_NAME /bin/bash -l -c iflow' 来启动 iFlow CLI"