# sing-box 一键安装脚本 — 菜单预览（MENU PREVIEW）

> **状态：v1.0.0 最终版。菜单与 `sing-box.sh`（v1.0.0，2773 行）一致，已按用户确认的全部决定落实。**
> State: for confirmation only. The full script will be produced after the user confirms this preview.
>
> - 脚本文件：`~/workspace/sing-box-own/sing-box.sh`（v1.0.0 (2026.11.24)，2773 行，sing-box 默认版本 1.14.4）
> - 说明文件：`~/workspace/sing-box-own/README.md`，许可证：`~/workspace/sing-box-own/LICENSE`（MIT）
> - 本预览文件：`~/workspace/sing-box-own/MENU_PREVIEW.md`
> - 预览依据：已逐个核对脚本里的 `pick_language()`、`print_header()`、`main_menu()`、`show_protocol_picker()`、`ask_wizard_*()`、`run_install()`、`change_config_menu()`、`change_ports_menu()`、`change_protocols_menu()`、`custom_route_menu()`、`change_argo_menu()`、`export_list()`、`show_version()`、`run_uninstall()`。凡是预览与脚本不一致的地方，都在文末「⚠️ 预览与脚本当前草稿的差异」里标出，不藏着。
> - 颜色说明：终端里绿色是标题/成功信息，黄色是菜单选项，红色是警告/错误，蓝色是提示信息。以下代码块去掉了颜色，只保留文字和顺序。
>
> **本次修改（v1.0.0）：按用户确认的全部决定落实——前 10 置顶、11–21 走 Cloudflare 并标注（CF）、22–28 其余；15–18 号按替换方案做；带宽、说明页、Clash 展开、Hysteria2 跳跃回车跳过全部落实；协议名一律写全称。**
>
> **本次修改（2026-11-24 第三次更新）：按用户追加要求，VLESS + WebSocket + Reality 移出 CF 组，移到其余组第一位（新 22 号，不标注 CF）；CF 组从 12 个变成 11 个（11–21 号）；其余组为 22–28 号。其他顺序不变，总数仍是 28 种。**
>
> **本次修改（2026-11-24 第四次更新）：Hysteria2 端口跳跃改为一步式、回车跳过。安装向导中途（Realm 问完、进 CDN/订阅之前）直接问跳跃范围，不再先问 `Use port hopping? [y/N]`；直接回车 = 不用端口跳跃，继续往下装。`sb -d` 里改跳跃同样是输范围、回车跳过/保持不变。其他顺序、编号、分组一律不动，总数仍 28 种。**

---

## 0. 本次确认的重点：协议分组排序（新顺序，1–28）

**Grouping (new order — this is the main thing to confirm).**

协议按用户 2026-11-24 的要求重排：**前 10 个置顶**（1–10，按用户给的顺序），**能走 CF 的 11–21 号紧跟在第 10 名之后**，其余 22–28 跟上，编号连续，字母从 `b` 开始顺延，`a = 全部`。端口分配、--CHOOSE_PROTOCOLS、sb -d、sb -r、导出链接顺序，全部按这个新顺序。分组改成三组：**置顶常用（1–10）、走 Cloudflare（11–21，协议名后逐个标注“（CF）”）、其余（22–28，VLESS + WebSocket + Reality 已按用户要求移出 CF 组、排在其余组第一位，不标注 CF）**。

| 编号 | 字母 | 协议（中文菜单名） | 英文 | 内部 tag | 组 |
| --- | --- | --- | --- | --- | --- |
| 1 | b | Hysteria2 | Hysteria2 | hysteria2 | 置顶常用 |
| 2 | c | VLESS + Reality | VLESS + Reality | vless-reality | 置顶常用 |
| 3 | d | AnyTLS | AnyTLS | anytls | 置顶常用 |
| 4 | e | TUIC | TUIC | tuic | 置顶常用 |
| 5 | f | Trojan | Trojan | trojan | 置顶常用 |
| 6 | g | ShadowTLS | ShadowTLS | shadowtls | 置顶常用 |
| 7 | h | Shadowsocks | Shadowsocks | shadowsocks | 置顶常用 |
| 8 | i | Naive | Naive | naive | 置顶常用 |
| 9 | j | Snell v6 | Snell v6 | snell-v6 | 置顶常用 |
| 10 | k | VLESS + Reality (Vision) / XTLS + Reality | VLESS + Reality (Vision) / XTLS + Reality | xtls-reality | 置顶常用 |
| 11 | l | VLESS + WebSocket + TLS（CF） | VLESS + WebSocket + TLS (CF) | vless-ws-tls | 走 Cloudflare |
| 12 | m | VMess + WebSocket（CF） | VMess + WebSocket (CF) | vmess-ws | 走 Cloudflare |
| 13 | n | VMess + WebSocket + TLS（CF） | VMess + WebSocket + TLS (CF) | vmess-ws-tls | 走 Cloudflare |
| 14 | o | Trojan + WebSocket（CF） | Trojan + WebSocket (CF) | trojan-ws-tls | 走 Cloudflare |
| 15 | p | Shadowsocks 2022 AES-256（CF） | Shadowsocks 2022 AES-256 (CF) ⚠️ | ss2022-256 | 走 Cloudflare |
| 16 | q | VLESS + HTTP（CF） | VLESS + HTTP (CF) ⚠️ | vless-http | 走 Cloudflare |
| 17 | r | VMess + HTTP（CF） | VMess + HTTP (CF) ⚠️ | vmess-http | 走 Cloudflare |
| 18 | s | Trojan + HTTP（CF） | Trojan + HTTP (CF) ⚠️ | trojan-http | 走 Cloudflare |
| 19 | t | VLESS + HTTPUpgrade（CF） | VLESS + HTTPUpgrade (CF) | vless-httpupgrade | 走 Cloudflare |
| 20 | u | VMess + gRPC（CF） | VMess + gRPC (CF) | vmess-grpc | 走 Cloudflare |
| 21 | v | Trojan + gRPC（CF） | Trojan + gRPC (CF) | trojan-grpc | 走 Cloudflare |
| 22 | w | VLESS + WebSocket + Reality | VLESS + WebSocket + Reality | vless-ws-reality | 其余 |
| 23 | x | VLESS + TCP + TLS（Vision） | VLESS + TCP + TLS (Vision) | vless-tls | 其余 |
| 24 | y | Trojan + Reality | Trojan + Reality | trojan-reality | 其余 |
| 25 | z | Shadowsocks 2022 | Shadowsocks 2022 | ss2022 | 其余 |
| 26 | aa | H2 + Reality | H2 + Reality | h2-reality | 其余（冷门） |
| 27 | ab | gRPC + Reality | gRPC + Reality | grpc-reality | 其余（冷门） |
| 28 | ac | AnyTLS + Reality | AnyTLS + Reality | anytls-reality | 其余（冷门） |

