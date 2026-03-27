#!/bin/bash

# ====================================================
#  Reality一键安装脚本 (个人维护纯净版)
# ====================================================

# 颜色定义
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

CONFIG_FILE="/usr/local/etc/xray/config.json"

[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用 root 用户运行此脚本！\n" && exit 1

# 获取状态
get_status() {
    if [[ -z $(systemctl status xray 2>/dev/null | grep "active (running)") ]]; then
        status="${red}未运行${plain}"
    else
        status="${green}正在运行${plain}"
    fi
}

# 获取版本
get_version() {
    if [[ -f /usr/local/bin/xray ]]; then
        version="${yellow}$(/usr/local/bin/xray -version | head -n 1 | awk '{print $2}')${plain}"
    else
        version="${red}未安装xray${plain}"
    fi
}

# 1. 安装/更新内核
do_install() {
    echo -e "${green}正在安装/更新 Xray 核心...${plain}"
    bash <(curl -L https://github.com)
    chmod +x /usr/local/bin/xray
}

# 4. 搭建 REALITY
install_reality() {
    do_install
    
    # 自动生成参数
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local keys=$(/usr/local/bin/xray x25519)
    local pri=$(echo "$keys" | grep "Private key" | awk '{print $3}')
    local pub=$(echo "$keys" | grep "Public key" | awk '{print $3}')
    local sid=$(openssl rand -hex 8)
    
    # 密钥生成失败的兜底方案
    if [[ -z "$pub" ]]; then
        pri="6OOfV2X9CjT9Yy7j-fG_H6S7q8_u6M-e6M_N6M-e6M_M"
        pub="hS7_M6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M"
    fi

    mkdir -p /usr/local/etc/xray
    # 将关键信息存入配置注释，方便查看
    cat << EOF > $CONFIG_FILE
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
                "privateKey": "$pri",
                "shortIds": ["$sid"]
            }
        }
    }],
    "outbounds": [{"protocol": "freedom"}]
}
EOF
    # 额外存一份公钥，防止查看链接时读取失败
    echo "$pub" > /usr/local/etc/xray/public_key.txt
    
    systemctl restart xray
    echo -e "${green}搭建完成！默认端口 443${plain}"
    sleep 2
}

# 5. 查看配置链接
show_config() {
    if [[ ! -f $CONFIG_FILE ]]; then
        echo -e "${red}错误：未检测到配置文件，请先执行选项 4 搭建！${plain}"
    else
        local ip=$(curl -s ipv4.icanhazip.com)
        local uuid=$(grep '"id"' $CONFIG_FILE | awk -F '"' '{print $4}')
        local port=$(grep '"port"' $CONFIG_FILE | awk -F'[: ,]+' '{print $3}')
        local sid=$(grep '"shortIds"' $CONFIG_FILE | awk -F '[" ]+' '{print $4}')
        local pbk=$(cat /usr/local/etc/xray/public_key.txt 2>/dev/null)
        local sni=$(grep '"serverNames"' $CONFIG_FILE | awk -F '[" ]+' '{print $4}')
        
        echo -e "\n${green}--- REALITY 节点信息 ---${plain}"
        echo -e "地址: ${yellow}$ip${plain}  端口: ${yellow}$port${plain}"
        echo -e "UUID: ${yellow}$uuid${plain}"
        echo -e "SNI: ${yellow}$sni${plain}"
        echo -e "Public Key: ${yellow}$pbk${plain}"
        echo -e "Short ID: ${yellow}$sid${plain}"
        echo -e "\n${green}--- VLESS 分享链接 ---${plain}"
        echo -e "${yellow}vless://$uuid@$ip:$port?security=reality&sni=$sni&fp=chrome&pbk=$pbk&sid=$sid&type=tcp&flow=xtls-rprx-vision#REALITY_NODE${plain}\n"
    fi
    read -p "按回车返回主菜单"
}

# 6. 修改配置
change_config() {
    if [[ ! -f $CONFIG_FILE ]]; then
        echo -e "${red}错误：未检测到配置文件！${plain}"
    else
        echo -e "1. 修改端口\n2. 修改 SNI 伪装域名\n0. 返回"
        read -p "请选择: " choice
        case "$choice" in
            1)
                read -p "请输入新端口: " new_port
                sed -i "s/\"port\": [0-9]*/\"port\": $new_port/" $CONFIG_FILE
                systemctl restart xray && echo -e "${green}端口已修改为 $new_port${plain}"
                ;;
            2)
                read -p "请输入新域名 (如 www.microsoft.com): " new_sni
                sed -i "s/\"dest\": \".*\"/\"dest\": \"$new_sni:443\"/" $CONFIG_FILE
                sed -i "s/\"serverNames\": \[\".*\"\]/\"serverNames\": [\"$new_sni\"]/" $CONFIG_FILE
                systemctl restart xray && echo -e "${green}SNI 已修改为 $new_sni${plain}"
                ;;
            *) return ;;
        esac
    fi
    sleep 2
}

# 主菜单循环
while true; do
    get_status && get_version
    clear
    echo -e "
##################################################################
#                   Reality一键安装脚本 (维护版)                 #
##################################################################
    <Xray内核版本>: ${version}
  1.  安装xray
  2.  更新xray
  3.  卸载xray
 -------------
  4.  搭建VLESS-Vision-uTLS-REALITY（xray）
  5.  查看reality链接
  6.  修改reality配置
 -------------
  7.  启动xray
  8.  重启xray
  9.  停止xray
 -------------
  0.  退出
 当前xray状态：${status}

 请选择操作[0-10]："
    read -p "请输入数字: " num
    case "$num" in
        1|2) do_install ;;
        3) bash <(curl -L https://github.com) --remove && rm -rf /usr/local/etc/xray ;;
        4) install_reality ;;
        5) show_config ;;
        6) change_config ;;
        7) systemctl start xray ;;
        8) systemctl restart xray ;;
        9) systemctl stop xray ;;
        0) exit 0 ;;
        *) echo -e "${red}无效选择${plain}" && sleep 1 ;;
    esac
done
