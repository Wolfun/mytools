#!/usr/bin/env bash

# link_tool.sh - 为脚本或文件创建软链接，方便用短命令调用

echo "== 软链接管理工具 =="

read -rp "请输入要创建软链接的脚本/文件路径（可相对/绝对）： " target
if [ -z "$target" ]; then
    echo "❌ 目标路径不能为空。"
    exit 1
fi

if [ ! -e "$target" ]; then
    echo "❌ 找不到目标文件：$target"
    exit 1
fi

# 转成绝对路径
target="$(cd "$(dirname "$target")" && pwd)/$(basename "$target")"
echo "✔ 目标绝对路径：$target"

read -rp "请输入想要使用的命令名（例如 iris、mt、lsd、dockerx 等）： " name
if [ -z "$name" ]; then
    echo "❌ 命令名不能为空。"
    exit 1
fi

link_path="/usr/local/bin/$name"

if [ -e "$link_path" ] || [ -L "$link_path" ]; then
    read -rp "⚠️  $link_path 已存在，是否覆盖？(y/n)： " yn
    if [[ ! "$yn" =~ ^[Yy]$ ]]; then
        echo "已取消创建软链接。"
        exit 0
    fi
    rm -f "$link_path"
fi

if [ "$EUID" -ne 0 ]; then
    echo "⚠️ 创建 /usr/local/bin 下的软链接通常需要 root 权限。"
    echo "   你可以使用：sudo ln -s \"$target\" \"$link_path\""
    exit 1
fi

ln -s "$target" "$link_path" || {
    echo "❌ 创建软链接失败。"
    exit 1
}

# 如果是脚本，则加执行权限
if file "$target" | grep -qi "script"; then
    chmod +x "$target"
fi

echo "✅ 已创建软链接：$link_path"
echo "👉 现在可以直接在任何目录输入：  $name"