字母说明（Letter mapping — to be confirmed）：

- `a` = 全部 28 种（ALL）。
- `b`–`z` = 第 1–25 种（单字母）。
- `aa`、`ab`、`ac` = 第 26、27、28 种（双字母，因为单字母用完了）。
- 输入方式和现在脚本一样：可多选，可连写（如 `bcd`）、可空格（如 `b c d`）、可逗号、大写自动转小写；也可以按数字 `1`–`28` 选（`11` = 第 11 种 VLESS + WebSocket + TLS（CF））。去重、按输入顺序保留。
- 字母 `aa/ab/ac` 和数字 `1`–`28` 在 v1.0.0 脚本里都已支持。

> **备注——第 10 号“VLESS + Reality Vision”：** 用户写的第 10 个按原表对应 **XTLS + Reality（Vision 流控，tag `xtls-reality`）**，不是新增一个第 29 种协议，总数仍是 28 种。第 2 号是普通 VLESS + Reality（`vless-reality`，不带 Vision / XTLS 流控），第 10 号是带 Vision 的 XTLS + Reality，两者不重复。预览里第 10 号写成“VLESS + Reality (Vision) / XTLS + Reality”，v1.0.0 已按这个对应关系落实。

**替换说明（15、16、17、18 号，v1.0.0 已落实）：**

- 15 号原来想要的 Shadowsocks + WebSocket：官方 sing-box 的 `shadowsocks` 入站没有 `transport` 字段，写进去 `sing-box check` 会报错（1.14.4 官方二进制实测）。已改成官方支持的等价组合 **Shadowsocks 2022 AES-256**（`2022-blake3-aes-256-gcm`，32 字节密钥），菜单和链接都按这个名字写。
- 16/17/18 号原来想要的 VLESS / VMess / Trojan + HTTP：`xhttp` 不是官方 sing-box 的合法传输类型（`unknown transport type: xhttp`，只存在于个别打补丁的 fork 里）。已改成官方支持的等价组合 **HTTP 传输**（`type=http`），菜单改成 VLESS + HTTP、VMess + HTTP、Trojan + HTTP。
- 其余 24 种已在 sing-box 1.14.4 上逐个 `sing-box check` 通过，28 种合在一起也通过，实际启动时 28 个入站全部监听。

分组说明（Grouping rationale）：

