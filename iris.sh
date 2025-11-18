#!/usr/bin/env bash

BASHRC="$HOME/.bashrc"
BACKUP_PREFIX="$BASHRC.bak."

CONFIG_DIR="$HOME/.twoline"
SCHEMES_FILE="$CONFIG_DIR/schemes.conf"
mkdir -p "$CONFIG_DIR"

# =============================
# 通用工具函数
# =============================

is_sourced() {
    [[ "$0" != "${BASH_SOURCE[0]}" ]]
}

backup_bashrc() {
    if [ -f "$BASHRC" ]; then
        local ts backup_file
        ts=$(date +%Y%m%d%H%M%S)
        backup_file="${BACKUP_PREFIX}${ts}"
        cp "$BASHRC" "$backup_file"
        echo "✅ 已备份当前 .bashrc 为：$backup_file"
    fi
}

# =============================
# 1. 固定主题（非双行 + 新增 3 种）
# =============================

write_classic_theme_block() {
    local theme="$1"

    backup_bashrc

    case "$theme" in
        1)
            # 原主题 2 — Cyber Arrow
            cat << 'EOF' >> "$BASHRC"

# === iris classic theme: Cyber Arrow ===
PS1='\[\e[1;31m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\] \[\e[1;37m\]→\[\e[0m\] \[\e[1;33m\]\w\[\e[0m\] # '

alias ls='ls --color=auto'
export LS_COLORS='di=1;32:ln=1;36:so=1;32:pi=1;32:ex=1;32:bd=1;32:cd=1;32:su=1;32:sg=1;32:tw=32:ow=32'
# === end iris classic ===
EOF
            ;;
        2)
            # 原主题 3 — Matrix OneLine
            cat << 'EOF' >> "$BASHRC"

# === iris classic theme: Matrix OneLine ===
PS1='\[\e[1;32m\]\u@\h:\w# \[\e[0m\]'

alias ls='ls --color=auto'
export LS_COLORS='di=1;32:ln=1;36:so=1;32:pi=1;32:ex=1;32:bd=1;32:cd=1;32:su=1;32:sg=1;32:tw=32:ow=32'
# === end iris classic ===
EOF
            ;;
        3)
            # 原主题 4 — Info HUD
            cat << 'EOF' >> "$BASHRC"

# === iris classic theme: Info HUD ===
PS1='\[\e[1;36m\][\A]\[\e[0m\] \[\e[1;31m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\]:\[\e[1;33m\]\w\[\e[0m\]# '

alias ls='ls --color=auto'
export LS_COLORS='di=1;32:ln=1;36:so=1;32:pi=1;32:ex=1;32:bd=1;32:cd=1;32:su=1;32:sg=1;32:tw=32:ow=32'
# === end iris classic ===
EOF
            ;;
        4)
            # 新主题 4 — Minimal Clean（简洁单行）
            cat << 'EOF' >> "$BASHRC"

# === iris classic theme: Minimal Clean ===
PS1='\[\e[1;37m\]\u\[\e[0m\]@\[\e[1;37m\]\h\[\e[0m\]: \[\e[1;36m\]\w\[\e[0m\] $ '

alias ls='ls --color=auto'
export LS_COLORS='di=1;36:ln=1;34:so=1;32:pi=1;32:ex=1;32:bd=1;32:cd=1;32:su=1;32:sg=1;32:tw=32:ow=32'
# === end iris classic ===
EOF
            ;;
        5)
            # 新主题 5 — Power Prompt（双箭头感但单行）
            cat << 'EOF' >> "$BASHRC"

# === iris classic theme: Power Prompt ===
PS1='\[\e[1;34m\]\u@\h\[\e[0m\] \[\e[1;37m\]>>\[\e[0m\] \[\e[1;32m\]\w\[\e[0m\] $ '

alias ls='ls --color=auto'
export LS_COLORS='di=1;34:ln=1;36:so=1;32:pi=1;32:ex=1;32:bd=1;32:cd=1;32:su=1;32:sg=1;32:tw=32:ow=32'
# === end iris classic ===
EOF
            ;;
        6)
            # 新主题 6 — Time Left Bar（时间在左）
            cat << 'EOF' >> "$BASHRC"

# === iris classic theme: Time Left Bar ===
PS1='\[\e[1;36m\][\A]\[\e[0m\] \[\e[1;32m\]\w\[\e[0m\] \[\e[1;37m\]\$\[\e[0m\] '

