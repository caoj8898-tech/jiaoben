# BOSS J 一键安装脚本（v1.0.23）

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

走 Cloudflare 的 4 个协议（VLESS + WS + TLS、Trojan + WS、VMess + WS + TLS、Trojan + HTTP）的配置全部按原版脚本对齐，目标是和原版 CF 节点一个速度：

- **多路复用 + brutal**：这 4 个入站都开了 `multiplex`（多路复用，`padding: true`）和 `brutal`（上行 1000 Mbps / 下行 1000 Mbps）。多路复用让客户端能同时开多条并行流，对高延迟的 Cloudflare 链路很关键；直连协议（其余 15 种）没加，保持原样。brutal 是有条件开：只有内核装了 brutal 模块（`lsmod` 能查到，或 `modprobe brutal` 能加载）才开，没装就不开，和原版的做法一样，不写死 `true`。
- **TLS 只用 1.3**：VLESS + WS + TLS、Trojan + WS、Trojan + HTTP 这 3 个入站的 TLS 改成 `min_version: 1.3, max_version: 1.3`；nginx 里这 4 个 CF 位置也加了 `proxy_ssl_protocols TLSv1.3;`；nginx 里原来写的 `proxy_ssl_session_reuse off` 删掉了（用默认的开，WS 长连接建连时可以会话复用）。
- **VMess + WS + TLS 走明文回源**：这个入站的 TLS 关掉了，nginx 到 sing-box 这一跳改成明文 `http://127.0.0.1:端口`（原来是 `https://`）。客户端看到的链接完全没变（还是 `security=tls` / `tls: true`，客户端到 Cloudflare 边缘还是 TLS），只是本机 nginx → sing-box 这一跳不再多做一次 TLS。VLESS + WS + TLS、Trojan + WS、Trojan + HTTP 这 3 个入站的 TLS 保持开启，没动。
- **cloudflared 隧道强制走 HTTP/2（关键）**：cloudflared 启动时加了 `--edge-ip-version auto --protocol http2`（三个分支：Token、JSON、临时隧道，全部都加）。原版就是这么写的；不加这个参数时 cloudflared 默认 `auto`，优先走 QUIC（UDP 7844），Oracle 到 Cloudflare 边缘这条 UDP 路径有损耗/限速，QUIC 一丢包就退让，速度就从 300 Mbps 掉到 200 Mbps；强制 HTTP/2 走 TCP + BBR，扛丢包能力强得多，能稳住速度。
- **其余对齐原版的小项**：`max_early_data` 是 2560（4 个 CF 入站、客户端 JSON、ShadowRocket 链接里的 `?ed=` 参数都是 2560）；4 个 CF 入站的 `listen` 是 `"::"`；nginx 的 CF 位置有 `X-Real-IP`、`X-Forwarded-For`、`proxy_redirect off`，3 个 WS 位置还有 WS 守卫（非 WebSocket 请求直接返回 404）。

上面协议表里的速度列还是 2026-11-25 在 Shadowrocket 上测的旧数据（CF 节点测速时还没做这个提速）；提速后的实际速度需要重新实测。2026-11-27 早上用户在 Oracle 服务器上用 v1.0.20 的 VLESS + WS + TLS 在 fast.com 上测出 **1.1 Gbps**，和原版 CF 节点的峰值持平；服务端 CF 配置自 v1.0.20 起没改，这个速度就是当前版本的水平。

**客户端订阅里的多路复用**：服务端入站的多路复用从 v1.0.19 就有了，但订阅文件里一直没给客户端配，导致用 sing-box 官方客户端（SFI / SFA / SFM）和 Clash / Mihomo 时，CF 节点不开多路复用。订阅文件里这一块也按原版补上了：

