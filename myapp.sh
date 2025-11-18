#!/usr/bin/env bash
#
# ============================================
# myapp.sh - 个人综合“终端应用商店”主控脚本
# --------------------------------------------
# 功能：
#   - 作为统一入口，调用 GitHub 仓库中的子脚本
#   - 分类菜单，方便后续脚本越来越多时归类
#   - 支持：
#       * 终端主题管理（iris.sh）
#       * 安装 lsd 并设置 ls 别名（lsd_install.sh）
#       * 软链接管理工具（link_tool.sh）
#       * 自更新 / 备份 / 清理旧备份
#       * 删除本地子脚本缓存（下次会自动重新下载）
#
# 存储策略：
#   - 所有通过 myapp 下载的脚本 + myapp 自己的备份等数据
#   - 统一放在【当前目录】的 myapp/ 文件夹下：
#       ./myapp/
#         backups/   - myapp.sh 旧版本备份
#         cache/     - 从 GitHub 下载的子脚本（iris.sh、lsd_install.sh 等）
#
# 仓库建议结构（GitHub: mytools）：
#   mytools/
#     myapp.sh          # 本文件（主控）
#     iris.sh           # 终端主题管理
#     lsd_install.sh    # 安装 lsd
#     link_tool.sh      # 软链接工具
#     （未来）
#     docker_menu.sh    # Docker compose 一键部署菜单
#     system_info.sh    # 系统信息查询
#     system_update.sh  # 系统更新
#     system_clean.sh   # 系统清理
#     bbr_manage.sh     # BBR 管理
# ============================================

# ======= 基本信息（版本号 & 更新说明：你每次改功能记得更新这里） =======
APP_NAME="myapp.sh"
APP_VERSION="v0.2.1"
APP_CHANGELOG="v0.2.1: 所有缓存与备份改为存放在【当前目录】的 ./myapp/ 下，方便按目录管理。"

# ======= GitHub 仓库信息（按你实际情况修改） =======
GITHUB_USER="Wolfun"           # 你的 GitHub 用户
GITHUB_REPO="mytools"          # 仓库名
GITHUB_BRANCH="main"           # 分支名（main 或 master）

# 原始文件基础地址（raw.githubusercontent.com）
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"

# 子脚本地址（目前都放在仓库根目录）
IRIS_URL="${RAW_BASE}/iris.sh"
LSD_URL="${RAW_BASE}/lsd_install.sh"
LINK_URL="${RAW_BASE}/link_tool.sh"
DOCKER_MENU_URL="${RAW_BASE}/docker_menu.sh"

# 未来例如：
# SYS_INFO_URL="${RAW_BASE}/system_info.sh"
# SYS_UPDATE_URL="${RAW_BASE}/system_update.sh"
# SYS_CLEAN_URL="${RAW_BASE}/system_clean.sh"
# BBR_URL="${RAW_BASE}/bbr_manage.sh"
# DOCKER_MENU_URL="${RAW_BASE}/docker_menu.sh"

# ======= 本地 myapp 工作目录（所有东西都放在【当前目录】的 myapp/ 下） =======
# 注意：这里用的是 $PWD，也就是你运行 myapp.sh 时所在的目录。
INSTALL_DIR="$PWD/myapp"
BACKUP_DIR="$INSTALL_DIR/backups"  # 存放 myapp.sh 的旧版本
CACHE_DIR="$INSTALL_DIR/cache"     # 存放下载的子脚本（iris.sh 等）

mkdir -p "$INSTALL_DIR" "$BACKUP_DIR" "$CACHE_DIR"

# 当前脚本路径（自更新时用于覆盖自己）
SCRIPT_PATH="${BASH_SOURCE[0]}"

# ============================
# 通用工具函数
# ============================

# 判断当前脚本是否是被 source 进来的
is_sourced() {
    [[ "$0" != "${BASH_SOURCE[0]}" ]]
}

# “按任意键继续”提示
press_any_key() {
    echo
    read -n1 -s -r -p "按任意键返回上一菜单..." _
    echo
}