- **置顶常用组（1–10）**：按用户给的顺序置顶——Hysteria2、VLESS + Reality、AnyTLS、TUIC、Trojan、ShadowTLS、Shadowsocks、Naive、Snell v6、VLESS + Reality (Vision) / XTLS + Reality。
- **走 Cloudflare 组（11–21）**：能走 CF 的全部排到第 10 名之后，协议名后逐个标注“（CF）”——VLESS + WebSocket + TLS、VMess + WebSocket、VMess + WebSocket + TLS、Trojan + WebSocket、Shadowsocks 2022 AES-256、VLESS + HTTP、VMess + HTTP、Trojan + HTTP、VLESS + HTTPUpgrade、VMess + gRPC、Trojan + gRPC。都要经过 nginx / CDN / Argo 或 HTTP/gRPC 传输，安装时要多问域名、CDN、回源方式，集中放一组。VLESS + WebSocket + Reality 已按用户要求移出本组，排在其余组第一位（22 号），不标注 CF。
- **其余组（22–28）**：VLESS + WebSocket + Reality、VLESS + TCP + TLS、Trojan + Reality、Shadowsocks 2022、H2 + Reality、gRPC + Reality、AnyTLS + Reality，按这个顺序跟在 CF 组后面。

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
 Script version: v1.0.0 (2026.11.24)
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
> - `1` 一键快速安装：全部 28 种协议、默认端口 8881 起、订阅开、Argo 用临时隧道，不再逐项问，直接装完出链接。
> - `2` 安装 + 订阅 + Argo：进安装向导（第 4 节），订阅开、Argo 开。
> - `3` 安装 + Argo：进安装向导，订阅关、Argo 开。
> - `4` 安装 + 订阅：进安装向导，订阅开、Argo 关。
> - `5` 自定义安装：进安装向导，协议、端口、订阅、Argo 全部现场选。
> - `6` 测速：下载并运行测速小工具；下载失败时改做一次简单的 curl 下载测速。
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
 Script version: v1.0.0 (2026.11.24)
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

 1. View node links                          查看节点信息 (sb -n)
 2. Toggle sing-box service (sb -s)          开/关 sing-box (sb -s)
 3. Toggle Argo tunnel (sb -a)               开/关 Argo (sb -a)
 4. Change Argo settings (sb -t)             修改 Argo (sb -t)
 5. Change configuration (sb -d)             修改配置 (sb -d)
 6. Check / update version (sb -v)           查看/更新版本 (sb -v)
 7. Network speed test                       测速
 8. Add / remove protocols (sb -r)           增删协议 (sb -r)
 9. Uninstall (sb -u)                        卸载 (sb -u)
 10. Argo helper tool                        Argo 工具
 11. Subscription helper tool                订阅工具
 12. Hysteria2 helper tool                   Hysteria2 工具
 0. Exit                                     退出

Choose an option: _
```

英文（English — same numbers, English labels）：

```
 Script version: v1.0.0 (2026.11.24)
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
 2. Toggle sing-box service (sb -s)
 3. Toggle Argo tunnel (sb -a)
 4. Change Argo settings (sb -t)
 5. Change configuration (sb -d)
 6. Check / update version (sb -v)
 7. Network speed test
 8. Add / remove protocols (sb -r)
 9. Uninstall (sb -u)
 10. Argo helper tool
 11. Subscription helper tool
 12. Hysteria2 helper tool
 0. Exit
```

> 顶部状态栏说明 / Header explained：
>
> - `Script version`：本脚本版本 `v1.0.0 (2026.11.24)`。
> - `What's new`：固定一行 `quick install, subscription, Argo, port hopping, WARP`。
> - `System information`：操作系统、内核、处理器架构、虚拟化（`systemd-detect-virt` 测不到时显示 `unknown`，`none` 显示为 `bare-metal`）。
> - `IPv4` / `IPv6`：公网 IP（后面跟 `WARP` / `WARP+` 表示走了 WARP；测不到就留空）。
> - `Sing-box / Argo / Nginx` 三行：每行是「状态（`running` / `stopped` / `not-installed`）+ 版本号 + 内存占用」；Sing-box 行后面还有流量 `↓下载 ↑上传`（从 clash_api 的 `/traffic` 接口取，取不到就不显示）。
> - 每次进菜单都会重新刷新状态和版本，不是写死的。

---

## 4. 安装向导全流程

**函数：`run_install()`，按顺序调 `ask_wizard_protocols()` → `ask_wizard_start_port()` → `ask_wizard_server()` → `ask_wizard_uuid()` → `ask_wizard_node_name()` → `ask_wizard_fingerprint()` → Reality 私钥（如有）→ `ask_wizard_hy2()`（如有 Hysteria2）→ `ask_wizard_cdn()`（如有 WebSocket / HTTP 类协议）→ 订阅开关 → nginx 端口 → `ask_wizard_argo()`（如有 WebSocket 类协议）。命令行 / 配置文件里已经给过的值，不再重复问。**

### 4.1 协议选择菜单（28 种，分组显示）

中文：

```
  a. ALL (all 28 protocols)                  a. 全部（共 28 种协议）

  --- 置顶常用 / Pinned (1-10) ---
  b. hysteria2                               1. Hysteria2
  c. VLESS + Reality                         2. VLESS + Reality
  d. AnyTLS                                  3. AnyTLS
  e. tuic                                    4. TUIC
  f. trojan                                  5. Trojan
  g. ShadowTLS                               6. ShadowTLS
  h. shadowsocks                             7. Shadowsocks
  i. naive                                   8. Naive
  j. Snell v6                                9. Snell v6
  k. VLESS + Reality (Vision) / XTLS + Reality  10. VLESS + Reality (Vision) / XTLS + Reality

  --- 走 Cloudflare 协议 / Cloudflare (CF) (11-21) ---
  l. VLESS + WebSocket + TLS (CF)                   11. VLESS + WebSocket + TLS（CF）
  m. VMess + WebSocket (CF)                         12. VMess + WebSocket（CF）
  n. VMess + WebSocket + TLS (CF)                   13. VMess + WebSocket + TLS（CF）
  o. Trojan + WebSocket (CF)                        14. Trojan + WebSocket（CF）
  p. Shadowsocks 2022 AES-256 (CF) 见第 0 节      15. Shadowsocks 2022 AES-256（CF）
  q. VLESS + HTTP (CF) 见第 0 节          16. VLESS + HTTP（CF）
  r. VMess + HTTP (CF) 见第 0 节          17. VMess + HTTP（CF）
  s. Trojan + HTTP (CF) 见第 0 节         18. Trojan + HTTP（CF）
  t. VLESS + HTTPUpgrade (CF)                19. VLESS + HTTPUpgrade（CF）
  u. VMess + gRPC (CF)                       20. VMess + gRPC（CF）
  v. Trojan + gRPC (CF)                      21. Trojan + gRPC（CF）

  --- 其余 / Others (22-28) ---
  w. VLESS + WebSocket + Reality                    22. VLESS + WebSocket + Reality
  x. VLESS + TCP + TLS                       23. VLESS + TCP + TLS（Vision）
  y. Trojan + Reality                        24. Trojan + Reality
  z. Shadowsocks 2022                        25. Shadowsocks 2022
  aa. H2 + Reality                           26. H2 + Reality
  ab. gRPC + Reality                         27. gRPC + Reality
  ac. AnyTLS + Reality                       28. AnyTLS + Reality

Select protocols to install (a = all, e.g. b c, or a): _
请选择要安装的协议（a = 全部，例如输入 b c，也可以只输入 a）：_
```

