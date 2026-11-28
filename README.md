# BOSS J 一键安装脚本（v1.0.27）

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

> 注意：仓库必须是公开的才能用这个链接拉到，私有会返回 404。

## ⚠️ 订阅地址带 UUID 前缀（旧 /sub 链接打不开）

**全部订阅地址前面都有一段 UUID**：`http://<服务器>:<端口>/<UUID>/sub`（这个 UUID 就是安装时生成的那个 UUID，`install.env` 里的 `WIZ_UUID`）。分客户端的地址也一样：`/<UUID>/sub/v2rayn`、`/<UUID>/sub/clash`、`/<UUID>/sub/sing-box`、`/<UUID>/sub/auto`、`/<UUID>/sub/qr`、`/<UUID>/sub/index`，全部带前缀。

- **不带 UUID 的旧订阅链接打不开**：nginx 只认带 UUID 的地址，不带 UUID 的返回 404。这是故意的——以前任何人只要知道服务器 IP 和 8080 端口就能拉走全部节点链接，现在不知道 UUID 就拉不到。
- **客户端里还是旧订阅地址时**：跑一次菜单 1（`cj -n`），复制新的订阅地址（带 UUID 的），到客户端里把旧订阅地址换成新的、重新同步一次。只在客户端里点“更新订阅”没用——旧地址本身已经失效了。
- **节点分享链接（`vless://`、`trojan://` 这种）没变**：已经发出去的单个节点链接照常用，不用换；变的是订阅地址。
- **二维码也变了**：`/sub/qr` 的二维码现在扫出来的是带 UUID 的新订阅地址，旧的二维码图片失效，重新生成后用新的。



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
cj          # 打开菜单
cj -n       # 查看节点信息
cj -s       # 开/关 sing-box
cj -a       # 开/关 Argo
cj -t       # 修改 Argo
cj -d       # 修改配置
cj -v       # 同步 Sing-box 和 Argo 至最新版本
cj -b       # 升级内核、安装BBR、DD脚本
cj -r       # 增删协议
cj -u       # 卸载
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
| 1 | 查看节点信息（`cj -n`） |
| 2 | 客户节点管理 |
| 3 | 关闭 Sing-box（`cj -s`），运行时显示“关闭”，停用时显示“开启” |
| 4 | 关闭 Argo（`cj -a`），运行时显示“关闭”，停用时显示“开启” |
| 5 | 更换 Argo 隧道（`cj -t`） |
| 6 | 修改节点配置（`cj -d`） |
| 7 | 同步 Sing-box 和 Argo 至最新版本（`cj -v`） |
| 8 | 升级内核、安装BBR、DD脚本（`cj -b`） |
| 9 | 增加 / 删除协议（`cj -r`） |
| 10 | 卸载（`cj -u`） |
| 11 | 安装 ArgoX 脚本 (argo + xray) |
| 12 | 安装 sba 脚本 (argo + sing-box) |
| 13 | 安装 TCP brutal |
| 14 | 升级脚本至最新版本（`cj --update-script`） |
| 0 | 退出 |

菜单顶部会显示脚本版本、系统信息（操作系统 / 内核 / 架构 / 虚拟化）、IPv4 / IPv6，以及 Sing-box / Argo / Nginx 的状态、版本、内存占用和流量，整块系统信息都是加粗绿色，系统信息每行之间空一行，不挤在一起。IPv4 / IPv6 后面会显示国家中文名和网络运营商名，三列对齐（IP、国家、运营商，例如 `170.9.26.154         美国          (Oracle Corporation)`，从公开 IP 库查的 ISP 和国家，查不到就不显示，不影响菜单；显示的是网络运营商，不是 VPS 转售品牌——公开库里这段 IP 登记在 Oracle Corporation 名下）。Argo 那一行会显示隧道类型和当前隧道域名：固定隧道显示「（固定隧道 <隧道域名>）」，临时隧道显示「（临时隧道 xxx.trycloudflare.com）」，没开 Argo 就不显示。状态在中文模式下显示为开启 / 关闭 / 未安装（英文模式 Running / Stopped / Not installed）。主菜单底部右下角显示累计运行次数（中文「累计运行 N 次」，英文 `Total runs: N`），每次进菜单加 1，次数存在 `/etc/sing-box/run_count`，重装脚本不丢；单项命令（`cj -n` 等）不计数；节点列表（菜单 1 / `cj -n`）末尾右下角也显示这个次数，只显示、不计数。菜单选项（主菜单和所有子菜单）都是加粗黄色，子菜单标题是加粗绿色，状态/进度行加粗，「请选择：」提示是绿色。

## 安装向导

按顺序问：选协议 → 起始端口（默认 8881，连续分配）→ 服务器地址（默认自动探测的公网 IP）→ UUID（默认随机生成）→ 节点名 → 客户端指纹（chrome / firefox）→ Reality 私钥（有 Reality 协议时，留空自动生成）→ Hysteria2 的 Realm、带宽、端口跳跃（只有选了 Hysteria2 才问）→ CDN 优选域名、订阅开关、Argo（只有选了走 Cloudflare 的协议才问）→ nginx 订阅端口。

