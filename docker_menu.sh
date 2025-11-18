#!/usr/bin/env bash
#
# docker_menu.sh - Docker 项目一键部署菜单
#
# 功能：
#   - 统一管理多个 docker-compose 项目（部署 / 启停 / 日志 / 删除）
#   - 所有项目放在当前目录的 myapp/docker/ 下
#   - 内置 3 个示例项目：
#       * demo_whoami  : 简单 HTTP 测试服务
#       * nginx_basic  : 简单 Nginx 静态站
#       * portainer    : Portainer 面板
#
# 目录结构示例（在你执行 myapp.sh 的目录下）：
#
#   ./myapp/
#     docker/
#       demo_whoami/
#         docker-compose.yml
#       nginx_basic/
#         docker-compose.yml
#       portainer/
#         docker-compose.yml
#
# ============================================

set -e

# ===== 根目录：和 myapp.sh 一致，使用当前目录的 myapp/ =====
APP_ROOT="$PWD/myapp"
DOCKER_ROOT="$APP_ROOT/docker"

mkdir -p "$DOCKER_ROOT"

# ===== 检测 docker / docker compose 命令 =====

COMPOSE_CMD=""

detect_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ 未检测到 docker 命令，请先安装 Docker 再使用此菜单。"
        exit 1
    fi

    # 检测 docker daemon 是否在运行（简单 ping 一下）
    if ! docker info >/dev/null 2>&1; then
        echo "❌ docker 似乎没有运行，请先启动 Docker 服务。"
        exit 1
    fi
}

detect_compose() {
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD="docker-compose"
    else
        echo "❌ 未检测到 docker compose 或 docker-compose，请先安装。"
        exit 1
    fi
}

# ===== 项目列表配置（你以后新增项目就改这里） =====
#
# PROJECT_KEYS：内部使用的 key，用来生成目录名等
# 例如：
#   demo_whoami -> ./myapp/docker/demo_whoami/
#   nginx_basic -> ./myapp/docker/nginx_basic/
#   portainer   -> ./myapp/docker/portainer/
#
# 如果你以后要新增一个项目：
#   1）在 PROJECT_KEYS 里加一个 key
#   2）在 project_name/project_desc/generate_compose 里面补充 case 分支
# ============================================

PROJECT_KEYS=(
  "demo_whoami"
  "nginx_basic"
  "portainer"
)

# ===== 获取项目中文名称 =====
project_name() {
    local key="$1"
    case "$key" in
        demo_whoami) echo "Demo Whoami 测试服务" ;;
        nginx_basic) echo "Nginx 简单静态站点" ;;
        portainer)   echo "Portainer 面板" ;;
        *)           echo "$key" ;;
    esac
}

# ===== 获取项目描述 =====
project_desc() {
    local key="$1"
    case "$key" in
        demo_whoami) echo "最简单的 whoami HTTP 服务，用来测试 Docker / 端口转发。" ;;
        nginx_basic) echo "Nginx 静态站，默认挂载 ./html 到容器的 /usr/share/nginx/html。" ;;
        portainer)   echo "基于 Web 的 Docker 管理面板，端口 9000 / 9443。" ;;
        *)           echo "无描述" ;;
    esac
}

# ===== 生成 docker-compose.yml （根据项目 key） =====
#
# 注意：
#   - 这些只是示例，你可以随意修改、扩展、增加环境变量等
#   - 如果你以后希望从 GitHub 下载 compose 文件，也可以改成 curl 方式
# ============================================

generate_compose() {
    local key="$1"
    local dir="$2"
    local file="$dir/docker-compose.yml"

    mkdir -p "$dir"

    case "$key" in
        demo_whoami)
            cat << 'EOF' > "$file"
version: "3.8"

services:
  whoami:
    image: traefik/whoami
    container_name: demo_whoami
    restart: unless-stopped
    ports:
      - "8081:80"
EOF
            ;;

        nginx_basic)
            mkdir -p "$dir/html"
            cat << 'EOF' > "$dir/html/index.html"
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Welcome to nginx_basic</title>
</head>
<body>
  <h1>nginx_basic is running!</h1>
  <p>你可以在 ./myapp/docker/nginx_basic/html/index.html 修改这个页面。</p>
</body>
</html>
EOF

            cat << 'EOF' > "$file"
version: "3.8"

services:
  nginx:
    image: nginx:alpine
    container_name: nginx_basic
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
EOF
            ;;

        portainer)
            mkdir -p "$dir/data"
            cat << 'EOF' > "$file"
version: "3.8"

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/data
    ports:
      - "9000:9000"
      - "9443:9443"
EOF
            ;;

        *)
            echo "❌ 未知项目 key：$key"
            return 1
            ;;
    esac

    echo "✅ 已生成 compose 文件：$file"
}

# ===== 工具函数 =====

press_any_key() {
    echo
    read -n1 -s -r -p "按任意键返回上一菜单..." _
    echo
}

