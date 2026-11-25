# sing-box 一键安装脚本（独立重写，v1.0.14）

一个独立重写的 sing-box 一键安装 / 管理脚本。菜单、安装流程和命令行用法对标常见的 sing-box 一键脚本（fscarmen/sing-box 的 sing-box.sh v1.3.31），但**代码全部是重新写的**，没有复制原版脚本的代码。

> 许可证：本脚本为 MIT 许可（见 `LICENSE`）。sing-box 本身是另一个项目（SagerNet/sing-box，GPL-3.0），本脚本只下载它的官方 release 二进制，不捆绑 sing-box 源码。

## 一键运行

1. 普通安装（出菜单，自己选）：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh)
```

2. 一键快速安装（英文，全部协议默认）：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh) -K
```

3. 一键快速安装（中文）：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh) -L
```

> 注意：仓库必须是公开的才能用这个链接拉到，私有会返回 404。装完后用 `sb` 或 `cj` 打开菜单。

> **v1.0.14 新行为：删掉 8 个超时协议（剩 19 种）+ CF 链接改走 CDN 优选域名 + VLESS + TCP + TLS 加 allowInsecure。** 删掉的 8 个：ShadowTLS、Naive、Snell v6、VLESS + HTTPUpgrade、Trojan + gRPC、VMess + gRPC、VLESS + HTTP、VMess + HTTP——用户实测全部超时：CF 的 gRPC 在公开隧道域名上是 Cloudflare 官方不支持的用法，CF 的 HTTP 传输走隧道不稳定，ShadowTLS 握手失败，Naive 用的自签证书（客户端不跳过证书校验就连不上），Snell v6 需要支持 v6 的客户端。剩下的 19 种里 CF 组是 8–11 号（VLESS + WS + TLS、Trojan + WS、VMess + WS + TLS、Trojan + HTTP），nginx 反代只剩 `/vless-ws-tls`、`/vmess-ws-tls`、`/trojan-ws`、`/trojan-http` 4 个位置。CF 链接：服务器地址改回 CDN 优选域名（默认 `cf.3666888.xyz`，用户实测过的优选域名），端口 443，SNI 和 Host 仍是 Argo 隧道域名（之前改成地址、SNI、Host 全用隧道域名也能通，但和原来 fscarmen 的写法不一样，速度也没更快）。VLESS + TCP + TLS（Vision）链接加上 `allowInsecure=1`（入站是自签证书，之前没加时客户端校验证书失败、报 bad certificate），Clash 里对应条目加 `skip-cert-verify: true`。防火墙 UDP 放行列表改成 `0|4|6|11|15`（Hysteria2、TUIC、Shadowsocks、Shadowsocks 2022 AES-256、Shadowsocks 2022）。**升级提醒：已装过旧版的机器，`install.env` / `selected.env` 里存的是旧协议编号，升级到 v1.0.14 后旧编号会错位，升级后请从菜单 8 重新选一次协议；全新安装不受影响。**

> **v1.0.13 新行为：去掉 nginx 8080 监听上的 `http2`（修 v1.0.9 引入的回归）+ 菜单 8 删除协议支持一键删除全部。** http2：v1.0.9 为了 gRPC 给 8080 加了 `listen … http2`，但这会让监听口只认 HTTP/2（h2c）：普通 HTTP/1.1 请求（订阅 `/sub`、curl、客户端同步订阅）走到这个口上，返回的根本不是正常 HTTP 响应，curl 报 `Received HTTP/0.9 when not allowed`，客户端显示连接错误、拉不到节点；脚本自己只看端口通不通，所以没有任何错误提示。现改回普通 `listen 8080` / `listen [::]:8080`，订阅恢复正常 HTTP/1.1 响应；gRPC 到入站仍走 `grpc_pass grpcs://`（nginx 到入站那段，不依赖监听上的 http2），cloudflared 到 nginx 本来就是 `--url http://127.0.0.1:8080`（HTTP/1.1）。另外订阅验证也加强了：`start_nginx_safe()` 失败时把 `/sub` 的实际 HTTP 码打出来，000 就表示 nginx 返回的东西根本不是正常 HTTP（例如 HTTP/0.9），不再只给一句通用提示。升级后请实测 `curl -I http://127.0.0.1:8080/sub` 返回 200，客户端重新同步订阅能拉到节点。**删除全部：菜单 8（增加 / 删除协议）删除协议那一步输入 `all`（大小写不限），就删除全部已安装协议；单独输入 `a` 还是只删已安装列表里的第 1 个，不是全部。删完照常走确认那步（保留列表为空、新增列表照常显示，按 [n] 可以取消），确认后才真正删；删完一个都不剩时空配置正常保存、服务正常重启、订阅为空，不会崩。**（注：http2 修复原计划随 v1.0.12 单独发版，因用户追加了删除全部需求，未单独发 v1.0.12，两项改动合并在 v1.0.13 一起交付。）

