#!/bin/bash

# 路径与颜色定义
CONFIG_FILE="/usr/local/etc/xray/config.json"
PUB_KEY_FILE="/usr/local/etc/xray/public_key.txt"
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# 检查 root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 请使用 root 用户运行！\n" && exit 1

# 基础环境安装
install_base() {
    apt update && apt install wget curl tar openssl jq -y || yum install wget curl tar openssl jq -y
}

# 显示配置和分享链接
show_config() {
    if [[ ! -f $CONFIG_FILE ]]; then
        echo -e "${red}错误：未检测到 Xray 配置文件，请先执行安装！${plain}"
        return
    fi
    local ip=$(curl -s ipv4.icanhazip.com)
    local uuid=$(jq -r '.inbounds[0].settings.clients[0].id' $CONFIG_FILE)
    local sid=$(jq -r '.inbounds[0].streamSettings.realitySettings.shortIds[0]' $CONFIG_FILE)
    local pbk=$(cat $PUB_KEY_FILE 2>/dev/null)
    
    echo -e "\n${green}--- REALITY 配置信息 ---${plain}"
    echo -e "地址: ${yellow}$ip${plain}  端口: ${yellow}443${plain}"
    echo -e "UUID: ${yellow}$uuid${plain}"
    echo -e "Public Key: ${yellow}$pbk${plain}"
    echo -e "Short ID: ${yellow}$sid${plain}"
    echo -e "\n${green}--- VLESS 分享链接 ---${plain}"
    echo -e "${yellow}vless://$uuid@$ip:443?security=reality&sni=www.lovelive-anime.jp&fp=chrome&pbk=$pbk&sid=$sid&type=tcp&flow=xtls-rprx-vision#REALITY_NODE${plain}\n"
}

# 安装与配置
install_reality() {
    install_base
    # 使用官方正确路径安装核心
    bash <(curl -L https://github.com)
    
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local keys=$(/usr/local/bin/xray x25519)
    local pri=$(echo "$keys" | grep "Private key" | awk '{print $3}')
    local pub=$(echo "$keys" | grep "Public key" | awk '{print $3}')
    local sid=$(openssl rand -hex 8)
    
    mkdir -p /usr/local/etc/xray
    echo "$pub" > $PUB_KEY_FILE
    
    cat << EOF > $CONFIG_FILE
{
    "log": {"loglevel": "warning"},
    "inbounds": [{
        "port": 443, "protocol": "vless",
        "settings": {"clients": [{"id": "$uuid", "flow": "xtls-rprx-vision"}], "decryption": "none"},
        "streamSettings": {
            "network": "tcp", "security": "reality",
            "realitySettings": {
                "show": false, "dest": "www.lovelive-anime.jp:443", "xver": 0,
                "serverNames": ["www.lovelive-anime.jp"], "privateKey": "$pri", "shortIds": ["$sid"]
            }
        }
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOF
    systemctl restart xray
    show_config
}

# 菜单
clear
echo -e "${green}Xray REALITY 一键安装管理脚本 (维护版)${plain}"
echo -e "1. 安装 REALITY\n2. 卸载 REALITY\n3. 重启服务\n4. 查看配置 & 分享链接\n0. 退出"
read -p "请输入数字 [0-4]: " num
case "$num" in
    1) install_reality ;;
    2) bash <(curl -L https://github.com) --remove && rm -rf /usr/local/etc/xray ;;
    3) systemctl restart xray && echo "已重启" ;;
    4) show_config ;;
    *) exit 0 ;;
esac