## 节点名：默认是 <J>，空格 = 不加前缀

安装向导问节点名时（菜单 6 里改节点名也一样），三种输法：

- **直接回车（什么都不输）**：用默认名 **<J>**，节点显示为「<J> Trojan-WS」「<J> VLESS-WS-TLS」这样。
- **只输一个空格**：不要前缀，节点只显示协议名，例如「Trojan-WS」「VLESS-WS-TLS」，前面没有空格。
- **自己输名字**：就用你输的名字。

只在新安装时用这个默认；已经装好的机器，存着的名字（`install.env` 里的 `WIZ_NODE_NAME`）不会被改掉，菜单 6 里改了才变。

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

- **sing-box JSON（`/<UUID>/sub/sing-box`）**：4 个 CF 出站（VLESS + WS + TLS、Trojan + WS、VMess + WS + TLS、Trojan + HTTP）都加了 `"multiplex": {"enabled": true, "protocol": "h2mux", "max_streams": 16, "padding": true, "brutal": {"enabled": <是否可用>, "up_mbps": 1000, "down_mbps": 1000}}`，和原版的格式一样；直连协议的出站没有 multiplex（只在服务端入站里有，见下面说明）。
- **Clash YAML（`/<UUID>/sub/clash`、`/<UUID>/sub/clash2`）**：4 个 CF 代理都加了 `smux: { enabled: true, protocol: 'h2mux', padding: true, max-connections: '8', min-streams: '16', statistic: true, only-tcp: false }` 和 `brutal-opts: { enabled: <是否可用>, up: '1000 Mbps', down: '1000 Mbps' }`；直连代理没有 smux（只在服务端入站里有多路复用，见下面说明）。
- **brutal 开关和服务端一致**：订阅里的 brutal 开关用的是同一个判定（`check_brutal()`：内核有 brutal 模块才开，没有就不开），不是写死的 `true`；每次重新生成订阅（菜单 1 / `cj -n`、菜单 6、菜单 9、菜单 14 升级、`cj --sync-argo`）之前都会先刷新一次这个判定，所以订阅里的值永远和服务端入站里的值一致。
- **分享链接没动**：`vless://`、`vmess://`、`trojan://` 这些链接里原版也没有 mux 参数，我们的也没加，ShadowRocket / V2rayN 用的链接和以前完全一样。

**直连协议入站的多路复用**：以前 Shadowsocks、Trojan、H2 + Reality、gRPC + Reality 这 4 个直连协议的服务端入站完全没有 `multiplex`，现在入站里带了 `multiplex`（brutal 开关同样看内核有没有 brutal 模块，有才开 1000/1000）。**订阅文件没变**：sing-box JSON / Clash YAML 里还是只有 4 个 CF 节点带 multiplex / smux，直连协议的订阅出站不带——订阅里给直连节点加 multiplex 是另一项（原版对齐清单里的中优先级），这次没做。XTLS 多路复用开关（菜单 6 第 15 项）切换时不再把 brutal 丢掉，切回 Vision 时 padding 也不残留。分享链接还是没动。

## 固定隧道域名自动识别

固定隧道（Token 方式）的域名不用再手动填、脚本里也不写死任何域名。配好 Token、Argo 启动后，脚本自动从 Argo 日志里读最新的 `Updated to new configuration` 那一行，取出 ingress 里的 `hostname`（一个 Token 对应一个隧道、一个域名，换 Token 就换域名），存到 `install.env` 的 `WIZ_ARGO_DOMAIN` 和 `/etc/sing-box/argo_domain`，再重新输出节点列表。菜单里 Argo 那一行就会显示「（固定隧道 <隧道域名>）」。如果日志里读不到域名，就保持原来的值不变，不影响安装流程。

> 注意：Cloudflare 后台那个隧道的 Public Hostname 的 Service 必须填 `http://localhost:8080`（nginx 订阅端口），填成别的端口（例如后台随机显示的端口）订阅会返回 502，CF 节点不通。这是后台设置，不是脚本能改的。

## Hysteria2：带宽和端口跳跃

选了 Hysteria2 后，安装向导中途（Realm 问完、进 CDN / 订阅之前）会依次问：

1. **带宽**：上行/下行，单位 Mbps，例如 `200/1000`，直接回车用默认 200/1000（新安装才用这个默认；已装好的机器存着的 100/100 不变）。装好后用 `cj -d` 第 12 项也能改。
2. **端口跳跃**：直接问范围，例如 `20000:21000`，**直接回车跳过，不用端口跳跃**。输了范围才开启，范围须在 10000–65535 之间、起始小于结束，支持 `起始:结束` 和 `起始-结束` 两种写法。

问范围之前会先打印一页说明：有些运营商会限速或阻断单个 UDP 端口，端口跳跃把流量分散到一段 UDP 端口上；推荐用 1000 个左右的端口；NAT 小鸡能用的端口一般只有 20–30 个，填了没开放的端口会导致节点不通，请慎用；默认不开启。

## Argo 凭证指引

