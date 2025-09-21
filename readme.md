# Code-Server Docker 容器配置指南

## 概述

本项目使用 Docker Compose 部署 code-server，提供基于浏览器的 VS Code 开发环境。包含完整的 NVM、Node.js 和 iFlow CLI 自动化安装脚本。

code-server仓库：https://github.com/coder/code-server 

## 配置文件说明

### docker-compose.yml 配置

```yaml
version: "3.9"
services:
  code-server:
    image: codercom/code-server:latest
    container_name: code-server-origin
    restart: unless-stopped
    ports:
      - "127.0.0.1:8680:8080"
    volumes:
      - ./code-server-data:/home/coder/.local/share/code-server
      - ./project:/home/coder/project
      - ./config.yaml:/home/coder/.config/code-server/config.yaml
    environment:
      - DOCKER_USER=${USER}
      - PASSWORD=xiaoyibao@1234
    user: "${UID:-1000}:${GID:-1000}"
    stdin_open: true
    tty: true
```

### 关键配置说明

- **端口映射**: `127.0.0.1:8680:8080` - 本地8680端口映射到容器8080端口
- **数据持久化**: `./code-server-data` - 保存 code-server 配置和扩展
- **项目目录**: `./project` - **重要：这是您应该保存代码文件的目录**
- **配置文件**: `./config.yaml` - code-server 配置文件
- **用户权限**: 使用 UID:GID 1000:1000

## 快速开始

### 1. 启动服务

```bash
# 启动服务
docker compose up -d

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs code-server-origin
```

### 2. 自动化安装脚本

本项目提供了两个自动化安装脚本，可以快速在容器中安装开发环境：

#### 安装 NVM 和 Node.js

```bash
# 运行 NVM 和 Node.js 自动安装脚本
./install-nvm-nodejs.sh
```

#### 安装 iFlow CLI

```bash
# 运行 iFlow CLI 自动安装脚本
./install-iflow-cli.sh
```

### 3. 停止服务

```bash
# 停止服务
docker compose down
```

## 访问方式

- **访问地址**: http://localhost:8680
- **登录密码**: `xiaoyibao@1234`（在 docker-compose.yml 中配置）

## ⚠️ 重要：文件保存路径说明

### 正确的文件保存路径

**必须在挂载的目录中保存文件，否则文件将丢失或无法保存！**

✅ **正确路径**：
- `/home/coder/project` - 映射到宿主机 `./project` 目录
- `/home/coder/.local/share/code-server` - code-server 数据目录

❌ **错误路径**：
- `/srv` - 未挂载，无写权限
- `/tmp` - 临时目录，容器重启后丢失
- `/root` - 权限问题
- 其他未挂载的目录

### 常见错误案例

**错误示例**：在浏览器中新建文件 `123.md`，保存到 `/srv/123.md`

**错误原因**：
- `/srv` 目录未挂载到宿主机
- 容器内 UID=1000 对 `/srv` 没有写权限
- 导致 `EACCES` 权限错误

**解决方案（二选一）**：

#### 方案1：使用正确的保存路径（推荐）

1. 在 VS Code 左侧资源管理器中打开 `/home/coder/project`
2. 在该目录下新建/保存文件
3. 文件将自动保存到宿主机 `./project` 目录

#### 方案2：额外挂载 /srv 目录（可选）

如果确实需要使用 `/srv` 目录：

1. 修改 `docker-compose.yml`，添加 `/srv` 挂载：

```yaml
volumes:
  - ./project:/home/coder/project
  - ./srv:/srv          # 新增挂载
  - ./code-server-data:/home/coder/.local/share/code-server
  - ./config.yaml:/home/coder/.config/code-server/config.yaml
```

2. 创建目录并设置权限：

```bash
# 创建 srv 目录
mkdir -p srv

# 设置正确的用户权限
sudo chown -R 1000:1000 srv

# 重启服务
docker compose up -d
```

## 最佳实践

### 文件管理原则

1. **只在挂载目录中写文件**
   - 主要使用 `/home/coder/project`
   - 或其他自己额外挂载的目录

2. **目录权限管理**
   - 宿主机目录提前设置 `chown 1000:1000`
   - 避免让 root 自动创建目录

### 推荐的项目结构

