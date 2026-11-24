# sing-box 一键安装脚本（独立重写，v1.0.0）

一个独立重写的 sing-box 一键安装 / 管理脚本。菜单、安装流程和命令行用法对标常见的 sing-box 一键脚本（fscarmen/sing-box 的 sing-box.sh v1.3.31），但**代码全部是重新写的**，没有复制原版脚本的代码。

> 许可证：本脚本为 MIT 许可（见 `LICENSE`）。sing-box 本身是另一个项目（SagerNet/sing-box，GPL-3.0），本脚本只下载它的官方 release 二进制，不捆绑 sing-box 源码。

## 一键运行

```bash
bash <(wget -qO- https://raw.githubusercontent.com/<你的用户名>/<你的仓库名>/main/sing-box.sh)
```

把上面链接里的 `<你的用户名>/<你的仓库名>` 换成你自己的仓库和分支后，传到仓库就能用。也可以先下载再运行：

```bash
wget https://raw.githubusercontent.com/<你的用户名>/<你的仓库名>/main/sing-box.sh
bash sing-box.sh
```

装好后直接用快捷命令：

```bash
sb          # 打开菜单
sb -n       # 查看节点信息
sb -s       # 开/关 sing-box
sb -a       # 开/关 Argo
sb -t       # 修改 Argo
sb -d       # 修改配置
sb -v       # 查看/更新版本
sb -b       # 网络测速
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
| 2 | 开/关 sing-box（`sb -s`） |
| 3 | 开/关 Argo（`sb -a`） |
| 4 | 修改 Argo（`sb -t`） |
| 5 | 修改配置（`sb -d`） |
| 6 | 查看/更新版本（`sb -v`） |
| 7 | 网络测速 |
| 8 | 增删协议（`sb -r`） |
| 9 | 卸载（`sb -u`） |
| 10 | Argo 工具 |
| 11 | 订阅工具 |
| 12 | Hysteria2 工具 |
| 0 | 退出 |

菜单顶部会显示脚本版本、系统信息（操作系统 / 内核 / 架构 / 虚拟化）、IPv4 / IPv6，以及 Sing-box / Argo / Nginx 的状态、版本、内存占用和流量。

## 安装向导

按顺序问：选协议 → 起始端口（默认 8881，连续分配）→ 服务器地址（默认自动探测的公网 IP）→ UUID（默认随机生成）→ 节点名 → 客户端指纹（chrome / firefox）→ Reality 私钥（有 Reality 协议时，留空自动生成）→ Hysteria2 的 Realm、带宽、端口跳跃（只有选了 Hysteria2 才问）→ CDN 优选域名、订阅开关、Argo（只有选了走 Cloudflare 的协议才问）→ nginx 订阅端口。

## 协议表（28 种，全称）

协议名一律写全称：WebSocket 写全，不写 WS；Shadowsocks 不写 SS；Hysteria2 不写 Hy2。链接里的 `type=ws`、`type=http`、`ss://` 等是客户端协议格式本身，不能改，不算简写。内部 tag（如 `vless-ws-tls`）只用在配置文件名和 JSON 里。

| 编号 | 字母 | 协议全称 | 内部 tag | 走 Cloudflare |
| --- | --- | --- | --- | --- |
| 1 | b | Hysteria2 | hysteria2 | 否 |
| 2 | c | VLESS + Reality | vless-reality | 否 |
| 3 | d | AnyTLS | anytls | 否 |
| 4 | e | TUIC | tuic | 否 |
| 5 | f | Trojan | trojan | 否 |
| 6 | g | ShadowTLS | shadowtls | 否 |
| 7 | h | Shadowsocks | shadowsocks | 否 |
| 8 | i | Naive | naive | 否 |
| 9 | j | Snell v6 | snell-v6 | 否 |
| 10 | k | VLESS + Reality (Vision) / XTLS + Reality | xtls-reality | 否 |
| 11 | l | VLESS + WebSocket + TLS (CF) | vless-ws-tls | 是 |
| 12 | m | VMess + WebSocket (CF) | vmess-ws | 是 |
| 13 | n | VMess + WebSocket + TLS (CF) | vmess-ws-tls | 是 |
| 14 | o | Trojan + WebSocket (CF) | trojan-ws-tls | 是 |
| 15 | p | Shadowsocks 2022 AES-256 (CF) | ss2022-256 | 是（见替换说明） |
| 16 | q | VLESS + HTTP (CF) | vless-http | 是 |
| 17 | r | VMess + HTTP (CF) | vmess-http | 是 |
| 18 | s | Trojan + HTTP (CF) | trojan-http | 是 |
| 19 | t | VLESS + HTTPUpgrade (CF) | vless-httpupgrade | 是 |
| 20 | u | VMess + gRPC (CF) | vmess-grpc | 是 |
| 21 | v | Trojan + gRPC (CF) | trojan-grpc | 是 |
| 22 | w | VLESS + WebSocket + Reality | vless-ws-reality | 否 |
| 23 | x | VLESS + TCP + TLS (Vision) | vless-tls | 否 |
| 24 | y | Trojan + Reality | trojan-reality | 否 |
| 25 | z | Shadowsocks 2022 | ss2022 | 否 |
| 26 | aa | H2 + Reality | h2-reality | 否 |
| 27 | ab | gRPC + Reality | grpc-reality | 否 |
| 28 | ac | AnyTLS + Reality | anytls-reality | 否 |