alias ls='ls --color=auto'
export LS_COLORS='di=1;32:ln=1;36:so=1;32:pi=1;32:ex=1;32:bd=1;32:cd=1;32:su=1;32:sg=1;32:tw=32:ow=32'
# === end iris classic ===
EOF
            ;;
        *)
            echo "❌ 无效主题：$theme"
            return 1
            ;;
    esac

    echo
    if is_sourced; then
        # shellcheck disable=SC1090
        . "$BASHRC"
        echo "🎉 固定主题已应用（当前终端已刷新）。"
    else
        echo "🎉 固定主题已写入 ~/.bashrc"
        echo "👉 请执行：  source ~/.bashrc  生效。"
    fi
}

classic_menu() {
    clear
    echo "== 固定主题（非双行样式） =="
    echo "  1. Cyber Arrow（单行箭头风）"
    echo "  2. Matrix OneLine（全绿单行）"
    echo "  3. Info HUD（带时间信息单行）"
    echo "  4. Minimal Clean（极简干净风）"
    echo "  5. Power Prompt（蓝色双箭头风）"
    echo "  6. Time Left Bar（时间在左，路径在右）"
    echo "  0. 返回主菜单"
    echo

    local c
    while true; do
        read -rp "请选择 0-6： " c
        case "$c" in
            0) return ;;
            1|2|3|4|5|6) break ;;
            *) echo "❌ 请输入 0~6" ;;
        esac
    done

    write_classic_theme_block "$c"
}

# =============================
# 2. 双行 TwoLine 配色系统
# =============================

# 16 进制 -> 38;2;R;G;B
hex_to_seq() {
    local hex="$1"
    hex="${hex#\#}"
    if [[ ${#hex} -ne 6 ]]; then
        return 1
    fi
    local r g b
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))
    echo "38;2;${r};${g};${b}"
}

prompt_color_hex() {
    local label="$1"
    local default_hex="$2"
    local hex seq
    while true; do
        read -rp "请输入 ${label} 颜色（16进制，如 #45ABBA，回车默认 ${default_hex}）： " hex
        if [ -z "$hex" ]; then
            hex="$default_hex"
        fi
        seq=$(hex_to_seq "$hex") || {
            echo "❌ 格式不正确，请重新输入（类似 #45ABBA）。"
            continue
        }
        echo "$seq"
        return 0
    done
}

preview_scheme() {
    local line="$1" time="$2" user="$3" host="$4" path="$5" symbol="$6"
    echo
    echo "配色预览："
    echo -e "  \e[${line}m连接线(Line)\e[0m    => ${line}"
    echo -e "  \e[${time}m时间(Time)\e[0m     => ${time}"
    echo -e "  \e[${user}m用户(User)\e[0m     => ${user}"
    echo -e "  \e[${host}m主机(Host)\e[0m     => ${host}"
    echo -e "  \e[${path}m路径(Path)\e[0m     => ${path}"
    echo "  结尾符号(Symbol)：${symbol}"
    echo
}

apply_twoline_scheme() {
    local line="$1" time="$2" user="$3" host="$4" path="$5" symbol="$6"

    backup_bashrc

    cat <<EOF >> "$BASHRC"

# === iris TwoLine theme ===
PS1='\n\
\[\e[${line}m\]┌─[\[\e[${time}m\]\A\[\e[${line}m\]]──[\[\e[${user}m\]\u\[\e[${line}m\]@\[\e[${host}m\]\h\[\e[${line}m\]]\n\
└─[\[\e[${path}m\]\w\[\e[${line}m\]] ${symbol} \[\e[0m\]'

alias ls='ls --color=auto'
export LS_COLORS='di=1;32:ln=1;36:so=1;32:pi=1;32:ex=1;32:bd=1;32:cd=1;32:su=1;32:sg=1;32:tw=32:ow=32'
# === end iris TwoLine theme ===
EOF

    echo
    if is_sourced; then
        # shellcheck disable=SC1090
        . "$BASHRC"
        echo "🎉 双行主题已应用（当前终端已刷新）。"
    else
        echo "🎉 双行主题已写入 ~/.bashrc"
        echo "👉 请执行：  source ~/.bashrc  生效。"
    fi
}

save_custom_scheme() {
    local name="$1" line="$2" time="$3" user="$4" host="$5" path="$6" symbol="$7"
    name="${name//|/_}"
    echo "${name}|${line}|${time}|${user}|${host}|${path}|${symbol}" >> "$SCHEMES_FILE"
    echo "✅ 已保存自定义方案：$name"
}

list_custom_schemes() {
    if [ ! -s "$SCHEMES_FILE" ]; then
        return 1
    fi
    echo "已有自定义方案："
    local i=1
    while IFS='|' read -r name _l _t _u _h _p _s; do
        printf "  %d. %s\n" "$i" "$name"
        i=$((i+1))
    done < "$SCHEMES_FILE"
    return 0
}

delete_custom_scheme() {
    if ! list_custom_schemes; then
        echo "⚠ 目前没有自定义方案。"
        return
    fi
    echo "  0. 取消删除"
    echo

    local count choice
    count=$(wc -l < "$SCHEMES_FILE")
    while true; do
        read -rp "请选择要删除的编号（0 取消）： " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "$count" ]; then
            break
        fi
        echo "❌ 请输入 0-${count}。"
    done

    if [ "$choice" -eq 0 ]; then
        echo "已取消删除。"
        return
    fi

    local line
    line=$(sed -n "${choice}p" "$SCHEMES_FILE")
    IFS='|' read -r name _ <<< "$line"

    read -rp "确定删除方案「$name」吗？(y/n)： " yn
    if [[ ! "$yn" =~ ^[Yy]$ ]]; then
        echo "已取消删除。"
        return
    fi

    sed -i "${choice}d" "$SCHEMES_FILE"
    echo "✅ 已删除方案：$name"
}

