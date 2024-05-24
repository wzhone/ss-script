#!/bin/bash

source ./scripts/common.sh

uninstall_suit() {

    # 停止和禁用服务
    if systemctl is-active --quiet shadowsocks; then
        log "停止服务..."
        systemctl stop shadowsocks >>"$LOG_FILE" 2>&1
    fi

    if systemctl is-enabled --quiet shadowsocks; then
        log "禁用服务..."
        systemctl disable shadowsocks >>"$LOG_FILE" 2>&1
    fi

    # 删除文件和目录
    log "删除文件和服务..."
    rm -f /bin/{v2ray-plugin,ssserver,ssservice,ssmanager,ssurl}
    rm -f /etc/systemd/system/shadowsocks.service

    # 重新加载 systemd
    log "重新加载 systemd..."
    systemctl daemon-reload >>"$LOG_FILE" 2>&1

    # 删除配置文件和用户
    log "删除配置文件和用户..."
    rm -rf /etc/shadowsocks
    if id shadowsocks &>/dev/null; then
        userdel shadowsocks >>"$LOG_FILE" 2>&1
    fi

    log "Shadowsocks 已成功卸载"
}