# 从 GitHub 下载子脚本到缓存目录
# 参数1：显示名称（仅用于输出）
# 参数2：远程 URL
# 参数3：本地文件名（保存在 $CACHE_DIR 下）
download_script_to_cache() {
    local display_name="$1"
    local url="$2"
    local filename="$3"
    local target="$CACHE_DIR/$filename"

    echo "📥 检查 / 下载 ${display_name} ..."
    if ! curl -fsSL "$url" -o "$target"; then
        echo "❌ 下载 ${display_name} 失败：$url"
        return 1
    fi

    chmod +x "$target"
    echo "✔ 已保存到缓存：$target"
    return 0
}

# ============================
# 1. 分类 1：系统工具（占位，目前做结构，方便你挂脚本）
# ============================

submenu_system_tools() {
    while true; do
        clear
        echo "===== 系统工具 ====="
        echo "  1. 系统信息查询（预留，可挂 system_info.sh）"
        echo "  2. 系统更新（预留，可挂 system_update.sh）"
        echo "  3. 系统清理（预留，可挂 system_clean.sh）"
        echo "  4. BBR 管理（预留，可挂 bbr_manage.sh）"
        echo "  0. 返回主菜单"
        echo "====================="
        read -rp "请输入选项： " opt

        case "$opt" in
            1)
                echo "👉 这里以后可以挂 system_info.sh 脚本。"
                echo "   步骤：写好 system_info.sh -> 上传到仓库 -> 在 myapp.sh 里写 run_system_info() 调用。"
                press_any_key
                ;;
            2)
                echo "👉 这里以后可以挂 system_update.sh 脚本。"
                press_any_key
                ;;
            3)
                echo "👉 这里以后可以挂 system_clean.sh 脚本。"
                press_any_key
                ;;
            4)
                echo "👉 这里以后可以挂 bbr_manage.sh 脚本。"
                press_any_key
                ;;
            0)
                break
                ;;
            *)
                echo "❌ 无效选项，请输入 0-4。"
                sleep 1
                ;;
        esac
    done
}

# ============================
# 2. 分类 2：终端美化与外观
# ============================

# 2.1 运行 iris 终端主题管理
run_iris() {
    echo "== iris 终端主题管理 =="
    if download_script_to_cache "iris.sh" "$IRIS_URL" "iris.sh"; then
        bash "$CACHE_DIR/iris.sh"
    fi
    # iris.sh 自己内部有菜单
}

# 2.2 运行 lsd 安装脚本
run_lsd_installer() {
    echo "== 安装 lsd 并设置 ls=lsd（ASCII 无图标） =="
    if download_script_to_cache "lsd_install.sh" "$LSD_URL" "lsd_install.sh"; then
        bash "$CACHE_DIR/lsd_install.sh"
    fi
    press_any_key
}

submenu_appearance() {
    while true; do
        clear
        echo "===== 终端美化与外观 ====="
        echo "  1. iris 终端主题管理（iris.sh）"
        echo "  2. 安装 lsd 并设置 ls=lsd"
        echo "  0. 返回主菜单"
        echo "=========================="
        read -rp "请输入选项： " opt

        case "$opt" in
            1) run_iris ;;
            2) run_lsd_installer ;;
            0) break ;;
            *)
                echo "❌ 无效选项，请输入 0-2。"
                sleep 1
                ;;
        esac
    done
}

# ============================
# 3. 分类 3：脚本与快捷命令管理
# ============================

# 3.1 运行软链接管理工具
run_link_tool() {
    echo "== 软链接管理工具 =="
    if download_script_to_cache "link_tool.sh" "$LINK_URL" "link_tool.sh"; then
        bash "$CACHE_DIR/link_tool.sh"
    fi
    press_any_key
}

