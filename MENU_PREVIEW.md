# sing-box 一键安装脚本 — 菜单预览（MENU PREVIEW）

> **状态：v1.0.13。菜单与 `sing-box.sh`（v1.0.13）一致，已安装主菜单按用户发的原版改好，子菜单按原版 fscarmen/sing-box v1.3.31 对过，新增 `cj` 快捷命令。**
> State: for confirmation only. The full script will be produced after the user confirms this preview.
>
> - 脚本文件：`~/workspace/sing-box-own/sing-box.sh`（v1.0.13 (2026.11.24)，sing-box 默认版本 1.14.4）
> - 说明文件：`~/workspace/sing-box-own/README.md`，许可证：`~/workspace/sing-box-own/LICENSE`（MIT）
> - 本预览文件：`~/workspace/sing-box-own/MENU_PREVIEW.md`
> - 预览依据：已逐个核对脚本里的 `pick_language()`、`print_header()`、`main_menu()`、`show_protocol_picker()`、`ask_wizard_*()`、`run_install()`、`change_config_menu()`、`change_ports_menu()`、`change_protocols_menu()`、`custom_route_menu()`、`change_argo_menu()`、`export_list()`、`show_version()`、`run_uninstall()`。凡是预览与脚本不一致的地方，都在文末「⚠️ 预览与脚本当前草稿的差异」里标出，不藏着。
> - 颜色说明：终端里绿色是标题/成功信息，黄色是菜单选项，红色是警告/错误，蓝色是提示信息。以下代码块去掉了颜色，只保留文字和顺序。
>
> **新安装命令：** 普通安装（出菜单，自己选）：`bash <(wget -qO- https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh)`；一键快速安装（英文）：`bash <(wget -qO- https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh) -K`。仓库必须是公开的才能用这个链接拉到，私有会 404。
>
> **本次修改（v1.0.13）：去掉 nginx 8080 监听上的 `http2`（修 v1.0.9 引入的回归）+ 菜单 8 删除协议支持一键删除全部。** http2：v1.0.9 为了 gRPC 给 8080 加了 `listen … http2`，但这会让监听口只认 HTTP/2 明文（h2c）：普通 HTTP/1.1 请求（订阅 `/sub`、curl、客户端同步订阅）走到这个口上，返回的根本不是正常 HTTP 响应，curl 报 `Received HTTP/0.9 when not allowed`，客户端显示连接错误、拉不到节点；脚本自己只看端口通不通，所以没有任何错误提示。现改回普通 `listen 8080` / `listen [::]:8080`，订阅恢复正常 HTTP/1.1 响应；gRPC 到入站仍走 `grpc_pass grpcs://`（nginx 到入站那段，不依赖监听上的 http2），cloudflared 到 nginx 本来就是 `--url http://127.0.0.1:8080`（HTTP/1.1）。另外订阅验证加强了：`start_nginx_safe()` 失败时把 `/sub` 的实际 HTTP 码打出来，000 就表示 nginx 返回的东西根本不是正常 HTTP，不再只给一句通用提示。**删除全部：菜单 8 删除协议那一步输入 `all`（大小写不限），就删除全部已安装协议；单独输入 `a` 还是只删已安装列表里的第 1 个，不是全部。删完照常走确认那步（保留列表为空，按 [n] 可以取消），确认后才真正删；删完一个都不剩时空配置正常保存、服务正常重启、订阅为空，不会崩。**（注：http2 修复原计划随 v1.0.12 单独发版，因用户追加了删除全部需求，未单独发 v1.0.12，两项改动合并在 v1.0.13 一起交付。）升级后请实测 `curl -I http://127.0.0.1:8080/sub` 返回 200，客户端重新同步订阅能拉到节点。
>
> **上次修改（v1.0.11）：防火墙 UDP 放行列表修正。** `sync_firewall()` 原来是 `1|3|5|15` 号放 UDP，但那四个全是只用 TCP 的协议（VLESS + Reality、AnyTLS、Trojan、VMess + WS + TLS (CF)），真正要用 UDP 的 6 个协议反而一个都没放：Hysteria2（0 号，QUIC/UDP）、TUIC（4 号，QUIC/UDP）、Shadowsocks（7 号，UDP 转发）、Snell v6（9 号）、Shadowsocks 2022 AES-256（19 号，UDP 转发，直连）、Shadowsocks 2022（23 号，UDP 转发）。现改成 `0|4|7|9|19|23` 放 UDP。ShadowTLS（6 号）外层是 TCP、内层 Shadowsocks 只监听 127.0.0.1，不用对外放 UDP；CF 组（10–18 号）和其余 VLESS / VMess / Trojan / Naive / H2 / gRPC / AnyTLS 全是 TCP。升级后请重新同步一次防火墙，Hysteria2 / TUIC / Snell / Shadowsocks 这几个 UDP 节点要实测连通。
>
> **上次修改（v1.0.10）：Shadowsocks 2022 AES-256 去掉名字里的 (CF)、移到 CF 组后面（新 20 号）。** 它没有 WS / HTTP / gRPC 传输，走不了 CF 隧道和 nginx 反代，只能直连，名字里的 (CF) 是误导，所以去掉；排序上从旧 17 号移到 CF 组后面（新 20 号，VLESS + WS + Reality 前面），VLESS + HTTP、VMess + HTTP、Trojan + HTTP 顺移到 17 / 18 / 19 号。CF 组现在是 11–19 号（9 个），其余组是 20–27 号（Shadowsocks 2022 AES-256 排在其余组第一位）。**升级提醒：已装过旧版的机器，`install.env` / `selected.env` 里存的是旧协议编号，升级到 v1.0.10 后旧 16–19 号协议会错位（例如旧 17 号 Shadowsocks 2022 AES-256 会读成新 17 号 VMess + HTTP），升级后请从菜单 8 重新选一次协议；全新安装不受影响。**
>
> **本次修改（v1.0.9）：修 CF 节点不通 + `cj` 调不出菜单。** CF 节点：13 号 Trojan + gRPC、14 号 VMess + gRPC 的链接之前写的是服务器 IP 和本地端口，现改成和其他 CF 协议一样走 Argo 隧道域名:443（没开 Argo 时走 CDN 优选域名和本地端口）；17 号 Shadowsocks 2022 AES-256 没有传输层可供 nginx / Argo 代理，链接改回直连服务器 IP:本地端口；nginx 反代新增 `/vless-httpupgrade`、`/vmess-grpc/`、`/trojan-grpc/` 三个位置（gRPC 用 `grpc_pass grpcs://`，WS / HTTP 入站反代改走 `https://`，入站开了自签 TLS）；写完 nginx 配置后只要有 nginx 进程在跑就先 `nginx -s reload`，订阅不再因配置没加载而打不开。`cj` / `sb`：快捷命令在语言选择之前就创建；`cj` 无参数且没存过语言时默认中文直接进菜单；本地已有完整脚本文件时优先用它，不再每次重新下载；重新下载失败时明确报错，不再静默无反应。
>
> **本次修改（v1.0.8）：菜单 8（增加 / 删除协议）增加一键安装所有协议：在“增加协议”那一步输入 `all`（大小写不限），就一键安装全部未安装协议；已装过的保留，只装剩下的；空安装时就是安装全部 27 种。选完后还是先显示确认列表、等用户确认（按 [n] 取消）再执行。单独输入 `a` 还是只选未安装列表里的第 1 个协议，不是全部。**
>
> **本次修改（v1.0.7）：协议重排成 27 种：原来第 10 号的 VLESS + Reality (Vision) / XTLS + Reality 移到第 3 号（VLESS + Reality 后面）；走 CF 的协议按网速优先、延迟其次重排成 11. VLESS + HTTPUpgrade、12. VLESS + WS + TLS、13. Trojan + gRPC、14. VMess + gRPC、15. Trojan + WS、16. VMess + WS + TLS、17. Shadowsocks 2022 AES-256、18. VLESS + HTTP、19. VMess + HTTP、20. Trojan + HTTP；删掉 VMess + WS (CF)；其他位置不动，序号重排。已装过旧版的机器升级后请从菜单 8 重新选一次协议（旧 install.env / selected.env 存的是旧编号）。**
>
> **本次修改（v1.0.6）：CDN 优选域名新增 cf.xreak.top、cf.3666888.xyz、cfsaas.080112.xyz、cf.92555.xyz；菜单 8 加了走 CF 的协议后自动问 Argo 隧道（1. 临时隧道、2. 固定隧道、3. 不启用），临时隧道开通后自动拿域名并匹配到 CF 节点链接（隧道域名:443）；nginx 启动改成安全启动（旧进程占 8080 时先重载，不行再杀旧进程重起）；`sb` / `cj` 记住上次语言直接进主菜单；语言选择里“2. 简体中文”标黄。**
>
> **本次修改（v1.0.5）：协议名 WebSocket 改成 WS；菜单 8 加完协议后自动 enable + 启动 sing-box（失败明确报错），并自动启用订阅 nginx，节点和 /sub 链接都能用了。**
>
> **本次修改（v1.0.4）：自动补装时生成空的安装状态。** v1.0.3 只补装了主程序，没生成 `install.env`，菜单 1/5/8 一进去就报“sing-box 尚未安装。”。v1.0.4 在补装时（主程序本来就已存在但 `install.env` 缺失时也会补）生成空的 `install.env`（默认值填好，协议为空），同时写好基础配置（无协议）、自签 TLS 证书、Reality 密钥和服务文件（只写文件，不启动服务）。菜单 1/5/8 都能正常打开，菜单 1 暂无协议时提示“暂无协议，请从菜单 8 增加 / 删除协议里添加”，协议从菜单 8 添加。
>
> **本次修改（v1.0.3）：首次运行自动补装主程序。** 第一次运行脚本进菜单时，`/etc/sing-box/sing-box` 缺失就自动补装主程序 + cloudflared（Argo 用），不装协议、不写配置、不启动服务；补装成功后直接显示已安装菜单 1–12 项，协议是空的，从菜单 8 增加 / 删除协议里自己选。补装失败留在未安装菜单 1–9 项并提示原因；cloudflared 失败只提示。ArgoX / xray 不在首次自动补装范围。
>
> **本次修改（v1.0.1）：已安装主菜单改成用户发的原版 1–12 项（2/3 项动态开/关、6 项同步 Sing-box 和 Argo、7 项改成 tcpx.sh、10/11/12 项改成 ArgoX / sba / TCP brutal）；新增 `cj` 快捷命令；`sb -d`、`sb -r`、自定义路由、WARP、Argo、端口修改、卸载、版本信息等子菜单按原版 fscarmen/sing-box v1.3.31 对过；28 种协议顺序、全称、15–18 号替换、Hysteria2 跳跃回车跳过、带宽、说明页、Clash 展开保持 v1.0.0 不变。**
>
> **本次修改（2026-11-24 第三次更新）：按用户追加要求，VLESS + WS + Reality 移出 CF 组，移到其余组第一位（新 22 号，不标注 CF）；CF 组从 12 个变成 11 个（11–21 号）；其余组为 22–28 号。其他顺序不变，总数仍是 28 种。**
>
> **本次修改（2026-11-24 第四次更新）：Hysteria2 端口跳跃改为一步式、回车跳过。安装向导中途（Realm 问完、进 CDN/订阅之前）直接问跳跃范围，不再先问 `Use port hopping? [y/N]`；直接回车 = 不用端口跳跃，继续往下装。`sb -d` 里改跳跃同样是输范围、回车跳过/保持不变。其他顺序、编号、分组一律不动，总数仍 28 种。**

