#!/usr/bin/env bash

# ============================
# myapp.sh - 个人终端应用商店
# 集成：
#   - iris.sh 终端主题管理
#   - lsd 安装 + alias
#   - 软链接管理工具
#   - 自更新 + 备份清理
# ============================

# ======= 基本信息（你以后更新时改这两行就行） =======
APP_NAME="myapp.sh"
APP_VERSION="v0.1.0"
APP_CHANGELOG="v0.1.0: 集成 iris 主题管理、lsd 安装、软链接工具，自更新与备份清理。"

# ======= GitHub 仓库信息（按你实际情况改） =======
GITHUB_USER="Wolfun"           # TODO: 改成你的 GitHub 用户名
GITHUB_REPO="mytools"            # TODO: 改成你新建的仓库名
GITHUB_BRANCH="main"         # main 就写 main
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"

# iris.sh 的路径（放在同一仓库根目录）
IRIS_URL="${RAW_BASE}/iris.sh"

# 本地存放 myapp 相关文件的目录
INSTALL_DIR="$HOME/.myapp"
BACKUP_DIR="$INSTALL_DIR/backups"
CACHE_DIR="$INSTALL_DIR/cache"

mkdir -p "$INSTALL_DIR" "$BACKUP_DIR" "$CACHE_DIR"

# 当前脚本路径（用于自更新覆盖自己）
SCRIPT_PATH="${BASH_SOURCE[0]}"

# ============================
# 工具函数
# ============================

is_sourced() {
    [[ "$0" != "${BASH_SOURCE[0]}" ]]
}

backup_bashrc() {
    local BASHRC="$HOME/.bashrc"
    if [ -f "$BASHRC" ]; then
        local ts backup_file
        ts=$(date +%Y%m%d%H%M%S)
        backup_file="${BASHRC}.myapp.bak.${ts}"
        cp "$BASHRC" "$backup_file"
        echo "✅ 已备份当前 .bashrc 为：$backup_file"
    fi
}

press_enter() {
    echo
    read -rp "按回车键返回主菜单..." _
}

# ============================
# 1. 集成 iris.sh 主题管理
# ============================

run_iris() {
    echo "== iris 终端主题管理 =="
    local target="$CACHE_DIR/iris.sh"

    echo "📥 检查 / 下载 iris.sh ..."
    if ! curl -fsSL "$IRIS_URL" -o "$target"; then
        echo "❌ 下载 iris.sh 失败，请检查网络或 IRIS_URL 设置。"
        press_enter
        return
    fi

    chmod +x "$target"
    echo "▶ 运行 iris.sh ..."
    bash "$target"
}

# ============================
# 2. lsd 安装 + alias ls
# ============================

install_lsd() {
    echo "== 安装 lsd 并设置 alias =="

    if command -v lsd >/dev/null 2>&1; then
        echo "✅ 已检测到 lsd：$(command -v lsd)"
    else
        echo "未检测到 lsd，尝试通过包管理器安装..."

        if command -v apt >/dev/null 2>&1; then
            apt update && apt install -y lsd || {
                echo "❌ apt 安装 lsd 失败，请手动安装。"
                press_enter
                return
            }
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y lsd || {
                echo "❌ dnf 安装 lsd 失败，请手动安装。"
                press_enter
                return
            }
        elif command -v yum >/dev/null 2>&1; then
            yum install -y lsd || {
                echo "❌ yum 安装 lsd 失败，请手动安装。"
                press_enter
                return
            }
        elif command -v pacman >/dev/null 2>&1; then
            pacman -Sy --noconfirm lsd || {
                echo "❌ pacman 安装 lsd 失败，请手动安装。"
                press_enter
                return
            }
        else
            echo "❌ 未识别的包管理器，请自行安装 lsd。"
            press_enter
            return
        fi
    fi

    local BASHRC="$HOME/.bashrc"
    backup_bashrc

    # 使用 ASCII 风格 + 无图标
    local alias_line="alias ls='lsd --classic --icon=never'"

    if grep -q "alias ls='lsd" "$BASHRC" 2>/dev/null; then
        sed -i "s|alias ls='lsd.*'|${alias_line}|" "$BASHRC"
        echo "✅ 已更新现有 ls 别名为：${alias_line}"
    else
        echo "$alias_line" >> "$BASHRC"
        echo "✅ 已追加 ls 别名：${alias_line}"
    fi

    echo
    if is_sourced; then
        # shellcheck disable=SC1090
        . "$BASHRC"
        echo "🎉 已自动加载新 alias，当前终端可直接使用 ls=lsd。"
    else
        echo "👉 请执行：  source ~/.bashrc  让新 alias 生效。"
    fi

    press_enter
}

# ============================
# 3. 软链接管理工具
# ============================

symlink_tool() {
    echo "== 软链接管理工具 =="
    echo "说明：为脚本或文件创建软链接，方便用一个短命令直接调用。"
    echo

    read -rp "请输入要创建软链接的脚本/文件路径（可相对/绝对）： " target
    if [ -z "$target" ]; then
        echo "❌ 目标路径不能为空。"
        press_enter
        return
    fi

    # 转成绝对路径
    if [ ! -e "$target" ]; then
        echo "❌ 找不到目标文件：$target"
        press_enter
        return
    fi

    target="$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
    echo "✔ 目标绝对路径：$target"

    read -rp "请输入想要使用的命令名（例如 iris、mt、lsd、dockerx 等）： " name
    if [ -z "$name" ]; then
        echo "❌ 命令名不能为空。"
        press_enter
        return
    fi

    local link_path="/usr/local/bin/$name"

    if [ -e "$link_path" ] || [ -L "$link_path" ]; then
        read -rp "⚠️  /usr/local/bin/$name 已存在，是否覆盖？(y/n)： " yn
        if [[ ! "$yn" =~ ^[Yy]$ ]]; then
            echo "已取消创建软链接。"
            press_enter
            return
        fi
        rm -f "$link_path"
    fi

    ln -s "$target" "$link_path" || {
        echo "❌ 创建软链接失败，可能需要 root 权限。"
        press_enter
        return
    }

    # 如果是脚本，顺便加执行权限
    if file "$target" | grep -qi "script"; then
        chmod +x "$target"
    fi

    echo "✅ 已创建软链接：$link_path"
    echo "👉 现在可以直接在任何目录输入：  $name"
    press_enter
}

