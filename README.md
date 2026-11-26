# BOSS J 一键安装脚本（v1.0.20）

BOSS J 一键安装 / 管理脚本。菜单、安装流程和命令行用法对标常见的 sing-box 一键脚本，但**代码全部是重新写的**，没有复制原版脚本的代码。

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



>
>
>
>
>
>
>

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

装好后（1–13 + 0）：

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
| 10 | 安装 ArgoX 脚本 (argo + xray) |
| 11 | 安装 sba 脚本 (argo + sing-box) |
| 12 | 安装 TCP brutal |
| 13 | 升级脚本至最新版本（`sb --update-script`） |
| 0 | 退出 |

菜单顶部会显示脚本版本、系统信息（操作系统 / 内核 / 架构 / 虚拟化）、IPv4 / IPv6，以及 Sing-box / Argo / Nginx 的状态、版本、内存占用和流量，整块系统信息都是加粗绿色，系统信息每行之间空一行，不挤在一起。IPv4 / IPv6 后面会显示国家中文名和网络运营商名，三列对齐（IP、国家、运营商，例如 `170.9.26.154         美国          (Oracle Corporation)`，从公开 IP 库查的 ISP 和国家，查不到就不显示，不影响菜单；显示的是网络运营商，不是 VPS 转售品牌——公开库里这段 IP 登记在 Oracle Corporation 名下）。Argo 那一行会显示隧道类型和当前隧道域名：固定隧道显示「（固定隧道 <隧道域名>）」，临时隧道显示「（临时隧道 xxx.trycloudflare.com）」，没开 Argo 就不显示。状态在中文模式下显示为开启 / 关闭 / 未安装（英文模式 Running / Stopped / Not installed）。主菜单底部右下角显示累计运行次数（中文「累计运行 N 次」，英文 `Total runs: N`），每次进菜单加 1，次数存在 `/etc/sing-box/run_count`，重装脚本不丢；单项命令（`sb -n` 等）不计数；节点列表（菜单 1 / `sb -n`）末尾右下角也显示这个次数，只显示、不计数。菜单选项（主菜单和所有子菜单）都是加粗黄色，子菜单标题是加粗绿色，状态/进度行加粗，「请选择：」提示是绿色。

## 安装向导

按顺序问：选协议 → 起始端口（默认 8881，连续分配）→ 服务器地址（默认自动探测的公网 IP）→ UUID（默认随机生成）→ 节点名 → 客户端指纹（chrome / firefox）→ Reality 私钥（有 Reality 协议时，留空自动生成）→ Hysteria2 的 Realm、带宽、端口跳跃（只有选了 Hysteria2 才问）→ CDN 优选域名、订阅开关、Argo（只有选了走 Cloudflare 的协议才问）→ nginx 订阅端口。

## 节点名：默认是 <J>，空格 = 不加前缀

安装向导问节点名时（菜单 5 里改节点名也一样），三种输法：

- **直接回车（什么都不输）**：用默认名 **<J>**，节点显示为「<J> Trojan-WS」「<J> VLESS-WS-TLS」这样。
- **只输一个空格**：不要前缀，节点只显示协议名，例如「Trojan-WS」「VLESS-WS-TLS」，前面没有空格。
- **自己输名字**：就用你输的名字。

只在新安装时用这个默认；已经装好的机器，存着的名字（`install.env` 里的 `WIZ_NODE_NAME`）不会被改掉，菜单 5 里改了才变。

## 协议表（19 种，全称）

协议名用 WS 缩写：WebSocket 写成 WS；Shadowsocks 不写 SS；Hysteria2 不写 Hy2。链接里的 `type=ws`、`type=http`、`ss://` 等是客户端协议格式本身，不能改，不算简写。内部 tag（如 `vless-ws-tls`）只用在配置文件名和 JSON 里。