---

## 0. 本次确认的重点：协议分组排序（新顺序，1–27）

**Grouping (new order — this is the main thing to confirm).**

协议按用户 2026-11-24 的要求重排（v1.0.10 最新顺序）：**前 10 个置顶**（1–10），**能走 CF 的 11–19 号紧跟在第 10 名之后（按网速优先、延迟其次排：VLESS + HTTPUpgrade、VLESS + WS + TLS、Trojan + gRPC、VMess + gRPC、Trojan + WS、VMess + WS + TLS、VLESS + HTTP、VMess + HTTP、Trojan + HTTP）**，其余 20–27 跟上（Shadowsocks 2022 AES-256 排在其余组第一位，20 号，不标注 CF），编号连续，字母从 `b` 开始顺延，`a = 全部`。端口分配、--CHOOSE_PROTOCOLS、sb -d、sb -r、导出链接顺序，全部按这个新顺序。分组改成三组：**置顶常用（1–10）、走 Cloudflare（11–19，协议名后逐个标注“（CF）”）、其余（20–27，Shadowsocks 2022 AES-256 已按用户要求移出 CF 组、排在其余组第一位，不标注 CF）**。

| 编号 | 字母 | 协议（中文菜单名） | 英文 | 内部 tag | 组 |
| --- | --- | --- | --- | --- | --- |
| 1 | b | Hysteria2 | Hysteria2 | hysteria2 | 置顶常用 |
| 2 | c | VLESS + Reality | VLESS + Reality | vless-reality | 置顶常用 |
| 3 | d | VLESS + Reality (Vision) / XTLS + Reality | VLESS + Reality (Vision) / XTLS + Reality | xtls-reality | 置顶常用 |
| 4 | e | AnyTLS | AnyTLS | anytls | 置顶常用 |
| 5 | f | TUIC | TUIC | tuic | 置顶常用 |
| 6 | g | Trojan | Trojan | trojan | 置顶常用 |
| 7 | h | ShadowTLS | ShadowTLS | shadowtls | 置顶常用 |
| 8 | i | Shadowsocks | Shadowsocks | shadowsocks | 置顶常用 |
| 9 | j | Naive | Naive | naive | 置顶常用 |
| 10 | k | Snell v6 | Snell v6 | snell-v6 | 置顶常用 |
| 11 | l | VLESS + HTTPUpgrade（CF） | VLESS + HTTPUpgrade (CF) | vless-httpupgrade | 走 Cloudflare |
| 12 | m | VLESS + WS + TLS（CF） | VLESS + WS + TLS (CF) | vless-ws-tls | 走 Cloudflare |
| 13 | n | Trojan + gRPC（CF） | Trojan + gRPC (CF) | trojan-grpc | 走 Cloudflare |
| 14 | o | VMess + gRPC（CF） | VMess + gRPC (CF) | vmess-grpc | 走 Cloudflare |
| 15 | p | Trojan + WS（CF） | Trojan + WS (CF) | trojan-ws-tls | 走 Cloudflare |
| 16 | q | VMess + WS + TLS（CF） | VMess + WS + TLS (CF) | vmess-ws-tls | 走 Cloudflare |
| 17 | r | VLESS + HTTP（CF） | VLESS + HTTP (CF) ⚠️ | vless-http | 走 Cloudflare |
| 18 | s | VMess + HTTP（CF） | VMess + HTTP (CF) ⚠️ | vmess-http | 走 Cloudflare |
| 19 | t | Trojan + HTTP（CF） | Trojan + HTTP (CF) ⚠️ | trojan-http | 走 Cloudflare |
| 20 | u | Shadowsocks 2022 AES-256 | Shadowsocks 2022 AES-256 | ss2022-256 | 其余 |
| 21 | v | VLESS + WS + Reality | VLESS + WS + Reality | vless-ws-reality | 其余 |
| 22 | w | VLESS + TCP + TLS（Vision） | VLESS + TCP + TLS (Vision) | vless-tls | 其余 |
| 23 | x | Trojan + Reality | Trojan + Reality | trojan-reality | 其余 |
| 24 | y | Shadowsocks 2022 | Shadowsocks 2022 | ss2022 | 其余 |
| 25 | z | H2 + Reality | H2 + Reality | h2-reality | 其余（冷门） |
| 26 | aa | gRPC + Reality | gRPC + Reality | grpc-reality | 其余（冷门） |
| 27 | ab | AnyTLS + Reality | AnyTLS + Reality | anytls-reality | 其余（冷门） |

字母说明（Letter mapping — to be confirmed）：

- `a` = 全部 27 种（ALL）。
- `b`–`z` = 第 1–25 种（单字母）。
- `aa`、`ab` = 第 26、27 种（双字母，因为单字母用完了）。
- 输入方式和现在脚本一样：可多选，可连写（如 `bcd`）、可空格（如 `b c d`）、可逗号、大写自动转小写；也可以按数字 `1`–`27` 选（`12` = 第 12 种 VLESS + WS + TLS（CF））。去重、按输入顺序保留。
- 字母 `aa/ab` 和数字 `1`–`27` 在 v1.0.0 脚本里都已支持。

> **备注——第 3 号“VLESS + Reality Vision”：** 用户写的按原表对应 **XTLS + Reality（Vision 流控，tag `xtls-reality`）**，不是新增一个协议，总数是 27 种。第 2 号是普通 VLESS + Reality（`vless-reality`，不带 Vision / XTLS 流控），第 3 号是带 Vision 的 XTLS + Reality，两者不重复。预览里第 3 号写成“VLESS + Reality (Vision) / XTLS + Reality”，已按这个对应关系落实。

**替换说明（15、16、17、18 号，v1.0.0 已落实）：**

- 15 号原来想要的 Shadowsocks + WS：官方 sing-box 的 `shadowsocks` 入站没有 `transport` 字段，写进去 `sing-box check` 会报错（1.14.4 官方二进制实测）。已改成官方支持的等价组合 **Shadowsocks 2022 AES-256**（`2022-blake3-aes-256-gcm`，32 字节密钥），菜单和链接都按这个名字写。
- 16/17/18 号原来想要的 VLESS / VMess / Trojan + HTTP：`xhttp` 不是官方 sing-box 的合法传输类型（`unknown transport type: xhttp`，只存在于个别打补丁的 fork 里）。已改成官方支持的等价组合 **HTTP 传输**（`type=http`），菜单改成 VLESS + HTTP、VMess + HTTP、Trojan + HTTP。
- 其余 23 种已在 sing-box 1.14.4 上逐个 `sing-box check` 通过，27 种合在一起也通过，实际启动时 27 个入站全部监听。

分组说明（Grouping rationale）：

- **置顶常用组（1–10）**：按用户给的顺序置顶——Hysteria2、VLESS + Reality、AnyTLS、TUIC、Trojan、ShadowTLS、Shadowsocks、Naive、Snell v6、VLESS + Reality (Vision) / XTLS + Reality。
- **走 Cloudflare 组（11–19）**：能走 CF 的全部排到第 10 名之后，协议名后逐个标注“（CF）”——VLESS + HTTPUpgrade、VLESS + WS + TLS、Trojan + gRPC、VMess + gRPC、Trojan + WS、VMess + WS + TLS、VLESS + HTTP、VMess + HTTP、Trojan + HTTP。都要经过 nginx / CDN / Argo 或 HTTP/gRPC 传输，安装时要多问域名、CDN、回源方式，集中放一组。Shadowsocks 2022 AES-256 已按用户要求移出本组，排在其余组第一位（20 号），不标注 CF。
- **其余组（20–27）**：Shadowsocks 2022 AES-256、VLESS + WS + Reality、VLESS + TCP + TLS、Trojan + Reality、Shadowsocks 2022、H2 + Reality、gRPC + Reality、AnyTLS + Reality，按这个顺序跟在 CF 组后面。

---

## 1. 启动语言选择菜单

**函数：`pick_language()`。启动后第一个画面。如果已经用 `-E` / `-C` / `--LANGUAGE` 指定过语言，就不再问，直接跳过。**

中文（默认按回车 = 英文，输入 `2` 选中文）：

```
Choose language:
 1. English (default)
 2. 简体中文
Choose an option: _
```

英文对照（English — the same screen, since the language has not been chosen yet）：

```
Choose language:
 1. English (default)
 2. 简体中文
Choose an option: _
```

> 说明：选了之后，之后所有提示都按这个语言显示。输入 `2` / `c` / `zh` 选中文，其他（包括直接回车）选英文。
> What it does: picks the language for all later prompts. `2` / `c` / `zh` = Chinese; anything else (including Enter) = English.

---

## 2. 未安装时主菜单（1–9 + 0）

**函数：`main_menu()` + `print_header()`（见第 3 节顶部状态栏）。第一次运行、还没装过时显示这个。**

中文：

```
================================================================================
 Script version: v1.0.2 (2026.11.24)
 What's new: quick install, subscription, Argo, port hopping, WARP
 System information:
        Operating system: Ubuntu 24.04.5 LTS
        Kernel: 7.0.0-44-generic
        Architecture: x86_64
        Virtualization: systemd-nspawn
        IPv4: 1.2.3.4
        IPv6: 2001:db8::1
        Sing-box: not-installed not-installed
        Argo:     not-installed not-installed
        Nginx:    not-installed not-installed
================================================================================

 1. Quick install (all protocols)            一键快速安装（全部协议）
 2. Install + subscription + Argo            安装 + 订阅 + Argo
 3. Install + Argo                           安装 + Argo
 4. Install + subscription                   安装 + 订阅
 5. Custom install                           自定义安装
 6. Network speed test                       网络测速
 7. Argo helper tool                         Argo 工具
 8. Subscription helper tool                 订阅工具
 9. Hysteria2 helper tool                    Hysteria2 工具
 0. Exit                                     退出

Choose an option: _
```

英文（English — same numbers, English labels）：

```
 1. Quick install (all protocols)
 2. Install + subscription + Argo
 3. Install + Argo
 4. Install + subscription
 5. Custom install
 6. Network speed test
 7. Argo helper tool
 8. Subscription helper tool
 9. Hysteria2 helper tool
 0. Exit
```