> 说明 / How to choose：
>
> - 直接回车 = `a`（全部 28 种）。
> - 输入 `b c`、`bcd`、`b,c` 都行，大写自动转小写，重复的自动去重，按输入顺序排端口。
> - 也可以输入数字 `1`–`28`（如 `1 2 11`，`11` = VLESS + WebSocket + TLS（CF）），`aa`/`ab`/`ac` 选最后三种。
> - 输错（一个有效字母都没有）会提示输入无效，错误累计 5 次后脚本退出（`Too many invalid inputs, exiting. / 输入错误次数过多，脚本退出。`）。
> - 协议选择菜单是分组显示的 28 种，字母 `b`–`z` + `aa/ab/ac`，也可以输数字 `1`–`28`。

**选完协议后，端口按选择顺序连续分配。举例：起始端口 8881，选全部 28 种：**

| 协议 | 端口 | 协议 | 端口 |
| --- | --- | --- | --- |
| 1. Hysteria2 | 8881 | 15. Shadowsocks 2022 AES-256（CF） | 8895 |
| 2. VLESS + Reality | 8882 | 16. VLESS + HTTP（CF） | 8896 |
| 3. AnyTLS | 8883 | 17. VMess + HTTP（CF） | 8897 |
| 4. TUIC | 8884 | 18. Trojan + HTTP（CF） | 8898 |
| 5. Trojan | 8885 | 19. VLESS + HTTPUpgrade（CF） | 8899 |
| 6. ShadowTLS | 8886 | 20. VMess + gRPC（CF） | 8900 |
| 7. Shadowsocks | 8887 | 21. Trojan + gRPC（CF） | 8901 |
| 8. Naive | 8888 | 22. VLESS + WebSocket + Reality | 8902 |
| 9. Snell v6 | 8889 | 23. VLESS + TCP + TLS | 8903 |
| 10. VLESS + Reality (Vision) / XTLS + Reality | 8890 | 24. Trojan + Reality | 8904 |
| 11. VLESS + WebSocket + TLS（CF） | 8891 | 25. Shadowsocks 2022 | 8905 |
| 12. VMess + WebSocket（CF） | 8892 | 26. H2 + Reality | 8906 |
| 13. VMess + WebSocket + TLS（CF） | 8893 | 27. gRPC + Reality | 8907 |
| 14. Trojan + WebSocket（CF） | 8894 | 28. AnyTLS + Reality | 8908 |

### 4.2 起始端口

```
Enter the starting port (Port must be between 100 and 65520, and the following consecutive ports must be free 28 consecutive free ports, default 8881):
请输入起始端口（端口须在 100-65520 之间，且以下连续端口必须空闲 28 个连续空闲端口，默认 8881）：
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

**涉及协议：2. VLESS + Reality、10. VLESS + Reality (Vision) / XTLS + Reality、22. VLESS + WebSocket + Reality、24. Trojan + Reality、26. H2 + Reality、27. gRPC + Reality、28. AnyTLS + Reality。**

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
> 说明：带宽问完才问跳跃范围；跳跃范围之前会先打印上面那页端口跳跃说明。`sb -d` 第 10 项也能改带宽 / 跳跃 / Realm。

### 4.9 WebSocket / HTTP 类：域名 + CDN + 回源方式 + nginx 订阅端口

**涉及协议：11. VLESS + WebSocket + TLS（CF）、12. VMess + WebSocket（CF）、13. VMess + WebSocket + TLS（CF）、14. Trojan + WebSocket（CF）、22. VLESS + WebSocket + Reality（回源，不标注 CF）、19. VLESS + HTTPUpgrade（CF）、16/17/18 号 VLESS + HTTP / VMess + HTTP / Trojan + HTTP（CF）（替换后同样走这套）。20. VMess + gRPC（CF）、21. Trojan + gRPC（CF）同属 CF 组，走 gRPC 传输，host 也可用 CDN 域名。CDN 优选域名只问一次，所有 WebSocket / HTTP / gRPC 节点共用。**

```
Enter preferred address / CDN domain:
请输入优选地址 / CDN 域名：
  1. skk.moe
  2. ip.sb
  3. time.is
  4. bestcf.top
  5. cdn.2020111.xyz
  6. cf.090227.xyz
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