| 编号 | 字母 | 协议全称 | 内部 tag | 走 Cloudflare | 速度 |
| --- | --- | --- | --- | --- | --- |
| 1 | b | Hysteria2 | hysteria2 | 否 | 442ms（中） |
| 2 | c | VLESS + Reality | vless-reality | 否 | 346ms（中） |
| 3 | d | VLESS + Reality (Vision) / XTLS + Reality | xtls-reality | 否 | 718ms（慢） |
| 4 | e | AnyTLS | anytls | 否 | 462ms（中） |
| 5 | f | TUIC | tuic | 否 | 435ms（中） |
| 6 | g | Trojan | trojan | 否 | 845ms（慢） |
| 7 | h | Shadowsocks | shadowsocks | 否 | 158ms（快） |
| 8 | i | VLESS + WS + TLS (CF) | vless-ws-tls | 是 | 223ms（快） |
| 9 | j | Trojan + WS (CF) | trojan-ws-tls | 是 | 191ms（快） |
| 10 | k | VMess + WS + TLS (CF) | vmess-ws-tls | 是 | 184ms（快） |
| 11 | l | Trojan + HTTP (CF) | trojan-http | 是 | 138ms（快） |
| 12 | m | Shadowsocks 2022 AES-256 | ss2022-256 | 否（直连，不走 CF） | 202ms（快） |
| 13 | n | VLESS + WS + Reality | vless-ws-reality | 否 | 886ms（慢） |
| 14 | o | VLESS + TCP + TLS (Vision) | vless-tls | 否 | 254ms（快） |
| 15 | p | Trojan + Reality | trojan-reality | 否 | 369ms（中） |
| 16 | q | Shadowsocks 2022 | ss2022 | 否 | 659ms（慢） |
| 17 | r | H2 + Reality | h2-reality | 否 | 1232ms（慢） |
| 18 | s | gRPC + Reality | grpc-reality | 否 | 952ms（慢） |
| 19 | t | AnyTLS + Reality | anytls-reality | 否 | 358ms（中） |

速度列是 2026-11-25 用户在 Shadowrocket 上测的参考延迟（<300ms 快，300–600ms 中，>600ms 慢）；实际速度随网络和时间变化。

选协议时：`a` = 全部 19 种；字母 `b`–`t` 对应第 1–19 种；也可以直接输数字 `1`–`19`。可多选，可连写（如 `bcd`）、可空格、可逗号，大写自动转小写。端口按选择顺序从起始端口连续分配（例如起始端口 8881，全选占 8881–8899）。

第 3 号就是 XTLS + Reality（Vision 流控），和第 2 号普通 VLESS + Reality 不重复。


## 替换说明（11–12 号，原来想要的写法在官方 sing-box 上跑不起来）

实测 sing-box 1.14.4 官方二进制：

- **12 号**：原来想要的 Shadowsocks + WS，`shadowsocks` 入站没有 `transport` 字段，写进去 `sing-box check` 会报错。改成官方支持的等价组合 **Shadowsocks 2022 AES-256**（`2022-blake3-aes-256-gcm`，32 字节密钥），菜单和链接都按这个名字写。它不再标注 (CF)、排在 CF 组后面（12 号），因为它没有传输层可供 nginx / Argo 代理，只能直连。
- **11 号**：原来想要的 Trojan + XHTTP，`xhttp` 不是官方 sing-box 的合法传输类型（`unknown transport type: xhttp`，只存在于个别打补丁的 fork 里）。改成官方支持的等价组合 **HTTP 传输**（`type=http`，HTTP/1.1 + H2，路径和 CDN 流程复用 WebSocket 那套），菜单改成 Trojan + HTTP。VLESS + HTTP、VMess + HTTP 本来也是这个替换，但已删掉（走 CF 超时），不在协议表里。

如果坚持要原汁原味的 XHTTP / Shadowsocks + WS，只能换核心（例如带 XHTTP 补丁的 fork 或 Xray-core），不在本脚本“官方 sing-box 二进制”的路线内。其余 17 种已在 sing-box 1.14.4 上逐个 `sing-box check` 通过，19 种合在一起也能通过，实际启动时 19 个入站全部监听。

## CF 节点提速（走 Cloudflare 的 4 个协议）

走 Cloudflare 的 4 个协议（VLESS + WS + TLS、Trojan + WS、VMess + WS + TLS、Trojan + HTTP）做了提速，目标是和原版脚本的 CF 节点一个速度。v1.0.19 先上了多路复用 + TLS 1.3，速度从 50 Mbps 涨到 300 Mbps 左右，但冲上去又往下掉到 200 Mbps，原版 CF 节点稳在 800 Mbps 左右，差距还在；v1.0.20 把 CF 这一段的配置全部按原版对齐：