select_project() {
    # 返回值：通过 echo 输出选中的 key，如果返回空字符串说明取消
    echo "可用项目列表："
    local i key name
    for i in "${!PROJECT_KEYS[@]}"; do
        key="${PROJECT_KEYS[$i]}"
        name=$(project_name "$key")
        printf "  %d. %s (%s)\n" $((i+1)) "$name" "$key"
    done
    echo "  0. 取消"
    echo

    local choice
    while true; do
        read -rp "请选择项目编号： " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "${#PROJECT_KEYS[@]}" ]; then
            break
        fi
        echo "❌ 请输入 0-${#PROJECT_KEYS[@]}。"
    done

    if [ "$choice" -eq 0 ]; then
        echo ""
    else
        echo "${PROJECT_KEYS[$((choice-1))]}"
    fi
}

project_dir() {
    local key="$1"
    echo "$DOCKER_ROOT/$key"
}

# ===== 对单个项目进行操作 =====

project_menu() {
    local key="$1"
    local name desc dir compose_file
    name=$(project_name "$key")
    desc=$(project_desc "$key")
    dir=$(project_dir "$key")
    compose_file="$dir/docker-compose.yml"

    while true; do
        clear
        echo "===== 项目：$name ====="
        echo "Key：$key"
        echo "目录：$dir"
        echo "说明：$desc"
        echo
        echo "  1. 部署 / 更新（生成 compose 文件并 up -d）"
        echo "  2. 启动（up -d）"
        echo "  3. 停止（stop）"
        echo "  4. 查看状态（ps）"
        echo "  5. 查看日志（logs）"
        echo "  6. 删除容器（down）"
        echo "  7. 删除整个项目目录（慎用）"
        echo "  0. 返回上一级"
        echo "================================"
        read -rp "请输入选项： " opt

        case "$opt" in
            1)
                echo "➡ 部署 / 更新 $name ..."
                generate_compose "$key" "$dir"
                ( cd "$dir" && $COMPOSE_CMD up -d )
                echo "✅ 已执行：$COMPOSE_CMD up -d"
                press_any_key
                ;;
            2)
                if [ ! -f "$compose_file" ]; then
                    echo "⚠ 未找到 compose 文件，先执行“部署 / 更新”生成。"
                else
                    ( cd "$dir" && $COMPOSE_CMD up -d )
                    echo "✅ 已执行：$COMPOSE_CMD up -d"
                fi
                press_any_key
                ;;
            3)
                if [ ! -f "$compose_file" ]; then
                    echo "⚠ 未找到 compose 文件，无法执行 stop。"
                else
                    ( cd "$dir" && $COMPOSE_CMD stop )
                    echo "✅ 已执行：$COMPOSE_CMD stop"
                fi
                press_any_key
                ;;
            4)
                if [ ! -f "$compose_file" ]; then
                    echo "⚠ 未找到 compose 文件，无法执行 ps。"
                else
                    ( cd "$dir" && $COMPOSE_CMD ps )
                fi
                press_any_key
                ;;
            5)
                if [ ! -f "$compose_file" ]; then
                    echo "⚠ 未找到 compose 文件，无法查看日志。"
                    press_any_key
                else
                    echo "👉 正在查看日志（Ctrl+C 退出）。"
                    ( cd "$dir" && $COMPOSE_CMD logs -f )
                fi
                ;;
            6)
                if [ ! -f "$compose_file" ]; then
                    echo "⚠ 未找到 compose 文件，无法执行 down。"
                else
                    read -rp "确认删除容器但保留数据卷吗？(y/n)： " yn
                    if [[ "$yn" =~ ^[Yy]$ ]]; then
                        ( cd "$dir" && $COMPOSE_CMD down )
                        echo "✅ 已执行：$COMPOSE_CMD down"
                    else
                        echo "已取消。"
                    fi
                fi
                press_any_key
                ;;
            7)
                read -rp "⚠ 确认要删除整个目录 $dir 吗？（包含 compose 文件和本地数据）(y/n)： " yn2
                if [[ "$yn2" =~ ^[Yy]$ ]]; then
                    rm -rf "$dir"
                    echo "✅ 已删除目录：$dir"
                    press_any_key
                    break
                else
                    echo "已取消。"
                    press_any_key
                fi
                ;;
            0)
                break
                ;;
            *)
                echo "❌ 无效选项。"
                sleep 1
                ;;
        esac
    done
}

# ===== 主菜单 =====

main_menu() {
    detect_docker
    detect_compose

    while true; do
        clear
        echo "===== Docker 项目一键部署菜单 ====="
        echo "工作根目录：$APP_ROOT"
        echo "项目目录：  $DOCKER_ROOT"
        echo
        echo "  1. 选择项目并管理（部署 / 启停 / 日志等）"
        echo "  0. 返回上一级 / 退出"
        echo "==================================="
        read -rp "请输入选项： " opt

        case "$opt" in
            1)
                local key
                key=$(select_project)
                if [ -n "$key" ]; then
                    project_menu "$key"
                fi
                ;;
            0)
                break
                ;;
            *)
                echo "❌ 无效选项，请输入 0/1。"
                sleep 1
                ;;
        esac
    done
}

main_menu