- **sing-box JSON（`/sub/sing-box`）**：4 个 CF 出站（VLESS + WS + TLS、Trojan + WS、VMess + WS + TLS、Trojan + HTTP）都加了 `"multiplex": {"enabled": true, "protocol": "h2mux", "max_streams": 16, "padding": true, "brutal": {"enabled": <是否可用>, "up_mbps": 1000, "down_mbps": 1000}}`，和原版的格式一样；直连协议（其余 15 种）的出站没加。
- **Clash YAML（`/sub/clash`、`/sub/clash2`）**：4 个 CF 代理都加了 `smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }` 和 `brutal-opts: { enabled: <是否可用>, up: '1000 Mbps', down: '1000 Mbps' }`；直连代理没加。
- **brutal 开关和服务端一致**：订阅里的 brutal 开关用的是同一个判定（`check_brutal()`：内核有 brutal 模块才开，没有就不开），不是写死的 `true`；每次重新生成订阅（菜单 1 / `sb -n`、菜单 5、菜单 8、菜单 13 升级、`sb --sync-argo`）之前都会先刷新一次这个判定，所以订阅里的值永远和服务端入站里的值一致。
- **分享链接没动**：`vless://`、`vmess://`、`trojan://` 这些链接里原版也没有 mux 参数，我们的也没加，ShadowRocket / V2rayN 用的链接和以前完全一样。

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
- **节点链接格式**：V2rayN / Throne 用标准链接（和通用订阅一样）；ShadowRocket 用 base64 编码的链接，VLESS + WS + TLS 和 Trojan + WS 这两个 WS 节点额外带 `obfs=websocket&obfsParam=<隧道域名>&tls=1&peer=<隧道域名>&path=...?ed=2560`；Clash / Mihomo 用 YAML proxy 条目（WS 的 `ws-opts` 路径 + Host 头、`max-early-data 2560`、`early-data-header-name Sec-WebSocket-Protocol`），4 个 CF 代理还带 `smux` + `brutal-opts`（多路复用，见上面「CF 节点提速」一节）；sing-box JSON 的 4 个 CF 出站带 `multiplex`（同样见上）。
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
- **重新生成用的是新版代码**：替换完脚本文件后，重新生成这一步是重新执行**新版**脚本来做的（内部入口 `--post-update`），不是用内存里还没换掉的旧代码。以前是旧代码在内存里直接重新生成，新版的格式改动（例如订阅里的 multiplex）要等下次运行 `sb -n` 才生效，升级当时生成的订阅还是旧格式；现在升级完立刻就是新格式。
- **重新生成失败会回滚、不假装成功**：重新生成的每一步（写全部入站、写 nginx 配置、保存配置、校验配置、重载、重新生成订阅）都检查结果；`sing-box check` 校验不过、或任何一步失败，都会把失败原因打出来、把备份的旧脚本和旧配置（入站配置、订阅文件、端口记录、nginx 配置）恢复回来，再明确提示「本次升级已回滚，当前仍是旧版脚本」，绝不打印成功提示。如果机器上还没有已装的配置（没有协议），只换脚本文件，提示没有配置需要重新生成。
- **注意：这个修法只对装了 v1.0.23 之后的升级生效**。从 v1.0.21 升到 v1.0.23 这一次，重新生成还是旧代码做的（旧代码里没有这个修法），升完请再跑一次 `sb -n`，让新代码重新生成一次订阅；之后再升级就不用了。
- **升级脚本不丢配置**：`install.env` / `selected.env` / `ports.env`、UUID、端口、隧道都不动，只换脚本文件本身；新脚本下次运行 `sb` 时生效。
- **13 比的是装在机器上的版本**：以前拿下载的新版本号跟**正在运行的**脚本版本比。用一键命令跑时，正在运行的脚本就是刚从仓库下载的最新版，两个版本号一样，13 就以为“已经是最新版”直接退出，机器上装的旧脚本根本没换（实测：机器上还是 1.0.18，13 却显示“已经是 19”）。现在 13 直接读机器上装的那个文件的版本号来比，不一样就换；换完还会重新生成配置（不只是重新生成订阅链接），这样多路复用、TLS 1.3 这些配置层面的改动升级后立刻生效，不用再手动重装或进菜单 5/8/4 触发一次。
- **下载失败不破坏**：仓库没公开、网络不通或下载到的文件校验不过，都会直接提示失败、保持当前版本，不会把脚本换成坏的。
- **菜单头显示的是装在机器上的版本**：以前菜单头显示的是正在运行的脚本版本；用一键命令跑时，正在运行的脚本就是刚从仓库下载的最新版，所以机器上装的还是旧版、升级还没成功时，菜单头就已经显示新版本号了，看着像升级成功了（“没更新成功怎么能显示新版本号呢”）。现在菜单头读机器上装的那个文件（`/etc/sing-box/installer.sh`）里的版本号来显示；只有全新安装（机器上还没有这个文件）时才显示正在运行的版本。如果正在运行的版本比装的新，菜单头会在版本号下面明确提示「已有新版本 vX.Y.Z 未安装，选 13 升级」，不会再假装已经升级了。
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

## v1.0.23 改了什么