> 说明 / What each option does：
>
> - `1` 一键快速安装：全部 27 种协议、默认端口 8881 起、订阅开、Argo 用临时隧道，不再逐项问，直接装完出链接。
> - `2` 安装 + 订阅 + Argo：进安装向导（第 4 节），订阅开、Argo 开。
> - `3` 安装 + Argo：进安装向导，订阅关、Argo 开。
> - `4` 安装 + 订阅：进安装向导，订阅开、Argo 关。
> - `5` 自定义安装：进安装向导，协议、端口、订阅、Argo 全部现场选。
> - `6` 测速：下载并运行 tcpx.sh（升级内核、安装 BBR、DD 脚本、测速都在那个脚本里，和已安装菜单第 7 项、`sb -b` 是同一条路）。
> - `7` Argo 工具：下载并运行外部 Argo 辅助工具（argox）。
> - `8` 订阅工具：下载并运行外部订阅辅助工具（sba）。
> - `9` Hysteria2 工具：下载并运行 Hysteria2 辅助工具（tcp.hy2.sh）。
> - `0` 退出。
> - 输错数字会提示 `Please enter a number in the range shown. / 请输入菜单中显示的数字范围。`，停 1 秒后重新显示菜单。

---

## 3. 已安装时主菜单（1–12 + 0）+ 顶部状态栏

**函数：`main_menu()` + `print_header()`。装好后每次运行 `sb` 或 `bash sing-box.sh` 都显示这个。**

中文：

```
================================================================================
 Script version: v1.0.2 (2026.11.24)
 What's new: quick install, subscription, Argo, port hopping, WARP
 System information:
        Operating system: Ubuntu 24.04.5 LTS
        Kernel: 7.0.0-44-generic
        Architecture: x86_64
        Virtualization: systemd-nspawn
        IPv4: 1.2.3.4
        IPv6: 2001:db8::1
        Sing-box: running     1.14.4         12.34 MB  ↓1.23 MB ↑456.78 KB
        Argo:     running     2026.1.1       8.90 MB
        Nginx:    running     1.24.0         5.67 MB
================================================================================

 1. 查看节点信息 (sb -n)
 2. 关闭 Sing-box (sb -s)                    （运行时显示“关闭”，停用时显示“开启”）
 3. 关闭 Argo (sb -a)                        （运行时显示“关闭”，停用时显示“开启”）
 4. 更换 Argo 隧道 (sb -t)
 5. 修改节点配置 (sb -d)
 6. 同步 Sing-box 和 Argo 至最新版本 (sb -v)
 7. 升级内核、安装BBR、DD脚本 (sb -b)
 8. 增加 / 删除协议 (sb -r)
 9. 卸载 (sb -u)
 10. 安装 ArgoX 脚本 (argo + xray) [https://github.com/fscarmen/argox]
 11. 安装 sba 脚本 (argo + sing-box) [https://github.com/fscarmen/sba]
 12. 安装 TCP brutal
 0. 退出

Choose an option: _
```

英文（English — same numbers, English labels）：

```
 Script version: v1.0.2 (2026.11.24)
 What's new: quick install, subscription, Argo, port hopping, WARP
 System information:
        Operating system: Ubuntu 24.04.5 LTS
        Kernel: 7.0.0-44-generic
        Architecture: x86_64
        Virtualization: systemd-nspawn
        IPv4: 1.2.3.4
        IPv6: 2001:db8::1
        Sing-box: running     1.14.4         12.34 MB  ↓1.23 MB ↑456.78 KB
        Argo:     running     2026.1.1       8.90 MB
        Nginx:    running     1.24.0         5.67 MB

 1. View node links
 2. Close Sing-box (sb -s)              (running shows "Close", stopped shows "Open")
 3. Close Argo (sb -a)                  (running shows "Close", stopped shows "Open")
 4. Change Argo tunnel (sb -t)
 5. Modify node configuration (sb -d)
 6. Sync Sing-box and Argo to the latest version (sb -v)
 7. Upgrade kernel, install BBR, DD script (sb -b)
 8. Add / remove protocols (sb -r)
 9. Uninstall (sb -u)
 10. Install ArgoX script (argo + xray) [https://github.com/fscarmen/argox]
 11. Install sba script (argo + sing-box) [https://github.com/fscarmen/sba]
 12. Install TCP brutal
 0. Exit
```

> 顶部状态栏说明 / Header explained：
>
> - `Script version`：本脚本版本 `v1.0.2 (2026.11.24)`。
> - `What's new`：固定一行 `quick install, subscription, Argo, port hopping, WARP`。
> - `System information`：操作系统、内核、处理器架构、虚拟化（`systemd-detect-virt` 测不到时显示 `unknown`，`none` 显示为 `bare-metal`）。
> - `IPv4` / `IPv6`：公网 IP（后面跟 `WARP` / `WARP+` 表示走了 WARP；测不到就留空）。
> - `Sing-box / Argo / Nginx` 三行：每行是「状态（`running` / `stopped` / `not-installed`）+ 版本号 + 内存占用」；Sing-box 行后面还有流量 `↓下载 ↑上传`（从 clash_api 的 `/traffic` 接口取，取不到就不显示）。
> - 每次进菜单都会重新刷新状态和版本，不是写死的。

---

## 4. 安装向导全流程

**函数：`run_install()`，按顺序调 `ask_wizard_protocols()` → `ask_wizard_start_port()` → `ask_wizard_server()` → `ask_wizard_uuid()` → `ask_wizard_node_name()` → `ask_wizard_fingerprint()` → Reality 私钥（如有）→ `ask_wizard_hy2()`（如有 Hysteria2）→ `ask_wizard_cdn()`（如有 WebSocket / HTTP 类协议）→ 订阅开关 → nginx 端口 → `ask_wizard_argo()`（如有 WebSocket 类协议）。命令行 / 配置文件里已经给过的值，不再重复问。**

### 4.1 协议选择菜单（27 种，分组显示）

中文：

```
  a. ALL (all 27 protocols)                  a. 全部（共 27 种协议）

  --- 置顶常用 / Pinned (1-10) ---
  b. hysteria2                               1. Hysteria2
  c. VLESS + Reality                         2. VLESS + Reality
  d. VLESS + Reality (Vision) / XTLS + Reality  3. VLESS + Reality (Vision) / XTLS + Reality
  e. AnyTLS                                  4. AnyTLS
  f. tuic                                    5. TUIC
  g. trojan                                  6. Trojan
  h. ShadowTLS                               7. ShadowTLS
  i. shadowsocks                             8. Shadowsocks
  j. naive                                   9. Naive
  k. Snell v6                                10. Snell v6

  --- 走 Cloudflare 协议 / Cloudflare (CF) (11-19) ---
  l. VLESS + HTTPUpgrade (CF)                11. VLESS + HTTPUpgrade（CF）
  m. VLESS + WS + TLS (CF)                   12. VLESS + WS + TLS（CF）
  n. Trojan + gRPC (CF)                      13. Trojan + gRPC（CF）
  o. VMess + gRPC (CF)                       14. VMess + gRPC（CF）
  p. Trojan + WS (CF)                        15. Trojan + WS（CF）
  q. VMess + WS + TLS (CF)                   16. VMess + WS + TLS（CF）
  r. VLESS + HTTP (CF) 见第 0 节          17. VLESS + HTTP（CF）
  s. VMess + HTTP (CF) 见第 0 节          18. VMess + HTTP（CF）
  t. Trojan + HTTP (CF) 见第 0 节         19. Trojan + HTTP（CF）

  --- 其余 / Others (20-27) ---
  u. Shadowsocks 2022 AES-256                20. Shadowsocks 2022 AES-256
  v. VLESS + WS + Reality                    21. VLESS + WS + Reality
  w. VLESS + TCP + TLS                       22. VLESS + TCP + TLS（Vision）
  x. Trojan + Reality                        23. Trojan + Reality
  y. Shadowsocks 2022                        24. Shadowsocks 2022
  z. H2 + Reality                            25. H2 + Reality
  aa. gRPC + Reality                         26. gRPC + Reality
  ab. AnyTLS + Reality                       27. AnyTLS + Reality

Select protocols to install (a = all, e.g. b c, or a): _
请选择要安装的协议（a = 全部，例如输入 b c，也可以只输入 a）：_
```

> 说明 / How to choose：
>
> - 直接回车 = `a`（全部 27 种）。
> - 输入 `b c`、`bcd`、`b,c` 都行，大写自动转小写，重复的自动去重，按输入顺序排端口。
> - 也可以输入数字 `1`–`27`（如 `1 2 12`，`12` = VLESS + WS + TLS（CF）），`aa`/`ab` 选最后两种。
> - 输错（一个有效字母都没有）会提示输入无效，错误累计 5 次后脚本退出（`Too many invalid inputs, exiting. / 输入错误次数过多，脚本退出。`）。
> - 协议选择菜单是分组显示的 27 种，字母 `b`–`z` + `aa/ab`，也可以输数字 `1`–`27`。

**选完协议后，端口按选择顺序连续分配。举例：起始端口 8881，选全部 27 种：**

| 协议 | 端口 | 协议 | 端口 |
| --- | --- | --- | --- |
| 1. Hysteria2 | 8881 | 15. Trojan + WS（CF） | 8895 |
| 2. VLESS + Reality | 8882 | 16. VMess + WS + TLS（CF） | 8896 |
| 3. VLESS + Reality (Vision) / XTLS + Reality | 8883 | 17. VLESS + HTTP（CF） | 8897 |
| 4. AnyTLS | 8884 | 18. VMess + HTTP（CF） | 8898 |
| 5. TUIC | 8885 | 19. Trojan + HTTP（CF） | 8899 |
| 6. Trojan | 8886 | 20. Shadowsocks 2022 AES-256 | 8900 |
| 7. ShadowTLS | 8887 | 21. VLESS + WS + Reality | 8901 |
| 8. Shadowsocks | 8888 | 22. VLESS + TCP + TLS | 8902 |
| 9. Naive | 8889 | 23. Trojan + Reality | 8903 |
| 10. Snell v6 | 8890 | 24. Shadowsocks 2022 | 8904 |
| 11. VLESS + HTTPUpgrade（CF） | 8891 | 25. H2 + Reality | 8905 |
| 12. VLESS + WS + TLS（CF） | 8892 | 26. gRPC + Reality | 8906 |
| 13. Trojan + gRPC（CF） | 8893 | 27. AnyTLS + Reality | 8907 |
| 14. VMess + gRPC（CF） | 8894 |  |  |

### 4.2 起始端口

```
Enter the starting port (Port must be between 100 and 65520, and the following consecutive ports must be free 27 consecutive free ports, default 8881):
请输入起始端口（端口须在 100-65520 之间，且以下连续端口必须空闲 27 个连续空闲端口，默认 8881）：
```

> 说明：只输一个起始端口，后面按 4.1 的顺序连续占。端口不在 100–65520 之间、或其中任何一个已被占用，都会提示 `Invalid port number / 端口号无效` 或 `Port is already in use, please choose another one / 端口已被占用，请换一个`，重新输入。

### 4.3 服务器地址

```
Enter server address, IP or domain (default: 1.2.3.4):
请输入服务器地址（IP 或域名）(默认为: 1.2.3.4):
```

