#!/bin/bash

# 容器名称
CONTAINER_NAME="code-server"

echo "开始在容器 $CONTAINER_NAME 中安装 NVM 和 Node.js..."

# 1. 安装 NVM
echo "步骤 1: 安装 NVM"
docker exec -it $CONTAINER_NAME /bin/bash -c 'curl -o- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash'

# 2. 安装 Node.js LTS
echo "步骤 2: 安装 Node.js LTS 版本"
docker exec -it $CONTAINER_NAME /bin/bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts && nvm use --lts'

# 3. 配置环境变量
echo "步骤 3: 配置环境变量"
docker exec -it $CONTAINER_NAME /bin/bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts && nvm use --lts && echo "export NVM_DIR=\$HOME/.nvm" > ~/.bash_profile && echo "[ -s \$NVM_DIR/nvm.sh ] && \. \$NVM_DIR/nvm.sh" >> ~/.bash_profile && echo "[ -s \$NVM_DIR/bash_completion ] && \. \$NVM_DIR/bash_completion" >> ~/.bash_profile'

# 4. 验证安装
echo "步骤 4: 验证安装"
docker exec -it $CONTAINER_NAME /bin/bash -l -c 'node -v && npm -v'

echo "NVM 和 Node.js 安装完成！"
echo "使用 'docker exec -it $CONTAINER_NAME /bin/bash -l' 进入容器并使用 Node.js"