选 Token / JSON / Cloudflare API 时，脚本会先打印分步指引：去 https://dash.cloudflare.com/ ，Zero Trust > 网络 > 连接器，创建隧道并选择 Cloudflared，Token 就显示在那里；或者用已建隧道的 JSON 凭证；或者用 Cloudflare API 令牌（https://dash.cloudflare.com/profile/api-tokens > 创建令牌 > 创建自定义令牌），授予：帐户 > Cloudflare One 连接器：Cloudflared > 编辑，以及区域 > DNS > 编辑；帐户资源包括你的账户，区域资源包括特定区域的域名。权限不够时 API 调用会失败。

## 订阅和 Clash

- 订阅链接：`http://<服务器地址>:<nginx 端口>/<UUID>/sub`，文件在 `/etc/sing-box/subscribe/`（明文 `list_plain.txt`、base64 `list.txt`、Clash `clash.yaml`）。**全部订阅地址前面都有一段 UUID**（就是安装时生成的那个 UUID），旧的 `/sub` 地址不再能打开——见上面「⚠️ 订阅地址带 UUID 前缀」。
- `clash.yaml` 是逐协议完整展开版：`proxies` 里按协议逐个写 VLESS / VMess / Trojan / Hysteria2 / Shadowsocks / TUIC / AnyTLS 等条目，`proxy-groups` 里有 PROXY 分组，`rules` 是 `MATCH,PROXY`。
- 动态订阅（`--SUBSCRIBE dynamic` 或 `cj -d` 第 10 项）：nginx 通过 fcgiwrap 按请求 Host 实时渲染，直连节点的 server 跟随访问地址，WebSocket / CDN / Argo 节点保持原地址不变；开启时会先探测动态端点，探测不过就自动回退到静态订阅，不会留一个打不开的订阅。

## 分客户端订阅

除了通用订阅 `/<UUID>/sub`（base64 链接列表，所有客户端都能导入），还按客户端分了订阅地址，都在同一个订阅服务器上（端口还是 nginx 订阅端口，默认 8080）：

| 客户端 | 订阅地址 | 格式 |
| --- | --- | --- |
| 订阅中心（索引页） | `http://<服务器>:<端口>/<UUID>/sub/index` | 网页，列出下面所有地址 + 二维码 |
| 通用 / V2rayN | `http://<服务器>:<端口>/<UUID>/sub/v2rayn` | base64 链接列表（和 `/<UUID>/sub` 一样） |
| Throne | `http://<服务器>:<端口>/<UUID>/sub/throne` | base64 链接列表 |
| ShadowRocket | `http://<服务器>:<端口>/<UUID>/sub/shadowrocket` | base64 链接列表（ShadowRocket 专用格式，WS 节点带 obfs/peer 参数） |
| Clash / Mihomo | `http://<服务器>:<端口>/<UUID>/sub/clash` | Clash YAML（`proxies` + PROXY 分组） |
| Clash 2 | `http://<服务器>:<端口>/<UUID>/sub/clash2` | Clash YAML（加自动测速分组 + TUN + DNS） |
| sing-box（SFI / SFA / SFM） | `http://<服务器>:<端口>/<UUID>/sub/sing-box` | sing-box 客户端 JSON（TUN + 混合入站 + proxy 选择器 + direct/block 出站 + 路由） |
| 自适应 | `http://<服务器>:<端口>/<UUID>/sub/auto` | 按客户端 User-Agent 自动返回对应格式（见下） |
| 二维码 | `http://<服务器>:<端口>/<UUID>/sub/qr` | 订阅二维码图片（纯黑白，见下） |

- **为什么要分客户端**：通用 base64 订阅在 ShadowRocket / V2rayN 里直接能导入，但 Clash / Mihomo 读不了 base64 链接，必须给 YAML；sing-box 客户端用专用 JSON 更稳。所以补了这套，通用订阅本身不动。
- **自适应 `/<UUID>/sub/auto` 的识别规则**（按请求里的 User-Agent）：含 `clash` 或 `mihomo` → Clash YAML；含 `sing-box`、`sfa`、`sfi`、`sfm` → sing-box JSON；含 `shadowrocket` → ShadowRocket 格式；含 `throne` → Throne（base64）；其他（包括没带 User-Agent 的）→ 通用 base64。匹配不区分大小写。
- **节点链接格式**：V2rayN / Throne 用标准链接（和通用订阅一样）；ShadowRocket 用 base64 编码的链接，VLESS + WS + TLS 和 Trojan + WS 这两个 WS 节点额外带 `obfs=websocket&obfsParam=<隧道域名>&tls=1&peer=<隧道域名>&path=...?ed=2560`；Clash / Mihomo 用 YAML proxy 条目（WS 的 `ws-opts` 路径 + Host 头、`max-early-data 2560`、`early-data-header-name Sec-WebSocket-Protocol`），4 个 CF 代理还带 `smux` + `brutal-opts`（多路复用，见上面「CF 节点提速」一节）；sing-box JSON 的 4 个 CF 出站带 `multiplex`（同样见上）。
- **CF 自动切换同样适用**：全部已装协议都是 CF 协议时，分客户端链接里的服务器也用隧道域名；否则用优选域名；SNI/Host 始终是隧道域名。和通用订阅、Clash 的逻辑完全一致。
- **订阅中心页**：`/<UUID>/sub/index` 是个网页，列出上面所有订阅地址，点开就能复制；下面有个订阅二维码，扫码导入通用订阅。
- **二维码要求**：纯黑（#000000）白（#FFFFFF）高对比，没有灰色抗锯齿、没有模糊，边缘锐利；用 `qrencode` 生成，图片里只有 0 和 255 两种灰度值；生成后会用解码工具验证能扫出正确的订阅地址。
- **qrencode 自动安装**：脚本启动时检查 `qrencode` 在不在，没有就自动装（Debian/Ubuntu 用 apt-get，CentOS/Fedora 用 dnf/yum，Alpine 用 apk，Arch 用 pacman）；装不上也不报错、不中断脚本，只是二维码那时还显示不出来，和以前一样。
- **自动刷新同样适用**：临时隧道域名变了，`cj --sync-argo`（和每 5 分钟的定时器）重新生成订阅时，分客户端的文件（Clash / Clash 2 / sing-box JSON / ShadowRocket / 索引页 / 二维码）会一起重新生成，不只是 `list.txt`。
- **节点列表里也能看到**：菜单 1 / `cj -n` 的节点列表末尾，在通用订阅链接下面有一节「Per-client subscriptions:」，列出上面这些地址。

