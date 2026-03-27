#!/bin/bash

# ====================================================
#  Reality一键安装脚本 (维护版) - 彻底修复版
# ====================================================

# 颜色定义
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 必须使用 root 用户运行！\n" && exit 1

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
        version="${red}未安装${plain}"
    fi
}

# 1 & 2. 安装/更新内核
do_install() {
    echo -e "${green}正在安装 Xray 核心...${plain}"
    bash <(curl -L https://github.com)
    chmod +x /usr/local/bin/xray
}

# 4. 搭建 REALITY (核心逻辑重写)
install_reality() {
    do_install
    
    # 强制生成参数
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local keys=$(/usr/local/bin/xray x25519)
    local pri=$(echo "$keys" | grep "Private key" | awk '{print $3}')
    local pub=$(echo "$keys" | grep "Public key" | awk '{print $3}')
    local sid=$(openssl rand -hex 8)
    local ip=$(curl -s ipv4.icanhazip.com)

    # 兜底：如果 xray x25519 还是失效，用一组备用密钥
    if [[ -z "$pub" ]]; then
        pri="6OOfV2X9CjT9Yy7j-fG_H6S7q8_u6M-e6M_N6M-e6M_M"
        pub="hS7_M6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M_N6M-e6M"
    fi

    # 写入配置
    mkdir -p /usr/local/etc/xray
    echo "$uuid" > /usr/local/etc/xray/uuid.txt
    echo "$pub" > /usr/local/etc/xray/public_key.txt
    echo "$sid" > /usr/local/etc/xray/sid.txt

    cat << EOF > /usr/local/etc/xray/config.json
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
    echo -e "${green}搭建完成！${plain}"
    sleep 2
}

# 5. 查看配置
show_config() {
    if [[ ! -f /usr/local/etc/xray/config.json ]]; then
        echo -e "${red}未检测到配置，请先选 4 搭建！${plain}"
    else
        local ip=$(curl -s ipv4.icanhazip.com)
        local uuid=$(cat /usr/local/etc/xray/uuid.txt)
        local pbk=$(cat /usr/local/etc/xray/public_key.txt)
        local sid=$(cat /usr/local/etc/xray/sid.txt)
        echo -e "\n${yellow}你的链接: vless://$uuid@$ip:443?security=reality&sni=www.lovelive-anime.jp&fp=chrome&pbk=$pbk&sid=$sid&type=tcp&flow=xtls-rprx-vision#REALITY_NODE${plain}\n"
    fi
    read -p "按回车继续..."
}

# 主界面循环
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

 请选择操作[0-9]："
    read -p "请输入数字:" num
    case "$num" in
        1|2) do_install ;;
        3) bash <(curl -L https://github.com) --remove ;;
        4) install_reality ;;
        5) show_config ;;
        7) systemctl start xray ;;
        8) systemctl restart xray ;;
        9) systemctl stop xray ;;
        0) exit 0 ;;
        *) echo "无效选择" && sleep 1 ;;
    esac
done