- **多路复用 + brutal**：这 4 个入站都开了 `multiplex`（多路复用，`padding: true`）和 `brutal`（上行 1000 Mbps / 下行 1000 Mbps）。多路复用让客户端能同时开多条并行流，对高延迟的 Cloudflare 链路很关键；直连协议（其余 15 种）没加，保持原样。v1.0.20 起 brutal 改成有条件开：只有内核装了 brutal 模块（`lsmod` 能查到，或 `modprobe brutal` 能加载）才开，没装就不开，和原版的做法一样，不再写死 `true`。
- **TLS 只用 1.3**：VLESS + WS + TLS、Trojan + WS、Trojan + HTTP 这 3 个入站的 TLS 改成 `min_version: 1.3, max_version: 1.3`；nginx 里这 4 个 CF 位置也加了 `proxy_ssl_protocols TLSv1.3;`；nginx 里原来写的 `proxy_ssl_session_reuse off` 删掉了（用默认的开，WS 长连接建连时可以会话复用）。
- **VMess + WS + TLS 走明文回源**：这个入站的 TLS 关掉了，nginx 到 sing-box 这一跳改成明文 `http://127.0.0.1:端口`（原来是 `https://`）。客户端看到的链接完全没变（还是 `security=tls` / `tls: true`，客户端到 Cloudflare 边缘还是 TLS），只是本机 nginx → sing-box 这一跳不再多做一次 TLS。VLESS + WS + TLS、Trojan + WS、Trojan + HTTP 这 3 个入站的 TLS 保持开启，没动。
- **cloudflared 隧道强制走 HTTP/2（v1.0.20，关键）**：cloudflared 启动时加了 `--edge-ip-version auto --protocol http2`（三个分支：Token、JSON、临时隧道，全部都加）。原版就是这么写的；不加这个参数时 cloudflared 默认 `auto`，优先走 QUIC（UDP 7844），Oracle 到 Cloudflare 边缘这条 UDP 路径有损耗/限速，QUIC 一丢包就退让，速度就从 300 Mbps 掉到 200 Mbps；强制 HTTP/2 走 TCP + BBR，扛丢包能力强得多，能稳住速度。这是 v1.0.19 之后剩下的最大一条差别。
- **其余对齐原版的小项（v1.0.20）**：`max_early_data` 从 2048 改成 2560（4 个 CF 入站、客户端 JSON、ShadowRocket 链接里的 `?ed=` 参数一起改）；4 个 CF 入站的 `listen` 从 `127.0.0.1` 改成 `"::"`；nginx 的 CF 位置补了 `X-Real-IP`、`X-Forwarded-For`、`proxy_redirect off`，3 个 WS 位置还加了 WS 守卫（非 WebSocket 请求直接返回 404）。

上面协议表里的速度列还是 2026-11-25 在 Shadowrocket 上测的旧数据（CF 节点测速时还没做这个提速）；提速后的实际速度需要重新实测。

## 固定隧道域名自动识别

固定隧道（Token 方式）的域名不用再手动填、脚本里也不写死任何域名。配好 Token、Argo 启动后，脚本自动从 Argo 日志里读最新的 `Updated to new configuration` 那一行，取出 ingress 里的 `hostname`（一个 Token 对应一个隧道、一个域名，换 Token 就换域名），存到 `install.env` 的 `WIZ_ARGO_DOMAIN` 和 `/etc/sing-box/argo_domain`，再重新输出节点列表。菜单里 Argo 那一行就会显示「（固定隧道 <隧道域名>）」。如果日志里读不到域名，就保持原来的值不变，不影响安装流程。

> 注意：Cloudflare 后台那个隧道的 Public Hostname 的 Service 必须填 `http://localhost:8080`（nginx 订阅端口），填成别的端口（例如后台随机显示的端口）订阅会返回 502，CF 节点不通。这是后台设置，不是脚本能改的。

## Hysteria2：带宽和端口跳跃

选了 Hysteria2 后，安装向导中途（Realm 问完、进 CDN / 订阅之前）会依次问：

1. **带宽**：上行/下行，单位 Mbps，例如 `200/1000`，直接回车用默认 200/1000（新安装才用这个默认；已装好的机器存着的 100/100 不变）。装好后用 `sb -d` 第 12 项也能改。
2. **端口跳跃**：直接问范围，例如 `20000:21000`，**直接回车跳过，不用端口跳跃**。输了范围才开启，范围须在 10000–65535 之间、起始小于结束，支持 `起始:结束` 和 `起始-结束` 两种写法。

问范围之前会先打印一页说明：有些运营商会限速或阻断单个 UDP 端口，端口跳跃把流量分散到一段 UDP 端口上；推荐用 1000 个左右的端口；NAT 小鸡能用的端口一般只有 20–30 个，填了没开放的端口会导致节点不通，请慎用；默认不开启。

## Argo 凭证指引

选 Token / JSON / Cloudflare API 时，脚本会先打印分步指引：去 https://dash.cloudflare.com/ ，Zero Trust > 网络 > 连接器，创建隧道并选择 Cloudflared，Token 就显示在那里；或者用已建隧道的 JSON 凭证；或者用 Cloudflare API 令牌（https://dash.cloudflare.com/profile/api-tokens > 创建令牌 > 创建自定义令牌），授予：帐户 > Cloudflare One 连接器：Cloudflared > 编辑，以及区域 > DNS > 编辑；帐户资源包括你的账户，区域资源包括特定区域的域名。权限不够时 API 调用会失败。

