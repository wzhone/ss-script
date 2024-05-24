# Shadowsocks Script

一个 shadowsocks + v2ray 的安装脚本。

## 安装

执行以下代码安装`sss`命令以及`shadowsocks`：

```
curl https://raw.githubusercontent.com/wzhone/ss-script/master/deploy.sh | sudo bash
sudo sss install
```

安装完后，修改配置文件 `/etc/shadowsocks/config.json`，进行个性化配置。

默认生成的配置文件会包含两个账号，需要自己修改端口号，按需增删账号数量。

修改完配置后，需要执行`sudo systemctl restart shadowsocks`重启服务使配置生效。

**注意：**由于`shadowsocks`是以普通用户权限运行，请避免使用`1024`以下的端口号。




## 卸载

执行 `sudo sss uninstall`，卸载`Shadowsocks`。

**注意：** 卸载程序会删除所有配置文件，卸载前请注意备份。




## 更新

执行 `sudo sss update`，更新`shadowsocks`和`v2ray`。

更新`shadowsocks`后，密码不会更新。更新即时生效无需重启服务。




## 更新密码

执行 `sudo sss rotate`，更新所有服务的密码。密码更新即时生效无需重启服务。

更新完成后将在命令行输出更新后的 `ss url`。修改后的密码需手动查看`/etc/shadowsocks/config.json`文件。




## 屏蔽中国出口IP

为了降低各种风险，可以在服务器配置禁止向中国IP发出TCP请求包。

注：此操作是**可选**的，如果并不清楚工作原理，请不要执行。

### 使用方式

```shell
sudo sss enhance
```
### 脚本说明

这个脚本会创建一个`ipset`，作为黑名单拦截发往中国的IP请求。

同时会记录尝试发往中国的请求。通过查看**系统日志**可以看到`iptables`输出的信息。




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

如需定时重启`shadowsocks`服务，可以参考如下得配置。

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



### 更新 sss 脚本

重新执行这条命令即可
```shell
curl https://raw.githubusercontent.com/wzhone/ss-script/master/deploy.sh | sudo bash
```