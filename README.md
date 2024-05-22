# Shadowsocks Script

一个 shadowsocks + v2ray 的安装脚本。

## 安装

执行 `sudo ./install.sh`，开始安装。

安装完后，修改配置文件 `/etc/shadowsocks/config.json`，进行配置。

默认生成的配置文件会包含两个账号，需要自己修改端口号，按需增删账号数量。

修改完配置后，需要执行`sudo systemctl restart shadowsocks`重启服务使配置生效。

**注意：**由于shadowsocks是以普通用户权限运行，请不要使用1024以下的端口号。

## 卸载

执行 `sudo ./uninstall.sh`，卸载安装。

**注意：** 卸载程序会删除所有配置文件，卸载前请注意备份。


## 更新 Shadowsocks

执行 `sudo ./uninstall.sh`，更新`shadowsocks`和`v2ray`。

更新`shadowsocks`后，密码不会更新。更新即时生效无需重启服务。

推荐将更新设置为定时任务：

```
# crontab -e
0 5 * * * /path/to/update.sh
```



## 更新密码

执行 `sudo ./update_password.sh`，更新所有服务的密码。密码更新即时生效无需重启服务。

更新完成后将在命令行输出更新后的 `ss url`。修改后的密码需手动查看`/etc/shadowsocks/config.json`文件。



## 扩展



### 1024端口限制

通过在服务配置文件里加入指定配置，可以使其绑定低于1024的端口。

**/etc/systemd/system/shadowsocks.service**

```
[Unit]
...
[Service]
...
CapabilityBoundingSet=CAP_NET_BIND_SERVICE # 允许服务绑定到低于 1024 的网络端口

[Install]
...
```



### 定时重启服务

**restart-shadowsocks.timer**
```
[Unit]
Description=Restart Shadowsocks Service Daily

[Timer]
OnCalendar=*-*-* 00:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

**restart-shadowsocks.service**
```
[Unit]
Description=Shadowsocks Service Restart

[Service]
Type=oneshot
ExecStart=/bin/systemctl restart shadowsocks.service

[Install]
WantedBy=multi-user.target
```

```shell
sudo systemctl daemon-reload
sudo systemctl enable restart-shadowsocks.timer
sudo systemctl start restart-shadowsocks.timer
```