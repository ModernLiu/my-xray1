#!/bin/bash
# REALITY一键安装脚本 + BBR管理

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[36m"
PLAIN='\033[0m'

NAME="xray"
CONFIG_FILE="/usr/local/etc/${NAME}/config.json"

colorEcho() {
    echo -e "${1}${@:2}${PLAIN}"
}

checkSystem() {
    [[ $EUID -ne 0 ]] && colorEcho $RED "请用root运行" && exit 1
}

# =========================
# 🚀 BBR 管理模块（新增）
# =========================

bbr_check() {
    colorEcho $BLUE "检查 BBR 状态..."
    sysctl net.ipv4.tcp_congestion_control
    lsmod | grep bbr
}

bbr_enable() {
    colorEcho $GREEN "开启 BBR..."
    cat >> /etc/sysctl.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
    sysctl -p
    colorEcho $GREEN "BBR 已开启"
}

bbr_plus() {
    colorEcho $GREEN "开启 BBR + 优化..."
    cat >> /etc/sysctl.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_slow_start_after_idle=0
EOF
    sysctl -p
    colorEcho $GREEN "BBR + 优化已开启"
}

bbr_disable() {
    sed -i '/bbr/d' /etc/sysctl.conf
    sysctl -p
    colorEcho $RED "BBR 已关闭"
}

bbr_menu() {
    clear
    echo "========== BBR 管理 =========="
    echo "1. 查看 BBR 状态"
    echo "2. 开启 BBR"
    echo "3. 开启 BBR + 优化"
    echo "4. 关闭 BBR"
    echo "0. 返回主菜单"
    echo "=============================="
    read -p "请输入: " num

    case "$num" in
        1) bbr_check ;;
        2) bbr_enable ;;
        3) bbr_plus ;;
        4) bbr_disable ;;
        0) main_menu ;;
        *) echo "输入错误" ;;
    esac
    read -n 1 -s -r -p "按任意键继续..."
    bbr_menu
}

# =========================
# 📦 Xray 原有逻辑（简化示例）
# =========================

installXray() {
    colorEcho $BLUE "安装 Xray..."
    bash -c "$(curl -s -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"
}

updateXray() {
    colorEcho $BLUE "更新 Xray..."
    bash -c "$(curl -s -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"
}

removeXray() {
    colorEcho $RED "卸载 Xray..."
    bash -c "$(curl -s -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
}

# =========================
# 📋 主菜单（0-11）
# =========================

main_menu() {
    clear
    echo "=================================="
    echo " REALITY 一键安装脚本"
    echo "=================================="
    echo " 0. 退出脚本"
    echo " 1. 安装 Xray"
    echo " 2. 更新 Xray"
    echo " 3. 卸载 Xray"
    echo " 4. 查看状态"
    echo " 5. 生成 UUID"
    echo " 6. 生成密钥"
    echo " 7. 设置端口"
    echo " 8. 获取IP"
    echo " 9. 防火墙放行"
    echo "10. 生成配置"
    echo "11. 🚀 BBR 管理（新增）"
    echo "=================================="

    read -p "请输入选项: " num

    case "$num" in
        0) exit 0 ;;
        1) installXray ;;
        2) updateXray ;;
        3) removeXray ;;
        4) status ;;
        5) getuuid ;;
        6) getkey ;;
        7) getport ;;
        8) getip ;;
        9) setFirewall ;;
        10) echo "生成配置逻辑..." ;;
        11) bbr_menu ;;
        *) colorEcho $RED "请输入正确选项" ;;
    esac

    read -n 1 -s -r -p "按任意键返回菜单..."
    main_menu
}

# 启动
checkSystem
main_menu
