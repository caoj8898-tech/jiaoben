# BOSS J 一键安装脚本（v1.0.15）

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
| 10 | 安装 ArgoX 脚本 (argo + xray) |
| 11 | 安装 sba 脚本 (argo + sing-box) |
| 12 | 安装 TCP brutal |
| 0 | 退出 |

菜单顶部会显示脚本版本、系统信息（操作系统 / 内核 / 架构 / 虚拟化）、IPv4 / IPv6，以及 Sing-box / Argo / Nginx 的状态、版本、内存占用和流量。状态在中文模式下显示为开启 / 关闭 / 未安装（英文模式 Running / Stopped / Not installed）。主菜单底部右下角显示累计运行次数（中文「累计运行 N 次」，英文 `Total runs: N`），每次进菜单加 1，次数存在 `/etc/sing-box/run_count`，重装脚本不丢；单项命令（`sb -n` 等）不计数。菜单选项（主菜单和子菜单）都是加粗黄色，「请选择：」提示是绿色。

## 安装向导

按顺序问：选协议 → 起始端口（默认 8881，连续分配）→ 服务器地址（默认自动探测的公网 IP）→ UUID（默认随机生成）→ 节点名 → 客户端指纹（chrome / firefox）→ Reality 私钥（有 Reality 协议时，留空自动生成）→ Hysteria2 的 Realm、带宽、端口跳跃（只有选了 Hysteria2 才问）→ CDN 优选域名、订阅开关、Argo（只有选了走 Cloudflare 的协议才问）→ nginx 订阅端口。

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

## v1.0.15 改了什么

- CDN 优选域名选择：`sb -d` 里改优选域名时，列表里当前用的后面标「（当前）」，直接回车保持不变，不再悄悄改回默认；安装向导里没有当前值，直接回车仍用默认 `cf.3666888.xyz`。
- 主菜单底部右下角显示累计运行次数（中文「累计运行 N 次」，英文 `Total runs: N`），每次进菜单加 1；次数存在 `/etc/sing-box/run_count`，重装脚本不丢；单项命令（`sb -n`、`sb -s` 等）不计数。
- 中文显示：主菜单状态栏的状态词中文模式显示 开启 / 关闭 / 未安装（英文模式 Running / Stopped / Not installed）；`sb -d` 里的当前值中文模式显示为「（当前：X）」；菜单 4、菜单 5、菜单 8、CDN 选择、Argo 提示等子菜单里的英文提示也改成中文（英文模式不变）。
- 子菜单选项列表改成加粗黄色，和主菜单一样；「请选择：」提示改成绿色（只改提示颜色，输入值的地方不变）。
- CDN 候选域名从 10 个加到 13 个：新增 `xn--b6gac.eu.org`、`cfvip.cf.3666888.xyz`、`fn.130519.xyz`；默认仍是 `cf.3666888.xyz`。
- **升级注意：从 v1.0.14 升级到 v1.0.15，协议编号没变，不用重新选协议；从 v1.0.13 及更早版本升级的机器，旧 `install.env` / `selected.env` 里存的是旧协议编号，升级后请从菜单 8 重新选一次协议；全新安装不受影响。**
- 测试：按用户要求做了全面测试，见下面的测试记录；真机完整安装、订阅在真实客户端里打开和同步、CF 节点实际连通仍需用户实测。

## v1.0.15 测试记录

测试方法是把真实脚本里的函数抽出来，在测试目录跑（`SB_HOME` 指向 `/tmp/sbtest15/home`，不用系统服务：`svc` / `sync_firewall` / `setup_argo` / `start_nginx_safe` 打桩成空操作；TLS 证书用脚本自己的 `make_self_signed_cert` 生成在 `/etc/sing-box/`，和真实安装一致），不改系统、不装到真机。结果：**61 项检查，全部通过，0 失败**。

- **结构检查 18/18**：`bash -n` 通过；版本 v1.0.15 (2026.11.25)；CDN 候选 13 个（新增 xn--b6gac.eu.org、cfvip.cf.3666888.xyz、fn.130519.xyz，默认仍是 cf.3666888.xyz）；33 个新增 `tr_text` 消息键中英双语齐全；`ask_choice` 14 处调用、`ask_line choose_option` 零残留；菜单 5 / 菜单 4 / 菜单 8 / CDN 选择里都有 `c_yellow`；主菜单调 `bump_run_count` + `print_run_count`，单项命令不经过；`print_header` 三处都用 `status_word`、不改状态变量；只剩 2 处功能性下载链接（ArgoX / sba 的 raw.githubusercontent.com 地址）；菜单标签和文档里已无第三方作者名和旧版重写表述；无 Argo 加固改动（`resolve_try_domain` 仍是 `head -1`）。
- **CDN 选择器 7/7**：菜单 5 里当前域名标「（当前）」，直接回车保持不变；输数字换域名；安装向导（无当前值）直接回车用默认 cf.3666888.xyz；数字 13 选到 fn.130519.xyz；英文模式标 "(current)"、回车保持；列表加粗黄色。
- **运行次数 7/7**：首次运行建文件记 1，再跑记 2；文件内容非数字时重置为 1；写不进文件时静默跳过、不影响菜单；中文「累计运行 12 次」在 C.UTF-8 下显示宽度正好 80 列（右对齐），英文 "Total runs: 7" 同样 80 列；POSIX locale 下退化为按字节对齐（80 字节）。
- **中文显示 11/11**：`status_word` 三种状态中英双语都对，未知状态原样返回；`print_header` 中文模式显示 开启/关闭/未安装、英文模式 Running/Stopped/Not installed，状态变量本身不变。
- **颜色 3/3**：`ask_choice` 提示是加粗绿色、能读到输入值、EOF 时返回空；英文提示同样是绿色。
- **sing-box 配置实测 6/6**：官方 sing-box 1.14.4 二进制跑 `sing-box check -C`：真实 `write_base_config` / `write_inbound` / `generate_reality_keys` 生成的**全部 19 个入站配置通过**、**删除全部后的空配置（只有 base）通过**、Hysteria2 / TUIC / Shadowsocks 2022 AES-256 / Shadowsocks 2022 单协议配置各自通过。
- **菜单 5 实测 5/5**：输错返回 0、列表显示「（当前：cf.xreak.top）」且加粗黄色；进 CDN 选单直接回车，`install.env` 里仍是 cf.xreak.top；输 3 改成 time.is 并保存。
- **菜单 8 实测 4/4**：跳过并取消后三个状态文件字节不变；删除 `all` 再取消同样不变；增加 Shadowsocks 后 `selected.env` 是 (0 1 6 7)、入站文件已写、`sing-box check` 通过；删除全部并确认后选择为空、只有基础配置、`sing-box check` 通过。
- **测试里发现并已修掉的问题**：`print_run_count` 最初用 `printf '%*s'` 直接按宽度填充，中文行按字节算会短 5 列（`累计运行 12 次` 是 19 字节、9 字符，行只有 70 字符）；已改成按显示宽度算（CJK 算 2 列），中文/英文都正好 80 列；POSIX locale 下退化为按字节对齐。另：脚本里 TLS 证书路径是写死的 `/etc/sing-box/cert.pem`（不是 `SB_HOME` 拼出来的），测试里按真实安装的路子生成证书，这一点是原有设计、这次没改。
- **没法在本机跑的（需用户实测）**：真机完整安装流程；订阅在真实客户端里打开和同步；CF 节点在真实客户端实际连通；菜单 5 / 菜单 8 在真机上的真实交互；Hysteria2 端口跳跃的 NAT 规则在真机上实际生效。

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