```
Codeserver/
├── docker-compose.yml        # Docker 配置文件
├── config.yaml              # code-server 配置
├── install-nvm-nodejs.sh    # NVM 和 Node.js 自动安装脚本
├── install-iflow-cli.sh     # iFlow CLI 自动安装脚本
├── nvm-nodejs-iflowcli-install-guide.md  # 详细安装指南
├── project/                 # 代码项目目录（重要！）
│   ├── src/
│   ├── docs/
│   └── README.md
├── code-server-data/        # code-server 数据（自动生成）
└── README.md               # 本说明文档
```

## 故障排除

### 常见问题

1. **无法保存文件 (EACCES)**
   - 检查是否在正确的挂载目录中保存
   - 确认目录权限为 1000:1000

2. **端口被占用**
   - 修改 docker-compose.yml 中的端口映射
   - 使用 `lsof -i :端口号` 检查端口占用

3. **容器启动失败**
   - 检查 `docker compose logs code-server`
   - 确认配置文件语法正确

### 有用的命令

```bash
# 进入容器
docker compose exec code-server-origin bash

# 查看容器内目录权限
docker compose exec code-server-origin ls -la /home/coder/

# 重新构建并启动
docker compose up -d --force-recreate

# 清理并重启
docker compose down && docker compose up -d

# 检查 Node.js 和 npm 版本
docker exec -it code-server-origin /bin/bash -l -c 'node -v && npm -v'

# 检查 iFlow CLI 版本
docker exec -it code-server-origin /bin/bash -l -c 'iflow --version'
```

## 配置文件模板

### config.yaml 示例

```yaml
bind-addr: 127.0.0.1:8080
auth: password
password: xiaoyibao@1234
cert: false
```

## 国内用户下载优化

### 腾讯云/阿里云等国内服务器加速方案

如果您在国内服务器上部署，从 GitHub 下载可能很慢（几十 KB/s），可以使用以下加速方案：

#### 方案1：使用清华大学镜像站（推荐）

```bash
# 查询最新版本号
VERSION=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest | grep tag_name | cut -d'"' -f4)
echo $VERSION

# 使用清华镜像下载（速度通常 3-10 MB/s）
BASE="https://mirrors.tuna.tsinghua.edu.cn/github-release/coder/code-server"
RPM="code-server-${VERSION#v}-amd64.rpm"
curl -L -C - -o "$HOME/$RPM" \
     "$BASE/${VERSION}/${RPM}"

# 安装 RPM 包（CentOS/RHEL）
sudo yum install -y "$HOME/$RPM"
```

#### 方案2：Docker 镜像加速

如果使用 Docker，可以配置国内镜像源：

```bash
# 配置 Docker 镜像加速器
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF

# 重启 Docker 服务
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 注意事项

- 🔒 **安全性**: 仅绑定到 127.0.0.1，不对外网开放
- 💾 **数据持久化**: 重要文件必须保存在挂载目录中
- 🔧 **权限管理**: 确保目录权限正确设置为 1000:1000
- 🚀 **性能优化**: 定期清理不需要的扩展和缓存
- 🌐 **网络优化**: 国内用户建议使用镜像站加速下载

## 自动化安装脚本详细说明

### install-nvm-nodejs.sh

**功能**：自动在容器中安装 NVM 和 Node.js LTS 版本

**包含步骤**：
1. 安装 NVM（使用 Gitee 镜像加速）
2. 安装 Node.js LTS 版本
3. 配置环境变量到 ~/.bash_profile
4. 验证安装结果

**使用方法**：
```bash
# 确保脚本有执行权限
chmod +x install-nvm-nodejs.sh

# 运行安装脚本
./install-nvm-nodejs.sh
```

### install-iflow-cli.sh

**功能**：自动在容器中安装 iFlow CLI

**包含步骤**：
1. 配置 npm 国内镜像源（提高下载速度）
2. 全局安装 @iflow-ai/iflow-cli
3. 验证安装结果

**使用方法**：
```bash
# 确保脚本有执行权限
chmod +x install-iflow-cli.sh

# 运行安装脚本
./install-iflow-cli.sh
```

**注意事项**：
- 运行脚本前请确保容器已启动
- 脚本会自动使用正确的容器名称 `code-server-origin`
- 如果安装失败，请检查网络连接和容器状态

### 详细安装指南

如需了解手动安装步骤和故障排除，请参考：
- `nvm-nodejs-iflowcli-install-guide.md` - 完整的安装指南文档

---

**记住核心原则**：
1. 只在挂载目录里写文件（`/home/coder/project` 或自己额外挂载的目录）
2. 宿主机目录提前 `chown 1000:1000`，避免权限问题
3. 使用提供的自动化脚本可以快速完成开发环境配置