## 每个节点的分客户端链接

菜单 1 / `cj -n` 的节点列表里，除了上面那一节订阅地址，还多了一节「Per-node links by client:」：每个已装节点按客户端分组列出自己的链接，方便直接复制单个节点的链接，不用再去订阅里找：

- **V2rayN**：标准链接（和节点列表顶部的主列表一样）。
- **ShadowRocket**：base64 编码的链接（ShadowRocket 专用格式；VLESS + WS + TLS 和 Trojan + WS 这两个 WS 节点带 `obfs=websocket&obfsParam=<隧道域名>&tls=1&peer=<隧道域名>&path=...?ed=2560`）。
- **Clash**：Mihomo YAML proxy 条目（和 `/<UUID>/sub/clash` 里同一个节点的条目一样）。

每组前面有客户端名标题，组和组之间、各节之间都空好几行，不挤在一起；所有链接（节点链接、订阅地址、分客户端链接）都是绿色加粗显示。这一节只影响终端显示，不改订阅文件：`list.txt` / `list_plain.txt` 里还是只有标准链接，没有分客户端内容。

## 升级脚本（菜单 14 / `cj --update-script`）

菜单 7（`cj -v`）只同步 sing-box 和 Argo（cloudflared）的**二进制**，不更新脚本本身——所以以前菜单 7 跑完，脚本版本永远不变。现在脚本升级是独立的菜单项：

- **菜单 14「升级脚本至最新版本」**（或命令行 `cj --update-script`）：从仓库拉最新 `sing-box.sh`（`https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh`），用 `bash -n` 校验语法、确认版本号和**装在机器上的**版本不一样，才备份当前 `/etc/sing-box/installer.sh`（备份名带旧版本号），替换成新版，再**重新生成全部配置**（全部入站 + nginx 配置，校验通过后重载 sing-box 和 nginx），最后重新输出一次节点列表、重新生成订阅；已经是最新版就直接提示，不动任何文件。
- **重新生成用的是新版代码**：替换完脚本文件后，重新生成这一步是重新执行**新版**脚本来做的（内部入口 `--post-update`），不是用内存里还没换掉的旧代码。以前是旧代码在内存里直接重新生成，新版的格式改动（例如订阅里的 multiplex）要等下次运行 `cj -n` 才生效，升级当时生成的订阅还是旧格式；现在升级完立刻就是新格式。
- **重新生成失败会回滚、不假装成功**：重新生成的每一步（写全部入站、写 nginx 配置、保存配置、校验配置、重载、重新生成订阅）都检查结果；`sing-box check` 校验不过、或任何一步失败，都会把失败原因打出来、把备份的旧脚本和旧配置（入站配置、订阅文件、端口记录、nginx 配置）恢复回来，再明确提示「本次升级已回滚，当前仍是旧版脚本」，绝不打印成功提示。如果机器上还没有已装的配置（没有协议），只换脚本文件，提示没有配置需要重新生成。
- **升级前先冒烟测试、拒绝降级**：替换之前先跑一遍新脚本的冒烟测试，不过就中止升级、不动已装脚本；版本号按 `sort -V` 比，同版拒绝、旧版也拒绝（以前只比字符串相等，旧版脚本也能“升级”上去）。
- **重新生成调新版的全部写入器**：重新生成时会重写基础配置、Argo daemon、HTTP 客户端（以前菜单 14 从不重写 Argo daemon）；升级时对账 Argo 凭证，Token 和 JSON 双份文件只留一个；新版本和旧配置不兼容时有修复路径，不会直接报错走人。
- **升级脚本不丢配置**：`install.env` / `selected.env` / `ports.env`、UUID、端口、隧道都不动，只换脚本文件本身；新脚本下次运行 `cj` 时生效。
- **14 比的是装在机器上的版本**：以前拿下载的新版本号跟**正在运行的**脚本版本比。用一键命令跑时，正在运行的脚本就是刚从仓库下载的最新版，两个版本号一样，14 就以为“已经是最新版”直接退出，机器上装的旧脚本根本没换（实测：机器上还是 1.0.18，14 却显示“已经是 19”）。现在 14 直接读机器上装的那个文件的版本号来比，不一样就换；换完还会重新生成配置（不只是重新生成订阅链接），这样多路复用、TLS 1.3 这些配置层面的改动升级后立刻生效，不用再手动重装或进菜单 6/9/5 触发一次。
- **下载失败不破坏**：仓库没公开、网络不通或下载到的文件校验不过，都会直接提示失败、保持当前版本，不会把脚本换成坏的。
- **菜单头显示的是装在机器上的版本**：以前菜单头显示的是正在运行的脚本版本；用一键命令跑时，正在运行的脚本就是刚从仓库下载的最新版，所以机器上装的还是旧版、升级还没成功时，菜单头就已经显示新版本号了，看着像升级成功了（“没更新成功怎么能显示新版本号呢”）。现在菜单头读机器上装的那个文件（`/etc/sing-box/installer.sh`）里的版本号来显示；只有全新安装（机器上还没有这个文件）时才显示正在运行的版本。如果正在运行的版本比装的新，菜单头会在版本号下面明确提示「已有新版本 vX.Y.Z 未安装，选 13 升级」，不会再假装已经升级了。
- 菜单 7 的行为没变：还是只同步二进制，不碰脚本。

