#!/bin/bash

source ./scripts/common.sh

# 生成随机密码的函数
generate_password() {
    ssservice genkey --encrypt-method aes-256-gcm
}

rotate_key() {
    log "开始更新 shadowsocks 密码..."
    install_common_package jq

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
        echo "$json_data" >/etc/shadowsocks/config.json
        log "密码已成功更新"
        systemctl restart shadowsocks
        echo "---------------shadowsocks url---------------"
        ssurl -e /etc/shadowsocks/config.json
        echo "---------------------------------------------"
    else
        log "/etc/shadowsocks/config.json 文件未找到！"
        log "请确认是否已执行install命令安装Shadowsocks套件"
    fi
}