# 3.2 管理本地子脚本缓存（删除 / 全删）
manage_cached_scripts() {
    while true; do
        clear
        echo "===== 子脚本缓存管理 ====="
        echo "缓存目录：$CACHE_DIR"
        echo

        mapfile -t files < <(ls -1 "$CACHE_DIR" 2>/dev/null || true)

        if [ "${#files[@]}" -eq 0 ]; then
            echo "当前没有任何缓存脚本。"
            echo "当你通过菜单运行 iris / lsd / link 等脚本时，会自动下载到这里。"
            press_any_key
            return
        fi

        echo "当前缓存的脚本："
        local i
        for i in "${!files[@]}"; do
            printf "  %d. %s\n" $((i+1)) "${files[i]}"
        done
        echo
        echo "  a. 删除所有缓存脚本"
        echo "  0. 返回上一级"
        echo "=========================="
        read -rp "请选择要删除的编号（或 a / 0）： " choice

        case "$choice" in
            0)
                break
                ;;
            a|A)
                read -rp "确认删除所有缓存脚本吗？(y/n)： " yn
                if [[ "$yn" =~ ^[Yy]$ ]]; then
                    rm -f "$CACHE_DIR"/*
                    echo "✅ 已删除所有缓存脚本。"
                else
                    echo "已取消删除。"
                fi
                press_any_key
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#files[@]}" ]; then
                    local file_to_del="${files[$((choice-1))]}"
                    read -rp "确认删除「$file_to_del」吗？(y/n)： " yn2
                    if [[ "$yn2" =~ ^[Yy]$ ]]; then
                        rm -f "$CACHE_DIR/$file_to_del"
                        echo "✅ 已删除：$file_to_del"
                    else
                        echo "已取消删除。"
                    fi
                    press_any_key
                else
                    echo "❌ 无效选项。"
                    sleep 1
                fi
                ;;
        esac
    done
}

submenu_script_manage() {
    while true; do
        clear
        echo "===== 脚本与快捷命令管理 ====="
        echo "  1. 软链接管理工具（link_tool.sh）"
        echo "  2. 管理本地子脚本缓存（删除 / 全删）"
        echo "  0. 返回主菜单"
        echo "=============================="
        read -rp "请输入选项： " opt

        case "$opt" in
            1) run_link_tool ;;
            2) manage_cached_scripts ;;
            0) break ;;
            *)
                echo "❌ 无效选项，请输入 0-2。"
                sleep 1
                ;;
        esac
    done
}

# ============================
# docker
# ============================

run_docker_menu() {
    echo "== Docker 项目一键部署菜单 =="
    local target="$CACHE_DIR/docker_menu.sh"

    echo "📥 检查 / 下载 docker_menu.sh ..."
    if ! curl -fsSL "$DOCKER_MENU_URL" -o "$target"; then
        echo "❌ 下载 docker_menu.sh 失败，请检查 DOCKER_MENU_URL 设置或网络。"
        press_any_key
        return
    fi

    chmod +x "$target"
    bash "$target"
}


# ============================
# 00. 分类 00：myapp 自身管理（自更新 / 备份 / 说明）
# ============================

# 0.1 自更新 myapp.sh（从 GitHub 覆盖当前脚本）
self_update() {
    echo "== 检查并更新 ${APP_NAME} =="

    # 如果当前脚本不是从文件运行（比如 bash <(curl ...）），SCRIPT_PATH 可能是 /dev/fd/63
    if [[ "$SCRIPT_PATH" == /dev/* ]]; then
        echo "⚠ 当前是通过管道/进程替换运行的（${SCRIPT_PATH}）。"
        echo "  自更新只对本地文件有效。建议先把 myapp.sh 下载到本机，例如："
        echo "    curl -O ${RAW_BASE}/${APP_NAME}"
        echo "    bash ${APP_NAME}"
        press_any_key
        return
    fi

    local tmp_new="$INSTALL_DIR/${APP_NAME}.new"

    echo "📥 正在从远程拉取最新版本：${RAW_BASE}/${APP_NAME}"
    if ! curl -fsSL "${RAW_BASE}/${APP_NAME}" -o "$tmp_new"; then
        echo "❌ 无法从远程仓库下载最新版本，请检查 RAW_BASE 设置或网络。"
        press_any_key
        return
    fi

    # 如果内容相同，就不用更新
    if cmp -s "$tmp_new" "$SCRIPT_PATH"; then
        echo "✅ 当前已经是最新版本（${APP_VERSION}）。"
        rm -f "$tmp_new"
        press_any_key
        return
    fi

    # 备份当前版本（存到 ./myapp/backups）
    local ts backup_file
    ts=$(date +%Y%m%d%H%M%S)
    backup_file="$BACKUP_DIR/${APP_NAME}.${ts}"
    cp "$SCRIPT_PATH" "$backup_file"
    echo "✅ 已备份当前版本到：$backup_file"

    # 覆盖当前脚本
    mv "$tmp_new" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"

    echo
    echo "🎉 已更新 ${APP_NAME} 到远程最新版本。"
    echo "当前版本号（本文件中的）：${APP_VERSION}"
    echo "更新说明（本文件中的）：${APP_CHANGELOG}"
    echo
    echo "👉 请重新运行：  bash ${SCRIPT_PATH}  使用新版本。"

    press_any_key
}

# 0.2 清理旧备份：只保留最新 1 个
clean_old_backups() {
    echo "== 清理 myapp 旧备份 =="

    if [ ! -d "$BACKUP_DIR" ]; then
        echo "当前没有备份目录：$BACKUP_DIR"
        press_any_key
        return
    fi

    local count
    count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
    if [ "$count" -le 1 ]; then
        echo "备份数量：$count（<=1），暂不需要清理。"
        press_any_key
        return
    fi

    echo "当前备份数量：$count，将保留最新 1 个，其余删除。"
    echo "所有备份（按时间从新到旧）："
    ls -1t "$BACKUP_DIR"
    echo

    # 保留最新 1 个，其余删除
    ls -1t "$BACKUP_DIR" | tail -n +2 | while read -r old; do
        rm -f "$BACKUP_DIR/$old"
    done

    echo "✅ 已清理旧备份，仅保留最新 1 个。"
    press_any_key
}

# 0.3 关于 / 版本信息
show_about() {
    clear
    echo "===== ${APP_NAME} 关于 / 版本信息 ====="
    echo "版本：${APP_VERSION}"
    echo "说明：${APP_CHANGELOG}"
    echo
    echo "远程仓库：${GITHUB_USER}/${GITHUB_REPO} (${GITHUB_BRANCH})"
    echo "RAW_BASE：${RAW_BASE}"
    echo
    echo "本地工作目录结构（相对于当前目录）："
    echo "  $INSTALL_DIR/"
    echo "    backups/   # myapp.sh 旧版本备份"
    echo "    cache/     # 从 GitHub 下载的子脚本（iris.sh、lsd_install.sh 等）"
    echo
    echo "提示："
    echo "  - 你可以在不同目录各放一份 myapp.sh，每个目录都会有自己的 ./myapp/ 作为“空间”"
    echo "  - 这样不同 VPS / 不同项目可以用不同目录分别管理自己的脚本和缓存。"
    press_any_key
}

submenu_myapp_manage() {
    while true; do
        clear
        echo "===== myapp 自身管理 ====="
        echo "  1. 检查并更新 myapp.sh"
        echo "  2. 清理 myapp 旧备份文件（只保留最新 1 个）"
        echo "  3. 查看当前版本与更新说明"
        echo "  0. 返回主菜单"
        echo "=========================="
        read -rp "请输入选项： " opt

        case "$opt" in
            1) self_update ;;
            2) clean_old_backups ;;
            3) show_about ;;
            0) break ;;
            *)
                echo "❌ 无效选项，请输入 0-3。"
                sleep 1
                ;;
        esac
    done
}

# ============================
# 主菜单（分类入口）
# ============================

main_menu() {
    while true; do
        clear
        echo "============== ${APP_NAME} 综合管理菜单 =============="
        echo "  版本：${APP_VERSION}"
        echo "  当前工作目录：$PWD"
        echo "  myapp 数据目录：$INSTALL_DIR"
        echo
        echo "  1. 系统工具（系统信息 / 更新 / 清理 / BBR 等分类入口）"
        echo "  2. 终端美化与外观（iris / lsd 等）"
        echo "  3. 脚本与快捷命令管理（软链接 / 子脚本缓存管理）"
        echo "  4. docker管理（实用docker项目）"
        echo "  00. myapp 自身管理（自更新 / 备份 / 说明）"
        echo "  0. 退出"
        echo "====================================================="
        read -rp "请输入选项： " opt

        case "$opt" in
            1) submenu_system_tools ;;
            2) submenu_appearance ;;
            3) submenu_script_manage ;;
            4) submenu_myapp_manage ;;
            5) run_docker_menu ;;
            0)
                echo "再见 ~"
                break
                ;;
            *)
                echo "❌ 无效选项，请输入 0-4。"
                sleep 1
                ;;
        esac
    done
}

main_menu