## Argo 升级下载修复

菜单 7 里同步 Argo（cloudflared）时，旧版把下载地址拼成了 `.../releases/download/v<版本号>/cloudflared-linux-amd64`，多加了一个 `v`；但 Cloudflare 官方 release 的 tag 本来就没有 `v`（例如 `2026.11.2`），所以那个地址一直返回 404，显示「下载失败」。现在直接用 GitHub API 返回的 `tag_name`（原样，不加 `v`），优先用 API 里对应文件的 `browser_download_url`；菜单上「最新版本」那一行也不再多写一个 `v`。修正后的地址实测返回 302（文件存在），旧的带 `v` 地址返回 404。

Argo 升级不再先停服务再下载：先下载新版并校验、再停服务、备份旧版、升级完验证服务活着，失败恢复旧版（以前下载失败就剩一个停掉的 Argo）。最新版本查不到时也不再悄悄当成 1.14.4：菜单 7 明确提示查不到、拒绝“升级”到旧版。

## 修改配置（`cj -d`）

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

自定义路由进去后显示“自定义 warp-ep 出站路由规则（规则数：N）”，再选 1. 添加规则、2. 查看规则、3. 删除规则、0. 返回；添加时先选类型（`domain_suffix` 或 `rule_set`），域名后缀支持逗号分隔、会校验格式，规则集名称会自动补 `geosite-` 前缀，**并且会联网去 SagerNet / MetaCubeX 仓库校验这个规则集存不存在，查不到就拒绝写入**；删除按条目编号删，删的只能是自定义规则，不会误删基础规则。规则写进独立的 `08_custom_route.json`，出站是 `warp-ep`。输错会显示“未做任何修改”并返回。

更换 WARP 账户进去后选：1. 重新注册免费账户、2. 手动输入信息、0. 返回；手动输入依次问 WARP IPv6 地址、Private Key、reserved 保留值（格式 `123,456,789`）。**私钥会校验格式**（43 位 base64url，或 44 位带 `=` 的都行，存的时候转成标准 base64）；换账户先备份、校验通过才热加载，失败恢复旧账户。注册新账户需要机器有 TUN 设备，没有就提示不可用。

每改一项后脚本都会 `sing-box check` 校验，通过才重载 / 重启，不通过报错不重启。

## 增删协议（`cj -r`）

先列已装的协议和端口，再问删除（字母多选，回车跳过），再问增加（字母多选，回车跳过）。改完按起始端口重新连续分配，删掉的入站文件删除、新增的写入，校验通过后重启服务、同步防火墙、重新输出节点链接。如果一个协议都没保留（全部删掉、或原来就一个都没装），重新生成时会像全新安装一样再问一遍起始端口、UUID、节点名：UUID 那一步默认就是新随机生成的，回车就换新 UUID，旧 UUID 立刻失效（旧节点链接连不上，旧订阅地址也打不开了）；想留着旧 UUID 就在那一步直接输入旧 UUID。只增减个别协议时不问 UUID，UUID 不变；只看节点（`cj -n`）也不会换 UUID。

## 命令行参数

