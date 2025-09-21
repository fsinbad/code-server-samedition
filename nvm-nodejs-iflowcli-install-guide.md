# Code-Server 容器中安装 NVM 和 Node.js 指导文档

## 概述
本文档提供在 code-server 容器中安装 NVM (Node Version Manager) 和 Node.js 的详细步骤。适用于腾讯云或其他云平台的容器环境。

## 前提条件
- 已运行的 code-server 容器（如果是其它容器名称，请相应修改命令中的容器名称）
- 容器名称：`code-server`
- 具有容器的执行权限
- **重要**：为了持久化 NVM 和 Node.js 环境，需要配置数据卷挂载

## 数据持久化配置

为了确保 NVM 和 Node.js 环境在容器重启后仍然可用，需要将容器的 home 目录挂载到本地。

### Docker Compose 配置

在你的 `docker-compose.yml` 或 `original.yml` 文件中添加以下挂载配置：

```yaml
services:
  code-server:
    # ... 其他配置
    volumes:
      - "$HOME/.local/share/code-server:/home/coder/.local/share/code-server"
      - "$PWD:/home/coder/project"
      - "$PWD/code-server-data/home:/home/coder"  # 新增：持久化 home 目录
```

### 创建本地挂载目录

```bash
mkdir -p code-server-data/home
```

### 重启容器应用配置

```bash
docker compose -f original.yml down && docker compose -f original.yml up -d
```

## 安装步骤

### 1. 安装 NVM
使用 gitee 镜像地址安装 NVM，在国内网络环境下速度更快：

```bash
docker exec -it code-server /bin/bash -c 'curl -o- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash'
```

### 2. 安装 Node.js LTS 版本
加载 NVM 环境变量并安装最新的 LTS 版本 Node.js：

```bash
docker exec -it code-server /bin/bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts && nvm use --lts && node -v && npm -v'
```

### 3. 配置环境变量
确保 NVM 环境变量在每次登录时自动加载：

```bash
docker exec -it code-server /bin/bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts && nvm use --lts && echo "export NVM_DIR=\$HOME/.nvm" > ~/.bash_profile && echo "[ -s \$NVM_DIR/nvm.sh ] && \. \$NVM_DIR/nvm.sh" >> ~/.bash_profile && echo "[ -s \$NVM_DIR/bash_completion ] && \. \$NVM_DIR/bash_completion" >> ~/.bash_profile'
```

### 4. 验证安装
测试 Node.js 和 npm 是否正确安装：

```bash
docker exec -it code-server /bin/bash -l -c 'node -v && npm -v'
```

## 预期输出

安装成功后，你应该看到类似以下的输出：

```
v22.19.0
10.9.3
```

## 常用 NVM 命令

在 code-server 的 Web 终端中，你可以使用以下命令：

```bash
# 查看已安装的 Node.js 版本
nvm ls

# 安装指定版本的 Node.js
nvm install 18.17.0

# 切换到指定版本
nvm use 18.17.0

# 设置默认版本
nvm alias default 18.17.0

# 查看当前使用的版本
node -v
npm -v
```

## 安装 iFlow CLI

在成功安装 Node.js（版本需 20+）后，可以安装 iFlow CLI 工具：

### 1. 配置 npm 国内镜像加速

```bash
docker exec -it code-server /bin/bash -l -c 'npm config set registry https://registry.npmmirror.com'
```

### 2. 全局安装 iFlow CLI

```bash
docker exec -it code-server /bin/bash -l -c 'npm install -g @iflow-ai/iflow-cli'
```

### 3. 验证安装

```bash
docker exec -it code-server /bin/bash -l -c 'iflow --version'
```

### 4. 运行 iFlow

```bash
docker exec -it code-server /bin/bash -l -c 'iflow'
```

运行后会进入终端交互模式，按向导完成 API 密钥绑定并选择模型。

### iFlow CLI 注意事项

- 确保 Node.js 版本为 20+（我们安装的 LTS 版本满足要求）
- 如果安装失败，可以尝试清除 npm 缓存：`npm cache clean --force`
- 在容器环境中，所有 npm 全局包都会安装到容器的 `/home/coder` 目录下
- 由于配置了数据持久化，iFlow CLI 安装后会保留，容器重启后仍可使用

## 故障排除

### 问题：在 Web 终端中提示 "node: command not found"

**解决方案：**
在 code-server 的 Web 终端中执行：

```bash
source ~/.bash_profile
```

或者重新打开一个新的终端窗口。

### 问题：NVM 命令不可用

**解决方案：**
手动加载 NVM 环境：

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

### 问题：提示 "N/A: version \"\" is not yet installed"

**解决方案：**
这是因为直接使用 `nvm use --lts` 时没有先安装 Node.js 版本。需要先安装：

```bash
docker exec -it code-server /bin/bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts && nvm use --lts'
```

## 注意事项

1. **网络环境**：使用 gitee 镜像可以提高在国内的下载速度
2. **权限问题**：确保有足够的权限执行 docker 命令
3. **数据持久化**：
   - 必须配置 home 目录挂载：`$PWD/code-server-data/home:/home/coder`
   - 这样 NVM、Node.js 和所有环境配置都会保存到本地
   - 容器重启后环境会自动恢复，无需重新安装
4. **版本选择**：建议使用 LTS 版本以获得更好的稳定性
5. **首次安装**：如果是在已有容器上添加挂载，需要重新安装 NVM 和 Node.js

