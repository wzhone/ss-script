#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "此操作需要 root 权限，请使用 root 身份执行此脚本。"
    exit 1
fi

# 安装 jq (如果尚未安装)
if ! command -v jq &> /dev/null
then
    echo "jq 未安装，正在安装..."
    sudo dnf install -y jq
    if [ $? -ne 0 ]; then
        echo "jq安装失败！"
        exit 1
    fi
fi

# 生成随机密码的函数
generate_password() {
    ssservice genkey --encrypt-method aes-256-gcm
}

# 读取和更新 config.json
if [ -f /etc/shadowsocks/config.json ]; then
    # 备份原始文件
    cp /etc/shadowsocks/config.json /etc/shadowsocks/config.json.bak

    # 读取 JSON 数据
    json_data=$(cat /etc/shadowsocks/config.json)

    # 获取 servers 数组的长度
    servers_length=$(echo "$json_data" | jq '.servers | length')

    # 循环更新每个 server 的密码
    for i in $(seq 0 $(($servers_length - 1))); do
        new_password=$(generate_password)
        json_data=$(echo "$json_data" | jq --arg new_password "$new_password" '.servers['$i'].password = $new_password')
    done

    # 将更新后的 JSON 写回文件
    echo "$json_data" > /etc/shadowsocks/config.json
    echo "密码已成功更新"
    systemctl restart shadowsocks

    ssurl -e /etc/shadowsocks/config.json -c
else
    echo "/etc/shadowsocks/config.json 文件未找到！"
fi