> 说明：默认是自动探测到的公网 IP；也可以填域名或 IPv6。填错格式（既不是 IP 也不是域名）会提示 `Invalid domain or IP address / 域名或 IP 地址无效`，重新输入。

### 4.4 UUID

```
Enter UUID (leave empty for a random one) (default: 11111111-2222-3333-4444-555555555555):
请输入 UUID（留空则随机生成）(默认为: 11111111-2222-3333-4444-555555555555):
```

> 说明：直接回车用随机生成的；自己填必须是 36 位 `8-4-4-4-12` 格式，否则提示 `UUID must be 36 characters long, please re-enter / UUID 须为 36 位字符，请重新输入`。

### 4.5 节点名

```
Enter node name (default: sing-box-node):
请输入节点名称 (默认为: sing-box-node):
```

> 说明：直接回车用默认名；这个名字会出现在所有节点链接的 `#` 后面和订阅文件标题里。

### 4.6 客户端指纹

```
Choose client fingerprint:
  1. chrome (default)
  2. firefox
Choose an option: _
请选择客户端指纹：
  1. chrome (默认)
  2. firefox
请选择：_
```

> 说明：只影响 Reality / TLS 节点的 `fp` 参数。

### 4.7 Reality 公私钥（只有选了 Reality 类协议才问）

**涉及协议：2. VLESS + Reality、3. VLESS + Reality (Vision) / XTLS + Reality、21. VLESS + WS + Reality、23. Trojan + Reality、25. H2 + Reality、26. gRPC + Reality、27. AnyTLS + Reality。**

```
Enter Reality private key (leave empty to generate one):
请输入 Reality 私钥（留空则自动生成）：
```

> 说明：直接回车由 `sing-box generate reality-keypair` 自动生成一对，私钥存服务端、公钥进客户端链接；也可以粘贴自己已有的私钥。SNI 默认 `addons.mozilla.org`，指纹用 4.6 选的值。

### 4.8 Hysteria2：Realm / WARP / 端口跳跃（只有选了 Hysteria2 才问）

**出现位置：安装向导中途，Realm 问完之后、进 CDN / 订阅（4.9）之前。端口跳跃是一步式输入，不再先问 `y/N`。**

```
Use Realm for Hysteria2? [y/N]:
Hysteria2 是否使用 Realm？[y/N]：
Enter Hysteria2 bandwidth in Mbps, upload/download, e.g. 100/100 (Enter for the default 100/100):
请输入 Hysteria2 带宽（Mbps，上行/下行，例如 100/100，直接回车用默认 100/100）：

Port hopping: some carriers throttle or block a single UDP port. Port hopping spreads Hysteria2 traffic over a range of UDP ports so one blocked port does not stop the node. Use about 1000 ports (for example 20000:21000). On a NAT VPS only 20-30 ports may be open; hopping ports that are not open will make the node unreachable, so be careful. Leave it empty to turn port hopping off (default).
端口跳跃说明：有些运营商会限速或阻断单个 UDP 端口。端口跳跃把 Hysteria2 的流量分散到一段 UDP 端口上，一个端口被封也不会导致节点全断。推荐用 1000 个左右的端口（例如 20000:21000）。NAT 小鸡能用的端口一般只有 20-30 个，填了没开放的端口会导致节点不通，请慎用。直接回车表示不开启端口跳跃（默认）。
Enter Hysteria2 port hopping range, e.g. 20000:21000 (Enter to skip, no port hopping):
请输入 Hysteria2 端口跳跃范围，例如 20000:21000（直接回车跳过，不用端口跳跃）：
```

> 说明：Realm 选 `y` 时会尝试注册一个免费 WARP 账号作为出站（失败也不阻塞安装，只提示继续）。端口跳跃这一步**直接回车 = 不用端口跳跃**，直接继续往下装（进 4.9 的域名 / CDN / 订阅）；输了范围才开启，范围须在 10000–65535 之间、起始小于结束，格式是 `起始:结束` 或 `起始-结束`（如 `20000:21000` 或 `20000-21000`），输错会提示重新输入，错误累计 5 次后脚本退出。开启后用 nftables / iptables NAT 把该范围的 UDP 转到 Hysteria2 的真实端口。
> 说明：带宽问完才问跳跃范围；跳跃范围之前会先打印上面那页端口跳跃说明。装好后在 `sb -d` 里分别改：Hysteria2 拥塞控制切换、Hysteria2 带宽、Realm 开关、Hysteria2 端口跳跃（见第 5 节）。

### 4.9 WebSocket / HTTP 类：域名 + CDN + 回源方式 + nginx 订阅端口

**涉及协议：12. VLESS + WS + TLS（CF）、15. Trojan + WS（CF）、16. VMess + WS + TLS（CF）、21. VLESS + WS + Reality（回源，不标注 CF）、11. VLESS + HTTPUpgrade（CF）、18/19/20 号 VLESS + HTTP / VMess + HTTP / Trojan + HTTP（CF）（替换后同样走这套）。14. VMess + gRPC（CF）、13. Trojan + gRPC（CF）同属 CF 组，走 gRPC 传输，host 也可用 CDN 域名。CDN 优选域名只问一次，所有 WebSocket / HTTP / gRPC 节点共用。**

```
Enter preferred address / CDN domain:
请输入优选地址 / CDN 域名：
  1. skk.moe
  2. ip.sb
  3. time.is
  4. bestcf.top
  5. cdn.2020111.xyz
  6. cf.090227.xyz
  7. cf.xreak.top
  8. cf.3666888.xyz
  9. cfsaas.080112.xyz
  10. cf.92555.xyz
Choose an option: _
请选择：_

Enable subscription (nginx)? [Y/n]:
是否开启订阅（nginx）？[Y/n]：
Enable Argo tunnel for WebSocket nodes? [Y/n]:
是否为 WebSocket 节点开启 Argo 隧道？[Y/n]：

Choose Argo tunnel type:
请选择 Argo 隧道类型：
  1. Temporary tunnel (try)
  2. Token / JSON / Cloudflare API
  1. 临时隧道（try）
  2. Token / JSON / Cloudflare API
Choose an option: _

Enter Argo Token, JSON, or Cloudflare API credentials:
请输入 Argo Token、JSON 或 Cloudflare API 信息：_

Enter the nginx subscription port (default 8080):
请输入 nginx 订阅端口 (默认为 8080)：
```

> 说明 / Notes：
>
> - CDN 那一步：输数字选列表里的、直接输域名/IP 也行、直接回车用默认 `skk.moe`。
> - 订阅开关、Argo 开关：只在选了 WebSocket 类协议时才问；`--SUBSCRIBE dynamic` 可开启动态订阅（nginx 按请求 Host 实时渲染，直连节点 server 跟随访问地址，WebSocket/CDN/Argo 节点不变）。
> - Argo 选 `1` 是临时隧道（cloudflared 随机给一个 `*.trycloudflare.com` 域名，装完后从日志里解析）；选 `2` 再贴 Token / JSON / Cloudflare API 凭证。
> - 选 Token / JSON / Cloudflare API 之前，脚本会先打印 Argo 分步指引：去 https://dash.cloudflare.com/ ，Zero Trust > 网络 > 连接器，创建隧道并选择 Cloudflared；或用已建隧道的 JSON 凭证；或用 Cloudflare API 令牌（https://dash.cloudflare.com/profile/api-tokens > 创建令牌 > 创建自定义令牌），授予：帐户 > Cloudflare One 连接器：Cloudflared > 编辑，以及区域 > DNS > 编辑；帐户资源包括你的账户，区域资源包括特定区域的域名。权限不够时 API 调用会失败。
> - nginx 订阅端口默认 8080，必须是空闲端口，否则重新输入。
> - 装完之后：下载 sing-box 官方二进制 → 生成证书/密钥 → 按 4.1 的顺序写 `/etc/sing-box/conf/` 下的 JSON → `sing-box check -C` 校验 → 写 nginx 配置 → 配 Argo → 写 systemd / OpenRC 服务 → 同步防火墙（ufw / firewalld / iptables / nftables 自动放行）→ 启动 sing-box / Argo / nginx → 输出节点链接（第 10 节）→ 创建 `sb` 快捷命令。

---

## 5. `sb -d` 修改配置子菜单

**函数：`change_config_menu()`。和原版一样是动态菜单：只显示和当前安装有关的项，按原版顺序排，每项后面都显示当前值；一次改一项，改完回主菜单（原版是改完退出脚本，本版回主菜单，见末尾冲突表）。输错数字显示“未做任何修改”并返回，原版的 `sb -d` 菜单里没有 `0. 返回` 这一项。**

中文（示例：装了 Hysteria2、VLESS + Reality、XTLS + Reality，订阅已开）：

```
请选择要修改的项目：
  1. 优选域名/IP  (current: skk.moe)
  2. Reality SNI  (current: addons.mozilla.org)
  3. 监听端口  (current: 8881, 8882, 8883)
  4. 节点名称  (current: my-node)
  5. UUID / 密码 / PSK  (current: 11111111-2222-3333-4444-555555555555)
  6. 服务器地址  (current: 1.2.3.4)
  7. 客户端指纹  (current: chrome)
  8. 指定网络出口  (current: default)
  9. 关闭订阅
 10. 关闭动态订阅
 11. Hysteria2 拥塞控制切换  (current: 声明带宽)
 12. Hysteria2 带宽  (current: up 100 Mbps, down 100 Mbps)
 13. 关闭 Realm  (current: disabled)
 14. Hysteria2 端口跳跃  (current: disabled)
 15. XTLS reality 切换为多路复用

请选择：_
```

英文（English — items are printed in English in the script）：

```
Please select what to modify:
  1. Preferred CDN  (current: skk.moe)
  2. Reality SNI  (current: addons.mozilla.org)
  3. Listen ports  (current: 8881, 8882, 8883)
  4. Node name  (current: my-node)
  5. UUID / Password / PSK  (current: 11111111-2222-3333-4444-555555555555)
  6. Server address  (current: 1.2.3.4)
  7. Client Fingerprint  (current: chrome)
  8. Bind network interface  (current: default)
  9. Disable subscription
 10. Disable dynamic subscription
 11. Hysteria2 congestion control toggle  (current: declared bandwidth)
 12. Hysteria2 bandwidth  (current: up 100 Mbps, down 100 Mbps)
 13. Disable Realm  (current: disabled)
 14. Hysteria2 Port Hopping  (current: disabled)
 15. Switch XTLS reality to Multiplex
```