- **菜单 13 升级用新版代码重新生成（bug 修复）**：以前菜单 13 替换完脚本文件后，直接用内存里还没换掉的旧代码重新生成配置和订阅，新版的格式改动要等下次运行 `sb -n` 才生效（实测：20 升 21 时，升级当时生成的订阅里没有 multiplex，跑一次 `sb -n` 才补上）。现在替换完文件后，重新执行新版脚本（内部入口 `--post-update`）来做重新生成：读已装配置 → 写全部入站 → 写 nginx 配置 → 保存配置 → `sing-box check` 校验 → 重载 sing-box 和 nginx → 重新生成订阅，全程用的都是新版代码。升级完立刻就是新格式，不用再跑一次 `sb -n`。Reality 协议的私钥也在新进程里重新读回来（以前只存在旧进程内存里），不会因为换进程丢了导致入站写成空私钥。
- **重新生成失败会回滚、不假装成功（bug 修复）**：以前重新生成的各步失败了也不警告、不回滚，照样打印“已重新生成”。现在每一步都检查结果并汇总：`sing-box check` 校验不过、或任何一步失败，都会把失败原因（具体是哪一步）打出来，把备份的旧脚本和旧配置（入站配置、订阅文件、端口记录、nginx 配置）恢复回来，明确提示已回滚、当前仍是旧版，绝不打印成功提示；备份失败时升级直接中止，不动已装脚本。如果机器上还没有已装的配置，只换脚本文件，提示没有配置需要重新生成。
- **其余都没动**：协议表（19 种、顺序不变）、菜单（13 项、顺序不变）、服务端 CF 配置（cloudflared HTTP/2、多路复用、TLS 1.3、max_early_data 2560、listen `::`、nginx 配置）、订阅生成和订阅 multiplex、分客户端订阅、分客户端节点链接、二维码逻辑、固定隧道域名自动识别、qrencode 自动安装、Argo 升级下载修复、菜单头版本号显示、节点名 `<J>` 默认、链接绿色加粗、链接之间 3 个空行，都原样保留。v1.0.23 只改了上面这 2 项（菜单 13 新版重新生成 + 失败回滚），相对 v1.0.21 总共 201 行改动（新增 `post_update_regen()` 一个函数，改了 `update_script()` 和 `parse_args()`，其余函数一个字节没改）。
- **升级注意：这个修法只对装了 v1.0.23 之后的升级生效；从 v1.0.21 升到 v1.0.23 这一次，重新生成还是旧代码做的，升完请再跑一次 `sb -n`，让新代码重新生成一次订阅。协议编号没变，不用重新选协议；从 v1.0.13 及更早版本升级的机器，旧 `install.env` / `selected.env` 里存的是旧协议编号，升级后请从菜单 8 重新选一次协议；全新安装不受影响。**
- 测试：按用户要求做了全面测试，见下面的测试记录；真机完整安装、订阅在真实客户端里打开和同步、CF 节点实际连通仍需用户实测。

## v1.0.23 测试记录

测试方法是把真实脚本里的函数抽出来，在测试目录跑（`SB_HOME` 指向测试目录，不用系统服务；TLS 证书用 `openssl` 自签在 `/etc/sing-box/`，和真实安装一致），不改系统、不装到真机；菜单用 pty 沙箱跑真实脚本、从原始 ANSI 流里检查；订阅端点用测试 nginx（端口 18080，真实 v1.0.23 配置）+ 真实 sing-box 1.14.4 二进制跑。结果：**结构 + 单元测试 156 项全部通过，0 失败；端点 + 冲突测试 221 项全部通过，0 失败；二维码测试通过；sing-box 1.14.4 校验通过；pty 菜单测试 14 项全部通过**。