> **v1.0.11 新行为：防火墙 UDP 放行列表修正。** `sync_firewall()` 里原来是 `1|3|5|15` 号放 UDP，但那四个全是只用 TCP 的协议（VLESS + Reality、AnyTLS、Trojan、VMess + WS + TLS (CF)），真正要用 UDP 的 6 个协议反而一个都没放：Hysteria2（0 号，QUIC/UDP）、TUIC（4 号，QUIC/UDP）、Shadowsocks（7 号，UDP 转发）、Snell v6（9 号）、Shadowsocks 2022 AES-256（19 号，UDP 转发，直连）、Shadowsocks 2022（23 号，UDP 转发）。现改成 `0|4|7|9|19|23` 放 UDP；ShadowTLS（6 号）外层是 TCP、内层 Shadowsocks 只监听 127.0.0.1，不用对外放 UDP；CF 组（10–18 号）和其余 VLESS / VMess / Trojan / Naive / H2 / gRPC / AnyTLS 全是 TCP。升级后请重新同步一次防火墙（菜单 8 重新确认一次或重启服务时会自动同步），Hysteria2 / TUIC / Snell / Shadowsocks 这几个 UDP 节点要实测连通。
>
> **v1.0.10 新行为：Shadowsocks 2022 AES-256 去掉名字里的 (CF)、移到 CF 组后面（新 20 号）。** 它没有 WS / HTTP / gRPC 传输，走不了 CF 隧道和 nginx 反代，只能直连，名字里的 (CF) 是误导，所以去掉；排序上从旧 17 号移到 CF 组后面（新 20 号，VLESS + WS + Reality 前面），VLESS + HTTP、VMess + HTTP、Trojan + HTTP 顺移到 17 / 18 / 19 号。CF 组现在是 11–19 号（9 个），其余组是 20–27 号。**升级提醒：已装过旧版的机器，`install.env` / `selected.env` 里存的是旧协议编号，升级到 v1.0.10 后旧 16–19 号协议会错位（例如旧 17 号 Shadowsocks 2022 AES-256 会读成新 17 号 VMess + HTTP），升级后请从菜单 8 重新选一次协议；全新安装不受影响。**
>
> **v1.0.9 新行为：修 CF 节点不通 + `cj` 调不出菜单。** CF 节点：Trojan + gRPC（13 号）、VMess + gRPC（14 号）的链接之前写的是服务器 IP 和本地端口，入站又只监听 127.0.0.1，直连根本没人监听，现改成和其他 CF 协议一样走 Argo 隧道域名:443（没开 Argo 时走 CDN 优选域名和本地端口）；Shadowsocks 2022 AES-256（17 号）没有 WS / HTTP / gRPC 传输，nginx 和 Argo 都代理不了它，链接改回直连服务器 IP:本地端口（名字里的 (CF) 是历史遗留，指它替代了 Shadowsocks + WebSocket）；nginx 反代新增 `/vless-httpupgrade`、`/vmess-grpc/`、`/trojan-grpc/` 三个位置（gRPC 用 `grpc_pass grpcs://`，因为入站开了 TLS；WS / HTTP 入站同样开了 TLS，nginx 反代改走 `https://` 并关闭证书校验，之前纯 `http://` 代理到等 TLS 握手的入站上必定失败；HTTPUpgrade 入站没开 TLS，仍走 `http://`）；写完 nginx 配置后只要有 nginx 进程在跑就先 `nginx -s reload`（之前只在 8080 被占时才 reload，正在跑但没监听 8080 的 nginx 会让 `systemctl start` 变成空操作，新配置永不加载，订阅打不开，用户手动 reload 后才通）。`cj` / `sb`：快捷命令在语言选择之前就创建（之前只在进菜单前创建，提前退出就根本没有 `cj`）；`cj` 无参数且没存过语言时默认中文直接进菜单，不再重复问语言（`-E` / `-C` 仍可覆盖）；本地已有完整脚本文件时优先用它，不再每次重新下载；重新下载失败时明确报错（检查网络和仓库是否公开），之前是静默跑空脚本、退出 0，看着像“没有任何反应”。
>
> **v1.0.8 新行为：菜单 8（增加 / 删除协议）增加一键安装所有协议：在“增加协议”那一步输入 `all`（大小写不限），就一键安装全部未安装协议；已装过的保留，只装剩下的；空安装时就是安装全部 19 种。选完后还是先显示确认列表、等用户确认（按 [n] 取消）再执行。单独输入 `a` 还是只选未安装列表里的第 1 个协议，不是全部。**
>
> **v1.0.7 新行为：协议重排成 27 种：原来第 10 号的 VLESS + Reality (Vision) / XTLS + Reality 移到第 3 号（VLESS + Reality 后面）；走 CF 的协议按网速优先、延迟其次重排（VLESS + HTTPUpgrade、VLESS + WS + TLS、Trojan + gRPC、VMess + gRPC、Trojan + WS、VMess + WS + TLS、Shadowsocks 2022 AES-256、VLESS + HTTP、VMess + HTTP、Trojan + HTTP）；删掉 VMess + WS (CF)；其他位置不动，序号重排。注意：已装过旧版的机器升级到 v1.0.7 后，旧 `install.env` / `selected.env` 里存的是旧协议编号，升级后请从菜单 8 重新选一次协议。**
>
> **v1.0.6 新行为：CDN 优选域名新增 cf.xreak.top、cf.3666888.xyz、cfsaas.080112.xyz、cf.92555.xyz；菜单 8 加了走 CF 的协议后自动问 Argo 隧道（临时/固定/不启用），临时隧道开通后自动拿到域名并匹配到 CF 节点链接上；nginx 启动改成安全启动（旧 nginx 进程占着 8080 时先重载，实在不行再杀掉旧进程重起）；`sb` / `cj` 记住上次的语言，直接进主菜单，不再重复问语言；语言选择里“2. 简体中文”标黄。**
>
> **v1.0.5 新行为：协议名 WebSocket 改成 WS；菜单 8 加完协议后自动 enable + 启动 sing-box，并自动启用订阅（nginx），节点能连通、订阅链接能打开。**
>
> **v1.0.4 新行为：自动补装时生成空的安装状态。** v1.0.3 只补装了主程序，没生成 `install.env`，所以菜单 1. 查看节点信息、5. 修改节点配置、8. 增加 / 删除协议一进去就报“sing-box 尚未安装。”。v1.0.4 在补装时（主程序本来就已存在但 `install.env` 缺失时也会补）生成一个空的 `install.env`：UUID、节点名、服务器地址、密码都用默认值填好，协议是空的（`SELECTED_IDX=()`），同时写好基础配置（无协议）、自签 TLS 证书、Reality 密钥和服务文件（只写文件，不启动服务）。这样菜单 1/5/8 都能正常打开，菜单 1 在暂无协议时会提示“暂无协议，请从菜单 8 增加 / 删除协议里添加”，协议从菜单 8 添加。ArgoX / xray 不在首次自动补装范围，选菜单 10 装 ArgoX 时它自己装。

也可以先下载再运行：

```bash
wget https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh
bash sing-box.sh
```

装好后直接用快捷命令：

```bash
sb          # 打开菜单
cj          # 打开菜单（和 sb 一样，快捷跳出菜单）
sb -n       # 查看节点信息
sb -s       # 开/关 sing-box
sb -a       # 开/关 Argo
sb -t       # 修改 Argo
sb -d       # 修改配置
sb -v       # 同步 Sing-box 和 Argo 至最新版本
sb -b       # 升级内核、安装BBR、DD脚本
sb -r       # 增删协议
sb -u       # 卸载
```

## 支持的系统

Debian、Ubuntu、CentOS / RHEL、Alpine、Armbian、Fedora、Arch Linux，x86_64 和 aarch64。需要 root 用户运行。支持 systemd 和 OpenRC。

## 主菜单

没装过时（1–9 + 0）：

| 选项 | 说明 |
| --- | --- |
| 1 | 一键快速安装（全部协议） |
| 2 | 安装 + 订阅 + Argo |
| 3 | 安装 + Argo |
| 4 | 安装 + 订阅 |
| 5 | 自定义安装 |
| 6 | 网络测速 |
| 7 | Argo 工具 |
| 8 | 订阅工具 |
| 9 | Hysteria2 工具 |
| 0 | 退出 |

装好后（1–12 + 0）：