> 哪些项会出现 / When each item appears：
>
> - `1` 优选域名/IP：只有装了 WebSocket 类协议才显示。
> - `2` Reality SNI：只有装了 Reality 类协议才显示。
> - `3` 监听端口：总有（见第 9.2 节）。
> - `4` 节点名、`5` UUID / 密码 / PSK、`6` 服务器地址、`7` 指纹：总有。
> - `8` 指定网络出口：总有，当前是默认（不指定）。
> - `9` 订阅开关：总有，按当前状态动态显示“开启/关闭订阅”。
> - `10` 动态订阅开关：只有订阅已开启时才显示。
> - `11` Hysteria2 拥塞控制切换：只有装了 Hysteria2 才显示，在“声明的 up/down 带宽”和“强制 BBR（忽略客户端带宽）”之间切换。
> - `12` Hysteria2 带宽：只有装了 Hysteria2、且未开启强制 BBR 时才显示；先问上行、再问下行（`Please enter Hysteria2 client upload speed in Mbps (e.g. 200)` / `download speed in Mbps (e.g. 1000)`，必须是正整数）。
> - `13` Realm 开关：只有装了 Hysteria2 才显示；和端口跳跃互斥，开启前会先确认（`Port hopping is enabled. Enabling Realm will disable port hopping. Continue? [y/N]`）。
> - `14` Hysteria2 端口跳跃：只有装了 Hysteria2 才显示；留空禁用，和 Realm 互斥（`Realm is enabled. Enabling port hopping will disable Realm. Continue? [y/N]`）。
> - `15` XTLS vision / 多路复用切换：只有装了 XTLS + Reality 才显示；vision 时切多路复用（清空 flow、开 multiplex），多路复用时切回 vision（恢复 `xtls-rprx-vision`、关 multiplex）。
> - 自定义路由、更换 WARP 账户：只有配了 WARP 账户才显示（原版是 TUN + warp-ep 出站存在时才显示，本版没有 TUN 出站，见末尾冲突表）。
> - 每改一项后脚本都会 `sing-box check` 校验，通过才 reload / restart，不通过报错不重启。

---

## 6. `sb -r` 增删协议子菜单

**函数：`change_protocols_menu()`。按原版流程：先删、再加、最后确认。字母是按列表排的（`a` = 列表第一项），不是安装向导里那个全局选择器（全局选择器里 `a` = 全部 27 种）。**

中文：

```
已安装的协议 (3)
 a. Hysteria2
 b. VLESS + Reality
 c. VLESS + Reality (Vision) / XTLS + Reality
请选择需要删除的协议（输入 all 删除全部已安装协议，也可以多选，回车跳过）：_

未安装的协议 (25)
 a. AnyTLS
 b. TUIC
 c. Trojan
 ...（按第 0 节的新顺序列出未装的全部协议，字母 a、b、c……按列表排，超过 26 项后用 aa、ab）
请选择需要增加的协议（输入 all 一键安装全部未安装协议，也可以多选，回车跳过）：_

确认重装的所有协议 (3)

保留协议 (2)
 1. VLESS + Reality
 2. VLESS + Reality (Vision) / XTLS + Reality

新增协议 (1)
 1. AnyTLS
如有错误请按 [n]，其他键继续：_

选择的协议及端口次序如下：
 1. VLESS + Reality 8881
 2. AnyTLS 8882
 3. VLESS + Reality (Vision) / XTLS + Reality 8883
```

> 说明：已装协议为空时不问删除、直接问增加；未装协议为空时不问增加。确认那一步按 `n` 取消（什么都不改）；其他键继续。保留的协议一个都不剩、又新加了协议时，会像新安装一样重新问起始端口和节点名。加完后按起始端口重新连续分配端口（仍是第 0 节的新顺序），删掉的协议的 inbound 文件删除、新增的写入，`sing-box check` 通过后重启服务、同步防火墙、重新输出节点链接。

---

## 7. 自定义路由子菜单

**函数：`custom_route_menu()`，从 `sb -d` 里“自定义 warp-ep 出站路由规则”那一项进入（只有配了 WARP 账户才显示）。标题里带规则数，输错会显示“未做任何修改”并返回。**

中文：

```
Custom warp-ep outbounds rules (rules: 2)
自定义 warp-ep 出站路由规则（规则数：2）：
  1. Add rule                             添加规则
  2. View rules                           查看规则
  3. Delete rule                          删除规则
  0. Back                                 返回

Choose an option: _
请选择：_
```

> 选 `1` 添加规则时，先问规则类型（原版顺序）：
>
> ```
> Select rule type:
> 请选择规则类型：
> 1. domain_suffix
> 2. rule_set
> Choose an option: _
> 请选择：_
> ```
>
> 选 `domain_suffix` 后问域名后缀（支持逗号分隔多个，格式不对会提示重新输入）：
>
> ```
> Enter a domain suffix, e.g. example.com:
> 请输入域名后缀，例如 example.com：_
> ```
>
> 选 `rule_set` 后问规则集名称（自动补 `geosite-` 前缀，空的或不合格式的会提示重新输入）：
>
> ```
> Enter a rule set name, e.g. category-ads-all:
> 请输入规则集名称，例如 category-ads-all：_
> ```
>
> 选 `2` 查看规则时，直接打印 `03_route.json` 里的全部规则（每条一行 JSON）。
> 选 `3` 删除规则时，先打印全部规则，再问 `Enter the rule numbers to delete, separated by commas, e.g. 1,3 (0 = cancel): / 输入要删除的规则编号，多个用逗号分隔，例如 1,3（0 = 取消）：`，支持逗号分隔多选，从大到小编号删。
> 规则写进 `/etc/sing-box/conf/03_route.json` 的 `route.rules` 里，出站固定为 `direct`（原版写进 `08_custom_route.json`、出站为 warp-ep，见末尾冲突表）。`rule_set` 规则本版不做原版那种联网校验，名称按原版规则自动补 `geosite-` 前缀，并按 SagerNet 的地址写入远程规则集定义。

---

## 8. WARP 账号子菜单、Argo 修改子菜单

### 8.1 WARP 账号子菜单（`sb -d` 里“更换 WARP 账户”那一项，只有配了 WARP 账户才显示）

```
Select WARP account operation:
请选择 WARP 账号操作：
1. Register a new free account
2. Enter account info manually
0. Back
1. 重新注册免费账户
2. 手动输入信息
0. 返回

Choose an option: _
请选择：_
```

> 说明：`1` 重新注册一个免费 WARP 账户；注册失败时保留原有账号，并提示 `New account registration failed, keeping the existing WARP account. / 新账号注册失败，保留现有 WARP 账号。`。`2` 手动输入信息，依次问 WARP IPv6 地址（`Enter WARP IPv6 address: / 请输入 WARP IPv6 地址：`）、Private Key（`Enter WARP private key: / 请输入 WARP 私钥：`）、reserved 保留值（`Enter WARP reserved values, e.g. 123,456,789: / 请输入 WARP reserved 保留值，例如 123,456,789：`，必须是 3 个 0–255 的数字，格式不对会提示重新输入）。

### 8.2 Argo 修改子菜单（主菜单第 4 项，`sb -t`）

```
Argo tunnel is: Try
 The domain is: abc123.trycloudflare.com

Argo tunnel type:
请选择 Argo 隧道类型：
  1. Try
  2. Token or Json. Including created through Cloudflare API
  1. 临时隧道（try）
  2. Token 或者 Json，包括通过 Cloudflare API 创建
Choose an option: _
请选择：_
```

> 说明：开头先打印当前隧道类型和域名。选 `1` 清掉旧凭证、用临时隧道；选 `2` 先打印 Argo 分步指引（见 4.9），再问 `Enter Argo Token, JSON, or Cloudflare API credentials: / 请输入 Argo Token、JSON 或 Cloudflare API 信息：`，保存后重启 Argo 服务、重新解析临时域名、重新输出节点链接。输错会显示“未做任何修改”并返回主菜单（原版是直接退出脚本，见末尾冲突表）。

---

## 9. 端口跳跃说明页、端口修改方式选择

### 9.1 端口跳跃（Hysteria2，安装向导 4.8 里问）

**v1.0.1 的实际样子（问范围之前先打印一页端口跳跃说明，见 4.8）：**

```
Enter Hysteria2 port hopping range, e.g. 20000:21000 (Enter to skip, no port hopping):
请输入 Hysteria2 端口跳跃范围，例如 20000:21000（直接回车跳过，不用端口跳跃）：
```

> 说明：安装时端口跳跃已改为**一步式、回车跳过**——直接回车 = 不用端口跳跃，输范围（`起始:结束` 或 `起始-结束`，10000–65535、起始小于结束）才开启，输错提示重新输入（错误 5 次退出）。装好后在 `sb -d` 里“Hysteria2 端口跳跃”那一项改跳跃，同样先打印说明页、再问范围，直接回车 = 禁用跳跃；和 Realm 互斥，开启前会先确认。问跳跃范围之前会先打印一页端口跳跃说明（见 4.8）。

### 9.2 端口修改方式选择（`sb -d` 里“监听端口”那一项 → `change_ports_menu()`）

```
Port modification mode:
端口修改方式：
1. Modify start port (protocols occupy sequential ports, default)
2. Set an independent port for each protocol
1. 修改起始端口（各协议按顺序占用，默认）
2. 修改为各协议独立端口

Choose an option: _
请选择：_
```

> 说明：
>
> - 默认选 `1`；输错会重新问（原版没有 `0. 返回` 这一项）。
> - 选 `1`：先输新起始端口，再打印预览（`Start port 8881 -> 9000: 3 protocol ports will become 9000 - 9002. / 起始端口 8881 -> 9000：3 个协议端口将变为 9000 - 9002。`），再问 `Apply the changes [y/N] (default N) / 是否应用这些更改 [y/N]（默认 N）`，按 `y` 才应用；全部协议按新顺序（第 0 节表）重新连续分配，重写全部 inbound，校验通过后 reload 并同步防火墙。
> - 选 `2`：先按字母选协议（`a` = 全部，回车跳过），再逐个问新端口（`Port for <协议名> (current: <当前端口>):`），输一个空闲端口就改那一个，不输/输错就跳过该协议；改完同样先预览、再问是否应用。
> - 选独立端口时字母表列出全部 27 种协议，但选择会过滤到只改已装的协议（原版只列已装的协议，见末尾冲突表）。

---

## 10. 查看节点信息 `sb -n` 的输出样式

**函数：`export_list()`。打印 `/etc/sing-box/list` 的内容；如果装了 `qrencode`，后面再打一个订阅二维码（ANSI 字符画）。订阅文件同时写到 `/etc/sing-box/subscribe/`（明文 `list_plain.txt`、base64 `list.txt`、Clash `clash.yaml`）。**

中文 / 英文（链接本身没有语言差别，只示例节点名不同）：

