#!/bin/bash

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "此操作需要 root 权限，请使用 root 身份执行此脚本。"
    exit 1
fi

LOG_FILE="/var/log/ss-script.log"
log() {
    local msg="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $msg" >> "$LOG_FILE"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $msg"
}

# 停止和禁用服务
if systemctl is-active --quiet shadowsocks; then
    log "停止 shadowsocks 服务..."
    systemctl stop shadowsocks >> "$LOG_FILE" 2>&1
fi

if systemctl is-enabled --quiet shadowsocks; then
    log "禁用 shadowsocks 服务..."
    systemctl disable shadowsocks >> "$LOG_FILE" 2>&1
fi

# 删除文件和目录
log "删除文件和目录..."
rm -f /bin/v2ray-plugin
rm -f /bin/ssserver
rm -f /bin/ssservice
rm -f /bin/ssmanager
rm -f /bin/ssurl
rm -f /etc/systemd/system/shadowsocks.service

# 重新加载 systemd
log "重新加载 systemd..."
systemctl daemon-reload >> "$LOG_FILE" 2>&1

# 删除配置文件和用户
log "删除配置文件和用户..."
rm -rf /etc/shadowsocks
userdel shadowsocks >> "$LOG_FILE" 2>&1

log "Shadowsocks 已成功卸载"