## 订阅和 Clash

- 订阅链接：`http://<服务器地址>:<nginx 端口>/sub`，文件在 `/etc/sing-box/subscribe/`（明文 `list_plain.txt`、base64 `list.txt`、Clash `clash.yaml`）。
- `clash.yaml` 是逐协议完整展开版：`proxies` 里按协议逐个写 VLESS / VMess / Trojan / Hysteria2 / Shadowsocks / TUIC / AnyTLS 等条目，`proxy-groups` 里有 PROXY 分组，`rules` 是 `MATCH,PROXY`。
- 动态订阅（`--SUBSCRIBE dynamic` 或 `sb -d` 第 9 项）：nginx 按请求 Host 实时渲染，直连节点的 server 跟随访问地址，WebSocket / CDN / Argo 节点保持原地址不变。

## 分客户端订阅

除了通用订阅 `/sub`（base64 链接列表，所有客户端都能导入），还按客户端分了订阅地址，都在同一个订阅服务器上（端口还是 nginx 订阅端口，默认 8080），`/sub` 本身完全没变、照常用：

| 客户端 | 订阅地址 | 格式 |
| --- | --- | --- |
| 订阅中心（索引页） | `http://<服务器>:<端口>/sub/index` | 网页，列出下面所有地址 + 二维码 |
| 通用 / V2rayN | `http://<服务器>:<端口>/sub/v2rayn` | base64 链接列表（和 `/sub` 一样） |
| Throne | `http://<服务器>:<端口>/sub/throne` | base64 链接列表 |
| ShadowRocket | `http://<服务器>:<端口>/sub/shadowrocket` | base64 链接列表（ShadowRocket 专用格式，WS 节点带 obfs/peer 参数） |
| Clash / Mihomo | `http://<服务器>:<端口>/sub/clash` | Clash YAML（`proxies` + PROXY 分组） |
| Clash 2 | `http://<服务器>:<端口>/sub/clash2` | Clash YAML（加自动测速分组 + TUN + DNS） |
| sing-box（SFI / SFA / SFM） | `http://<服务器>:<端口>/sub/sing-box` | sing-box 客户端 JSON（TUN + 混合入站 + proxy 选择器 + direct/block 出站 + 路由） |
| 自适应 | `http://<服务器>:<端口>/sub/auto` | 按客户端 User-Agent 自动返回对应格式（见下） |
| 二维码 | `http://<服务器>:<端口>/sub/qr` | 订阅二维码图片（纯黑白，见下） |

- **为什么要分客户端**：通用 base64 订阅在 ShadowRocket / V2rayN 里直接能导入，但 Clash / Mihomo 读不了 base64 链接，必须给 YAML；sing-box 客户端用专用 JSON 更稳。所以补了这套，通用订阅本身不动。
- **自适应 `/sub/auto` 的识别规则**（按请求里的 User-Agent）：含 `clash` 或 `mihomo` → Clash YAML；含 `sing-box`、`sfa`、`sfi`、`sfm` → sing-box JSON；含 `shadowrocket` → ShadowRocket 格式；含 `throne` → Throne（base64）；其他（包括没带 User-Agent 的）→ 通用 base64。匹配不区分大小写。
- **节点链接格式**：V2rayN / Throne 用标准链接（和通用订阅一样）；ShadowRocket 用 base64 编码的链接，VLESS + WS + TLS 和 Trojan + WS 这两个 WS 节点额外带 `obfs=websocket&obfsParam=<隧道域名>&tls=1&peer=<隧道域名>&path=...?ed=2560`；Clash / Mihomo 用 YAML proxy 条目（WS 的 `ws-opts` 路径 + Host 头、`max-early-data 2560`、`early-data-header-name Sec-WebSocket-Protocol`）。
- **CF 自动切换同样适用**：全部已装协议都是 CF 协议时，分客户端链接里的服务器也用隧道域名；否则用优选域名；SNI/Host 始终是隧道域名。和通用订阅、Clash 的逻辑完全一致。
- **订阅中心页**：`/sub/index` 是个网页，列出上面所有订阅地址，点开就能复制；下面有个订阅二维码，扫码导入通用订阅。
- **二维码要求**：纯黑（#000000）白（#FFFFFF）高对比，没有灰色抗锯齿、没有模糊，边缘锐利；用 `qrencode` 生成，图片里只有 0 和 255 两种灰度值；生成后会用解码工具验证能扫出正确的订阅地址。
- **qrencode 自动安装**：脚本启动时检查 `qrencode` 在不在，没有就自动装（Debian/Ubuntu 用 apt-get，CentOS/Fedora 用 dnf/yum，Alpine 用 apk，Arch 用 pacman）；装不上也不报错、不中断脚本，只是二维码那时还显示不出来，和以前一样。
- **自动刷新同样适用**：临时隧道域名变了，`sb --sync-argo`（和每 5 分钟的定时器）重新生成订阅时，分客户端的文件（Clash / Clash 2 / sing-box JSON / ShadowRocket / 索引页 / 二维码）会一起重新生成，不只是 `list.txt`。
- **节点列表里也能看到**：菜单 1 / `sb -n` 的节点列表末尾，在通用订阅链接下面有一节「Per-client subscriptions:」，列出上面这些地址。