```
sing-box nodes -- my-node
Server: 1.2.3.4

hysteria2://<密码>@1.2.3.4:8881?insecure=1&sni=addons.mozilla.org#my-node%20Hysteria2
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8882?encryption=none&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&sid=&type=tcp#my-node%20VLESS-Reality
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8883?encryption=none&flow=xtls-rprx-vision&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&sid=&type=tcp#my-node%20VLESS-Reality-Vision
anytls://11111111-2222-3333-4444-555555555555@1.2.3.4:8884?insecure=1&sni=addons.mozilla.org#my-node%20AnyTLS
tuic://11111111-2222-3333-4444-555555555555:<密码>@1.2.3.4:8885?congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#my-node%20TUIC
trojan://<密码>@1.2.3.4:8886?security=tls&sni=addons.mozilla.org&allowInsecure=1#my-node%20Trojan
ss://<base64(2022-blake3-aes-128-gcm:密码)>@1.2.3.4:8887#my-node%20ShadowTLS
ss://<base64(2022-blake3-aes-128-gcm:密码)>@1.2.3.4:8888#my-node%20Shadowsocks
https://user:<密码>@1.2.3.4:8889?padding=1#my-node%20Naive
snell://<PSK>@1.2.3.4:8890?version=6#my-node%20Snell-v6
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8891?encryption=none&type=httpupgrade&path=/vless-httpupgrade&host=skk.moe#my-node%20VLESS-HTTPUpgrade
vless://11111111-2222-3333-4444-555555555555@skk.moe:8892?encryption=none&security=tls&sni=addons.mozilla.org&type=ws&host=skk.moe&path=/vless-ws-tls#my-node%20VLESS-WS-TLS
trojan://<密码>@1.2.3.4:8893?security=tls&sni=addons.mozilla.org&type=grpc&serviceName=trojan-grpc#my-node%20Trojan-gRPC
vmess://<base64 JSON: net=grpc, serviceName=vmess-grpc, tls=tls>#my-node%20VMess-gRPC
trojan://<密码>@skk.moe:8895?security=tls&sni=addons.mozilla.org&type=ws&host=skk.moe&path=/trojan-ws#my-node%20Trojan-WS
vmess://<base64 JSON: net=ws, host=skk.moe, path=/vmess-ws-tls, tls=tls>#my-node%20VMess-WS-TLS
ss://<base64(2022-blake3-aes-256-gcm:密码)>@1.2.3.4:8897#my-node%20Shadowsocks-2022-AES-256
vless://11111111-2222-3333-4444-555555555555@skk.moe:8898?encryption=none&security=tls&sni=addons.mozilla.org&type=http&host=skk.moe&path=/vless-http#my-node%20VLESS-HTTP
vmess://<base64 JSON: net=http, host=skk.moe, path=/vmess-http, tls=tls>#my-node%20VMess-HTTP
trojan://<密码>@skk.moe:8900?security=tls&sni=addons.mozilla.org&type=http&host=skk.moe&path=/trojan-http#my-node%20Trojan-HTTP
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8901?encryption=none&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&type=ws&host=1.2.3.4&path=/vless-ws-reality#my-node%20VLESS-WS-Reality
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8902?encryption=none&flow=xtls-rprx-vision&security=tls&sni=addons.mozilla.org#my-node%20VLESS-TCP-TLS
trojan://<密码>@1.2.3.4:8903?security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&type=tcp#my-node%20Trojan-Reality
ss://<base64(2022-blake3-aes-128-gcm:密码2)>@1.2.3.4:8904#my-node%20Shadowsocks-2022
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8905?encryption=none&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&type=http#my-node%20H2-Reality
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8906?encryption=none&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&type=grpc&serviceName=grpc#my-node%20gRPC-Reality
anytls://11111111-2222-3333-4444-555555555555@1.2.3.4:8907?security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>#my-node%20AnyTLS-Reality

Subscription: http://1.2.3.4:8080/sub

Subscription QR:
（qrencode 的 ANSI 二维码，仅在装了 qrencode 时显示）
```

> 说明 / Notes：
>
> - 链接顺序 = 第 0 节的新分组顺序，端口按 4.1 的表连续分配（示例起始端口 8881）。
> - WebSocket / HTTP 类节点的 `host` 用 CDN 优选域名（如 `skk.moe`），直连节点用服务器地址。
> - 上面 20 号是替换方案的链接（Shadowsocks 2022 AES-256）；17/18/19 号是替换方案的链接（`type=http`，不是原来想要的 XHTTP 写法）。原 XHTTP / Shadowsocks + WS 在官方 sing-box 上跑不起来，见第 0 节替换说明。
> - 订阅链接固定是 `http://<服务器地址>:<nginx端口>/sub`；动态订阅开启时，nginx 按请求 Host 实时渲染。
> - Clash 的 `clash.yaml` 是逐协议完整展开版：`proxies` 里按协议逐个写 VLESS / VMess / Trojan / Hysteria2 / Shadowsocks / TUIC / AnyTLS / Snell 等条目（共 26 条，Naive 没有对应的 Clash 代理类型所以不在内，链接仍在 `list_plain.txt` 里），`proxy-groups` 里有 PROXY 分组，`rules` 是 `MATCH,PROXY`。

---

## 11. 卸载确认、`sb -v` 版本信息

### 11.1 卸载（主菜单第 9 项，`sb -u`）

和原版一样，卸载本身**没有**“确定吗”确认。直接停服务、删服务文件、清端口跳跃 NAT、按 `/etc/sing-box/firewall/service_ports.list` 删防火墙规则、删 nginx 订阅配置、删 `/etc/sing-box` 和快捷命令 `/usr/local/bin/sb`、`/usr/local/bin/cj`，最后显示 `sing-box has been completely removed. / sing-box 已彻底卸载。`。过程中只问两件事（都默认不删，回车 = 不删）：

```
Whether to uninstall Nginx [y/N] (default is N):
是否卸载 Nginx [y/N]（默认 N）：
To uninstall fcgiwrap / spawn-fcgi press [y], they are not uninstalled by default:
是否卸载 fcgiwrap / spawn-fcgi，按 [y] 卸载，默认不卸载：
```

> 说明：第一问只在装了 Nginx 时出现，第二问只在装了 fcgiwrap / spawn-fcgi 时出现；要删的包以后台方式卸载，日志在 `/tmp/sing-box-uninstall.log`。`sb -u` 命令行方式跳过这两问。

### 11.2 版本信息（主菜单第 6 项，`sb -v`，同步 Sing-box 和 Argo 至最新版本）

```
APP local version: 1.14.4. The newest version: 1.14.4
应用本地版本：1.14.4。最新版本：1.14.4
No upgrade required.
无需升级。
APP local version: 2026.1.1. The newest version: 2026.1.1
应用本地版本：2026.1.1。最新版本：2026.1.1
No upgrade required.
无需升级。
```

> 有新版本时，先分别显示本地版本和最新版本，再分别追问是否升级：
>
> ```
> APP local version: 1.14.4. The newest version: 1.15.0-alpha.13
> 应用本地版本：1.14.4。最新版本：1.15.0-alpha.13
> Whether to upgrade [y/N] (default is N):
> 是否升级 [y/N]（默认 N）：
> ```
>
> 说明：先查 Argo、再查 Sing-box（原版顺序），两个都问；按 `y` 才升级。Sing-box 升级前备份旧版本二进制，下载的新版本先 `sing-box check` 校验，校验不过回滚旧版本（原版还会问是否更新基础配置，本版直接回滚，见末尾冲突表）。没装对应组件时显示 `sing-box is not installed yet. / sing-box 尚未安装。` 或 `Argo is not installed yet. / Argo 尚未安装。`。

---

## 附录 A. 命令行参数（与菜单对应的快捷方式，不进菜单也看得到）

```
sb          打开菜单（`cj` 也一样，快捷跳出菜单）
sb -s    开/关 sing-box        sb -a    开/关 Argo
sb -t    更换 Argo 隧道        sb -d    修改配置（第 5 节）
sb -u    卸载                  sb -n    查看节点信息（第 10 节）
sb -v    同步 Sing-box 和 Argo 至最新版本   sb -b    升级内核、安装BBR、DD脚本
sb -r    增删协议（第 6 节）
-E / -C / --LANGUAGE en|zh    语言
-K / -L                       一键快速安装（-L 为中文）
-f / -F FILE                  从 KEY=VALUE 配置文件读安装答案
--CHOOSE_PROTOCOLS a|b c ...  按第 0 节的字母/数字选协议（a=全部 27 种）
--START_PORT / --PORT_NGINX / --SERVER_IP / --CDN / --UUID_CONFIRM /
--NODE_NAME_CONFIRM / --SUBSCRIBE yes|no|dynamic / --ARGO true|false /
--ARGO_DOMAIN / --ARGO_AUTH / --HY2_PORT_HOPPING_RANGE /
--HY2_REALM / --BIND_INTERFACE / --REALITY_PRIVATE
```

---

## v1.0.0 落实情况（原 D1–D9 的处理结果）

| 编号 | 原问题 | v1.0.0 的处理 |
| --- | --- | --- |
| D1 | 协议只有 13 种、旧顺序、无分组 | 已落实：脚本已是 27 种新顺序（前 10 置顶、11–19 走 Cloudflare、20–27 其余），字母 `b`–`z` + `aa/ab`、数字 `1`–`27` 都支持，`a` = 全部 27 种。 |
| D2 | 函数名与原版不一致（`menu()` / `menu_setting()`） | 接受现状：独立重写，菜单函数叫 `main_menu()` + `print_header()`，功能和编号与原版一致。 |
| D3 | 15/16/17/18 号在官方 sing-box 上不支持 | 已落实：按替换方案做（15→Shadowsocks 2022 AES-256；16/17/18→HTTP 传输），菜单名和链接都已改掉，README 有替换说明。 |
| D4 | `sb -d` 第 10 项标题有带宽、实际没有带宽输入 | 已落实：补了带宽输入。安装时问上行/下行（默认 100/100 Mbps），`sb -d` 第 10 项也能改带宽、跳跃、Realm。 |
| D5 | 没有端口跳跃说明页 | 已落实：问跳跃范围之前打印一页说明（运营商限速、推荐 1000 个左右、NAT 小鸡端口少要慎用、默认不开启）。 |
| D6 | Argo 输入没有分步指引 | 已落实：选 Token / JSON / API 之前打印分步指引（去哪里开隧道、去哪里建 API 令牌、令牌要勾哪些权限）。 |
| D7 | Clash 订阅不是完整展开版 | 已落实：`clash.yaml` 逐协议完整展开，共 27 条（Naive 没有 Clash 代理类型所以不在内，已在文件里注明）。 |
| D8 | 1.15.0-alpha.13 未实测 | 未变：结论依据仍是 1.14.4 实测 + 上游文档。脚本默认安装 1.14.4，`sb -v` 会提示更新。 |
| D9 | README / LICENSE 还没写 | 已落实：`README.md` 和 `LICENSE`（MIT）已写好。 |

## 全称对照表（27 种）

协议名用 WS 缩写（用户要求，v1.0.5）：WebSocket 写成 WS；Shadowsocks 不写 SS；Hysteria2 不写 Hy2。链接里的 `type=ws`、`type=http`、`ss://` 等是客户端协议格式本身，不能改；内部 tag 只用在配置文件名和 JSON 里。

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
| 17 | r | VLESS + HTTP (CF) | vless-http | 是 |
| 18 | s | VMess + HTTP (CF) | vmess-http | 是 |
| 19 | t | Trojan + HTTP (CF) | trojan-http | 是 |
| 20 | u | Shadowsocks 2022 AES-256 | ss2022-256 | 否（直连，v1.0.10 起不标注 CF） |
| 21 | v | VLESS + WS + Reality | vless-ws-reality | 否 |
| 22 | w | VLESS + TCP + TLS (Vision) | vless-tls | 否 |
| 23 | x | Trojan + Reality | trojan-reality | 否 |
| 24 | y | Shadowsocks 2022 | ss2022 | 否 |
| 25 | z | H2 + Reality | h2-reality | 否 |
| 26 | aa | gRPC + Reality | grpc-reality | 否 |
| 27 | ab | AnyTLS + Reality | anytls-reality | 否 |