choose_custom_scheme() {
    if ! list_custom_schemes; then
        echo "⚠ 目前还没有自定义方案。"
        return
    fi

    echo "  0. 返回上一级"
    echo

    local count choice
    count=$(wc -l < "$SCHEMES_FILE")
    while true; do
        read -rp "请选择方案编号（0 返回）： " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "$count" ]; then
            break
        fi
        echo "❌ 请输入 0-${count}。"
    done

    [ "$choice" -eq 0 ] && return

    local line_all
    line_all=$(sed -n "${choice}p" "$SCHEMES_FILE")
    IFS='|' read -r name line_c time_c user_c host_c path_c symbol_c <<< "$line_all"

    echo "你选择了方案：$name"
    preview_scheme "$line_c" "$time_c" "$user_c" "$host_c" "$path_c" "$symbol_c"
    read -rp "是否应用该方案？(y/n)： " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        apply_twoline_scheme "$line_c" "$time_c" "$user_c" "$host_c" "$path_c" "$symbol_c"
    else
        echo "已取消应用。"
    fi
}

create_custom_scheme() {
    echo "== 创建新的自定义双行配色方案 =="
    echo "提示：直接回车会使用括号里的默认颜色（基于 Ocean 风格）。"
    echo

    local line time user host path symbol
    line=$(prompt_color_hex "连接线(Line)" "#45ABBA")
    time=$(prompt_color_hex "时间(Time)" "#82CDD0")
    user=$(prompt_color_hex "用户(User)" "#638DA3")
    host=$(prompt_color_hex "主机(Host)" "#097971")
    path=$(prompt_color_hex "路径(Path)" "#F5E663")

    read -rp "请输入结尾符号（如 # 或 >，默认 #）： " symbol
    [ -z "$symbol" ] && symbol="#"

    preview_scheme "$line" "$time" "$user" "$host" "$path" "$symbol"

    read -rp "是否应用这套自定义方案？(y/n)： " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        apply_twoline_scheme "$line" "$time" "$user" "$host" "$path" "$symbol"
    else
        echo "已取消应用（仅预览）。"
    fi

    read -rp "是否保存这套方案供下次使用？(y/n)： " save
    if [[ "$save" =~ ^[Yy]$ ]]; then
        read -rp "请为这套方案起一个名字（推荐英文或拼音）： " name
        [ -z "$name" ] && name="custom_$(date +%H%M%S)"
        save_custom_scheme "$name" "$line" "$time" "$user" "$host" "$path" "$symbol"
    else
        echo "未保存该方案。"
    fi
}

twoline_builtin_menu() {
    echo "== 双行内置冷色方案 =="
    echo "  1. Ocean（海蓝系）"
    echo "  2. NightSky（夜空紫蓝）"
    echo "  3. Ice（冰蓝淡色）"
    echo "  0. 返回上一级"
    echo

    local c
    while true; do
        read -rp "请选择 0-3： " c
        case "$c" in
            0) return ;;
            1|2|3) break ;;
            *) echo "❌ 请输入 0~3" ;;
        esac
    done

    local line time user host path symbol
    symbol=">"

    case "$c" in
        1)
            line="38;2;69;171;186"
            time="38;2;130;205;208"
            user="38;2;99;141;163"
            host="38;2;9;121;113"
            path="38;2;245;230;99"
            ;;
        2)
            line="38;2;75;63;114"
            time="38;2;187;134;252"
            user="38;2;236;239;244"
            host="38;2;94;129;172"
            path="38;2;136;192;208"
            ;;
        3)
            line="38;2;129;161;193"
            time="38;2;229;233;240"
            user="38;2;94;129;172"
            host="38;2;143;188;187"
            path="38;2;216;222;233"
            ;;
    esac

    preview_scheme "$line" "$time" "$user" "$host" "$path" "$symbol"
    read -rp "是否应用该内置双行方案？(y/n)： " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        apply_twoline_scheme "$line" "$time" "$user" "$host" "$path" "$symbol"
    else
        echo "已取消应用。"
    fi
}