**函数：`change_config_menu()`。菜单文字（中英文）与脚本完全一致；第 10 项能改带宽、跳跃和 Realm（v1.0.0 已补带宽输入）。**

中文：

```
What would you like to change?
请选择要修改的项目：
  1. Ports                                端口
  2. UUID                                 UUID
  3. Node name                            节点名
  4. Server address                       服务器地址
  5. Fingerprint                          指纹
  6. SNI                                  SNI
  7. CDN                                  CDN
  8. Subscription on/off                  订阅开关
  9. Dynamic subscription on/off          动态订阅开关
 10. Hysteria2 bandwidth / hopping / Realm  Hysteria2 带宽 / 跳跃 / Realm
 11. Custom routes                        自定义路由
 12. WARP account                         WARP 账号
 13. Bind interface                       绑定网卡
  0. Back                                 返回

Choose an option: _
请选择：_
```

英文（English — items 1–13 are printed in English in the script; only the header/back are translated）：

```
What would you like to change?
  1. Ports
  2. UUID
  3. Node name
  4. Server address
  5. Fingerprint
  6. SNI
  7. CDN
  8. Subscription on/off
  9. Dynamic subscription on/off
 10. Hysteria2 bandwidth / hopping / Realm
 11. Custom routes
 12. WARP account
 13. Bind interface
  0. Back
```

> 选了之后去哪 / What each item does：
>
> - `1` 端口 → 第 9 节的端口修改方式选择（改起始端口 / 各协议独立端口）。
> - `2` UUID → 输新 UUID（36 位校验），重写全部 inbound，热加载。
> - `3` 节点名 → 改名后重新导出链接。
> - `4` 服务器地址 → 重新探测/输入，重新导出链接。
> - `5` 指纹 → chrome / firefox 二选一（同 4.6）。
> - `6` SNI → 输新 SNI，默认 `addons.mozilla.org`。
> - `7` CDN → 重新选优选域名（同 4.9 列表）。
> - `8` 订阅开关 → 开/关 nginx 订阅（开就启动 nginx，关就停止）。
> - `9` 动态订阅开关 → 在 `yes` 和 `dynamic` 之间切换。
> - `10` Hysteria2 → 先显示 `Hysteria2: Realm=… Hop=… Bandwidth=…/… Mbps`，再按 4.8 重新问 Realm、带宽和跳跃（v1.0.0 已补带宽输入）。
> - `11` 自定义路由 → 第 7 节子菜单。
> - `12` WARP 账号 → 第 8 节 WARP 子菜单。
> - `13` 绑定网卡 → 先列出本机网卡（`ip -o link show`），再输网卡名，留空 = 默认。
> - `0` 返回主菜单。每改一项后脚本都会 `sing-box check` 校验，通过才 reload / restart，不通过报错不重启。

---

## 6. `sb -r` 增删协议子菜单

**函数：`change_protocols_menu()`。没有单独的数字菜单，是“先删、再加”两步问答。**

中文：

```
Installed protocols:
已安装的协议：
  - Hysteria2 (port 8881)
  - VLESS + Reality (port 8882)
  - AnyTLS (port 8883)
  ...（按新顺序列出当前已装的全部协议和端口）

Remove (enter letters, e.g. c d, Enter to skip):
删除（输入字母多选，例如 c d，直接回车跳过）：
  a. ALL (all 28 protocols)
  b. Hysteria2
  c. VLESS + Reality
  ...（同 4.1 的分组协议表，28 种全列）
Choose an option: _
请选择：_

Add (enter letters, Enter to skip):
增加（输入字母多选，直接回车跳过）：
Choose an option: _
请选择：_
```

> 说明：删完再加；加完后按起始端口重新连续分配端口，删掉的协议的 inbound 文件删除、新增的写入，`sing-box check` 通过后重启服务、同步防火墙、重新输出节点链接。这一步的协议表与第 0 节的新顺序一致。

---

## 7. 自定义路由子菜单

**函数：`custom_route_menu()`，从 `sb -d` 的第 11 项进入。**

中文：

```
Custom routes:
自定义路由：
  1. Add rule                             添加规则
  2. View rules                           查看规则
  3. Delete rule                          删除规则
  0. Back                                 返回

Choose an option: _
请选择：_
```

> 选 `1` 添加规则时，再问规则类型：
>
> ```
> 1. domain_suffix
> 2. rule_set
> Choose an option: _
> 请选择：_
> Enter a domain suffix, e.g. example.com:
> 请输入域名后缀，例如 example.com：_
> ```
>
> 选 `2` 查看规则时，直接打印 `03_route.json` 里的全部规则（每条一行 JSON）。
> 选 `3` 删除规则时，先打印全部规则，再问 `Enter rule number to delete (0 = cancel): / 输入要删除的规则编号（0 = 取消）：`，输编号删除对应的一条。
> 规则写进 `/etc/sing-box/conf/03_route.json` 的 `route.rules` 里，出站固定为 `direct`。

---

## 8. WARP 账号子菜单、Argo 修改子菜单

### 8.1 WARP 账号子菜单（`sb -d` 第 12 项）