## v1.0.13 改了什么

- 菜单 8（增加 / 删除协议）删除协议支持一键删除全部：删除那一步输入 `all`（大小写不限、首尾空格/逗号容忍）就删除全部已安装协议；单独输入 `a` 还是只删已安装列表里的第 1 个。判断放在 `parse_list_letters` 之前（它会把 "all" 拆成 a+l+l），和 v1.0.8 增加那边的 `all` 做法对称；删除提示文字（中英双语）改成写明“输入 all 删除全部已安装协议，也可以多选，回车跳过”。删完照常走确认那步（保留列表为空，按 [n] 可以取消），确认后才真正删。删完一个都不剩、又不加新的情况已核对过：`SELECTED_IDX` 为空时不问起始端口和节点名，`assign_ports` / `save_install_env` / `check_config` / 重启服务 / `export_list` 都能正常走完，空配置正常保存、服务正常重启、订阅为空、菜单 1 显示“暂无协议，请从菜单 8 添加”，不会报错、不会死循环。
- 去掉 nginx 8080 监听上的 `http2`（修 v1.0.9 引入的回归）：`write_nginx_conf()` 里 `listen 8080 http2;` / `listen [::]:8080 http2;` 改回普通 `listen 8080;` / `listen [::]:8080;`。用户实测：v1.0.11 机器上 nginx 在跑、也在监听 8080，脚本没有任何错误提示，但 `curl -I http://127.0.0.1:8080/sub` 返回 `curl: (1) Received HTTP/0.9 when not allowed`，客户端同步订阅报连接错误、拉不到节点。原因是 `listen … http2` 让监听口只认 HTTP/2 明文（h2c），普通 HTTP/1.1 请求返回的不是正常 HTTP 响应。9 个反代位置和 `grpc_pass grpcs://` 一个都没动；cloudflared 到 nginx 是 `--url http://127.0.0.1:8080`（HTTP/1.1）。
- 订阅验证加强：`start_nginx_safe()` 失败时把 `/sub` 的实际 HTTP 码打出来，000 表示 nginx 返回的东西根本不是正常 HTTP（连接失败，或 HTTP/0.9 式坏响应）；`_sub_ok()` 的判断逻辑没变（200 有内容算通、404 算新配置已加载）。
- 全脚本搜过：除了注释里对这次改动的说明，不再有任何功能性的 `http2` 残留。
- 测试：按用户要求做了全面测试（见 README 的测试记录，159 项检查全部通过、0 失败）：nginx 配置实测（`nginx -t` + 测试实例实际监听 + `curl -I /sub` 返回 200 + 9 个反代位置逐个确认 + 旧 http2 配置复现了用户遇到的 `Received HTTP/0.9` 错误）、订阅 reload 实测（真实 nginx 主进程在跑、旧配置和没监听 8080 两种情况都正确 reload）、订阅文件实测（27 个协议链接逐个核对 + base64 解码核对）、协议选择器实测、防火墙列表实测、cj/sb 链路实测、官方 sing-box 1.14.4 跑 `sing-box check`（27 个入站全配置和删除全部后的空配置都通过）、v1.0.5–v1.0.11 回归清单。真机订阅打开、客户端同步、CF gRPC 节点实际连通仍需用户实测。

## v1.0.11 改了什么

- 防火墙 UDP 放行列表修正：`sync_firewall()` 原来是 `1|3|5|15` 号放 UDP，那四个全是只用 TCP 的协议（VLESS + Reality、AnyTLS、Trojan、VMess + WS + TLS (CF)），真正要用 UDP 的 6 个协议反而一个都没放；现改成 `0|4|7|9|19|23` 号放 UDP（Hysteria2 0 号 QUIC/UDP、TUIC 4 号 QUIC/UDP、Shadowsocks 7 号 UDP 转发、Snell v6 9 号、Shadowsocks 2022 AES-256 19 号 UDP 转发、Shadowsocks 2022 23 号 UDP 转发）。注释同步写清每个序号的协议名和原因。ShadowTLS（6 号）外层是 TCP、内层只监听 127.0.0.1，不用对外放 UDP；CF 组（10–18 号）和其余 TCP 协议不变。
- 全脚本搜过：只有这一处按序号判断 UDP/TCP 的地方（另一处 2662 行是 Hysteria2 端口跳跃范围的 UDP 放行，按范围放行、与协议序号无关，没动）。
- 升级后请重新同步一次防火墙，Hysteria2 / TUIC / Snell / Shadowsocks 这几个 UDP 节点要实测连通；真机防火墙放行、UDP 节点实际连通未验证。

## v1.0.10 改了什么

- Shadowsocks 2022 AES-256 去掉名字里的 (CF)、移到 CF 组后面（新 20 号，其余组第一位）：它没有 WS / HTTP / gRPC 传输，走不了 CF 隧道和 nginx 反代，只能直连；VLESS + HTTP、VMess + HTTP、Trojan + HTTP 顺移到 17 / 18 / 19 号。`PROTO_NAMES` / `PROTO_LINK_NAMES` / `PROTO_TAGS` / `PROTO_CF` 四个数组按新顺序重写（`PROTO_CF`：新 11–19 号为 1，新 20 号为 0）；`show_protocol_picker()` 分组改成置顶 1–10、CF 11–19、其余 20–27；`write_inbound()` / `build_link_for()` / `clash_proxy_for()` 三个分支按新编号重排，分支内容和 v1.0.9 逐字节对过，只换编号（SS2022 直连那条的 NOTE 注释按新名字改写）；Reality 检查（1/2/20/22/24/25/26 号）、`sb -d` 的 WS/Reality 判断、Clash 里 Naive 跳过（8 号）都不涉及 16–19 号，不用改；字母映射不变（`r`/`s`/`t`/`u` 现在对应 17/18/19/20 号）。
- **升级注意：已装过旧版的机器升级到 v1.0.10 后，旧 `install.env` / `selected.env` 里存的是旧协议编号，旧 16–19 号会错位（例如旧 17 号 Shadowsocks 2022 AES-256 会读成新 17 号 VMess + HTTP），升级后请从菜单 8 重新选一次协议；全新安装不受影响。**
- 27 个协议的实际生成和连通未在真机上重测，需要用户实测。

## v1.0.9 改了什么

- 修 CF 节点全部超时：13 号 Trojan + gRPC、14 号 VMess + gRPC 的链接和 Clash 条目之前用服务器 IP 和本地端口，现改成和其他 CF 协议一样走 Argo 隧道域名:443（没开 Argo 时走 CDN 优选域名:本地端口）；17 号 Shadowsocks 2022 AES-256 没有传输层可供代理，链接和 Clash 条目改回直连服务器 IP:本地端口；其余 CF 条目（11、12、15、18、19、20 号）核对过，都已用隧道域名 / CDN 域名。
- nginx 反代新增 `/vless-httpupgrade`（纯 `http://`，入站没开 TLS）、`/vmess-grpc/` 和 `/trojan-grpc/`（`grpc_pass grpcs://127.0.0.1:端口` + `proxy_ssl_verify off`，入站开了 TLS）；WS / HTTP 入站的反代从 `http://` 改成 `https://127.0.0.1:端口` + `proxy_ssl_verify off`（入站开了自签 TLS，之前纯 `http://` 代理过去握手必定失败）；监听加上 `http2`（cloudflared 能用 HTTP/2 明文连 nginx，gRPC 需要 HTTP/2）——**这个判断是错的，v1.0.13 已去掉**：`listen … http2` 让监听口只认 h2c，普通 HTTP/1.1 请求返回的不是正常 HTTP 响应，订阅 `/sub` 直接坏掉。
- 订阅 reload 根因：`start_nginx_safe()` 之前只在“8080 被占且 nginx 在跑”时才 reload；用户那台机器是 nginx 在跑、但根本没监听 8080，端口是空的，于是跳过 reload，走到 `systemctl start`——已运行的服务上这一步是空操作，新配置（含 /sub）永不加载，直到用户手动 `nginx -s reload`。现改成只要有 nginx 进程在跑，写完配置就先 reload 再验证 /sub；只有完全没 nginx 进程时才走 systemd 启动；启动后 /sub 还不通时再 reload 一次。`sb -d` 里订阅开关、改端口后也同步改成写完配置就 reload。
- 修 `cj` 调不出菜单：wrapper 下载失败时明确报错（之前 `exec bash <(wget -qO- URL)` 跑空脚本、静默退出 0）；`create_shortcut()` 在语言选择之前就创建快捷命令（提前退出也有 `cj`）；`cj` 无参数且没存过语言时默认中文直接进菜单（`-E` / `-C` 仍可覆盖）；复制安装脚本先写临时文件、校验通过才移动到位，已有的完整本地副本不再被截断复制或 wrapper 覆盖。cj 完整链路：`cj` → `/usr/local/bin/cj`（`SB_VIA_SHORTCUT=1 exec bash /etc/sing-box/installer.sh`）→ `installer.sh` 是本地完整脚本时直接跑，是重新下载 wrapper 时先下载校验再跑 → `main()` 按语言记录 / 快捷方式默认中文进主菜单。
- CF 节点实际连通、订阅打开、`cj` 实际调用均未在真机上验证（只做了 `bash -n`、链接生成和 nginx 配置生成的单元测试），需要用户实测。

## v1.0.8 改了什么

- 菜单 8（增加 / 删除协议）增加一键安装所有协议：在“增加协议”那一步输入 `all`（大小写不限）就一键安装全部未安装协议；已装过的保留，只装剩下的；空安装时就是安装全部 27 种。单独输入 `a` 还是只选未安装列表里的第 1 个协议，不是全部。选完后原有的确认列表（保留 + 新增）和按 [n] 取消流程不变，确认后走原来的端口分配、写站、Argo 询问、重启、订阅流程。

## v1.0.7 改了什么