twoline_menu() {
    clear
    echo "== 双行 TwoLine 主题系统 =="
    echo "  1. 使用内置冷色方案（Ocean / NightSky / Ice）"
    echo "  2. 创建 / 应用自定义方案"
    echo "  3. 删除自定义方案"
    echo "  0. 返回主菜单"
    echo

    local c
    while true; do
        read -rp "请选择 0-3： " c
        case "$c" in
            0) return ;;
            1) twoline_builtin_menu; return ;;
            2) 
                if [ -s "$SCHEMES_FILE" ]; then
                    echo "  1. 使用已有自定义方案"
                    echo "  2. 创建新的自定义方案"
                    echo "  0. 返回"
                    local cc
                    while true; do
                        read -rp "请选择 0-2： " cc
                        case "$cc" in
                            0) return ;;
                            1) choose_custom_scheme; return ;;
                            2) create_custom_scheme; return ;;
                            *) echo "❌ 请输入 0/1/2" ;;
                        esac
                    done
                else
                    echo "当前还没有自定义方案，直接进入创建流程。"
                    create_custom_scheme
                    return
                fi
                ;;
            3) delete_custom_scheme; return ;;
            *) echo "❌ 请输入 0-3" ;;
        esac
    done
}

# =============================
# 3. 备份 / 还原
# =============================
backup_restore_menu() {
    clear
    echo "== 备份 / 还原 .bashrc =="

    mapfile -t backups < <(ls -1 "${BACKUP_PREFIX}"* 2>/dev/null)

    if [ ${#backups[@]} -eq 0 ]; then
        echo "⚠ 还没有任何由 iris.sh 创建的备份。"
        return
    fi

    echo "可用备份："
    local i
    for i in "${!backups[@]}"; do
        printf "  %d. %s\n" $((i+1)) "${backups[i]}"
    done
    echo "  0. 取消"
    echo

    local choice
    while true; do
        read -rp "请选择要恢复的编号（0 取消）： " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le ${#backups[@]} ]; then
            break
        fi
        echo "❌ 输入无效，请重新输入。"
    done

    [ "$choice" -eq 0 ] && return

    local selected="${backups[$((choice-1))]}"
    cp "$selected" "$BASHRC"
    echo "✅ 已恢复：$selected"

    if is_sourced; then
        # shellcheck disable=SC1090
        . "$BASHRC"
        echo "当前终端已自动应用恢复后的配置。"
    else
        echo "👉 请执行： source ~/.bashrc  让恢复后的配置生效。"
    fi
}

# =============================
# 4. 修改 hostname
# =============================
change_hostname() {
    clear
    echo "== 修改 hostname =="

    local current_host newhost
    current_host=$(hostname)
    echo "当前 hostname：$current_host"
    echo

    read -rp "请输入新的 hostname： " newhost

    if [[ -z "$newhost" ]]; then
        echo "❌ hostname 不能为空"
        return
    fi

    if [[ $EUID -ne 0 ]]; then
        echo "❌ 错误：需要 root 才能更改 hostname"
        return
    fi

    hostnamectl set-hostname "$newhost"

    if [ -f /etc/hosts ]; then
        sed -i "s/$current_host/$newhost/g" /etc/hosts
    fi

    echo "✅ hostname 修改成功：$newhost"
    echo "👉 建议重新登录使提示符立即更新。"
}

# =============================
# 主菜单
# =============================
main_menu() {
    while true; do
        clear   # ← 每次回到主菜单先清屏
        echo
        echo "============== iris 终端主题管理 =============="
        echo "  1. 固定主题（非双行样式，6种方案）"
        echo "  2. 双行 TwoLine 主题（内置 + 自定义 + 删除）"
        echo "  3. 备份 / 还原 .bashrc"
        echo "  4. 修改 hostname（主机名）"
        echo "  0. 退出脚本"
        echo "==============================================="
        read -rp "请输入选项： " opt

        case "$opt" in
            1) classic_menu ;;
            2) twoline_menu ;;
            3) backup_restore_menu ;;
            4) change_hostname ;;
            0)
                echo "退出 iris.sh"
                break
                ;;
            *)
                echo "❌ 无效选项，请输入 0/1/2/3/4。"
                ;;
        esac
    done
}

main_menu