选协议时：`a` = 全部 28 种；字母 `b`–`z` 对应第 1–25 种，`aa` / `ab` / `ac` 对应第 26–28 种；也可以直接输数字 `1`–`28`。可多选，可连写（如 `bcd`）、可空格、可逗号，大写自动转小写。端口按选择顺序从起始端口连续分配（例如起始端口 8881，全选占 8881–8908）。

第 10 号就是 XTLS + Reality（Vision 流控），和第 2 号普通 VLESS + Reality 不重复。

## 替换说明（15–18 号，原来想要的写法在官方 sing-box 上跑不起来）

实测 sing-box 1.14.4 官方二进制：

- **15 号**：原来想要的 Shadowsocks + WebSocket，`shadowsocks` 入站没有 `transport` 字段，写进去 `sing-box check` 会报错。改成官方支持的等价组合 **Shadowsocks 2022 AES-256**（`2022-blake3-aes-256-gcm`，32 字节密钥），菜单和链接都按这个名字写。
- **16 / 17 / 18 号**：原来想要的 VLESS / VMess / Trojan + XHTTP，`xhttp` 不是官方 sing-box 的合法传输类型（`unknown transport type: xhttp`，只存在于个别打补丁的 fork 里）。改成官方支持的等价组合 **HTTP 传输**（`type=http`，HTTP/1.1 + H2，路径和 CDN 流程复用 WebSocket 那套），菜单改成 VLESS + HTTP、VMess + HTTP、Trojan + HTTP。

如果坚持要原汁原味的 XHTTP / Shadowsocks + WebSocket，只能换核心（例如带 XHTTP 补丁的 fork 或 Xray-core），不在本脚本“官方 sing-box 二进制”的路线内。其余 24 种已在 sing-box 1.14.4 上逐个 `sing-box check` 通过，28 种合在一起也能通过，实际启动时 28 个入站全部监听。

## Hysteria2：带宽和端口跳跃

选了 Hysteria2 后，安装向导中途（Realm 问完、进 CDN / 订阅之前）会依次问：

1. **带宽**：上行/下行，单位 Mbps，例如 `100/100`，直接回车用默认 100/100。装好后用 `sb -d` 第 10 项也能改。
2. **端口跳跃**：直接问范围，例如 `20000:21000`，**直接回车跳过，不用端口跳跃**。输了范围才开启，范围须在 10000–65535 之间、起始小于结束，支持 `起始:结束` 和 `起始-结束` 两种写法。

问范围之前会先打印一页说明：有些运营商会限速或阻断单个 UDP 端口，端口跳跃把流量分散到一段 UDP 端口上；推荐用 1000 个左右的端口；NAT 小鸡能用的端口一般只有 20–30 个，填了没开放的端口会导致节点不通，请慎用；默认不开启。

## Argo 凭证指引

选 Token / JSON / Cloudflare API 时，脚本会先打印分步指引：去 https://dash.cloudflare.com/ ，Zero Trust > 网络 > 连接器，创建隧道并选择 Cloudflared，Token 就显示在那里；或者用已建隧道的 JSON 凭证；或者用 Cloudflare API 令牌（https://dash.cloudflare.com/profile/api-tokens > 创建令牌 > 创建自定义令牌），授予：帐户 > Cloudflare One 连接器：Cloudflared > 编辑，以及区域 > DNS > 编辑；帐户资源包括你的账户，区域资源包括特定区域的域名。权限不够时 API 调用会失败。