- 协议重排成 27 种：原来第 10 号的 VLESS + Reality (Vision) / XTLS + Reality 移到第 3 号；走 CF 的协议按网速优先、延迟其次重排成 11. VLESS + HTTPUpgrade、12. VLESS + WS + TLS、13. Trojan + gRPC、14. VMess + gRPC、15. Trojan + WS、16. VMess + WS + TLS、17. Shadowsocks 2022 AES-256、18. VLESS + HTTP、19. VMess + HTTP、20. Trojan + HTTP；删掉 VMess + WS (CF)；其他位置不动，序号重排。`PROTO_NAMES` / `PROTO_LINK_NAMES` / `PROTO_TAGS` / `PROTO_CF`、协议选择解析（`a` = 全部 27 种，`aa`/`ab` = 第 26/27 种）、`write_inbound()` / `build_link_for()` / `clash_proxy_for()` 三个分支、Reality 检查、`sb -d` 的 WS/Reality 判断、XTLS 切换、Clash Naive 跳过、nginx 反代位置全部按新编号换过；分支内容和 v1.0.6 逐字节对过，只换编号。
- **升级注意：已装过旧版的机器升级到 v1.0.7 后，旧 `install.env` / `selected.env` 里存的是旧协议编号，升级后请从菜单 8 重新选一次协议。**
- 27 个协议的实际生成和连通未在真机上重测，需要用户实测。

## v1.0.6 改了什么

- CDN 优选域名新增 4 个：`cf.xreak.top`、`cf.3666888.xyz`、`cfsaas.080112.xyz`、`cf.92555.xyz`（共 10 个，原有 6 个不动）。
- 菜单 8 加了走 CF 的协议（10–20 号）后自动问 Argo 隧道：1. 临时隧道（try）、2. 固定隧道（Token）、3. 不启用。临时隧道开通后自动拿域名并匹配到 CF 节点链接（隧道域名:443）；已配好且在运行的隧道不再重复问，只刷新临时域名；配好但停了的直接重启。
- nginx 启动改成安全启动 `start_nginx_safe()`：旧 nginx 进程占着 8080 时先 `nginx -s reload` 加载新配置，不行再杀旧进程重起；被非 nginx 程序占用则不杀，打印占用者。
- `sb` / `cj` 记住上次的语言，直接进主菜单，不再重复问语言；语言选择里“2. 简体中文”标黄。

## v1.0.5 改了什么

- 协议名 WebSocket 改成 WS（用户要求，v1.0.5 时的编号）：11 `VLESS + WS + TLS (CF)`、12 `VMess + WS (CF)`、13 `VMess + WS + TLS (CF)`、14 `Trojan + WS (CF)`、22 `VLESS + WS + Reality`；链接后缀同步改成 `VLESS-WS-TLS` 等。内部 tag、JSON `type: "ws"`、`Sec-WebSocket-Protocol`、链接 `type=ws` 参数不动。
- 菜单 8 加完协议节点不通：原来只 `svc restart sing-box`，服务没启用时静默无动作。现在保存后 `svc enable` + `svc restart`，失败再 `svc start` 兜底，仍不运行明确报错，不再只印节点。
- 菜单 8 加完协议订阅不通：原来订阅默认 `no` 且不写 nginx 配置、不启动 nginx。现在加了协议后自动启用订阅（装 nginx、写配置、enable + start nginx）；`export_list()` 打印订阅链接时 nginx 未运行会提示订阅未启动。

## v1.0.4 改了什么

- 修了 v1.0.3 的缺口：自动补装只装了主程序，没生成 `install.env`，菜单 1. 查看节点信息、5. 修改节点配置、8. 增加 / 删除协议一进去就报“sing-box 尚未安装。”。新增 `ensure_empty_install_env()`：补装成功后（或主程序已存在但 `install.env` 缺失时）生成空的安装状态，`install.env` 默认值填好、协议为空；已有 `install.env` 的机器不会被覆盖。
- 同时写好加协议需要的基础文件：基础配置（无协议）、自签 TLS 证书、Reality 密钥对、服务文件（只写文件，不启用、不启动）。不写带假协议的配置，不启动服务。
- 菜单 1 空协议时提示“暂无协议，请从菜单 8 增加 / 删除协议里添加”，不再只显示一个空列表。
- 修了菜单 8 的旧缺口：新进程里 Reality 私钥不在内存中，加 Reality 协议会写出空私钥导致 `sing-box check` 失败；现在写协议前先从 `reality_private.key` 恢复，没有就生成一次并存下来。
- 菜单 5（`sb -d`）和菜单 8（`sb -r`）在空协议下没有别的硬性检查：`sb -d` 的端口、节点名、UUID、服务器地址、指纹等项正常显示；`sb -r` 直接列出全部 27 种待添加，确认后按新装流程问起始端口和节点名。

## v1.0.3 改了什么

- 首次运行自动补装主程序（`ensure_core_installed()`，只在交互进菜单时跑一次）：主程序缺失时自动补装 sing-box 二进制 + cloudflared，不装协议；成功后重新 `refresh_status()`，菜单变已安装 1–12 项；失败留在未安装 1–9 项并报错。
- 新增不退出的安全版 `install_singbox_binary_safe()`：原来下载失败用 `die` 直接退出整个脚本，安全版每一步失败都 `return 1`。

## v1.0.2 改了什么

- `cj` / `sb`：v1.0.1 只在安装完成时才创建，没装过就没有 `cj`；v1.0.2 在第一次运行脚本进菜单时就创建（`main()` 进 `main_menu()` 之前调用 `create_shortcut()`，安装完成时也会再次调用）。
- `create_shortcut()`：一键方式下 `$0` 是 `/dev/fd/63`，`cp "$0"` 会失败；v1.0.2 先试真实文件，一键方式先试 `cat` 从 `/dev/fd/*` 读出脚本内容，但实测 `cat` 同一个 fd 只拿到未读的尾巴（251KB 的脚本只拿到 24 字节），校验不过就不用这个残缺副本，改成把 `installer.sh` 写成重新下载的 wrapper（`INSTALLER_URL`，即 jiaoben 仓库地址），`sb` / `cj` 每次运行时重新拉取脚本——和原版 `sb.sh` 的做法一样。写完校验 `bash -n` 通过。
- 已安装菜单 1-9 文字和顺序没动。

## v1.0.1 改了什么

- 已安装主菜单改成用户发的原版 1–12 项（第 3 节）；`sb -v` 同步 Sing-box 和 Argo 两个组件，`sb -b` 改成下载运行 tcpx.sh，10/11/12 项改成安装 ArgoX / sba / TCP brutal。
- 新增 `cj` 快捷命令：第一次运行脚本进菜单时就创建 `/usr/local/bin/sb` 和 `/usr/local/bin/cj`，不用等装完，安装时也会再次创建；`cj` 不带参数打开主菜单，带参数和 `sb` 一样；卸载时两个一起删。
- 子菜单按原版 fscarmen/sing-box v1.3.31 对过：`sb -d` 改成原版动态菜单（第 5 节），`sb -r` 改成原版先删、再加、最后确认的流程（第 6 节），自定义路由、WARP、Argo、端口修改、卸载、版本信息都按原版文字、编号和问答流程改好（第 7、8、9、11 节）。
- 修了一个 v1.0.0 的 bug：`sb -d` / `sb -r` 在新进程里运行时端口表没恢复（`load_install_env` 现在会从 `ports.env` 恢复独立端口）。
- 28 种协议顺序、全称、15–18 号替换、Hysteria2 跳跃回车跳过、带宽、说明页、Clash 展开保持 v1.0.0 不变。

## 和原版冲突的地方（已确认的改动为准）

| 冲突点 | 处理 |
| --- | --- |
| `sb -d` 原版没有 `0. 返回` 这一项，输错直接返回 | 按原版：没有 `0. 返回`，输错显示“未做任何修改”并返回主菜单 |
| `sb -d` 原版改完一项直接退出脚本 | 本版改完回主菜单（菜单循环），不在脚本里退出 |
| `change_argo` 原版输错直接退出脚本 | 本版输错显示“未做任何修改”并返回主菜单 |
| 自定义路由 / 更换 WARP 账户原版只在 TUN + warp-ep 出站存在时显示 | 本版没有 TUN 出站，改成配了 WARP 账户才显示；规则写进 `03_route.json`、出站固定为 `direct`（原版是 `08_custom_route.json`、出站 warp-ep） |
| `rule_set` 原版会联网去 SagerNet / MetaCubeX 仓库校验规则集是否存在 | 本版不做联网校验，名称按原版规则自动补 `geosite-` 前缀，并按 SagerNet 的地址写入远程规则集定义 |
| Sing-box 升级失败时原版问是否更新基础配置 | 本版不问，直接回滚旧版本二进制 |
| `sb -r` 原版字母按列表排（最多 13 项，`a` = 第一项）；本版 27 种协议，列表超过 26 项时用 `aa`、`ab` | 按原版按列表排字母，超过 26 项的部分用 `aa`、`ab` 续排；安装向导的全局选择器（`a` = 全部 27 种）不受影响 |
| 独立端口选择时原版只列已装的协议 | 本版字母表列出全部 27 种协议，但选择会过滤到只改已装的协议 |
| 节点导出（`sb -n`）原版用远程模板拉取、双订阅二维码链接 | 仍是 v1.0.0 的简化渲染（链接 + 订阅 + Clash + 二维码），没有改 |
| Hysteria2 带宽原版 `sb -d` 提示示例是上行 200 / 下行 1000 | 安装向导默认值仍是 100/100；`sb -d` 里改带宽时先问上行、再问下行，提示文字和示例按原版 |
| 卸载时原版也会问 Nginx / fcgiwrap | 按原版问；但 `sb -u` 命令行方式跳过这两问 |

## 测试结果（v1.0.1）

- `bash -n sing-box.sh` 通过；ShellCheck error 级 0 个（53 条 warning，多为未使用变量，未逐条修）。
- sing-box 1.14.4 官方二进制：27 种逐个 `sing-box check` 全部通过，27 种合在一起也通过；实际启动 8 秒，27 个入站全部监听（v1.0.0 实测，v1.0.1 未改协议生成逻辑；v1.0.7 只换了编号，分支内容没变，未重测）。
- 导出链接 27 条，Clash `clash.yaml` 26 条（Naive 除外），YAML 能正常解析。
- 协议选择解析测试：`a` → 全部 27 种，`bcd` → 前 3 种，`aa ab` → 最后 2 种，`1 12 27` → 第 1、12、27 种。
- v1.0.1 冒烟测试（32 项全过）：已安装菜单 1–12 项文字和编号、2/3 项动态开/关标签、`sb -d` 动态菜单顺序和当前值、输错返回无修改、Hysteria2 带宽改 200/1000 并重写 inbound、XTLS vision 切多路复用（`flow` 清空、`multiplex` 开启）、`sb -r` 删加确认三条路径（正常增删、`n` 取消、全部删光后重问起始端口和节点名）、真实 sing-box 1.14.4 `check` 通过改写后的配置。

## 已知限制（v1.0.2）

- ShadowTLS 节点在 `sb -n` 里导出的是它内部 Shadowsocks 的链接，不是独立的 ShadowTLS 客户端链接；Clash 里 ShadowTLS 条目也没有展开 detour。
- 安装向导里指纹选择放在 Reality 提问之前（原版是在 Reality 流程里问），不影响结果。
- 外部小工具（ArgoX、sba、TCP brutal）按原版做法下载并运行第三方脚本，不是本仓库的代码。
- 动态订阅在没有 fcgiwrap 的机器上会回退到静态文件（实际以装机时的表现为准）。