## 每个节点的分客户端链接

菜单 1 / `sb -n` 的节点列表里，除了上面那一节订阅地址，还多了一节「Per-node links by client:」：每个已装节点按客户端分组列出自己的链接，方便直接复制单个节点的链接，不用再去订阅里找：

- **V2rayN**：标准链接（和节点列表顶部的主列表一样）。
- **ShadowRocket**：base64 编码的链接（ShadowRocket 专用格式；VLESS + WS + TLS 和 Trojan + WS 这两个 WS 节点带 `obfs=websocket&obfsParam=<隧道域名>&tls=1&peer=<隧道域名>&path=...?ed=2560`）。
- **Clash**：Mihomo YAML proxy 条目（和 `/sub/clash` 里同一个节点的条目一样）。

每组前面有客户端名标题，组和组之间、各节之间都空好几行，不挤在一起；所有链接（节点链接、订阅地址、分客户端链接）都是绿色加粗显示。这一节只影响终端显示，不改订阅文件：`list.txt` / `list_plain.txt` 里还是只有标准链接，没有分客户端内容。

## 升级脚本（菜单 13 / `sb --update-script`）

菜单 6（`sb -v`）只同步 sing-box 和 Argo（cloudflared）的**二进制**，不更新脚本本身——所以以前菜单 6 跑完，脚本版本永远不变。现在脚本升级是独立的菜单项：

- **菜单 13「升级脚本至最新版本」**（或命令行 `sb --update-script`）：从仓库拉最新 `sing-box.sh`（`https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh`），用 `bash -n` 校验语法、确认版本号和**装在机器上的**版本不一样，才备份当前 `/etc/sing-box/installer.sh`（备份名带旧版本号），替换成新版，再**重新生成全部配置**（全部入站 + nginx 配置，校验通过后重载 sing-box 和 nginx），最后重新输出一次节点列表、重新生成订阅；已经是最新版就直接提示，不动任何文件。
- **升级脚本不丢配置**：`install.env` / `selected.env` / `ports.env`、UUID、端口、隧道都不动，只换脚本文件本身；新脚本下次运行 `sb` 时生效。
- **v1.0.20 修了 13 的一个 bug**：旧版拿下载的新版本号跟**正在运行的**脚本版本比。用一键命令跑时，正在运行的脚本就是刚从仓库下载的最新版，两个版本号一样，13 就以为“已经是最新版”直接退出，机器上装的旧脚本根本没换（实测：机器上还是 1.0.18，13 却显示“已经是 19”）。现在 13 直接读机器上装的那个文件的版本号来比，不一样就换；换完还会重新生成配置（不只是重新生成订阅链接），这样多路复用、TLS 1.3 这些配置层面的改动升级后立刻生效，不用再手动重装或进菜单 5/8/4 触发一次。
- **下载失败不破坏**：仓库没公开、网络不通或下载到的文件校验不过，都会直接提示失败、保持当前版本，不会把脚本换成坏的。
- 菜单 6 的行为没变：还是只同步二进制，不碰脚本。

## Argo 升级下载修复

菜单 6 里同步 Argo（cloudflared）时，旧版把下载地址拼成了 `.../releases/download/v<版本号>/cloudflared-linux-amd64`，多加了一个 `v`；但 Cloudflare 官方 release 的 tag 本来就没有 `v`（例如 `2026.11.2`），所以那个地址一直返回 404，显示「下载失败」。现在直接用 GitHub API 返回的 `tag_name`（原样，不加 `v`），优先用 API 里对应文件的 `browser_download_url`；菜单上「最新版本」那一行也不再多写一个 `v`。修正后的地址实测返回 302（文件存在），旧的带 `v` 地址返回 404。

## 修改配置（`sb -d`）

和原版一样是动态菜单，只显示和当前安装有关的项，按原版顺序排，每项后面都显示当前值（中文模式下写成「（当前：X）」）；子菜单选项列表加粗黄色显示，「请选择：」提示是绿色；一次改一项，改完回主菜单，输错数字显示“未做任何修改”并返回：