## 订阅和 Clash

- 订阅链接：`http://<服务器地址>:<nginx 端口>/sub`，文件在 `/etc/sing-box/subscribe/`（明文 `list_plain.txt`、base64 `list.txt`、Clash `clash.yaml`）。
- `clash.yaml` 是逐协议完整展开版：`proxies` 里按协议逐个写 VLESS / VMess / Trojan / Hysteria2 / Shadowsocks / TUIC / AnyTLS / Snell 等条目，`proxy-groups` 里有 PROXY 分组，`rules` 是 `MATCH,PROXY`。例外：Naive 没有对应的 Clash 代理类型，订阅文件里会留一行注释说明，节点链接本身仍在 `list_plain.txt` 里。
- 动态订阅（`--SUBSCRIBE dynamic` 或 `sb -d` 第 9 项）：nginx 按请求 Host 实时渲染，直连节点的 server 跟随访问地址，WebSocket / CDN / Argo 节点保持原地址不变。

## 修改配置（`sb -d`）

1. 端口（改起始端口，或逐个协议改独立端口）
2. UUID
3. 节点名
4. 服务器地址
5. 指纹
6. SNI
7. CDN
8. 订阅开关
9. 动态订阅开关
10. Hysteria2 带宽 / 跳跃 / Realm
11. 自定义路由（添加 / 查看 / 删除，`domain_suffix` 或 `rule_set`）
12. WARP 账号（重新注册免费账户，或手动输入信息）
13. 绑定网卡
0. 返回

每改一项后脚本都会 `sing-box check` 校验，通过才重载 / 重启，不通过报错不重启。

## 增删协议（`sb -r`）

先列已装的协议和端口，再问删除（字母多选，回车跳过），再问增加（字母多选，回车跳过）。改完按起始端口重新连续分配，删掉的入站文件删除、新增的写入，校验通过后重启服务、同步防火墙、重新输出节点链接。

## 命令行参数

```
sb -s    开/关 sing-box        sb -a    开/关 Argo
sb -t    修改 Argo             sb -d    修改配置
sb -u    卸载                  sb -n    查看节点信息
sb -v    查看/更新版本         sb -b    测速
sb -r    增删协议
-E / -C / --LANGUAGE en|zh    语言
-K / -L                       一键快速安装（-L 为中文）
-f / -F FILE                  从 KEY=VALUE 配置文件读安装答案
--CHOOSE_PROTOCOLS a|b c ...  按协议表选协议（a=全部 28 种）
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
- 服务：`sing-box.service`、`argo.service`；快捷命令：`/usr/local/bin/sb`（指向 `/etc/sing-box/installer.sh` 的副本）
- 防火墙记录：`/etc/sing-box/firewall/service_ports.list`

## 卸载

菜单选 9 或运行 `sb -u`：停服务、删服务文件、清端口跳跃 NAT、按记录删防火墙规则、删 nginx 订阅配置、删 `/etc/sing-box` 和 `/usr/local/bin/sb`。

## 已知限制（v1.0.0，第一版）

- ShadowTLS 节点在 `sb -n` 里导出的是它内部 Shadowsocks 的链接（`ss://`），不是独立的 ShadowTLS 客户端链接；Clash 里 ShadowTLS 条目也没有展开 detour，导入后需要按 ShadowTLS 的用法另行配置。这是第一版的已知问题，后续版本再改。
- `sb -d` 菜单是固定顺序的 13 项；原版是按已装协议动态拼菜单，本版为了第一版能用先用了固定顺序，功能一样，顺序不同。
- 安装向导里指纹选择放在 Reality 提问之前（原版是在 Reality 流程里问），不影响结果。
- 外部小工具（Argo 工具、订阅工具、Hysteria2 工具）是按原版的做法下载并运行第三方脚本（argox / sba / tcp.hy2.sh），不是本仓库的代码。
- 动态订阅在没有 fcgiwrap 的机器上会回退到静态文件（README 里这句沿用草稿说明，实际以装机时的表现为准）。
- ShellCheck 只跑了 error 级（0 个 error，53 条 warning，多为未使用变量），warning 没逐条修。