```
1. Register a new free account
2. Enter account info manually
0. Back
1. 重新注册免费账户
2. 手动输入信息
0. 返回

Choose an option: _
请选择：_
```

> 说明：`1` 用 wgcf / Cloudflare API 注册一个免费 WARP 账号；`2` 提示 `Paste WARP private key: / 粘贴 WARP 私钥：`，手动贴入私钥存到 `/etc/sing-box/warp-private.key`。

### 8.2 Argo 修改子菜单（主菜单第 4 项，`sb -t`）

```
Choose Argo tunnel type:
请选择 Argo 隧道类型：
  1. Temporary tunnel (try)
  2. Token / JSON / Cloudflare API
  1. 临时隧道（try）
  2. Token / JSON / Cloudflare API
Choose an option: _
请选择：_

Enter Argo Token, JSON, or Cloudflare API credentials:
请输入 Argo Token、JSON 或 Cloudflare API 信息：_
```

> 说明：选 `1` 清掉旧凭证、用临时隧道；选 `2` 再贴 Token / JSON / API 凭证，保存后重启 Argo 服务、重新解析临时域名、重新输出节点链接。选 Token / JSON / API 之前会先打印 Argo 分步指引（见 4.9），v1.0.0 已落实。

---

## 9. 端口跳跃说明页、端口修改方式选择

### 9.1 端口跳跃（Hysteria2，安装向导 4.8 里问）

**v1.0.0 的实际样子（问范围之前先打印一页端口跳跃说明，见 4.8）：**

```
Enter Hysteria2 port hopping range, e.g. 20000:21000 (Enter to skip, no port hopping):
请输入 Hysteria2 端口跳跃范围，例如 20000:21000（直接回车跳过，不用端口跳跃）：
```

> 说明：安装时端口跳跃已改为**一步式、回车跳过**——直接回车 = 不用端口跳跃，输范围（`起始:结束` 或 `起始-结束`，10000–65535、起始小于结束）才开启，输错提示重新输入（错误 5 次退出）。装好后在 `sb -d` 第 10 项里改跳跃，同样是输范围、直接回车跳过/保持不变。
> 说明：问跳跃范围之前会先打印一页端口跳跃说明（见 4.8），v1.0.0 已落实。

### 9.2 端口修改方式选择（`sb -d` 第 1 项 → `change_ports_menu()`）

```
1. Change start port (protocols keep consecutive ports)
2. Set an independent port per protocol
0. Back
1. 修改起始端口（各协议按顺序占用，默认）
2. 修改为各协议独立端口
0. 返回

Choose an option: _
请选择：_
```

> 说明：
>
> - 选 `1`：输一个新起始端口（默认 8881），全部协议按新顺序（第 0 节表）重新连续分配，重写全部 inbound，校验通过后 reload 并同步防火墙。
> - 选 `2`：逐个协议问一遍，格式是 `Port for <协议名> (current: <当前端口>):`，输一个空闲端口就改那一个，不输/输错就跳过该协议。
> - 选 `0`：返回 `sb -d` 菜单。

---

## 10. 查看节点信息 `sb -n` 的输出样式

**函数：`export_list()`。打印 `/etc/sing-box/list` 的内容；如果装了 `qrencode`，后面再打一个订阅二维码（ANSI 字符画）。订阅文件同时写到 `/etc/sing-box/subscribe/`（明文 `list_plain.txt`、base64 `list.txt`、Clash `clash.yaml`）。**

中文 / 英文（链接本身没有语言差别，只示例节点名不同）：