1. 优选域名/IP（只有装了 WebSocket 类协议才显示；进去后列表里当前用的后面标「（当前）」，直接回车保持不变；候选共 13 个：skk.moe、ip.sb、time.is、bestcf.top、cdn.2020111.xyz、cf.090227.xyz、cf.xreak.top、cf.3666888.xyz（默认）、cfsaas.080112.xyz、cf.92555.xyz、xn--b6gac.eu.org、cfvip.cf.3666888.xyz、fn.130519.xyz）
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
sb --update-script    升级脚本至最新版本（菜单 13）
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

## v1.0.20 改了什么

- **CF 配置全部按原版对齐（关键）**：v1.0.19 的多路复用 + TLS 1.3 让 CF 速度从 50 Mbps 涨到 300 Mbps 左右，但冲上去又往下掉到 200 Mbps，原版 CF 节点稳在 800 Mbps 左右；逐行对比后发现剩下的差距在 cloudflared 到 Cloudflare 边缘这一段，v1.0.20 把 CF 这一段全部按原版改了（见上面「CF 节点提速」一节）：cloudflared 强制 `--edge-ip-version auto --protocol http2`（TCP + BBR，不再走 QUIC）；`max_early_data` 2048 → 2560；nginx 删掉 `proxy_ssl_session_reuse off`；4 个 CF 入站 `listen` 改成 `"::"`；nginx 的 CF 位置补了 `X-Real-IP` / `X-Forwarded-For` / `proxy_redirect off` + WS 守卫；brutal 改成有条件开（内核有模块才开）。客户端链接完全没变，SNI/Host、优选域名、端口、UUID 都没动；直连协议（其余 15 种）的代码一个字节没改。
- **IPv4 三列对齐**：系统信息里 IPv4 / IPv6 那一行改成 `IP 国家 （运营商）` 三列对齐，例如 `170.9.26.154         美国          (Oracle Corporation)`；用固定宽度排，不管 IP 长短，国家和运营商那两列都对得齐。国家和运营商还是从公开 IP 库查的，查不到就不显示，不影响菜单；别的系统信息行没动。
- **菜单 13 修好了**：以前用一键命令跑、点 13 会显示“已经是最新版”，但机器上装的还是旧版（见上面「升级脚本」一节）；现在 13 直接读机器上装的那个文件的版本号来比，不一样就换，换完还会重新生成全部配置（不只是重新生成订阅链接），这样多路复用、TLS 1.3 这些配置层面的改动升级后立刻生效。
- **其余 v1.0.19 的功能都没动**：协议表（19 种、顺序不变）、菜单（13 项、顺序不变）、订阅生成、分客户端订阅、分客户端节点链接、二维码逻辑、固定隧道域名自动识别、qrencode 自动安装、Argo 升级下载修复、节点名 `<J>` 默认、链接绿色加粗、链接之间 3 个空行，都原样保留。v1.0.20 只改了上面这 8 项（6 个 CF 对齐 + IPv4 布局 + 菜单 13 修复）。
- **升级注意：从 v1.0.19 升级到 v1.0.20，协议编号没变，不用重新选协议；从 v1.0.13 及更早版本升级的机器，旧 `install.env` / `selected.env` 里存的是旧协议编号，升级后请从菜单 8 重新选一次协议；全新安装不受影响。**
- 测试：按用户要求做了全面测试，并专门测了新代码和 v1.0.19 各功能的冲突点，见下面的测试记录；真机完整安装、订阅在真实客户端里打开和同步、CF 节点实际连通和提速后的真实速度仍需用户实测——用户已确认：先按这个方案做，做好后他再测试，网速确定上来、和原版 CF 节点一个水平，才正式发布新版。

## v1.0.20 测试记录

测试方法是把真实脚本里的函数抽出来，在测试目录跑（`SB_HOME` 指向测试目录，不用系统服务；TLS 证书用 `openssl` 自签在 `/etc/sing-box/`，和真实安装一致），不改系统、不装到真机；菜单用 pty 沙箱跑真实脚本、从原始 ANSI 流里检查；订阅端点用测试 nginx（端口 18080，真实 v1.0.20 配置）+ 真实 sing-box 1.14.4 二进制跑。结果：**结构 + 单元测试 162 项全部通过，0 失败；端点 + 冲突测试 211 项全部通过，0 失败；二维码测试通过；sing-box 1.14.4 校验通过；pty 菜单测试通过**。

