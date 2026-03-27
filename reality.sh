#!/bin/bash

# ====================================================
#  系统要求: Debian 10+ / Ubuntu 20.04+ / CentOS 7+
#  描述: Xray REALITY 一键安装脚本 (完全修复版)
# ====================================================

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 颜色定义
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 检查 root 权限
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用 root 用户运行此脚本！\n" && exit 1

# 安装基础依赖
install_base() {
    apt update && apt install wget curl tar openssl -y || yum install wget curl tar openssl -y
}

# 核心配置生成逻辑
generate_config() {
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local keys=$(/usr/local/bin/xray x25519)
    local private_key=$(echo "$keys" | grep "Private key" | awk '{print $3}')
    local public_key=$(echo "$keys" | grep "Public key" | awk '{print $3}')
    local short_id=$(openssl rand -hex 8)
    
    mkdir -p /usr/local/etc/xray
    cat << EOF > /usr/local/etc/xray/config.json
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": 443,
        "protocol": "vless",
        "settings": {
            "clients": [{"id": "$uuid", "flow": "xtls-rprx-vision"}],
            "decryption": "none"
        },
        "streamSettings": {
            "network": "tcp",
            "security": "reality",
            "realitySettings": {
                "show": false,
                "dest": "www.lovelive-anime.jp:443",
                "xver": 0,
                "serverNames": ["www.lovelive-anime.jp"],
                "privateKey": "$private_key",
                "shortIds": ["$short_id"]
            }
        }
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOF
    systemctl restart xray
    
    echo -e "\n${green}REALITY 安装成功！${plain}"
    echo -e "-------------------------------------------"
    echo -e "${yellow}地址 (Address):${plain} $(curl -s ipv4.icanhazip.com)"
    echo -e "${yellow}端口 (Port):${plain} 443"
    echo -e "${yellow}用户 ID (UUID):${plain} $uuid"
    echo -e "${yellow}流控 (Flow):${plain} xtls-rprx-vision"
    echo -e "${yellow}传输协议 (Network):${plain} tcp"
    echo -e "${yellow}安全传输 (Security):${plain} reality"
    echo -e "${yellow}SNI:${plain} www.lovelive-anime.jp"
    echo -e "${yellow}PublicKey:${plain} $public_key"
    echo -e "${yellow}ShortId:${plain} $short_id"
    echo -e "-------------------------------------------"
    echo -e "${green}请使用支持 REALITY 的客户端（如 v2rayN/AnXray）添加以上信息。${plain}\n"
}

# 安装 Xray 主程序
install_xray() {
    install_base
    # 使用官方正确的安装链接
    bash <(curl -L https://github.com)
}

# 脚本主菜单
show_menu() {
    clear
    echo -e "
  ${green}Xray REALITY 一键安装管理脚本${plain}
  --- 个人维护版 ---

  ${green}1.${plain} 安装 REALITY 并显示配置
  ${green}2.${plain} 卸载 REALITY
  ${green}3.${plain} 重启服务
  ${green}0.${plain} 退出脚本
    "
    read -p "请输入数字 [0-3]: " num
    case "$num" in
        1) install_xray && generate_config ;;
        2) bash <(curl -L https://github.com) --remove ;;
        3) systemctl restart xray && echo "已重启" ;;
        0) exit 0 ;;
        *) echo -e "${red}请输入正确数字${plain}" ;;
    esac
}

show_menu