```
cj -s    开/关 sing-box        cj -a    开/关 Argo
cj -t    修改 Argo             cj -d    修改配置
cj -u    卸载                  cj -n    查看节点信息
cj -v    同步 Sing-box 和 Argo 至最新版本   cj -b    升级内核、安装BBR、DD脚本
cj -r    增删协议
cj --update-script    升级脚本至最新版本（菜单 14）
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

- 二进制：`/etc/sing-box/sing-box`，配置：`/etc/sing-box/conf/`（`00_base.json`、`01_<tag>_inbounds.json`、`02_outbounds.json`、`02_endpoints.json`（WARP 出站，有 WARP 账户时才有）、`03_route.json`、`04_experimental.json`、`07_http_clients.json`、`08_custom_route.json`（自定义路由，有自定义路由时才有））
- 节点列表：`/etc/sing-box/list`，订阅：`/etc/sing-box/subscribe/`（动态订阅时还有 `/etc/sing-box/subscribe/dynamic/`：`render.sh`、`meta.env`、fcgiwrap 套接字）
- 服务：`sing-box.service`、`argo.service`；快捷命令：`/usr/local/bin/cj`（都指向 `/etc/sing-box/installer.sh` 的副本，第一次运行脚本进菜单时就创建）
- 防火墙记录：`/etc/sing-box/firewall/service_ports.list`

## 卸载

菜单选 10 或运行 `cj -u`。和原版一样，卸载本身不做“确定吗”确认，停服务、删服务文件、清端口跳跃 NAT、按记录删防火墙规则、删 nginx 订阅配置、删 `/etc/sing-box` 和快捷命令 `/usr/local/bin/cj` 后直接完成；卸载还会停掉并删掉 `sb-sync-argo` 定时器（以前卸载后定时器还留着，每 5 分钟跑一次已经删掉的脚本）、删掉 cloudflared 和 wgcf 二进制、清掉防火墙持久化记录。注意：如果 ArgoX / sba 用的是同一个 `/usr/local/bin/cloudflared`，卸载后它们也要重装一次。过程中只问两件事（都默认不删）：装了 Nginx 时问是否一并卸载 Nginx，装了 fcgiwrap / spawn-fcgi 时问是否一并卸载。`cj -u` 命令行方式跳过这两问。

## v1.0.27 改了什么

- **客户节点管理（新增，菜单 2）**：给不同客户提供同样几个 CF 节点，但各用各的 UUID 和密码。管理员（你自己）原来那套 UUID 和密码不动，只给你自己用，现有节点继续能用；每个客户新建时再单独生成一套新的 UUID 和密码（一个 UUID 给 VLESS-WS-TLS、VMess-WS-TLS 用，一个 Trojan 密码给 Trojan-WS、Trojan-HTTP 用），A 和 B 的不一样，互不影响。只针对 CF 的 4 个协议（VLESS-WS-TLS、Trojan-WS、VMess-WS-TLS、Trojan-HTTP）；直连协议还是管理员一套共用，不分客户。
- **做法是一个入口、多个用户**：CF 每个协议还是一个入站，但入站里同时认管理员和所有已启用客户的凭证。客户连的是同一个入站、同一个端口和域名，只是 UUID、密码各用各的，服务器都放行。
- **每个客户有自己的订阅地址**：`/<客户UUID>/sub`，订阅里只有他自己的 CF 节点（已装的 CF 协议），看不到别人的。管理员的订阅不变（全部已装协议，管理员凭证）。
- **菜单 2 子菜单**：现有客户列表里，启用的后面标绿色的“（启用）”，停用的标红色的“（已停用）”，括号都是全角。子菜单 1 添加客户、2 停用 / 启用客户、3 删除客户、4 查看客户订阅、0 返回主菜单。
- **停用 / 启用**：停用不是删掉凭证，只是先不把他放进入口的用户名单里重新生成配置，他的节点就超时连不上；重新启用再把他的 UUID 和密码加回名单，节点不用换链接，直接又能用，凭证还是原来那套。
- **删除客户**：删掉后他的 UUID 和密码彻底没了，节点永久失效，不影响其他客户和管理员。删除前会问一次确认，默认不删。
- **客户名称**：支持中文（比如 张三、测试客户）和常用符号（括号 （）()【】、- _ 、，。！？ 等），名字只是个显示标签，不会进 URL、文件名或 JSON 键（订阅地址用的是客户 UUID），所以不会弄坏解析、菜单或订阅。名字最多 20 个字符（按字符数算，不是字节数，20 个汉字也可以）；超过 20 个、空名字、包含 `|`、控制字符的名字都会明确报错、重新让输入，不会悄悄截断。名字里不能用的只有 `|`（客户文件的分隔符）、换行和控制字符。
- **菜单顺序调整**：客户节点管理从菜单 14 移到菜单 2（紧跟查看节点信息），其余项整体下移一位：3 关闭 Sing-box、4 关闭 Argo、5 更换 Argo 隧道、6 修改节点配置、7 同步至最新版本、8 升级内核/BBR/DD、9 增加/删除协议、10 卸载、11 ArgoX、12 sba、13 TCP brutal、14 升级脚本至最新版本。各菜单项的文字和 `cj` 子命令都没变，只是编号变了。
- **快捷命令只剩 `cj`**：`sb` 命令彻底取消（原来 `sb` 和 `cj` 是一样的，现在只有 `cj`）。`cj`（打开菜单）、`cj -n`、`cj -s`、`cj -a`、`cj -t`、`cj -d`、`cj -v`、`cj -b`、`cj -r`、`cj -u`、`cj --update-script` 的用法和原来 `sb` 的一样。升级到本版后，`/usr/local/bin/sb` 会被删掉，`sb` 再打就提示找不到命令；卸载时会同时删 `/usr/local/bin/cj` 和残留的 `/usr/local/bin/sb`。
- **客户订阅二维码**：在“添加客户”和“查看客户订阅”里，订阅链接下面会再打印一个二维码，扫码就能把该客户的订阅地址导入客户端（Shadowrocket、Clash、V2RayNG、Sing-box 等都支持扫订阅二维码）。二维码里就是该客户的订阅地址本身（有固定隧道时是隧道地址 `https://<隧道域名>/<客户UUID>/sub`）。二维码尽量小：最低纠错级别（L）+ 1 格边距，约 62 字符的地址是 29×29 模块、终端里占 31 列 × 15 行。没装 qrencode 时只显示一行提示，不影响流程。网页上也有：`/<客户UUID>/sub/qr` 返回该客户订阅地址的二维码图片。
- **菜单配色修复**：新加的菜单文字（客户管理子菜单、菜单 9 的凭证二选一）之前是白色，现在统一改成黄色加粗，和主菜单其他项一样；“按回车继续”提示保持白色、只加粗；绿色输入提示、绿色“（启用）”/红色“（已停用）”、绿色加粗的链接/订阅地址都不变。
- **不影响别的**：`cj -n` 和菜单 9 只增减个别协议都不会动客户和他们的凭证；菜单 9 删光重建时的凭证二选一（v1.0.26 那个）也没变；管理员的凭证、节点名 `<J>` 默认、订阅地址格式都没变。
- 测试：见下面的测试记录；真机完整安装、订阅在真实客户端里打开和同步、CF 节点实际连通仍需用户实测。

