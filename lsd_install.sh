#!/usr/bin/env bash

# lsd_install.sh - 安装 lsd 并设置 ls=lsd（ASCII 模式，无图标）

set -e

BASHRC="$HOME/.bashrc"

backup_bashrc() {
    if [ -f "$BASHRC" ]; then
        local ts backup_file
        ts=$(date +%Y%m%d%H%M%S)
        backup_file="${BASHRC}.lsd.bak.${ts}"
        cp "$BASHRC" "$backup_file"
        echo "✅ 已备份当前 .bashrc 为：$backup_file"
    fi
}

echo "== lsd 安装脚本 =="

if command -v lsd >/dev/null 2>&1; then
    echo "✔ 已检测到 lsd：$(command -v lsd)"
else
    echo "未检测到 lsd，尝试通过包管理器安装..."

    if command -v apt >/dev/null 2>&1; then
        apt update && apt install -y lsd
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y lsd
    elif command -v yum >/dev/null 2>&1; then
        yum install -y lsd
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm lsd
    else
        echo "❌ 未识别的包管理器，请手动安装 lsd。"
        exit 1
    fi

    echo "✅ 已安装 lsd。"
fi

backup_bashrc

ALIAS_LINE="alias ls='lsd --classic --icon=never'"

if grep -q "alias ls='lsd" "$BASHRC" 2>/dev/null; then
    sed -i "s|alias ls='lsd.*'|${ALIAS_LINE}|" "$BASHRC"
    echo "✅ 已更新现有 ls 别名为：${ALIAS_LINE}"
else
    echo "$ALIAS_LINE" >> "$BASHRC"
    echo "✅ 已追加 ls 别名：${ALIAS_LINE}"
fi

echo
echo "🎉 已完成 lsd 安装与 ls 别名设置。"
echo "👉 请执行：  source ~/.bashrc  让新 alias 生效。"