| 选项 | 说明 |
| --- | --- |
| 1 | 查看节点信息（`sb -n`） |
| 2 | 关闭 Sing-box（`sb -s`），运行时显示“关闭”，停用时显示“开启” |
| 3 | 关闭 Argo（`sb -a`），运行时显示“关闭”，停用时显示“开启” |
| 4 | 更换 Argo 隧道（`sb -t`） |
| 5 | 修改节点配置（`sb -d`） |
| 6 | 同步 Sing-box 和 Argo 至最新版本（`sb -v`） |
| 7 | 升级内核、安装BBR、DD脚本（`sb -b`） |
| 8 | 增加 / 删除协议（`sb -r`） |
| 9 | 卸载（`sb -u`） |
| 10 | 安装 ArgoX 脚本 (argo + xray) [https://github.com/fscarmen/argox] |
| 11 | 安装 sba 脚本 (argo + sing-box) [https://github.com/fscarmen/sba] |
| 12 | 安装 TCP brutal |
| 0 | 退出 |

菜单顶部会显示脚本版本、系统信息（操作系统 / 内核 / 架构 / 虚拟化）、IPv4 / IPv6，以及 Sing-box / Argo / Nginx 的状态、版本、内存占用和流量。

## 安装向导

按顺序问：选协议 → 起始端口（默认 8881，连续分配）→ 服务器地址（默认自动探测的公网 IP）→ UUID（默认随机生成）→ 节点名 → 客户端指纹（chrome / firefox）→ Reality 私钥（有 Reality 协议时，留空自动生成）→ Hysteria2 的 Realm、带宽、端口跳跃（只有选了 Hysteria2 才问）→ CDN 优选域名、订阅开关、Argo（只有选了走 Cloudflare 的协议才问）→ nginx 订阅端口。

## 协议表（19 种，全称）

协议名用 WS 缩写（用户要求，v1.0.5）：WebSocket 写成 WS；Shadowsocks 不写 SS；Hysteria2 不写 Hy2。链接里的 `type=ws`、`type=http`、`ss://` 等是客户端协议格式本身，不能改，不算简写。内部 tag（如 `vless-ws-tls`）只用在配置文件名和 JSON 里。

| 编号 | 字母 | 协议全称 | 内部 tag | 走 Cloudflare |
| --- | --- | --- | --- | --- |
| 1 | b | Hysteria2 | hysteria2 | 否 |
| 2 | c | VLESS + Reality | vless-reality | 否 |
| 3 | d | VLESS + Reality (Vision) / XTLS + Reality | xtls-reality | 否 |
| 4 | e | AnyTLS | anytls | 否 |
| 5 | f | TUIC | tuic | 否 |
| 6 | g | Trojan | trojan | 否 |
| 7 | h | Shadowsocks | shadowsocks | 否 |
| 8 | i | VLESS + WS + TLS (CF) | vless-ws-tls | 是 |
| 9 | j | Trojan + WS (CF) | trojan-ws-tls | 是 |
| 10 | k | VMess + WS + TLS (CF) | vmess-ws-tls | 是 |
| 11 | l | Trojan + HTTP (CF) | trojan-http | 是 |
| 12 | m | Shadowsocks 2022 AES-256 | ss2022-256 | 否（直连，不走 CF，见 v1.0.10 说明） |
| 13 | n | VLESS + WS + Reality | vless-ws-reality | 否 |
| 14 | o | VLESS + TCP + TLS (Vision) | vless-tls | 否 |
| 15 | p | Trojan + Reality | trojan-reality | 否 |
| 16 | q | Shadowsocks 2022 | ss2022 | 否 |
| 17 | r | H2 + Reality | h2-reality | 否 |
| 18 | s | gRPC + Reality | grpc-reality | 否 |
| 19 | t | AnyTLS + Reality | anytls-reality | 否 |

选协议时：`a` = 全部 19 种；字母 `b`–`t` 对应第 1–19 种；也可以直接输数字 `1`–`19`。可多选，可连写（如 `bcd`）、可空格、可逗号，大写自动转小写。端口按选择顺序从起始端口连续分配（例如起始端口 8881，全选占 8881–8899）。

第 3 号就是 XTLS + Reality（Vision 流控），和第 2 号普通 VLESS + Reality 不重复。

第 3 号就是 XTLS + Reality（Vision 流控），和第 2 号普通 VLESS + Reality 不重复。

## 替换说明（11–12 号，原来想要的写法在官方 sing-box 上跑不起来）

实测 sing-box 1.14.4 官方二进制：

- **12 号**：原来想要的 Shadowsocks + WS，`shadowsocks` 入站没有 `transport` 字段，写进去 `sing-box check` 会报错。改成官方支持的等价组合 **Shadowsocks 2022 AES-256**（`2022-blake3-aes-256-gcm`，32 字节密钥），菜单和链接都按这个名字写。v1.0.10 起它不再标注 (CF)、移到 CF 组后面（12 号），因为它没有传输层可供 nginx / Argo 代理，只能直连。
- **11 号**：原来想要的 Trojan + XHTTP，`xhttp` 不是官方 sing-box 的合法传输类型（`unknown transport type: xhttp`，只存在于个别打补丁的 fork 里）。改成官方支持的等价组合 **HTTP 传输**（`type=http`，HTTP/1.1 + H2，路径和 CDN 流程复用 WebSocket 那套），菜单改成 Trojan + HTTP。VLESS + HTTP、VMess + HTTP 本来也是这个替换，但 v1.0.14 起删掉了（走 CF 超时，见 v1.0.14 说明）。

如果坚持要原汁原味的 XHTTP / Shadowsocks + WS，只能换核心（例如带 XHTTP 补丁的 fork 或 Xray-core），不在本脚本“官方 sing-box 二进制”的路线内。其余 17 种已在 sing-box 1.14.4 上逐个 `sing-box check` 通过，19 种合在一起也能通过，实际启动时 19 个入站全部监听。

## Hysteria2：带宽和端口跳跃

选了 Hysteria2 后，安装向导中途（Realm 问完、进 CDN / 订阅之前）会依次问：

1. **带宽**：上行/下行，单位 Mbps，例如 `100/100`，直接回车用默认 100/100。装好后用 `sb -d` 第 10 项也能改。
2. **端口跳跃**：直接问范围，例如 `20000:21000`，**直接回车跳过，不用端口跳跃**。输了范围才开启，范围须在 10000–65535 之间、起始小于结束，支持 `起始:结束` 和 `起始-结束` 两种写法。

问范围之前会先打印一页说明：有些运营商会限速或阻断单个 UDP 端口，端口跳跃把流量分散到一段 UDP 端口上；推荐用 1000 个左右的端口；NAT 小鸡能用的端口一般只有 20–30 个，填了没开放的端口会导致节点不通，请慎用；默认不开启。

## Argo 凭证指引

选 Token / JSON / Cloudflare API 时，脚本会先打印分步指引：去 https://dash.cloudflare.com/ ，Zero Trust > 网络 > 连接器，创建隧道并选择 Cloudflared，Token 就显示在那里；或者用已建隧道的 JSON 凭证；或者用 Cloudflare API 令牌（https://dash.cloudflare.com/profile/api-tokens > 创建令牌 > 创建自定义令牌），授予：帐户 > Cloudflare One 连接器：Cloudflared > 编辑，以及区域 > DNS > 编辑；帐户资源包括你的账户，区域资源包括特定区域的域名。权限不够时 API 调用会失败。

## 订阅和 Clash

- 订阅链接：`http://<服务器地址>:<nginx 端口>/sub`，文件在 `/etc/sing-box/subscribe/`（明文 `list_plain.txt`、base64 `list.txt`、Clash `clash.yaml`）。
- `clash.yaml` 是逐协议完整展开版：`proxies` 里按协议逐个写 VLESS / VMess / Trojan / Hysteria2 / Shadowsocks / TUIC / AnyTLS 等条目，`proxy-groups` 里有 PROXY 分组，`rules` 是 `MATCH,PROXY`。
- 动态订阅（`--SUBSCRIBE dynamic` 或 `sb -d` 第 9 项）：nginx 按请求 Host 实时渲染，直连节点的 server 跟随访问地址，WebSocket / CDN / Argo 节点保持原地址不变。

## 修改配置（`sb -d`）

和原版一样是动态菜单，只显示和当前安装有关的项，按原版顺序排，每项后面都显示当前值；一次改一项，改完回主菜单，输错数字显示“未做任何修改”并返回：

1. 优选域名/IP（只有装了 WebSocket 类协议才显示）
2. Reality SNI（只有装了 Reality 类协议才显示）
3. 监听端口（当前值）
4. 节点名称（当前值）
5. UUID / 密码 / PSK（当前值）
6. 服务器地址（当前值）
7. 客户端指纹（当前值）
8. 指定网络出口（当前值，默认不指定）
9. 开启/关闭订阅（按当前状态动态显示）
10. 开启/关闭动态订阅（只有订阅已开启时才显示）
11. Hysteria2 拥塞控制切换（只有装了 Hysteria2 才显示；声明的 up/down 和强制 BBR 之间切换）
12. Hysteria2 带宽（只有装了 Hysteria2、且未开启强制 BBR 时才显示；先问上行、再问下行）
13. 开启/关闭 Realm（只有装了 Hysteria2 才显示；和端口跳跃互斥，开启前会先确认）
14. Hysteria2 端口跳跃（只有装了 Hysteria2 才显示；留空禁用，和 Realm 互斥）
15. XTLS reality 切换为多路复用 / vision（只有装了 XTLS + Reality 才显示）
16. 自定义 warp-ep 出站路由规则（只有配了 WARP 账户才显示）
17. 更换 WARP 账户（只有配了 WARP 账户才显示）

端口那一项进去后先选方式：1. 修改开始端口（各协议按顺序占用，默认），2. 修改为各协议独立端口；改开始端口会先预览“起始端口 A -> B：N 个协议端口将变为 B - C”，再问是否应用；改独立端口先按字母选协议（`a` = 全部，回车跳过），逐个问新端口，再预览确认。

自定义路由进去后显示“自定义 warp-ep 出站路由规则（规则数：N）”，再选 1. 添加规则、2. 查看规则、3. 删除规则、0. 返回；添加时先选类型（`domain_suffix` 或 `rule_set`），域名后缀支持逗号分隔、会校验格式，规则集名称会自动补 `geosite-` 前缀；删除支持逗号分隔多选。输错会显示“未做任何修改”并返回。

更换 WARP 账户进去后选：1. 重新注册免费账户、2. 手动输入信息、0. 返回；手动输入依次问 WARP IPv6 地址、Private Key、reserved 保留值（格式 `123,456,789`）。

每改一项后脚本都会 `sing-box check` 校验，通过才重载 / 重启，不通过报错不重启。

## 增删协议（`sb -r`）

先列已装的协议和端口，再问删除（字母多选，回车跳过），再问增加（字母多选，回车跳过）。改完按起始端口重新连续分配，删掉的入站文件删除、新增的写入，校验通过后重启服务、同步防火墙、重新输出节点链接。

## 命令行参数

```
sb -s    开/关 sing-box        sb -a    开/关 Argo
sb -t    修改 Argo             sb -d    修改配置
sb -u    卸载                  sb -n    查看节点信息
sb -v    同步 Sing-box 和 Argo 至最新版本   sb -b    升级内核、安装BBR、DD脚本
sb -r    增删协议
-E / -C / --LANGUAGE en|zh    语言
-K / -L                       一键快速安装（-L 为中文）
-f / -F FILE                  从 KEY=VALUE 配置文件读安装答案
--CHOOSE_PROTOCOLS a|b c ...  按协议表选协议（a=全部 19 种）
--START_PORT / --PORT_NGINX / --SERVER_IP / --CDN / --UUID_CONFIRM /
--NODE_NAME_CONFIRM / --SUBSCRIBE yes|no|dynamic / --ARGO true|false /
--ARGO_DOMAIN / --ARGO_AUTH / --HY2_PORT_HOPPING_RANGE /
--HY2_REALM / --BIND_INTERFACE / --REALITY_PRIVATE
```

例子：

```bash
bash sing-box.sh -K
bash sing-box.sh --CHOOSE_PROTOCOLS b --START_PORT 8881 --SERVER_IP 1.2.3.4
bash sing-box.sh -f /root/install.conf
```

## 文件位置（装好后）

- 二进制：`/etc/sing-box/sing-box`，配置：`/etc/sing-box/conf/`（`00_base.json`、`01_<tag>_inbounds.json`、`02_outbounds.json`、`03_route.json`、`04_experimental.json`）
- 节点列表：`/etc/sing-box/list`，订阅：`/etc/sing-box/subscribe/`
- 服务：`sing-box.service`、`argo.service`；快捷命令：`/usr/local/bin/sb` 和 `/usr/local/bin/cj`（都指向 `/etc/sing-box/installer.sh` 的副本，第一次运行脚本进菜单时就创建）
- 防火墙记录：`/etc/sing-box/firewall/service_ports.list`

## 卸载

菜单选 9 或运行 `sb -u`。和原版一样，卸载本身不做“确定吗”确认，停服务、删服务文件、清端口跳跃 NAT、按记录删防火墙规则、删 nginx 订阅配置、删 `/etc/sing-box` 和快捷命令 `/usr/local/bin/sb`、`/usr/local/bin/cj` 后直接完成；过程中只问两件事（都默认不删）：装了 Nginx 时问是否一并卸载 Nginx，装了 fcgiwrap / spawn-fcgi 时问是否一并卸载。`sb -u` 命令行方式跳过这两问。

## v1.0.14 改了什么

- 删掉 8 个超时协议（27 → 19 种）：ShadowTLS（7 号）、Naive（9 号）、Snell v6（10 号）、VLESS + HTTPUpgrade（11 号）、Trojan + gRPC（13 号）、VMess + gRPC（14 号）、VLESS + HTTP（17 号）、VMess + HTTP（18 号）。用户 2026-11-25 在真机上实测全部超时：CF 的 gRPC 在公开隧道域名上是 Cloudflare 官方不支持的用法，CF 的 HTTP 传输走隧道不稳定，ShadowTLS 握手失败（`read client handshake: unexpected EOF`），Naive 用的自签证书、客户端不跳过证书校验就连不上，Snell v6 需要支持 v6 的客户端（sing-box 1.14.4 服务端只支持 v6，不支持 v4）。删掉后协议重排成 19 种：置顶 1–7 号，CF 组 8–11 号（VLESS + WS + TLS、Trojan + WS、VMess + WS + TLS、Trojan + HTTP），其余 12–19 号；`PROTO_NAMES` / `PROTO_LINK_NAMES` / `PROTO_TAGS` / `PROTO_CF` 四个数组、协议选择器（字母 `b`–`t`，不再有 `aa`/`ab`）、`write_inbound()` / `build_link_for()` / `clash_proxy_for()` 三个分支、Reality 检查（新 1/2/12/14/16/17/18 号）、`sb -d` 的 WS/Reality 判断、nginx 反代位置全部按新编号换过。
- CF 链接改回 CDN 优选域名做服务器地址：之前 v1.0.9 的修法是地址、SNI、Host 全用 Argo 隧道域名，虽然能通，但和原来 fscarmen 的写法不一样；现改成地址用 CDN 优选域名:443、SNI 和 Host 用 Argo 隧道域名（和 fscarmen 一样）。这是 2026-11-25 真机上验证过的写法：SNI 必须是隧道域名，否则 Cloudflare 边缘握手直接失败（`SSL alert 40`，CF 节点全部超时）；地址用优选域名时走优选 IP，默认优选域名改成用户实测过的 `cf.3666888.xyz`（`DEFAULT_CDN_HOST`）。没开 Argo 时 CF 链接仍用 CDN 优选域名和本地端口，和原来一样。
- VLESS + TCP + TLS（Vision）链接加上 `allowInsecure=1`：入站是自签证书（CN=`addons.mozilla.org`），之前链接里没加时客户端校验证书失败、服务器日志报 `bad certificate`，节点超时；Trojan、AnyTLS 这些本来就有 `allowInsecure=1`，就它漏了。Clash 里对应条目加 `skip-cert-verify: true`。
- 防火墙 UDP 放行列表改成 `0|4|6|11|15`（Hysteria2 0 号、TUIC 4 号、Shadowsocks 6 号、Shadowsocks 2022 AES-256 11 号、Shadowsocks 2022 15 号）；Snell v6 删掉了，不用再放 UDP。
- nginx 反代只剩 4 个位置：`/vless-ws-tls`、`/vmess-ws-tls`、`/trojan-ws`、`/trojan-http`（都是 `https://127.0.0.1:端口` + 关闭证书校验）；`/vless-httpupgrade`、`/vless-http`、`/vmess-http`、`/vmess-grpc/`、`/trojan-grpc/` 随协议删掉，`grpc_pass` 和 `httpupgrade` 的分支也删掉了。
- **升级提醒：已装过旧版的机器，`install.env` / `selected.env` 里存的是旧协议编号，升级到 v1.0.14 后旧编号会错位（例如旧 11 号 VLESS + WS + TLS 会读成新 11 号 Trojan + HTTP），升级后请从菜单 8 重新选一次协议；全新安装不受影响。**

## v1.0.13 改了什么

- 菜单 8（增加 / 删除协议）删除协议支持一键删除全部：删除那一步输入 `all`（大小写不限、首尾空格/逗号容忍）就删除全部已安装协议；单独输入 `a` 还是只删已安装列表里的第 1 个，不是全部。判断放在 `parse_list_letters` 之前（它会把 "all" 拆成 a+l+l），和 v1.0.8 增加那边的 `all` 做法对称。删除提示文字（中英双语）改成写明“输入 all 删除全部已安装协议，也可以多选，回车跳过”。删完照常走确认那步：确认列表显示保留（空）和新增，按 [n] 可以取消，确认后才真正删。删完一个都不剩、又不加新的情况已核对过：`SELECTED_IDX` 为空时不问起始端口和节点名（那步只在“有重装协议、但一个都没保留”时才问），`assign_ports` / `save_install_env` / `check_config` / 重启服务 / `export_list` 都能正常走完——入站文件全删、空配置正常保存、服务正常重启、订阅文件为空、菜单 1 显示“暂无协议，请从菜单 8 添加”，不会报错、不会死循环。
- 去掉 nginx 8080 监听上的 `http2`（修 v1.0.9 引入的回归，用户实测：v1.0.11 机器上 nginx 在跑、也在监听 8080，脚本没有任何错误提示，但 `curl -I http://127.0.0.1:8080/sub` 返回 `curl: (1) Received HTTP/0.9 when not allowed`，客户端同步订阅报连接错误、拉不到节点）：
  - `write_nginx_conf()`：`listen 8080 http2;` / `listen [::]:8080 http2;` 改回普通 `listen 8080;` / `listen [::]:8080;`。`listen … http2` 会让监听口只认 HTTP/2 明文（h2c），普通 HTTP/1.1 请求返回的根本不是正常 HTTP 响应；同一端口既要服务 HTTP/1.1 的 `/sub`，又要反代 WS / HTTP / gRPC，不能用 http2-only 监听。注释同步改写，写清了为什么去掉：cloudflared 到 nginx 是 `--url http://127.0.0.1:8080`（HTTP/1.1），gRPC 到入站靠 `grpc_pass grpcs://`（nginx 到入站那段），不依赖监听上的 http2。
  - gRPC 反代（`grpc_pass grpcs://127.0.0.1:端口`）和 9 个反代位置（`/vless-httpupgrade`、`/vless-ws-tls`、`/vmess-ws-tls`、`/trojan-ws`、`/vless-http`、`/vmess-http`、`/trojan-http`、`/vmess-grpc/`、`/trojan-grpc/`）一个都没动。
  - 订阅验证加强：`start_nginx_safe()` 失败时把 `/sub` 的实际 HTTP 码打出来（`curl -s -o /dev/null -w "%{http_code}"`），000 表示 nginx 返回的东西根本不是正常 HTTP（连接失败，或 HTTP/0.9 式坏响应），不再只给一句通用提示。`_sub_ok()` 本身的判断逻辑没变（200 有内容算通、404 算新配置已加载，因为 `export_list` 写 `list.txt` 之前 `/sub` 本来就是 404）。
  - 全脚本搜过：除了注释里对这次改动的说明，不再有任何功能性的 `http2` 残留。
- 测试：按用户要求做了全面测试，见下面的测试记录；真机订阅打开、客户端同步、CF gRPC 节点实际连通仍需用户实测：升级后 `curl -I http://127.0.0.1:8080/sub` 应返回 200，客户端重新同步订阅能拉到节点。

## v1.0.14 测试记录（2026-11-25，测试机上跑的，不是真机完整安装）

测试方法是把真实脚本里的函数抽出来，在测试目录跑（`SB_HOME` 指向 `/tmp/sbtest14/home`，nginx 用测试端口 18081，系统 nginx 服务从不启动），不改系统、不装到真机。结果：**159 项检查，全部通过，0 失败**。

- **结构检查 36/36**：`bash -n` 通过；版本 v1.0.14 (2026.11.25)；默认 CDN `cf.3666888.xyz` 且在候选列表里；`PROTO_NAMES` / `PROTO_LINK_NAMES` / `PROTO_TAGS` / `PROTO_CF` 都是 19 项（CF 是 0-based 7–10 号）；三个分支函数（`write_inbound` / `build_link_for` / `clash_proxy_for`）的 case 标号正好是 0–18；Reality 检查是新编号 1/2/12/14/16/17/18；防火墙 UDP 只放 `0|4|6|11|15`；选择器 `seq 0 18` / `-le 19` / 字母 `b`–`t`，没有 `aa`/`ab`；删掉的 8 个协议名只在注释和 `show_help()` 的版本历史里出现，不在任何功能代码里；Hysteria2 端口跳跃（菜单 5 入口、`hy2_hopping_change`、NAT、`--HY2_PORT_HOPPING_RANGE`）原样保留；SNI 修复（`cf_sni`）、VLESS + TCP + TLS 的 `allowInsecure=1`、`skip-cert-verify` 都在。
- **协议选择器 18/18**：`a` = 全部 19 个；`b` = 0 号、`t` = 18 号；`bcd` = 0/1/2；数字 `1` / `19` / `1 19`；`B, C` 大小写和逗号都行；`20`、空输入、`aa`、`u` 都判非法；菜单 8 的字母解析 `a` = 列表第一项、`ab` = 0/1，`t` 只在列表有 20 项时有效（19 项的列表只用到 `a`–`s`）。
- **链接生成 Argo 开 32/32**：19 条链接全在；4 个 CF 链接用 `cf.3666888.xyz:443`、SNI 和 Host 都是 Argo 隧道域名（VMess 解码核对过 `add`/`host`）；直连链接用服务器地址和本地端口；VLESS + TCP + TLS 带 `allowInsecure=1`；Shadowsocks 三条的加密方式逐项核对（2022-blake3-aes-128/256-gcm）；删掉的协议名和路径（ShadowTLS、Naive、Snell、httpupgrade、trojan-grpc、vmess-grpc、vless-http、vmess-http）在链接里零出现。
- **链接生成 Argo 关 29/29**：19 条链接全在；4 个 CF 链接用 CDN 域名加本地端口、SNI 回到 `addons.mozilla.org`；其余核对项和 Argo 开一样。
- **订阅导出 10/10**：明文 19 条、base64 解码后 19 条且和明文一致；Clash 19 条，4 个 CF 条目都在 `cf.3666888.xyz:443`，VLESS/VMess 的 `servername` 是 Argo 域名（2 条），Trojan 的 `sni` 是 Argo 域名（2 条），VLESS + TCP + TLS 的 Clash 条目有 `skip-cert-verify: true`；订阅文件里有正确的 `/sub` 地址。
- **nginx 配置生成 10/10**：`write_nginx_conf()` 只剩 `/vless-ws-tls`、`/vmess-ws-tls`、`/trojan-ws`、`/trojan-http` 4 个反代位置加 `/sub`；`listen 8080` 没有 `http2`；WS 反代到 8888、Trojan-HTTP 反代到 8891。
- **防火墙 1/1**（一套 TCP+UDP 集合检查）：TCP 放 8881–8899 共 19 个端口加 8080，UDP 只放 8881/8885/8887/8892/8896（Hysteria2、TUIC、Shadowsocks、Shadowsocks 2022 AES-256、Shadowsocks 2022）。
- **sing-box 配置实测 6/6**：官方 sing-box 1.14.4 二进制跑 `sing-box check -C`：真实 `write_base_config` / `write_inbound` / `generate_reality_keys` 生成的**全部 19 个入站配置通过**、**删除全部后的空配置（只有 base）通过**、Hysteria2 / TUIC / Shadowsocks 2022 AES-256 / Shadowsocks 2022 单协议配置各自通过。
- **菜单 8 实测 9/9**：删除 `all`（删空后入站文件清掉、订阅为空、环境文件里是空选择）；删除 `all` 后按 [n] 取消（install.env 和 selected.env 字节不变）；从 18 个（缺 0 号）增加 `all` 装回 19 个；删 `a` 只删第一项（剩 18 个，0 号没了）；删 `b` 只删第二项（剩 18 个，1 号没了）。注意：菜单 8 里刚删掉的协议不能在同一次里再加回来（增加列表是按进菜单时的已装列表算的，这是 v1.0.13 就有的行为，不是 v1.0.14 改的）。
- **nginx 实测 8/8**：真实 nginx 1.24.0（测试实例，端口 18081）跑 `write_nginx_conf()` 生成的配置：`nginx -t` 通过；`/sub` 返回 200，base64 解码后是 19 条链接；`/` 返回 200；`/vless-ws-tls` 返回 502（位置存在、在反代，只是测试机上入站没跑）；删掉的 `/trojan-grpc/`、`/vless-httpupgrade` 不再是反代位置（落到 `/` 返回 200）；**旧配置复现**：`listen … http2` 的配置让 `/sub` 对 HTTP/1.1 客户端失败（和用户 v1.0.11 机器上一样的错误），去掉 http2 的配置正常返回 200。
- **测试里发现、但不在本次改动范围的问题**（脚本里原先就有，v1.0.13 也一样，这次没改）：`write_inbound()` 每调一次就往 `ports.env` 追加一行；如果某段流程写了入站但没经过 `save_install_env()`（它会先清空再重写），`ports.env` 里就会有重复行，`load_install_env()` 再读时会把端口读成多行，`sing-box check` 会报 `jq: invalid JSON text passed to --argjson`、订阅链接里的端口也会断成多行。正常安装和菜单 8 流程都是先写后存，不会触发；测试里是自己搭的恢复流程触发的，已在测试流程里按脚本自己的顺序（写完就存）绕过去了。
- **没法在本机跑的（需用户实测）**：真机完整安装流程；订阅在真实客户端里打开和同步；CF 节点（WS、Trojan-HTTP）在真实客户端实际连通；菜单 8 在真机上的真实交互；Hysteria2 端口跳跃的 NAT 规则在真机上实际生效。

## v1.0.13 测试记录（2026-11-24，测试机上跑的，不是真机完整安装）

测试方法是把真实脚本里的函数抽出来，在测试目录跑（`SB_HOME` 指向 `/tmp/sbtest/home`，nginx 用测试端口 18080/18081，系统 nginx 服务从不启动），不改系统、不装到真机。结果：**159 项检查，全部通过，0 失败**。

- **主测试套件 73/73**：版本/协议数组/`PROTO_CF`/无功能性 http2 残留；27 个协议链接（Argo 开：CF 协议走隧道域名:443、直连协议走服务器 IP:本地端口；Argo 关：CF 协议走 CDN 域名:本地端口；VMess JSON 解码核对、Reality 公钥、Shadowsocks 加密方式逐项核对）；订阅导出 27 条（base64 解码后 27 条全在、无空行、无错位，Clash 26 条、Naive 按规则跳过）与空选择（空文件、无协议提示、退出 0）；协议选择器（`a`/`all`、单个字母、`aa`/`ab`、非法输入、空输入）；防火墙（UDP 只放 0|4|7|9|19|23、TCP 放全部 27 个）；菜单 8 增加 `all`（装齐 27 个）、删除 `all`（删空后入站文件清掉、订阅为空、无协议提示）、删除 `all` 后按 [n] 取消（环境文件字节不变、仍是 27 个）、删除 `a`/`al`/`ALL`/`" all "`/空输入；Hysteria2 端口跳跃（`hopping.env` 写/删）；v1.0.5–v1.0.11 回归清单逐项核对（订阅 reload、gRPC 链接用 Argo 域名、SS2022 直连、菜单 8 的 `all`、端口跳跃、语言默认中文）。
- **nginx 实测 34/34**：真实 nginx 1.24.0（测试实例，端口 18080/18081）跑 `write_nginx_conf()` 生成的配置：`nginx -t` 通过；`listen` 行没有 `http2`；`/sub` 返回 HTTP/1.1 200、内容和订阅文件逐字节一致；`/` 返回 200；9 个反代位置都存在（入站没跑时返回 502，说明位置存在且在反代，不是 404 或配置错误）；**旧配置复现**：`listen … http2` 的配置让 `curl -I /sub` 对 HTTP/1.1 客户端失败（和用户 v1.0.11 机器上一样的 `Received HTTP/0.9` 错误），去掉 http2 的配置正常返回 200。
- **订阅 reload 实测 10/10**：真实 nginx 主进程在跑的两种情况都测过——旧配置在跑（`/sub` 返回旧内容）和主进程在跑、但根本没监听 18080 端口（v1.0.9 的根因场景）——`start_nginx_safe()` 都正确 reload，`/sub` 随后返回 200，没有走到 `systemctl start` 那条空操作路径。
- **cj/sb 链路实测 26/26**：管道来源创建 wrapper、下载失败明确报错（中文+英文、退出 1）、本地完整副本不被覆盖、本地文件运行装完整副本、快捷方式默认中文进菜单、`create_shortcut` 在语言选择之前调用。
- **sing-box 配置实测 16/16**：官方 sing-box 1.14.4 二进制跑 `sing-box check -C`：真实 `write_base_config` / `write_inbound` / `generate_reality_keys` 生成的**全部 27 个入站配置通过**、**删除全部后的空配置（只有 base）通过**、Hysteria2 / TUIC / Snell v6 / Shadowsocks 2022 AES-256 / Shadowsocks 2022 单协议配置各自通过。测试里第一次跑 T7 有 5 项失败，查下来是测试用的假密码不对（Shadowsocks 2022-blake3 密码必须是对应长度的 base64 密钥，测试写了 16 个普通字符），脚本自己的 `make_ss_key` / `make_ss_key_256` 生成的就是正确格式，改成真实格式后全部通过——不是脚本的 bug。
- **没法在本机跑的（需用户实测）**：真机完整安装流程（装二进制、写服务、systemd 启动）；订阅在真实客户端里打开和同步；CF gRPC 节点在真实客户端实际连通；菜单 8 在真机上的真实交互；Hysteria2 端口跳跃的 NAT 规则在真机上实际生效；`raw.githubusercontent.com` 在测试机上曾有一次 20 秒超时（出口代理抖动），不是脚本问题，同一天稍后同一地址又能正常访问。

## v1.0.9 改了什么

- 修 CF 节点全部超时（用户实测：非 CF 节点有延迟、能通，CF 节点全部超时；订阅是跑 `nginx -s reload` 后才通的）：
  - `build_link_for()` / `clash_proxy_for()`：Trojan + gRPC（13 号）、VMess + gRPC（14 号）的链接和 Clash 条目之前用服务器 IP 和本地端口，现改成 `cf_host` / `cf_port`，和 11、12、15、18、19、20 号一样（开 Argo 时是隧道域名:443，没开时是 CDN 优选域名:本地端口）；其余 CF 条目（11、12、15、18、19、20 号）核对过，都已用 `cf_host` / `cf_port`。
  - Shadowsocks 2022 AES-256（17 号）结论：直连。Shadowsocks 没有 WS / HTTP / gRPC 传输，nginx 没法反代、Argo 也没法代理，入站监听 `::`，链接改回直连服务器 IP:本地端口（之前写的是服务器 IP:443，开 Argo 时端口错位，必定不通）；Clash 条目同步改回直连；名字里的 (CF) 保留（历史原因：它替代了 Shadowsocks + WebSocket），但它不走隧道（v1.0.10 起 (CF) 已去掉，见上）。
  - `write_nginx_conf()`：新增 `/vless-httpupgrade`（纯 `http://` 反代，入站没开 TLS）、`/vmess-grpc/` 和 `/trojan-grpc/`（`grpc_pass grpcs://127.0.0.1:端口` + `proxy_ssl_verify off`，入站开了 TLS，普通 `grpc://` 发明文 gRPC 到 TLS 入站上必定失败）三个反代位置；WS / HTTP 入站的反代从 `http://` 改成 `https://127.0.0.1:端口` + `proxy_ssl_verify off`（入站开了自签 TLS，之前纯 `http://` 代理过去握手必定失败）；监听加上 `http2`，让 cloudflared 能用 HTTP/2 明文（h2c）连 nginx，gRPC 需要 HTTP/2，普通 HTTP/1.1 照常可用（**这个判断是错的，v1.0.13 已去掉**：`listen … http2` 会让监听口只认 h2c，普通 HTTP/1.1 请求返回的不是正常 HTTP 响应，订阅 `/sub` 直接坏掉，见 v1.0.13）。
  - 订阅 reload 根因：`start_nginx_safe()` 之前只在“8080 被占且 nginx 在跑”时才 reload；用户那台机器是 nginx 在跑、但根本没监听 8080（旧配置），端口是空的，于是跳过 reload，走到 `systemctl start`——已运行的服务上这一步是空操作，新配置（含 /sub）永不加载，直到用户手动 `nginx -s reload`。现改成：只要有 nginx 进程在跑，写完配置就先 reload 再验证 /sub；只有完全没 nginx 进程时才走 systemd 启动；启动后 /sub 还不通时再 reload 一次。`sb -d` 里订阅开关那处也改成先写配置、再用安全启动（之前先启动、后写配置、从不 reload）；改端口后（`apply_ports_post()`）订阅开着时也 reload 一次。
  - 提醒：CF 节点链接里的 SNI 仍是默认域名（`addons.mozilla.org`），隧道域名的 TLS 由 Cloudflare 终结；如果实测 CF 节点仍超时，优先检查 Argo 隧道域名是否最新、以及客户端是否用隧道域名:443 连接。
- 修 `cj` 调不出菜单（和 CF 修复放进同一版）：
  - 根因 1：wrapper 用 `exec bash <(wget -qO- URL)`，下载失败（网络不通、仓库私有、404）时跑的是空脚本，静默退出 0，没有任何提示，看着像“没有任何反应”。现改成先下载到临时文件、校验非空且以 `#!` 开头且 `bash -n` 通过，失败时明确报错（中文+英文，提示检查网络和仓库是否公开），退出 1。
  - 根因 2：`create_shortcut()` 只在进菜单前调用，用户在一键命令里提前退出（语言选择、检测 IP、自动补装时按 Ctrl+C）就根本没有 `cj`。现改成 `main()` 里 `require_root` 之后、语言选择之前就创建一次（进菜单前仍保留一次调用，函数是幂等的）。
  - 根因 3：`cj` 第一次运行没有语言记录，又卡在语言选择上。现改成：经 `sb` / `cj` 调用（`SB_VIA_SHORTCUT=1`）、且没存过语言、也没加 `-E` / `-C` 时，默认中文直接进菜单，不再问语言；`-E` / `-C` / `--LANGUAGE` 仍可覆盖。
  - 根因 4：本地已有完整脚本文件时，`create_shortcut()` 可能用截断的 `/dev/fd` 复制把它覆盖掉，现改成先复制到临时文件、校验通过才移动到位，校验不过就保留已有的完整本地副本，不再用重新下载的 wrapper 覆盖它（wrapper 只在没有可用本地副本时才写）。
  - cj 完整链路：`cj` → `/usr/local/bin/cj`（`SB_VIA_SHORTCUT=1 exec bash /etc/sing-box/installer.sh`）→ `installer.sh` 是本地完整脚本时直接跑，是重新下载 wrapper 时先下载校验再跑 → `main()` 按语言记录 / 快捷方式默认中文进主菜单。
- CF 节点实际连通、订阅打开、`cj` 实际调用均未在真机上验证（只做了 `bash -n`、链接生成和 nginx 配置生成的单元测试），需要用户实测：菜单 8 重新加 CF 协议、选临时隧道、导出链接检查 CF 节点是不是 Argo 域名:443、客户端实际连通；`cj` 直接进菜单；订阅 `curl http://127.0.0.1:8080/sub`。

## v1.0.8 改了什么

- 菜单 8（增加 / 删除协议，`sb -r`）增加一键安装所有协议：在列出未安装协议后，提示写明输入 `all` 一键安装全部未安装协议；输入 `all` / `ALL`（大小写不限，前后空格也行）时，新增列表 = 全部未安装协议，已安装的保留（keep 列表不变）；空安装时就是安装全部 19 种。单独输入 `a` 还是只选未安装列表里的第 1 个协议，不是全部（`all` 在进入字母解析前就拦截了，不会被拆成字母 `a`+`l`+`l`）。选完后原有的确认列表（保留 + 新增）和按 [n] 取消流程不变，一键全部也要先显示确认列表、等用户确认再执行；之后走原来的确认、端口分配、写站、Argo 询问、重启、订阅流程，和原来选全部时完全一样。提示文字是中英双语（`add_protocols_prompt` 消息键）。
- 菜单 8 一键安装全部未在真机上验证，需要用户实测。

## v1.0.7 改了什么

- 协议重排成 27 种（用户按网速优先、延迟其次确认）：原来第 10 号的 VLESS + Reality (Vision) / XTLS + Reality 移到第 3 号（第 2 号 VLESS + Reality 后面）；走 CF 的协议（原来 11–21 号）按速度重排成 11. VLESS + HTTPUpgrade、12. VLESS + WS + TLS、13. Trojan + gRPC、14. VMess + gRPC、15. Trojan + WS、16. VMess + WS + TLS、17. Shadowsocks 2022 AES-256、18. VLESS + HTTP、19. VMess + HTTP、20. Trojan + HTTP；删掉 VMess + WS (CF)（无 TLS 的纯 WS 版本，在 CF 环境下意义不大）；其他位置不动，序号重排。`PROTO_NAMES` / `PROTO_LINK_NAMES` / `PROTO_TAGS` / `PROTO_CF` 四个数组按新顺序重写（`PROTO_CF`：新 11–20 号为 1），字母 `b`–`z` 对应第 1–25 种、`aa` / `ab` 对应第 26–27 种，`ac` 没有了；`write_inbound()` / `build_link_for()` / `clash_proxy_for()` 三个分支按新编号重排（分支内容逐字节没变，只换编号，删掉 VMess + WS 那条）；Reality 检查（新 1/2/20/22/24/25/26 号）、`sb -d` 的 WS/Reality 判断、XTLS 切换（新 2 号）、Clash 里 Naive 跳过（新 8 号）、nginx 反代位置（删 `/vmess-ws` 那条）全部按新编号换过；`bash -n` 通过，三处分支内容和 v1.0.6 逐字节对过。
- **升级注意：已装过旧版的机器升级到 v1.0.7 后，旧 `install.env` / `selected.env` 里存的是旧协议编号，旧选中的协议会错位，升级后请从菜单 8 重新选一次协议。**新装的机器不受影响。
- 27 个协议的实际生成和连通未在真机上重测（只做了 `bash -n`、分支内容逐字节对照和协议选择解析测试），需要用户实测。

## v1.0.1 改了什么

- 已安装主菜单改成原版 1–12 项：2/3 项按运行状态动态显示“关闭/开启”，6 项同步 Sing-box 和 Argo 两个组件（先分别问是否升级，再分别升级；Sing-box 升级前备份，校验不过回滚旧版本），7 项改成下载运行 tcpx.sh（升级内核、安装 BBR、DD 脚本），10/11/12 项改成安装 ArgoX / sba / TCP brutal。
- 新增快捷命令 `cj`：第一次运行脚本进菜单时就创建 `/usr/local/bin/sb` 和 `/usr/local/bin/cj`，不用等装完，安装时也会再次创建；两个都指向同一个脚本入口；`cj` 不带参数打开主菜单，带参数和 `sb` 一样（`cj -n`、`cj -d`、`cj -s` 等）；卸载时两个一起删。
- `sb -d` 改成原版动态菜单（见上节），Hysteria2 拆成拥塞控制、带宽、Realm、端口跳跃四个独立项，新增 XTLS vision / 多路复用切换；端口修改加预览确认；自定义路由、WARP、Argo 子菜单都按原版的文字、编号和问答流程对过。
- 卸载去掉“确定吗”确认，改成原版的两问（是否卸载 Nginx、是否卸载 fcgiwrap / spawn-fcgi，默认不删）。
- 修了一个 v1.0.0 的 bug：`sb -d` / `sb -r` 在新进程里运行时端口表没恢复（`load_install_env` 现在会从 `ports.env` 恢复独立端口）。

## v1.0.6 改了什么

- CDN 优选域名新增 4 个：`cf.xreak.top`、`cf.3666888.xyz`、`cfsaas.080112.xyz`、`cf.92555.xyz`（`CDN_CANDIDATES` 从 6 个变成 10 个，原有 6 个不动，顺序在最后）。
- 修了走 CF 的节点不通的问题（用户实测：普通节点正常有延迟，走 CF 的节点不通）。原因是 CF 协议的入站只监听在 `127.0.0.1` 上，要靠 nginx 反代 + Argo 隧道才能从外面进来，而菜单 8 加 CF 协议时从不问 Argo、不启动隧道。现在菜单 8 加完协议、写完入站、保存后、导出链接前，如果选了任何走 CF 的协议（10–20 号），自动跳出 Argo 隧道选择：1. 临时隧道（try）、2. 固定隧道（Token）、3. 不启用 Argo。选临时隧道就调 `setup_argo()`、enable + 启动 argo 服务，等隧道分配域名（最多约 30 秒轮询），拿到域名后存到 `WIZ_ARGO_DOMAIN` / `argo_domain`，再导出链接；选固定隧道就按现有流程问 Token、启动 argo；选不启用就明确提示 CF 节点需要 Argo 或 CDN 域名才能访问。已经配好且在运行的隧道不再重复问，只刷新临时域名；配好但停了的直接重启，不再问。
- 临时隧道打通的完整链路：问选择 → `setup_argo()`（装 cloudflared、写 argo-daemon）→ `write_services()`（argo.service 现在写日志到 `/var/log/argo.log`）→ enable + 启动 argo → 轮询 `resolve_try_domain()` 拿域名（读日志，读不到再读 `journalctl -u argo`）→ 域名存下来 → 导出链接时匹配。匹配规则：`build_link_for()` / `clash_proxy_for()` 里，走 CF 的协议（10–18 号）在 Argo 启用且域名已知时，链接的服务器用 Argo 隧道域名、端口用 443（隧道只走 443，查询参数和路径不变）；没启用 Argo 时仍用 CDN 优选域名和本地端口，跟原来一样。19/20 号 gRPC 和 14 号 Shadowsocks 2022 不走这套（nginx 没有对应的反代位置），保持原逻辑。`run_install()` 里的 Argo 询问也补齐了：以前只在 10–13、15–18 号协议时问（漏了 14、19、20 号），现在用 `has_cf_protocol()` 判断 10–20 号，`ask_wizard_argo()` 增加“3. 不启用”选项；完整安装里“是否启用 Argo”和“选哪种隧道”不会重复问两次。
- 修了 nginx 启动失败的根因（用户实测：`nginx -t` 通过，但 `systemctl start nginx` 报 `bind() to 0.0.0.0:8080 failed (98: Address already in use)`，因为一个不在 systemd 管理下的旧 nginx 进程 pid 79018 已占着 8080 且用旧配置）。v1.0.6 新增 `start_nginx_safe()`：先跑 `nginx -t`，8080 已被 nginx 占用就先 `nginx -s reload` 让旧进程加载新配置并验证 `/sub` 能打开，reload 不行再优雅退出旧进程、等端口释放后重起；8080 被非 nginx 程序占用则不杀，打印占用者；启动失败打印 `nginx -t` / `systemctl status nginx` 的关键错误。菜单 8 和 `run_install()` 的订阅启动都用这个安全启动函数。
- `cj` / `sb` 直接进主菜单：语言选择存到 `/etc/sing-box/lang`，下次运行直接用上次的语言（默认中文），不再重复问；`-E` / `-C` / `--LANGUAGE` 仍可改，单项命令（`sb -n`、`cj -d` 等）也用存下来的语言。语言选择里“2. 简体中文”改成黄色显示。

## v1.0.5 改了什么

- 协议名 WebSocket 改成 WS（用户要求，之前要求全称，现改回缩写）：`VLESS + WS + TLS (CF)`、`VMess + WS (CF)`、`VMess + WS + TLS (CF)`、`Trojan + WS (CF)`、`VLESS + WS + Reality`，节点链接后面的名字同步改成 `VLESS-WS-TLS` 等。内部东西不动：`PROTO_TAGS`（`vless-ws-tls` 等）、JSON 里 `transport: {type: "ws"}`、`Sec-WebSocket-Protocol` 头、链接里的 `type=ws` 参数、文件路径 `/vless-ws-tls` 等都是协议格式，不能改。
- 修了菜单 8 加完协议节点不通的问题：原来只做 `svc restart sing-box`，服务没启用过时静默无动作，节点印出来了但端口根本没监听（用户实测 Sing-box: stopped）。现在菜单 8 保存后先确认服务文件存在，再 `svc enable sing-box` + `svc restart sing-box`，启动失败先 `sleep 2` 再 `svc start` 兜底一次，仍不运行就明确报“sing-box 服务保存后启动失败，请用 systemctl status sing-box 检查服务和配置。”`run_install()` 本来就是 enable + start，不用改。
- 修了菜单 8 加完协议订阅不通的问题：空安装默认订阅 `no`，菜单 8 以前不写 nginx 配置、不启动 nginx，`/sub` 链接印出来了却打不开。现在菜单 8 加了协议后自动把订阅改成 `yes`，没装 nginx 就先装（`install_deps nginx`），写 nginx 配置（`write_nginx_conf`，含 WS / HTTP 入站的反向代理），`svc enable nginx` + `svc start nginx`，启动失败报提示。`export_list()` 打印订阅链接时如果 nginx 未运行，会提示“订阅未启动：nginx 未运行，上面这个订阅链接打不开。”

## v1.0.4 改了什么

- 修了 v1.0.3 的一个缺口：自动补装只装了主程序，没生成 `install.env`，菜单 1/5/8 一进去就报“sing-box 尚未安装。”。v1.0.4 新增 `ensure_empty_install_env()`：主程序补装成功后（或主程序本来就已存在但 `install.env` 缺失时）生成空的安装状态——`install.env`（UUID 用 `make_uuid()` 生成、节点名默认 `sing-box-node`、服务器地址用已检测到的公网 IP、起始端口 8881、密码用 `make_password` / `make_ss_key` / `make_ss_key_256` 生成、订阅和 Argo 默认 `no`）、`selected.env`（空数组）、`ports.env`（空文件）；已有 `install.env` 的机器不会被覆盖。
- 光有 `install.env` 还不够，菜单 8 加协议还需要基础配置、证书和密钥，所以同时写好：基础配置 `write_base_config()`（00/02/03/04，无协议）、自签 TLS 证书、Reality 密钥对（`generate_reality_keys()`，私钥存 `reality_private.key`）、systemd / OpenRC 服务文件（只写文件，不启用、不启动）。不写带假协议的配置，不启动服务。
- 菜单 1 空协议时不再只显示一个空列表，会提示“暂无协议，请从菜单 8 增加 / 删除协议里添加”（新增 `no_protocols_yet` 提示）。
- 还修了菜单 8 的一个旧缺口：新进程里 Reality 私钥不在内存中（`load_install_env` 只恢复公钥），加 Reality 协议会写出空私钥导致 `sing-box check` 失败。现在菜单 8 写协议前先从 `reality_private.key` 恢复私钥，没有就生成一次并存下来。
- 菜单 5（`sb -d`）和菜单 8（`sb -r`）在空协议下没有别的硬性检查：`sb -d` 的动态列表里端口、节点名、UUID、服务器地址、指纹等项本来就有，空协议时正常显示；`sb -r` 本来就是先删、再加、最后确认的流程，空协议时直接列出全部 19 种待添加，确认后按新装流程问起始端口和节点名。

## v1.0.3 改了什么

- 首次运行自动补装主程序：`main()` 进菜单前调用新增的 `ensure_core_installed()`，`/etc/sing-box/sing-box` 缺失时自动补装主程序 + cloudflared，不装协议、不写配置、不启动服务；补装成功后重新跑 `refresh_status()`，菜单直接变成已安装的 1–12 项，协议从菜单 8 添加。补装失败留在未安装菜单（1–9 项）并明确报错；cloudflared 补装失败只提示，不中断菜单。
- 关键坑：原来下载主程序的 `install_singbox_binary()` 失败时用 `die` 直接退出整个脚本，v1.0.3 新增不退出的安全版 `install_singbox_binary_safe()`（复用 `latest_sb_tag()` 查最新版、失败回落 1.14.4，和 `fetch_file()` 下载逻辑），每一步失败都 `return 1`，不退出。
- ArgoX / xray 不在首次自动补装范围；`-h`、`-K`/`-L` 快速安装和 `-s`/`-a`/`-t`/`-d`/`-u`/`-n`/`-v`/`-b`/`-r` 等单项动作不受影响，补装只在交互进菜单时跑一次。

## v1.0.2 改了什么

- 修了 v1.0.1 的两个真问题：`cj` / `sb` 只在安装完成时才创建，没装过就根本没有 `cj`，输入 `cj` 会报 command not found；现在第一次运行脚本进菜单时就创建，不用等装完。
- 修了 `create_shortcut()` 用 `cp "$0"` 复制脚本的问题：一键方式 `bash <(wget -qO- 链接)` 运行时 `$0` 是 `/dev/fd/63`，不是真实文件，复制会失败，`installer.sh` 建不出来。现在先试真实文件（`$0`、`${BASH_SOURCE[0]}`），一键方式先试 `cat` 从 `/dev/fd/*` 读出脚本内容，但实测 `cat` 同一个 fd 只拿到未读的尾巴（251KB 的脚本只拿到 24 字节），校验不过就不用这个残缺副本，改成把 `installer.sh` 写成重新下载的 wrapper（`INSTALLER_URL`，即 jiaoben 仓库地址），`sb` / `cj` 每次运行时重新拉取脚本——和原版 `sb.sh` 的做法一样；写完校验 `bash -n` 通过，失败只提示、不中断菜单。
- 已安装菜单 1-9 文字和顺序没动；`main_menu()` 已安装分支里加了 1-9 项中文名的注释，`grep "查看节点信息"` 能在菜单附近搜到。

## 已知限制（v1.0.2）

- 自定义路由和更换 WARP 账户这两项，原版只在 TUN + warp-ep 出站存在时显示；本版没有 TUN 出站，改成“配了 WARP 账户才显示”，规则写进 `03_route.json`、出站固定为 `direct`（原版写进 `08_custom_route.json`、出站为 warp-ep）。
- `rule_set` 规则本版不做原版那种联网校验（原版会去 SagerNet / MetaCubeX 仓库查规则集是否存在），名称按原版规则自动补 `geosite-` 前缀，并按 SagerNet 的地址写入远程规则集定义。
- 节点导出（`sb -n`）仍是 v1.0.0 的简化渲染（链接 + 订阅 + Clash + 二维码），没有原版那种远程模板拉取和双订阅二维码链接。
- `sb -d` 一次改一项后回主菜单（原版改完直接退出脚本）；Argo 修改时输错返回主菜单（原版直接退出脚本）。

- 安装向导里指纹选择放在 Reality 提问之前（原版是在 Reality 流程里问），不影响结果。
- 外部小工具（ArgoX、sba、TCP brutal）是按原版的做法下载并运行第三方脚本，不是本仓库的代码。
- 动态订阅在没有 fcgiwrap 的机器上会回退到静态文件（实际以装机时的表现为准）。
- ShellCheck 只跑了 error 级（0 个 error，53 条 warning，多为未使用变量），warning 没逐条修。
