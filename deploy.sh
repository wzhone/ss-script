#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "此操作需要 root 权限，请使用 root 身份执行此脚本。"
    exit 1
fi

repo="https://api.github.com/repos/StaticN/temp/releases/latest"
assets=$(curl -s "$repo" | jq -r '.assets[] | select(.name | contains("sss")) | .browser_download_url')
if [ -n "$assets" ]; then
    for url in $assets; do
        curl -L -s -o /bin/sss "$url"
        chmod +x /bin/sss
        /bin/sss version
    done
else
    log "部署失败！"
    exit 1
fi