# ============================
# 4. 自更新 + 清理旧备份
# ============================

self_update() {
    echo "== 检查并更新 ${APP_NAME} =="

    local tmp_new="$INSTALL_DIR/${APP_NAME}.new"

    if ! curl -fsSL "${RAW_BASE}/${APP_NAME}" -o "$tmp_new"; then
        echo "❌ 无法从远程仓库下载最新版本，请检查 RAW_BASE 设置或网络。"
        press_enter
        return
    fi

    if cmp -s "$tmp_new" "$SCRIPT_PATH"; then
        echo "✅ 当前已经是最新版本（${APP_VERSION}）。"
        rm -f "$tmp_new"
        press_enter
        return
    fi

    # 备份当前版本
    local ts backup_file
    ts=$(date +%Y%m%d%H%M%S)
    backup_file="$BACKUP_DIR/${APP_NAME}.${ts}"
    cp "$SCRIPT_PATH" "$backup_file"
    echo "✅ 已备份当前版本到：$backup_file"

    # 覆盖当前脚本
    mv "$tmp_new" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"

    echo "🎉 已更新 ${APP_NAME} 到远程最新版本。"
    echo "当前版本号（本文件中的）：${APP_VERSION}"
    echo "更新说明（本文件中的）：${APP_CHANGELOG}"
    echo
    echo "👉 请重新运行：  bash ${SCRIPT_PATH}  使用新版本。"

    press_enter
}

clean_old_backups() {
    echo "== 清理 myapp 旧备份 =="

    if [ ! -d "$BACKUP_DIR" ]; then
        echo "当前没有备份目录：$BACKUP_DIR"
        press_enter
        return
    fi

    local count
    count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
    if [ "$count" -le 5 ]; then
        echo "备份数量：$count（<=5），暂不需要清理。"
        press_enter
        return
    fi

    echo "当前备份数量：$count，保留最新 5 个，其余删除。"
    ls -1t "$BACKUP_DIR"

    # 保留最新 5 个
    ls -1t "$BACKUP_DIR" | tail -n +6 | while read -r old; do
        rm -f "$BACKUP_DIR/$old"
    done

    echo "✅ 已清理旧备份，仅保留最新 5 个。"
    press_enter
}

# ============================
# 更新说明展示
# ============================

show_about() {
    clear
    echo "===== ${APP_NAME} 关于 / 版本信息 ====="
    echo "版本：${APP_VERSION}"
    echo "说明：${APP_CHANGELOG}"
    echo
    echo "远程仓库：${GITHUB_USER}/${GITHUB_REPO} (${GITHUB_BRANCH})"
    echo "RAW_BASE：${RAW_BASE}"
    echo
    echo "提示：每次你在 GitHub 上更新 ${APP_NAME} 并修改上述版本信息，"
    echo "      VPS 上通过“检查更新”就能拉取最新版本。"
    press_enter
}

# ============================
# 【重要】以后如何添加新脚本？
# ============================
# 1. 把新脚本上传到仓库，例如：scripts/newtool.sh
# 2. 确保它能被直接执行：bash <(curl -s RAW_BASE/scripts/newtool.sh) 或 curl -s … | bash
# 3. 在下面 main_menu 的菜单里加一个选项，比如 5) 新工具
# 4. 写一个函数 run_newtool()，里面调用：
#       curl -fsSL "${RAW_BASE}/scripts/newtool.sh" -o "$CACHE_DIR/newtool.sh"
#       chmod +x "$CACHE_DIR/newtool.sh"
#       bash "$CACHE_DIR/newtool.sh"
# 5. 以后更新 newtool.sh，只要 push 到 GitHub，myapp.sh 这边就会用最新的脚本。

# ============================
# 主菜单
# ============================

main_menu() {
    while true; do
        clear
        echo "============== ${APP_NAME} 综合管理菜单 =============="
        echo "  版本：${APP_VERSION}"
        echo
        echo "  1. 打开 iris 终端主题管理（iris.sh）"
        echo "  2. 安装 lsd 并设置 ls=lsd（ASCII 无图标）"
        echo "  3. 软链接管理工具（为脚本/文件设置启动命令）"
        echo "  4. 检查并更新 ${APP_NAME}"
        echo "  5. 清理 myapp 旧备份文件"
        echo "  6. 查看当前版本与更新说明"
        echo "  0. 退出"
        echo "====================================================="
        read -rp "请输入选项： " opt

        case "$opt" in
            1) run_iris ;;
            2) install_lsd ;;
            3) symlink_tool ;;
            4) self_update ;;
            5) clean_old_backups ;;
            6) show_about ;;
            0)
                echo "再见 ~"
                break
                ;;
            *)
                echo "❌ 无效选项，请输入 0-6。"
                sleep 1
                ;;
        esac
    done
}

main_menu
