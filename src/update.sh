#!/bin/bash
source ./scripts/common.sh

# 下载与安装 v2ray-plugin
update_v2ray_plugin() {
    v2ray_plugin_repo="https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest"
    v2ray_plugin_assets=$(curl -s $v2ray_plugin_repo | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url')

    if [ -n "$v2ray_plugin_assets" ]; then
        url=$(echo $v2ray_plugin_assets | head -n 1)
        log "下载 v2ray plugin from $url"
        curl -L -s -o $TMP_DIR/v2ray-plugin.tar.gz "$url"
        tar -xzf $TMP_DIR/v2ray-plugin.tar.gz -C $TMP_DIR
    else
        log "未找到 v2ray plugin 的最新版本。"
    fi
}

# 下载与安装 shadowsocks
update_shadowsocks() {
    shadowsocks_repo="https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest"
    shadowsocks_assets=$(curl -s $shadowsocks_repo | jq -r '.assets[] | select(.name | contains("x86_64-unknown-linux-gnu")) | .browser_download_url')

    if [ -n "$shadowsocks_assets" ]; then
        url=$(echo $shadowsocks_assets | head -n 1)
        log "下载 shadowsocks from $url"
        curl -L -s -o $TMP_DIR/shadowsocks.tar.xz "$url"
        tar -xJf $TMP_DIR/shadowsocks.tar.xz -C $TMP_DIR
    else
        log "未找到 shadowsocks 的最新版本。"
    fi
}

# 安装文件
install_files() {
    log "安装shadowsocks文件..."
    /usr/bin/install -m 755 $TMP_DIR/v2ray-plugin_linux_amd64 /bin/v2ray-plugin
    /usr/bin/install -m 755 $TMP_DIR/ssserver /bin/ssserver
    /usr/bin/install -m 755 $TMP_DIR/ssservice /bin/ssservice
    /usr/bin/install -m 755 $TMP_DIR/ssmanager /bin/ssmanager
    /usr/bin/install -m 755 $TMP_DIR/ssurl /bin/ssurl
}

update_suit() {

    # 检测是否已经安装
    if [ ! -f /bin/v2ray-plugin ] || [ ! -f /bin/ssserver ] || [ ! -f /bin/ssservice ] || [ ! -f /bin/ssmanager ] || [ ! -f /bin/ssurl ]; then
        log "未检测到 Shadowsocks 安装文件"
        log "请确认是否已执行install命令安装Shadowsocks套件"
        exit 1
    fi


    # 创建目录
    mkdir -p $TMP_DIR

    update_v2ray_plugin
    update_shadowsocks

    log "停止shadowsocks服务..."
    systemctl stop shadowsocks

    install_files

    log "启动shadowsocks服务..."
    systemctl daemon-reload
    systemctl start shadowsocks
    log "更新完成"
    systemctl status shadowsocks --no-pager | grep -E 'Active:|Loaded:'
}