- **结构 + 单元测试 162 项**：`bash -n` 通过；版本 v1.0.20 (2026.11.26)；第三方作者名还是 2 处，都是 ArgoX / sba 的功能性下载链接；脚本里没有任何写死的隧道域名。
  - **cloudflared 强制 HTTP/2**：`write_argo_daemon` 三个分支（Token、JSON、临时隧道）+ OpenRC `command_args`，共 4 处，都有 `--edge-ip-version auto --protocol http2`；`--no-autoupdate` 和原来的 token/config/url 参数都还在。
  - **max_early_data 2560**：3 个服务端 WS 入站、3 个客户端 JSON、2 个 ShadowRocket `?ed=` 链接，都是 2560，没有残留的 2048。
  - **nginx**：`proxy_ssl_session_reuse off` 是 0 处（已删掉）；4 个 CF 位置都有 `proxy_ssl_protocols TLSv1.3;`；CF 位置有 `X-Real-IP` / `X-Forwarded-For` / `proxy_redirect off`；3 个 WS 位置有 WS 守卫（非 WebSocket 请求返回 404，Trojan-HTTP 不加）。
  - **listen `"::"`**：4 个 CF 入站的 `listen` 都是 `"::"`；直连协议的 `listen` 没动。
  - **brutal 有条件开**：`check_brutal()` 存在（`lsmod` 查模块，查不到就试 `modprobe brutal`），4 个 CF 入站用 `--argjson brutal_enabled "${IS_BRUTAL:-false}"`；没装模块的机器上 brutal 是关的，和原版一致。
  - **IPv4 三列对齐**：`print_header()` 里 IPv4 行用 `printf %-20s %-15s`，IP、国家、运营商三列对齐；国家还是 `country_zh()` 映射的中文名，运营商还是 `provider_for_ip()` 查的；查不到国家时只显示运营商，不影响菜单。
  - **菜单 13 修复**：`update_script` 读 `${SB_HOME}/installer.sh` 的 `MY_VERSION` 作 `installed_ver` 比较（读不到才回退 `$MY_VERSION`），备份名用 `installed_ver`；替换后重新生成配置（`write_inbound` 循环 + `write_nginx_conf` + `save_install_env`，`check_config` 通过后 `svc reload sing-box` / `svc reload nginx`），再 `export_list`。模拟测试：一键命令跑 v1.0.20、机器上装 v1.0.19 时，13 正确升级到 v1.0.20、生成 `installer.sh.bak-v1.0.19`、CF 入站含 multiplex、nginx 含 `proxy_ssl_protocols`、订阅仍是 19 条链接；同版本已装时拒绝替换、不生成备份。`save_install_env` 必须在 `write_inbound` 循环之后调用（先保存再写会留下重复行，已按菜单 8 的顺序修正并验证 `ports.env` 干净，19 行、无重复）。
  - **生成**：19 协议全装时 `list.txt` / ShadowRocket 都是 19 条链接，Clash 19 个 proxy、sing-box JSON 19 个出站，索引页有全部订阅地址和二维码图片，`qr.png` 存在；CF 链接还是 `cf.3666888.xyz:443`、SNI 是隧道域名。
- **端点 + 冲突测试 211 项全部通过**：
  - **C1 nginx + 误报修复**：和 v1.0.19 一样，模拟 nginx 启动慢 → 返回 0、不报「订阅（nginx）自动启用失败」；模拟真的坏了 → 返回 1、照常报警。
  - **C2 节点列表 + 运行次数 + 节点名**：运行次数显示在节点列表末尾、分客户端一节之后，只显示、不计数；节点名 `<J>`、自定义名、空格（不加前缀）在通用订阅、ShadowRocket、Clash、sing-box JSON 四种格式里都正确渲染。
  - **C3 CF 自动切换**：只选 4 个 CF 协议时，四种格式的 CF 链接服务器都是隧道域名；混装直连协议时 CF 链接服务器是优选域名、直连节点用服务器 IP。
  - **C4 自动刷新**：模拟临时隧道域名轮换后，`sync_argo_domain` 更新 `install.env` + `argo_domain`，并重新生成全部订阅文件；索引页和二维码也重新生成，二维码仍能解出正确的订阅地址。
  - **C6 地址冲突**：9 个分客户端路径和 `/sub`、4 个 CF 路径都不重名；配置里 `/sub` 只有一个前缀路径、每个分客户端路径恰好一个精确路径、CF 路径还是 4 个；实测 `/sub` 返回 `list.txt`、`/sub/index` 返回索引页、CF 路径返回 CF 入站响应，互不干扰；4 个 CF 路径真实跑通（WS 类返回 400，Trojan-HTTP 的连接确实到达了入站）。
  - **C7 v1.0.19 新增项（回归）**：菜单 6 不碰 `installer.sh`、不调 `update_script`，`update_script` 不升级二进制、两者互不干扰；Argo 下载地址修正后实测返回 **302**，旧的带 `v` 地址返回 **404**；分客户端节点链接只出现在显示文件里，订阅数据文件里没有；显示文件里的链接是绿色加粗。
  - **C8 v1.0.20 回归（没动的东西）**：协议表（`PROTO_NAMES` / `PROTO_TAGS` / `PROTO_CF`）和 v1.0.19 一模一样，19 种、顺序不变；15 个直连入站的代码和 v1.0.19 一个字节没改；脚本里没有写死的隧道域名；第三方作者名还是 2 处；菜单还是 13 项（1–13 + 0 退出）；默认节点名还是 `<J>`；链接之间还是 3 个空行；链接还是绿色加粗；Argo 升级下载修复还在；二维码逻辑还在；分客户端节点链接还在（19/19/19）。
  - **C9 菜单 13 功能测试**：模拟一键命令跑新版、机器上装旧版时，13 升级已装脚本、生成备份、重新生成配置（CF 入站含 multiplex、nginx 含 `proxy_ssl_protocols`）、订阅仍是 19 条；同版本已装时拒绝替换、无备份；下载失败时保持当前版本、不破坏脚本。