- **结构 + 单元测试 156 项**：`bash -n` 通过；版本 v1.0.23 (2026.11.27)；第三方作者名还是 2 处，都是 ArgoX / sba 的功能性下载链接；脚本里没有任何写死的隧道域名；相对 v1.0.21 总共 201 行改动。
  - **改动范围**：函数级对比 v1.0.21，只新增了 `post_update_regen()` 一个函数，只改了 `parse_args()`（加 `--post-update` 入口）和 `update_script()`（新版重新生成 + 失败回滚），其余 156 个函数一个字节没改；`write_inbound`（协议代码）、`build_link_for`（分享链接）、`export_list`（订阅格式）、`singbox_outbound_for` / `clash_proxy_for`（订阅 multiplex）、`print_header`（版本号显示）、`show_version`（菜单 6）、`setup_argo`（Token/JSON）、`write_nginx_conf`、`check_brutal` 都和 v1.0.21 一个字节没改。
  - **新版重新生成结构**：`post_update_regen()` 先读已装配置（没有配置返回 2）、从文件恢复 Reality 私钥（没有才重新生成）、按顺序写全部入站 → 写 nginx 配置 → 保存配置 → `sing-box check` 校验通过才重载 → 重新生成订阅；每一步失败都报步骤名并返回 1，没有 `|| true` 静默吞掉；`update_script()` 替换文件前先快照配置（入站配置、订阅文件、端口记录、nginx 配置），失败时恢复快照 + 从备份恢复旧脚本、再重载一次让运行中的服务和恢复后的文件一致；备份失败时升级直接中止。
  - **菜单 13 全流程模拟（U13a 成功）**：模拟一键命令跑 v1.0.23、机器上装 v1.0.21 时，13 正确升级到 v1.0.23、生成 `installer.sh.bak-v1.0.21`、提示「配置和订阅已用新版重新生成」、无回滚提示；因为 v1.0.23 和 v1.0.21 生成的订阅内容本身一样，用了一个可观测的夹具证明重新生成用的是新版代码（新版 `export_list` 里埋的标记文件出现了）；CF 入站含 multiplex、nginx 含 `proxy_ssl_protocols`、订阅仍是 19 条链接、生成后的 `sing-box.json` / `clash.yaml` 里 CF 节点带 multiplex / smux、`ports.env` 干净（19 行、无重复）；升级完菜单头显示 v1.0.23、无残留提示。
  - **反向对照（U13b）**：同一夹具、同一份“新版”脚本，但升级跑旧版 v1.0.21 的 `update_script`（内存里旧代码重新生成）时，脚本文件照样换成 v1.0.23、备份照样生成，但标记文件**不出现**、提示还是旧 wording「下次运行 sb 时生效」——证明标记只可能来自新版代码重新生成，正向对照有效。
  - **失败路径（U13c）**：人为让 `sing-box` 二进制不可执行（`sing-box check` 必然失败），`update_script` 返回 1、报错明确点出 `check_config` 这一步、提示「本次升级已回滚」、**不打印**成功提示；`installer.sh` 恢复成 v1.0.21、备份还在；升级前删掉的入站文件没有被重新生成出来（配置恢复到了升级前状态）、`ports.env` 和 nginx 配置里的标记恢复回来了。
  - **无已装配置（U13d）**：没有 `install.env` 时，脚本照样升级到 v1.0.23、备份照样生成，提示「当前没有已安装的配置需要重新生成」，不回滚、不报错。
  - **同版本拒绝（U13e）**：已装 v1.0.23、再拉到 v1.0.23 时拒绝替换、不生成备份。
  - **测试中真抓到一个 bug 并修了**：第一版 `update_script` 里用 `if ! bash ...; then regen_rc=$?; fi` 抓子进程退出码——在 bash 里那个分支里的 `$?` 是 `!` 测试本身的状态（永远是 0），不是子进程的退出码，结果失败路径照样走成功分支、打印成功提示。测试 U13c / U13d 第一轮跑出了这个 bug（失败时照样显示成功），已改成先单独跑、再在下一行取 `$?`，重跑后 U13c / U13d 全部通过。
  - **v1.0.21 回归**：订阅 multiplex（sing-box JSON 4 个 CF 出站、Clash YAML 4 个 CF 代理的 smux + brutal-opts）还在，直连协议没加；菜单版本号显示 5 种场景（已装旧版 + 运行新版 → 显示旧版 + 提示；同版 → 无提示；全新安装 → 显示运行版；已装比运行新 → 无误报；英文模式 → 英文提示）都通过；cloudflared 强制 HTTP/2 还是 4 处；`max_early_data` 还是 2560，没有残留的 2048；nginx 还是 `proxy_ssl_protocols TLSv1.3`、没有 `proxy_ssl_session_reuse off`；4 个 CF 入站 `listen` 还是 `"::"`；brutal 还是有条件开；IPv4 三列对齐还在；生成的全部入站 `sing-box check` 通过、`nginx -t` 通过。
  - **生成**：19 协议全装时 `list.txt` / ShadowRocket 都是 19 条链接，Clash 19 个 proxy、sing-box JSON 19 个出站，索引页有全部订阅地址和二维码图片，`qr.png` 存在；CF 链接还是 `cf.3666888.xyz:443`、SNI 是隧道域名。