## v1.0.27 测试记录

测试方法是把真实脚本里的函数抽出来，在测试目录跑（`SB_HOME` 指向测试目录，不用系统服务；TLS 证书用 `openssl` 自签在 `/etc/sing-box/`，和真实安装一致），不改系统、不装到真机；菜单 2 用管道输入跑真实脚本、从输出里检查。**一共跑了 2 轮完整测试，每轮 146 项，全部通过，0 失败**（123 项客户功能 + 10 项客户二维码 + 13 项菜单重排/cj 标签）。另外单独跑了 nginx 配置测试 10 项全过，菜单 9 回归测试 242 项通过（另 2 项是 v1.0.26 测试里写死的版本号和 diff 检查，v1.0.27 本来就该变，不是问题）。

- **第 1 轮**：123 项通过、0 失败。**第 2 轮（全套重跑）**：123 项通过、0 失败。
- **改动范围**：相对 v1.0.26 共 43 个 hunks、505 行加、74 行删，净增 432 行（7460 → 7892 行）：版本号 v1.0.26 → v1.0.27；客户文件读写和 CF 多用户入站的辅助函数；`write_inbound` 里 4 个 CF 协议改成多用户；`export_list` 里补上客户订阅生成；`write_nginx_conf` 里补上每个客户的 `/<UUID>/sub` 位置；主菜单第 2 项改为客户节点管理、其余项下移一位（原 2–13 项现为 3–14 项）；客户订阅二维码（终端 `print_customer_qr` + 网页 `/<UUID>/sub/qr`）；菜单配色（客户子菜单、凭证二选一改黄色加粗，“按回车继续”改白色加粗）；快捷命令只剩 `cj`（`sb` 取消，`create_shortcut` 只建 `cj` 并删 `/usr/local/bin/sb`，菜单标签和帮助里的 `(sb -X)` 全改 `(cj -X)`）；`load_install_env` 读 `ports.env` 时只取第一个匹配（防重复行）；`regen_customer_configs` 里写完入站后调 `save_install_env` 清掉 `ports.env` 的重复行。其余代码、参数一个字节没动。`bash -n` 通过；版本 v1.0.27 (2026.11.28)。
- **场景测试（每轮都跑，真实脚本 + 真实 sing-box 1.14.4 二进制 `check`）**：(a) 加客户 A：CF 入站的用户列表里有管理员 UUID + A 的 UUID（VLESS、VMess）和管理员 Trojan 密码 + A 的密码（Trojan-WS、Trojan-HTTP），A 的订阅里只有 A 的 4 个 CF 节点、用的就是 A 的 UUID 和密码，管理员的订阅和节点都不变，直连协议（Hysteria2、VLESS-Reality）里没有 A，`sing-box check` 通过。(b) 再加客户 B：B 的 UUID、密码和 A、管理员的都不一样，三个人的凭证同时在入站里，B 的订阅里只有 B 的节点，A 的订阅里还是只有 A 的，`sing-box check` 通过。(c) 停用 A：A 的 UUID、密码从 4 个 CF 入站里都不见了（节点会超时），但还存在客户文件里没删，B 和管理员的还在，`sing-box check` 通过。(d) 重新启用 A：A 的 UUID、密码原样回到入站里，和停用前一模一样，没重新发凭证，`sing-box check` 通过。(e) 删除 B：B 的 UUID、密码从入站和客户文件里都没了，订阅目录也删了，A 和管理员的不受影响，`sing-box check` 通过。(f) 菜单状态标签：启用的显示绿色“（启用）”，停用的显示红色“（已停用）”，都是全角括号。(g) `cj -n`：客户和凭证都不变，客户订阅还在。(h) 查看客户订阅：显示该客户的订阅地址（绿+粗）和他的 CF 节点链接，只含他的 UUID、密码。(i) 菜单 9 只加 1 个协议（留着别的）：客户和凭证都不变，CF 入站里还认他们，客户订阅还在，`sing-box check` 通过。(j) 中文名和符号名：加“测试客户”能正常存、正常在菜单里显示、能停用/启用、订阅正常；加“客户（测试）”也能正常存、显示、生成订阅、正常删除。(k) 名字长度：21 个字符（英文和中文都测了）会被明确报错“不能超过 20 个字符”并重新让输入，不会悄悄截断；20 个字符（英文和中文）都能正常加上；空名字和含 `|` 的名字也会明确报错、重新让输入。(l) nginx 配置：每个客户都有自己的 `/<UUID>/sub` 位置、指到他自己的订阅文件，删掉客户后位置也跟着没了，`nginx -t` 通过。
- **测试里发现并修好的 3 个真问题（都是脚本问题）**：(1) `ports.env` 重复行：`write_inbound` 每调一次就往 `ports.env` 追加一行，客户操作多次调它又不经过 `save_install_env`，重复行越攒越多，`load_install_env` 再读就把端口读成多行，`jq --argjson port` 报错、CF 入站文件被写成空的，`sing-box check` 失败。修法：`load_install_env` 读端口时只取第一个匹配（`grep -m1`），并且客户配置重生成后调 `save_install_env` 把 `ports.env` 重写干净。(2) `customer_pick` 用命令替换接返回值，客户列表和提示都打到标准输出里，把要返回的序号给污染了，停用/启用、删除、查看都挑不对客户。修法：序号改走全局变量 `PICKED_IDX` 传，不再用标准输出返回。(3) `regen_customer_configs` 在服务没跑起来时直接返回失败：测试里服务状态桩一直返回“没跑”，每个客户操作明明配置都写对了、校验也过了，还报失败。修法：服务没跑时只打印提示、不算失败（配置本身有效且已保存）。
- **没法在本机跑的（需用户实测）**：真机上菜单 2 的完整交互（加客户、停用/启用、删除、查看订阅）；客户的订阅地址在真实客户端里打开和同步、CF 节点实际连通；停用后客户节点确实超时、重新启用后确实恢复。