- **二维码**：330×330 纯黑白图，灰度值只有 0 和 255（无灰色抗锯齿）；`zbarimg` 解码得到正确的订阅地址 `http://127.0.0.1:18080/sub`。
- **sing-box 校验**：19 个入站全装的配置（`00_base.json` + 19 个 `01_*_inbounds.json` + 出站/路由/实验配置）用真实 sing-box 1.14.4 二进制 `sing-box check` 通过；分客户端 sing-box JSON 也通过。
- **pty 菜单测试通过**：pty 沙箱跑真实脚本，主菜单正常显示 13 项 + 退出；系统信息里 IPv4 是三列对齐（IP、国家、运营商），每行之间有空行；Argo 那一行显示隧道域名和隧道类型；节点列表文件里节点名是 `<J>`；链接是绿色加粗；右下角显示累计运行次数。
- **实测验证的行为**：WS 守卫 plain GET → 404、真实 WS 升级 → 101（直通 sing-box）。
- **没法在本机跑的（需用户实测）**：真机完整安装流程；订阅在真实客户端里打开和同步（ShadowRocket / Clash / sing-box / V2rayN / Throne）；CF 节点在真实客户端实际连通；**CF 提速后的真实速度（这是 v1.0.20 最关键的一项，必须在真机上和原版 CF 节点对比实测）**；菜单 5 / 菜单 8 / 菜单 13 在真机上的真实交互；`sb --sync-argo` 定时器在真机上 5 分钟一跑、临时隧道换域名时自动更新订阅；固定隧道域名自动识别在真机上（配 Token 后日志里读出真实隧道域名）；IPv4 三列对齐在真机上显示（例如 `170.9.26.154         美国          (Oracle Corporation)`）。

## 已知限制

- 自定义路由和更换 WARP 账户这两项，原版只在 TUN + warp-ep 出站存在时显示；本版没有 TUN 出站，改成“配了 WARP 账户才显示”，规则写进 `03_route.json`、出站固定为 `direct`（原版写进 `08_custom_route.json`、出站为 warp-ep）。
- `rule_set` 规则本版不做原版那种联网校验（原版会去 SagerNet / MetaCubeX 仓库查规则集是否存在），名称按原版规则自动补 `geosite-` 前缀，并按 SagerNet 的地址写入远程规则集定义。
- 节点导出（`sb -n`）仍是简化渲染（链接 + 订阅 + Clash + 二维码），没有原版那种远程模板拉取和双订阅二维码链接。
- `sb -d` 一次改一项后回主菜单（原版改完直接退出脚本）；Argo 修改时输错返回主菜单（原版直接退出脚本）。
- 安装向导里指纹选择放在 Reality 提问之前（原版是在 Reality 流程里问），不影响结果。
- 外部小工具（ArgoX、sba、TCP brutal）是按原版的做法下载并运行第三方脚本，不是本仓库的代码。
- 动态订阅在没有 fcgiwrap 的机器上会回退到静态文件（实际以装机时的表现为准）。
- ShellCheck 只跑了 error 级（0 个 error，53 条 warning，多为未使用变量），warning 没逐条修。
- `ports.env` 可能出现重复行：`write_inbound()` 每调一次就往 `ports.env` 追加一行，如果某段流程写了入站但没经过 `save_install_env()`（它会先清空再重写），`ports.env` 里就会有重复行，`load_install_env()` 再读时会把端口读成多行，`sing-box check` 会报 `jq: invalid JSON text passed to --argjson`、订阅链接里的端口也会断成多行。正常安装和菜单 8 流程都是先写后存，不会触发。
- 菜单 8 里刚删掉的协议不能在同一次里再加回来（增加列表是按进菜单时的已装列表算的）。