- **端点 + 冲突测试 221 项全部通过**：
  - **C1–C6**：和 v1.0.21 一样（nginx 启动慢不误报、节点列表 + 运行次数 + 节点名、CF 自动切换、临时隧道域名轮换后全部订阅文件重新生成、URL 不冲突、4 个 CF 路径真实跑通）。
  - **C7**：菜单 6 不碰 `installer.sh`、不调 `update_script`，`update_script` 不升级二进制、两者互不干扰；Argo 下载地址修正后实测返回 **302**，旧的带 `v` 地址返回 **404**；分客户端节点链接只出现在显示文件里，订阅数据文件里没有；显示文件里的链接是绿色加粗。
  - **C8 v1.0.23 回归（没动的东西）**：协议表（`PROTO_NAMES` / `PROTO_TAGS` / `PROTO_CF`）和 v1.0.21 一模一样，19 种、顺序不变；`write_inbound`（全部 19 个入站）、`show_version`（菜单 6）、`export_list`、`singbox_outbound_for`、`clash_proxy_for`、`print_header`、`build_link_for`、`setup_argo`、`write_argo_daemon`、`write_nginx_conf`、`check_brutal`、`resolve_fixed_domain` 和 v1.0.21 一个字节没改；相对 v1.0.21 总共 201 行改动（只新增 `post_update_regen`，只改 `parse_args` + `update_script`）；脚本里没有写死的隧道域名；第三方作者名还是 2 处；菜单还是 13 项（1–13 + 0 退出）；默认节点名还是 `<J>`；链接之间还是 3 个空行；链接还是绿色加粗；Argo 升级下载修复还在；二维码逻辑还在；分客户端节点链接还在（19/19/19）。
  - **C9 菜单 13 功能测试**：模拟一键命令跑 v1.0.23、机器上装 v1.0.21 时，13 升级已装脚本、生成备份、返回 0、提示「配置和订阅已用新版重新生成」、无回滚提示、重新生成配置（CF 入站含 multiplex、nginx 含 `proxy_ssl_protocols`）、订阅仍是 19 条、`ports.env` 干净（19 行、无重复）；升级后生成的 `sing-box.json` 里 4 个 CF 出站带 multiplex、`clash.yaml` / `clash2.yaml` 里 4 个 CF 代理带 smux。
  - **C10 菜单头版本号（升级前后）**：升级前（已装 v1.0.21、运行 v1.0.23）菜单头显示 v1.0.21 + 提示未安装；升级后（已装 v1.0.23、运行 v1.0.23）菜单头显示 v1.0.23、无提示。
- **二维码**：330×330 纯黑白图，灰度值只有 0 和 255（无灰色抗锯齿）；`zbarimg` 解码得到正确的订阅地址 `http://127.0.0.1:18080/sub`。
- **sing-box 校验**：19 个入站全装的配置（`00_base.json` + 19 个 `01_*_inbounds.json` + 出站/路由/实验配置）用真实 sing-box 1.14.4 二进制 `sing-box check` 通过；分客户端 sing-box JSON 也通过。
- **pty 菜单测试 14 项全部通过**：pty 沙箱跑真实脚本，主菜单正常显示 13 项 + 退出；菜单头显示已安装版本 v1.0.23、无残留提示；系统信息里 IPv4 是三列对齐（IP、国家、运营商），每行之间有空行；Argo 那一行显示隧道域名和隧道类型；节点列表文件里节点名是 `<J>`；链接是绿色加粗；右下角显示累计运行次数。
- **实测验证的行为**：WS 守卫 plain GET → 404、真实 WS 升级 → 101（直通 sing-box）。
- **没法在本机跑的（需用户实测）**：真机完整安装流程；订阅在真实客户端里打开和同步（ShadowRocket / Clash / sing-box / V2rayN / Throne）；CF 节点在真实客户端实际连通；菜单 5 / 菜单 8 / 菜单 13 在真机上的真实交互（特别是从 v1.0.21 升到 v1.0.23 后，升完跑一次 `sb -n`、确认订阅是新代码生成的）；`sb --sync-argo` 定时器在真机上 5 分钟一跑、临时隧道换域名时自动更新订阅；固定隧道域名自动识别在真机上（配 Token 后日志里读出真实隧道域名）；IPv4 三列对齐在真机上显示（例如 `170.9.26.154         美国          (Oracle Corporation)`）。

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