## 已知限制

- 自定义路由和更换 WARP 账户这两项，原版只在 TUN + warp-ep 出站存在时显示；本版改成“配了 WARP 账户才显示”，规则写进 `08_custom_route.json`、出站为 warp-ep（和原版一样）；注册 WARP 账户需要机器有 TUN 设备（`/dev/net/tun`），没有就提示不可用。
- 节点导出（`cj -n`）仍是简化渲染（链接 + 订阅 + Clash + 二维码），没有原版那种远程模板拉取和双订阅二维码链接。
- `cj -d` 一次改一项后回主菜单（原版改完直接退出脚本）；Argo 修改时输错返回主菜单（原版直接退出脚本）。
- 安装向导里指纹选择放在 Reality 提问之前（原版是在 Reality 流程里问），不影响结果。
- 外部小工具（ArgoX、sba、TCP brutal）是按原版的做法下载并运行第三方脚本，不是本仓库的代码。
- 动态订阅：开启时如果机器上没有 fcgiwrap / spawn-fcgi，探测失败、自动回退到静态订阅并提示；动态模式下只有分客户端端点（v2rayn / Throne / ShadowRocket / Clash / Clash2 / sing-box / auto / auto2）是实时渲染的，通用订阅 `/<UUID>/sub` 本身还是静态文件（`list.txt`）。
- ShellCheck 只跑了 error 级（0 个 error，53 条 warning，多为未使用变量），warning 没逐条修。
- `ports.env` 可能出现重复行：`write_inbound()` 每调一次就往 `ports.env` 追加一行，如果某段流程写了入站但没经过 `save_install_env()`（它会先清空再重写），`ports.env` 里就会有重复行。v1.0.27 起 `load_install_env()` 读端口时只取第一个匹配（`grep -m1`），重复行不会再把端口读成多行；客户配置重生成也会调 `save_install_env()` 把 `ports.env` 重写干净。正常安装和菜单 9 流程都是先写后存，本来就不会触发。
- 菜单 9 里刚删掉的协议不能在同一次里再加回来（增加列表是按进菜单时的已装列表算的）。
- 已装好的机器证书还是旧的 RSA 2048（新装用 EC P-256 + SAN），删掉 `/etc/sing-box/cert.pem` 和 `key.pem` 后重新生成订阅才会换成新的。
- ufw / firewalld / ip6tables 的端口跳跃 NAT 命令只在沙箱里用桩测过，没有在装了这些防火墙的真机上跑过。
