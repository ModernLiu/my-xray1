#!/bin/bash

# ====================================================
#  系统要求: Debian 10+ / Ubuntu 20.04+ / CentOS 7+
#  描述: Xray REALITY 一键安装脚本 (VLESS 分享链接版)
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
    apt update && apt install wget curl tar openssl jq -y || yum install wget curl tar openssl jq -y
}

# 显示配置并生成分享链接
show_config() {
    if [[ ! -f /usr/local/etc/xray/config.json ]]; then
        echo -e "${red}错误：${plain} 未检测到 Xray 配置文件，请先执行安装！"
        return
    fi
    
    local ip=$(curl -s ipv4.icanhazip.com)
    local config="/usr/local/etc/xray/config.json"
    
    # 提取配置参数
    local uuid=$(jq -r '.inbounds[0].settings.clients[0].id' $config)
    local port=$(jq -r '.inbounds[0].port' $config)
    local sni=$(jq -r '.inbounds[0].streamSettings.realitySettings.serverNames[0]' $config)
    local sid=$(jq -r '.inbounds[0].streamSettings.realitySettings.shortIds[0]' $config)
    
    # 获取之前保存的公钥 (存放在专门的文件中以便查看)
    local pbk=""
    if [[ -f /usr/local/etc/xray/public_key.txt ]]; then
        pbk=$(cat /usr/local/etc/xray/public_key.txt)
    fi

    echo -e "\n${green}--- REALITY 节点信息 ---${plain}"
    echo -e "地址: ${yellow}$ip${plain}"
    echo -e "端口: ${yellow}$port${plain}"
    echo -e "UUID: ${yellow}$uuid${plain}"
    echo -e "SNI: ${yellow}$sni${plain}"
    echo -e "Public Key: ${yellow}$pbk${plain}"
    echo -e "Short ID: ${yellow}$sid${plain}"
    echo -e "流控: ${yellow}xtls-rprx-vision${plain}"
    
    echo -e "\n${green}--- 一键导入链接 ---${plain}"
    local link="vless://$uuid@$ip:$port?security=reality&sni=$sni&fp=chrome&pbk=$pbk&sid=$sid&type=tcp&flow=xtls-rprx-vision#REALITY_$(echo $ip | tr '.' '_')"
    echo -e "${yellow}$link${plain}"
    echo -e "-------------------------------------------\n"
}

# 核心配置生成逻辑
generate_config() {
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local keys=$(/usr/local/bin/xray x25519)
    local private_key=$(echo "$keys" | grep "Private key" | awk '{print $3}')
    local public_key=$(echo "$keys" | grep "Public key" | awk '{print $3}')
    local short_id=$(openssl rand -hex 8)
    
    # 保存公钥到本地文件供以后查询
    mkdir -p /usr/local/etc/xray
    echo "$public_key" > /usr/local/etc/xray/public_key.txt
    
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
    echo -e "\n${green}REALITY 安装完成并已启动！${plain}"
    show_config
}

# 脚本主菜单
show_menu() {
    echo -e "
  ${green}Xray REALITY 一键安装管理脚本${plain}
  --- 个人维护版 ---

  ${green}1.${plain} 安装 REALITY
  ${green}2.${plain} 卸载 REALITY
  ${green}3.${plain} 重启服务
  ${green}4.${plain} 查看配置 & 分享链接
  ${green}0.${plain} 退出脚本
    "
    read -p "请输入数字 [0-4]: " num
    case "$num" in
        1) install_base && bash <(curl -L https://github.com) && generate_config ;;
        2) bash <(curl -L https://github.com) --remove && rm -rf /usr/local/etc/xray ;;
        3) systemctl restart xray && echo "已重启" ;;
        4) show_config ;;
        0) exit 0 ;;
        *) echo -e "${red}请输入正确数字${plain}" ;;
    esac
}

show_menu