## 完整安装脚本

如果你想要一次性执行所有安装步骤，可以使用以下脚本：

```bash
#!/bin/bash

# 容器名称
CONTAINER_NAME="code-server"

echo "开始在容器 code-server 中安装 NVM 和 Node.js..."

# 1. 安装 NVM
echo "步骤 1: 安装 NVM"
docker exec -it code-server /bin/bash -c 'curl -o- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash'

# 2. 安装 Node.js LTS
echo "步骤 2: 安装 Node.js LTS 版本"
docker exec -it code-server /bin/bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts && nvm use --lts'

# 3. 配置环境变量
echo "步骤 3: 配置环境变量"
docker exec -it code-server /bin/bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm install --lts && nvm use --lts && echo "export NVM_DIR=\$HOME/.nvm" > ~/.bash_profile && echo "[ -s \$NVM_DIR/nvm.sh ] && \. \$NVM_DIR/nvm.sh" >> ~/.bash_profile && echo "[ -s \$NVM_DIR/bash_completion ] && \. \$NVM_DIR/bash_completion" >> ~/.bash_profile'

# 4. 验证安装
echo "步骤 4: 验证安装"
docker exec -it code-server /bin/bash -l -c 'node -v && npm -v'

echo "安装完成！"
```

将上述脚本保存为 `install-nvm-nodejs.sh`，然后执行：

```bash
chmod +x install-nvm-nodejs.sh
./install-nvm-nodejs.sh
```

---

# 5. 安装 iFlow CLI

在成功安装 Node.js（版本需 20+）后，可以安装 iFlow CLI 工具。iFlow CLI 是一个强大的 AI 代码助手工具，可以帮助开发者提高编程效率。

## 5.1 配置 npm 国内镜像加速

为了提高下载速度，建议先配置 npm 使用国内镜像：

```bash
docker exec -it code-server /bin/bash -l -c 'npm config set registry https://registry.npmmirror.com'
```

**说明**：使用淘宝 npm 镜像可以显著提高包下载速度，特别是在国内网络环境下。

## 5.2 全局安装 iFlow CLI

```bash
docker exec -it code-server /bin/bash -l -c 'npm install -g @iflow-ai/iflow-cli'
```

**安装过程**：
- 该命令会全局安装 iFlow CLI 工具
- 安装完成后，可以在任何目录下使用 `iflow` 命令
- 安装时间取决于网络速度，通常需要几分钟

## 5.3 验证安装

检查 iFlow CLI 是否安装成功：

```bash
docker exec -it code-server /bin/bash -l -c 'iflow --version'
```

**预期输出**：
```
0.2.26
```

如果看到版本号，说明安装成功。

## 5.4 运行 iFlow CLI

启动 iFlow CLI 进入交互模式：

```bash
docker exec -it code-server /bin/bash -l -c 'iflow'
```

**首次运行**：
- 会提示输入 API 密钥
- 需要选择使用的 AI 模型
- 按照向导完成初始配置

## 5.5 iFlow CLI 使用说明

### 常用命令

```bash
# 查看帮助信息
iflow --help

# 查看版本信息
iflow --version

# 启动交互模式
iflow

# 直接执行代码生成
iflow generate "创建一个 React 组件"
```

### 配置文件

iFlow CLI 的配置文件位于：`~/.iflow/config.json`

### 支持的功能

- **代码生成**：根据自然语言描述生成代码
- **代码解释**：解释现有代码的功能
- **代码优化**：提供代码改进建议
- **错误修复**：帮助修复代码中的错误
- **文档生成**：自动生成代码文档

## 5.6 注意事项

1. **Node.js 版本要求**：确保 Node.js 版本为 20+（我们安装的 LTS 版本满足要求）
2. **网络连接**：iFlow CLI 需要网络连接来访问 AI 服务
3. **API 密钥**：需要有效的 API 密钥才能使用 AI 功能
4. **数据持久化**：由于配置了数据持久化，iFlow CLI 安装后会保留，容器重启后仍可使用
5. **权限问题**：确保容器有足够的权限安装全局 npm 包

## 5.7 故障排除

### 问题：安装失败

**解决方案**：
```bash
# 清除 npm 缓存
docker exec -it code-server /bin/bash -l -c 'npm cache clean --force'

# 重新安装
docker exec -it code-server /bin/bash -l -c 'npm install -g @iflow-ai/iflow-cli'
```

### 问题：命令不可用

**解决方案**：
```bash
# 检查全局包安装路径
docker exec -it code-server /bin/bash -l -c 'npm list -g --depth=0'

# 重新加载环境变量
docker exec -it code-server /bin/bash -l -c 'source ~/.bash_profile'
```

### 问题：API 密钥配置

**解决方案**：
- 确保有有效的 API 密钥
- 检查网络连接是否正常
- 参考 iFlow 官方文档获取 API 密钥

## 5.8 完整安装脚本

如果你想要一次性执行 iFlow CLI 的所有安装步骤，可以使用以下脚本：

```bash
#!/bin/bash

# 容器名称
CONTAINER_NAME="code-server"

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
```

将上述脚本保存为 `install-iflow-cli.sh`，然后执行：

```bash
chmod +x install-iflow-cli.sh
./install-iflow-cli.sh
```
```

**文档版本**: 1.0  
**最后更新**: 2024年9月21日  
**适用环境**: Docker 容器、腾讯云、阿里云等云平台