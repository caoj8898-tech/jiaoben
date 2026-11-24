# sing-box 一键安装脚本（独立重写，v1.0.8）

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

> **v1.0.8 新行为：菜单 8（增加 / 删除协议）增加一键安装所有协议：在“增加协议”那一步输入 `all`（大小写不限），就一键安装全部未安装协议；已装过的保留，只装剩下的；空安装时就是安装全部 27 种。选完后还是先显示确认列表、等用户确认（按 [n] 取消）再执行。单独输入 `a` 还是只选未安装列表里的第 1 个协议，不是全部。**
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

## 协议表（27 种，全称）

协议名用 WS 缩写（用户要求，v1.0.5）：WebSocket 写成 WS；Shadowsocks 不写 SS；Hysteria2 不写 Hy2。链接里的 `type=ws`、`type=http`、`ss://` 等是客户端协议格式本身，不能改，不算简写。内部 tag（如 `vless-ws-tls`）只用在配置文件名和 JSON 里。

| 编号 | 字母 | 协议全称 | 内部 tag | 走 Cloudflare |
| --- | --- | --- | --- | --- |
| 1 | b | Hysteria2 | hysteria2 | 否 |
| 2 | c | VLESS + Reality | vless-reality | 否 |
| 3 | d | VLESS + Reality (Vision) / XTLS + Reality | xtls-reality | 否 |
| 4 | e | AnyTLS | anytls | 否 |
| 5 | f | TUIC | tuic | 否 |
| 6 | g | Trojan | trojan | 否 |
| 7 | h | ShadowTLS | shadowtls | 否 |
| 8 | i | Shadowsocks | shadowsocks | 否 |
| 9 | j | Naive | naive | 否 |
| 10 | k | Snell v6 | snell-v6 | 否 |
| 11 | l | VLESS + HTTPUpgrade (CF) | vless-httpupgrade | 是 |
| 12 | m | VLESS + WS + TLS (CF) | vless-ws-tls | 是 |
| 13 | n | Trojan + gRPC (CF) | trojan-grpc | 是 |
| 14 | o | VMess + gRPC (CF) | vmess-grpc | 是 |
| 15 | p | Trojan + WS (CF) | trojan-ws-tls | 是 |
| 16 | q | VMess + WS + TLS (CF) | vmess-ws-tls | 是 |
| 17 | r | Shadowsocks 2022 AES-256 (CF) | ss2022-256 | 是（见替换说明） |
| 18 | s | VLESS + HTTP (CF) | vless-http | 是 |
| 19 | t | VMess + HTTP (CF) | vmess-http | 是 |
| 20 | u | Trojan + HTTP (CF) | trojan-http | 是 |
| 21 | v | VLESS + WS + Reality | vless-ws-reality | 否 |
| 22 | w | VLESS + TCP + TLS (Vision) | vless-tls | 否 |
| 23 | x | Trojan + Reality | trojan-reality | 否 |
| 24 | y | Shadowsocks 2022 | ss2022 | 否 |
| 25 | z | H2 + Reality | h2-reality | 否 |
| 26 | aa | gRPC + Reality | grpc-reality | 否 |
| 27 | ab | AnyTLS + Reality | anytls-reality | 否 |

选协议时：`a` = 全部 27 种；字母 `b`–`z` 对应第 1–25 种，`aa` / `ab` 对应第 26–27 种；也可以直接输数字 `1`–`27`。可多选，可连写（如 `bcd`）、可空格、可逗号，大写自动转小写。端口按选择顺序从起始端口连续分配（例如起始端口 8881，全选占 8881–8907）。

第 3 号就是 XTLS + Reality（Vision 流控），和第 2 号普通 VLESS + Reality 不重复。

## 替换说明（17–20 号，原来想要的写法在官方 sing-box 上跑不起来）

实测 sing-box 1.14.4 官方二进制：

- **17 号**：原来想要的 Shadowsocks + WS，`shadowsocks` 入站没有 `transport` 字段，写进去 `sing-box check` 会报错。改成官方支持的等价组合 **Shadowsocks 2022 AES-256**（`2022-blake3-aes-256-gcm`，32 字节密钥），菜单和链接都按这个名字写。
- **18 / 19 / 20 号**：原来想要的 VLESS / VMess / Trojan + XHTTP，`xhttp` 不是官方 sing-box 的合法传输类型（`unknown transport type: xhttp`，只存在于个别打补丁的 fork 里）。改成官方支持的等价组合 **HTTP 传输**（`type=http`，HTTP/1.1 + H2，路径和 CDN 流程复用 WebSocket 那套），菜单改成 VLESS + HTTP、VMess + HTTP、Trojan + HTTP。

如果坚持要原汁原味的 XHTTP / Shadowsocks + WS，只能换核心（例如带 XHTTP 补丁的 fork 或 Xray-core），不在本脚本“官方 sing-box 二进制”的路线内。其余 23 种已在 sing-box 1.14.4 上逐个 `sing-box check` 通过，27 种合在一起也能通过，实际启动时 27 个入站全部监听。

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
--CHOOSE_PROTOCOLS a|b c ...  按协议表选协议（a=全部 27 种）
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

## v1.0.8 改了什么

- 菜单 8（增加 / 删除协议，`sb -r`）增加一键安装所有协议：在列出未安装协议后，提示写明输入 `all` 一键安装全部未安装协议；输入 `all` / `ALL`（大小写不限，前后空格也行）时，新增列表 = 全部未安装协议，已安装的保留（keep 列表不变）；空安装时就是安装全部 27 种。单独输入 `a` 还是只选未安装列表里的第 1 个协议，不是全部（`all` 在进入字母解析前就拦截了，不会被拆成字母 `a`+`l`+`l`）。选完后原有的确认列表（保留 + 新增）和按 [n] 取消流程不变，一键全部也要先显示确认列表、等用户确认再执行；之后走原来的确认、端口分配、写站、Argo 询问、重启、订阅流程，和原来选全部时完全一样。提示文字是中英双语（`add_protocols_prompt` 消息键）。
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
- 菜单 5（`sb -d`）和菜单 8（`sb -r`）在空协议下没有别的硬性检查：`sb -d` 的动态列表里端口、节点名、UUID、服务器地址、指纹等项本来就有，空协议时正常显示；`sb -r` 本来就是先删、再加、最后确认的流程，空协议时直接列出全部 27 种待添加，确认后按新装流程问起始端口和节点名。

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
- ShadowTLS 节点在 `sb -n` 里导出的是它内部 Shadowsocks 的链接（`ss://`），不是独立的 ShadowTLS 客户端链接；Clash 里 ShadowTLS 条目也没有展开 detour，导入后需要按 ShadowTLS 的用法另行配置。这是第一版的已知问题，后续版本再改。

- 安装向导里指纹选择放在 Reality 提问之前（原版是在 Reality 流程里问），不影响结果。
- 外部小工具（ArgoX、sba、TCP brutal）是按原版的做法下载并运行第三方脚本，不是本仓库的代码。
- 动态订阅在没有 fcgiwrap 的机器上会回退到静态文件（实际以装机时的表现为准）。
- ShellCheck 只跑了 error 级（0 个 error，53 条 warning，多为未使用变量），warning 没逐条修。