```
sing-box nodes -- my-node
Server: 1.2.3.4

hysteria2://<密码>@1.2.3.4:8881?insecure=1&sni=addons.mozilla.org#my-node%20Hysteria2
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8882?encryption=none&flow=xtls-rprx-vision&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&sid=&type=tcp#my-node%20VLESS-Reality
anytls://11111111-2222-3333-4444-555555555555@1.2.3.4:8883?insecure=1&sni=addons.mozilla.org#my-node%20AnyTLS
tuic://11111111-2222-3333-4444-555555555555:<密码>@1.2.3.4:8884?congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#my-node%20TUIC
trojan://<密码>@1.2.3.4:8885?security=tls&sni=addons.mozilla.org&allowInsecure=1#my-node%20Trojan
ss://<base64(2022-blake3-aes-128-gcm:密码)>@1.2.3.4:8886#my-node%20ShadowTLS
ss://<base64(2022-blake3-aes-128-gcm:密码)>@1.2.3.4:8887#my-node%20Shadowsocks
https://user:<密码>@1.2.3.4:8888?padding=1#my-node%20Naive
snell://<PSK>@1.2.3.4:8889?version=6#my-node%20Snell-v6
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8890?encryption=none&flow=xtls-rprx-vision&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&sid=&type=tcp#my-node%20VLESS-Reality-Vision
vless://11111111-2222-3333-4444-555555555555@skk.moe:8891?encryption=none&security=tls&sni=addons.mozilla.org&type=ws&host=skk.moe&path=/vless-ws-tls#my-node%20VLESS-WebSocket-TLS
vmess://<base64 JSON: net=ws, host=skk.moe, path=/vmess-ws, tls为空>#my-node%20VMess-WebSocket
vmess://<base64 JSON: net=ws, host=skk.moe, path=/vmess-ws-tls, tls=tls>#my-node%20VMess-WebSocket-TLS
trojan://<密码>@skk.moe:8894?security=tls&sni=addons.mozilla.org&type=ws&host=skk.moe&path=/trojan-ws#my-node%20Trojan-WebSocket
ss://<base64(2022-blake3-aes-256-gcm:密码)>@1.2.3.4:8895#my-node%20Shadowsocks-2022-AES-256
vless://11111111-2222-3333-4444-555555555555@skk.moe:8896?encryption=none&security=tls&sni=addons.mozilla.org&type=http&host=skk.moe&path=/vless-http#my-node%20VLESS-HTTP
vmess://<base64 JSON: net=http, host=skk.moe, path=/vmess-http, tls=tls>#my-node%20VMess-HTTP
trojan://<密码>@skk.moe:8898?security=tls&sni=addons.mozilla.org&type=http&host=skk.moe&path=/trojan-http#my-node%20Trojan-HTTP
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8899?encryption=none&type=httpupgrade&path=/vless-httpupgrade&host=skk.moe#my-node%20VLESS-HTTPupgrade
vmess://<base64 JSON: net=grpc, serviceName=vmess-grpc, tls=tls>#my-node%20VMess-gRPC
trojan://<密码>@1.2.3.4:8901?security=tls&sni=addons.mozilla.org&type=grpc&serviceName=trojan-grpc#my-node%20Trojan-gRPC
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8902?encryption=none&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&type=ws&host=1.2.3.4&path=/vless-ws#my-node%20VLESS-WebSocket-Reality
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8903?encryption=none&flow=xtls-rprx-vision&security=tls&sni=addons.mozilla.org#my-node%20VLESS-TCP-TLS
trojan://<密码>@1.2.3.4:8904?security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&type=tcp#my-node%20Trojan-Reality
ss://<base64(2022-blake3-aes-128-gcm:密码2)>@1.2.3.4:8905#my-node%20Shadowsocks-2022
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8906?encryption=none&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&type=http#my-node%20H2-Reality
vless://11111111-2222-3333-4444-555555555555@1.2.3.4:8907?encryption=none&security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>&type=grpc&serviceName=grpc#my-node%20gRPC-Reality
anytls://11111111-2222-3333-4444-555555555555@1.2.3.4:8908?security=reality&sni=addons.mozilla.org&fp=chrome&pbk=<Reality公钥>#my-node%20AnyTLS-Reality

Subscription: http://1.2.3.4:8080/sub

Subscription QR:
（qrencode 的 ANSI 二维码，仅在装了 qrencode 时显示）
```

> 说明 / Notes：
>
> - 链接顺序 = 第 0 节的新分组顺序，端口按 4.1 的表连续分配（示例起始端口 8881）。
> - WebSocket / HTTP 类节点的 `host` 用 CDN 优选域名（如 `skk.moe`），直连节点用服务器地址。
> - 上面 15 号是替换方案的链接（Shadowsocks 2022 AES-256）；16/17/18 号是替换方案的链接（`type=http`，不是原来想要的 XHTTP 写法）。原 XHTTP / Shadowsocks + WebSocket 在官方 sing-box 上跑不起来，见第 0 节替换说明。
> - 订阅链接固定是 `http://<服务器地址>:<nginx端口>/sub`；动态订阅开启时，nginx 按请求 Host 实时渲染。
> - Clash 的 `clash.yaml` 是逐协议完整展开版：`proxies` 里按协议逐个写 VLESS / VMess / Trojan / Hysteria2 / Shadowsocks / TUIC / AnyTLS / Snell 等条目（共 27 条，Naive 没有对应的 Clash 代理类型所以不在内，链接仍在 `list_plain.txt` 里），`proxy-groups` 里有 PROXY 分组，`rules` 是 `MATCH,PROXY`。

---

## 11. 卸载确认、`sb -v` 版本信息

### 11.1 卸载确认（主菜单第 9 项，`sb -u`）

```
This will remove sing-box, its configuration and the sb shortcut. Continue? [y/N]:
将删除 sing-box、配置文件和 sb 快捷命令，确定继续吗？[y/N]：
```

> 说明：输 `y` 才继续；其他（包括回车）取消，显示 `No change made. / 未做任何修改。`。继续后会停服务、删服务文件、清端口跳跃 NAT、按 `/etc/sing-box/firewall/service_ports.list` 删防火墙规则、删 nginx 订阅配置、删 `/etc/sing-box` 和 `/usr/local/bin/sb`，最后显示 `sing-box has been completely removed. / sing-box 已彻底卸载。`。`sb -u` 命令行方式跳过确认直接卸载。

### 11.2 版本信息（主菜单第 6 项，`sb -v`）

```
Script version: v1.0.0 (2026.11.24)
sing-box: 1.14.4
Argo: 2026.1.1
Nginx: 1.24.0
You are already on the latest version.
当前已是最新版本。
```

> 有新版本时，上面最后一行改成下面这样，并追问是否更新：
>
> ```
> A new version is available.: v1.15.0-alpha.13 (installed v1.14.4)
> 发现新版本。: v1.15.0-alpha.13 (installed v1.14.4)
> Update sing-box now? [y/N]:
> 现在更新 sing-box 吗？[y/N]：
> ```
>
> 说明：版本号从 GitHub API 查最新 release；没装过对应组件时那一行显示 `sing-box is not installed yet. / sing-box 尚未安装。`。

---

## 附录 A. 命令行参数（与菜单对应的快捷方式，不进菜单也看得到）

```
sb -s    开/关 sing-box        sb -a    开/关 Argo
sb -t    修改 Argo             sb -d    修改配置（第 5 节）
sb -u    卸载                  sb -n    查看节点信息（第 10 节）
sb -v    查看/更新版本         sb -b    测速
sb -r    增删协议（第 6 节）
-E / -C / --LANGUAGE en|zh    语言
-K / -L                       一键快速安装（-L 为中文）
-f / -F FILE                  从 KEY=VALUE 配置文件读安装答案
--CHOOSE_PROTOCOLS a|b c ...  按第 0 节的字母/数字选协议（a=全部 28 种）
--START_PORT / --PORT_NGINX / --SERVER_IP / --CDN / --UUID_CONFIRM /
--NODE_NAME_CONFIRM / --SUBSCRIBE yes|no|dynamic / --ARGO true|false /
--ARGO_DOMAIN / --ARGO_AUTH / --HY2_PORT_HOPPING_RANGE /
--HY2_REALM / --BIND_INTERFACE / --REALITY_PRIVATE
```

---

## v1.0.0 落实情况（原 D1–D9 的处理结果）

| 编号 | 原问题 | v1.0.0 的处理 |
| --- | --- | --- |
| D1 | 协议只有 13 种、旧顺序、无分组 | 已落实：脚本已是 28 种新顺序（前 10 置顶、11–21 走 Cloudflare、22–28 其余），字母 `b`–`z` + `aa/ab/ac`、数字 `1`–`28` 都支持，`a` = 全部 28 种。 |
| D2 | 函数名与原版不一致（`menu()` / `menu_setting()`） | 接受现状：独立重写，菜单函数叫 `main_menu()` + `print_header()`，功能和编号与原版一致。 |
| D3 | 15/16/17/18 号在官方 sing-box 上不支持 | 已落实：按替换方案做（15→Shadowsocks 2022 AES-256；16/17/18→HTTP 传输），菜单名和链接都已改掉，README 有替换说明。 |
| D4 | `sb -d` 第 10 项标题有带宽、实际没有带宽输入 | 已落实：补了带宽输入。安装时问上行/下行（默认 100/100 Mbps），`sb -d` 第 10 项也能改带宽、跳跃、Realm。 |
| D5 | 没有端口跳跃说明页 | 已落实：问跳跃范围之前打印一页说明（运营商限速、推荐 1000 个左右、NAT 小鸡端口少要慎用、默认不开启）。 |
| D6 | Argo 输入没有分步指引 | 已落实：选 Token / JSON / API 之前打印分步指引（去哪里开隧道、去哪里建 API 令牌、令牌要勾哪些权限）。 |
| D7 | Clash 订阅不是完整展开版 | 已落实：`clash.yaml` 逐协议完整展开，共 27 条（Naive 没有 Clash 代理类型所以不在内，已在文件里注明）。 |
| D8 | 1.15.0-alpha.13 未实测 | 未变：结论依据仍是 1.14.4 实测 + 上游文档。脚本默认安装 1.14.4，`sb -v` 会提示更新。 |
| D9 | README / LICENSE 还没写 | 已落实：`README.md` 和 `LICENSE`（MIT）已写好。 |

## 全称对照表（28 种）

协议名一律写全称：WebSocket 写全，不写 WS；Shadowsocks 不写 SS；Hysteria2 不写 Hy2。链接里的 `type=ws`、`type=http`、`ss://` 等是客户端协议格式本身，不能改；内部 tag 只用在配置文件名和 JSON 里。

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
| 15 | p | Shadowsocks 2022 AES-256 (CF) | ss2022-256 | 是（替换方案，见第 0 节） |
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

## 测试结果（v1.0.0）

- `bash -n sing-box.sh` 通过；ShellCheck error 级 0 个（53 条 warning，多为未使用变量，未逐条修）。
- sing-box 1.14.4 官方二进制：28 种逐个 `sing-box check` 全部通过，28 种合在一起也通过；实际启动 8 秒，28 个入站全部监听。
- 导出链接 28 条，Clash `clash.yaml` 27 条（Naive 除外），YAML 能正常解析。
- 协议选择解析测试：`a` → 全部 28 种，`bcd` → 前 3 种，`aa ab ac` → 最后 3 种，`1 14 28` → 第 1、14、28 种。

## 已知限制（v1.0.0，第一版）

- ShadowTLS 节点在 `sb -n` 里导出的是它内部 Shadowsocks 的链接，不是独立的 ShadowTLS 客户端链接；Clash 里 ShadowTLS 条目也没有展开 detour。
- `sb -d` 菜单是固定顺序的 13 项；原版是按已装协议动态拼菜单，本版先用了固定顺序，功能一样。
- 安装向导里指纹选择放在 Reality 提问之前（原版是在 Reality 流程里问），不影响结果。
- 外部小工具（Argo 工具、订阅工具、Hysteria2 工具）按原版做法下载并运行第三方脚本，不是本仓库的代码。
