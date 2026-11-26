#!/usr/bin/env bash
# =============================================================================
# sing-box one-click installer -- independent reimplementation
# -----------------------------------------------------------------------------
# This file was written from scratch. It is NOT a copy of any other
# installer script. It implements a similar user-visible workflow
# (language choice, protocol selection, install / manage / uninstall)
# because that workflow is what users expect from a sing-box helper,
# but every function, variable name, control flow and message in this
# file is original work by the author of this repository.
#
# License: MIT (see LICENSE in the same repository).
# Upstream sing-box itself is a separate project (SagerNet/sing-box,
# licensed under GPL-3.0). This installer only downloads its official
# release binary; it does not bundle sing-box source code.
#
# Usage:
#   bash <(wget -qO- https://raw.githubusercontent.com/<user>/sing-box/main/sing-box.sh)
#   bash sing-box.sh            # interactive menu
#   sb                          # shortcut created on first run (also `cj`)
#   bash sing-box.sh -n         # show node links
#   bash sing-box.sh -s         # toggle sing-box service
#   bash sing-box.sh -u         # uninstall
#   bash sing-box.sh --help     # show all options
#
# Supported systems: Debian, Ubuntu, CentOS / RHEL, Alpine, Armbian,
# Fedora, Arch Linux (x86_64 and aarch64).
# =============================================================================

# ---------------------------------------------------------------------------
# 1. Metadata and global defaults
# ---------------------------------------------------------------------------
MY_VERSION="v1.0.20 (2026.11.26)"
MY_NAME="sing-box installer (independent build)"
# The URL this installer is downloaded from. `sb` / `cj` re-fetch the
# installer from here when the script was run via a one-liner, because
# a one-liner's script comes through a pipe that cannot be copied back
# (see create_shortcut). Set SB_INSTALLER_URL in the environment to
# override it, e.g. for a local test server.
INSTALLER_URL="https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh"
# Default sing-box release to install when the GitHub API is unreachable.
# The installer normally queries the GitHub API for the newest release.
FALLBACK_SB_VERSION="1.14.4"
# Where everything lives on the server.
SB_HOME="/etc/sing-box"
SB_CONF_DIR="${SB_HOME}/conf"
SB_BIN="${SB_HOME}/sing-box"
SB_JQ="${SB_HOME}/jq"
SB_LIST_FILE="${SB_HOME}/list"
SB_FIREWALL_DIR="${SB_HOME}/firewall"
SB_FIREWALL_PORTS_FILE="${SB_FIREWALL_DIR}/service_ports.list"
SB_TMP="/tmp/sb-installer"
SB_ARGO_BIN="/usr/local/bin/cloudflared"
SB_ARGO_CONF="${SB_HOME}/argo.json"
SB_ARGO_DAEMON="/usr/local/bin/argo-daemon"
# Working defaults for the install wizard. The user may override them
# interactively or with command line flags.
DEFAULT_START_PORT=8881
PORT_MIN=100
PORT_MAX=65520
HOP_MIN=10000
HOP_MAX=65535
DEFAULT_TLS_HOST="addons.mozilla.org"
DEFAULT_FINGERPRINT="chrome"
DEFAULT_CDN_HOST="cf.3666888.xyz"
# The nineteen protocols, in the exact order shown to the user.
# Display names use the WS abbreviation, as the user requested
# (v1.0.5: WebSocket is written "WS" in user-visible protocol names).
# Shadowsocks is never "SS", and Hysteria2 is never "Hy2". Short tags
# are used only inside file names, JSON tags and the standard
# client-link parameters (type=ws, etc.), which are part of the
# client protocol format and cannot be renamed.
# (CF) after a name means the protocol is routed through Cloudflare
# (CDN / Argo tunnel / nginx reverse proxy).
PROTO_NAMES=(
  "Hysteria2"
  "VLESS + Reality"
  "VLESS + Reality (Vision) / XTLS + Reality"
  "AnyTLS"
  "TUIC"
  "Trojan"
  "Shadowsocks"
  "VLESS + WS + TLS (CF)"
  "Trojan + WS (CF)"
  "VMess + WS + TLS (CF)"
  "Trojan + HTTP (CF)"
  "Shadowsocks 2022 AES-256"
  "VLESS + WS + Reality"
  "VLESS + TCP + TLS (Vision)"
  "Trojan + Reality"
  "Shadowsocks 2022"
  "H2 + Reality"
  "gRPC + Reality"
  "AnyTLS + Reality"
)
# Suffix used after "#" in client links: protocol name, spaces
# replaced with "-", no "(CF)" annotation. WS is the user-required
# abbreviation for WebSocket (v1.0.5).
PROTO_LINK_NAMES=(
  "Hysteria2" "VLESS-Reality" "VLESS-Reality-Vision" "AnyTLS" "TUIC"
  "Trojan" "Shadowsocks" "VLESS-WS-TLS" "Trojan-WS" "VMess-WS-TLS"
  "Trojan-HTTP" "Shadowsocks-2022-AES-256" "VLESS-WS-Reality" "VLESS-TCP-TLS"
  "Trojan-Reality" "Shadowsocks-2022" "H2-Reality" "gRPC-Reality"
  "AnyTLS-Reality"
)
PROTO_TAGS=(
  "hysteria2" "vless-reality" "xtls-reality" "anytls" "tuic" "trojan"
  "shadowsocks" "vless-ws-tls" "trojan-ws-tls" "vmess-ws-tls" "trojan-http"
  "ss2022-256" "vless-ws-reality" "vless-tls" "trojan-reality" "ss2022"
  "h2-reality" "grpc-reality" "anytls-reality"
)
# 1 = routed through Cloudflare (CDN / Argo / nginx), 0 = direct.
PROTO_CF=(0 0 0 0 0 0 0 1 1 1 1 0 0 0 0 0 0 0 0)
# Letters shown in the protocol picker: a = all, then b..t.
PROTO_LETTERS=(a b c d e f g h i j k l m n o p q r s t)
# CDN / preferred-address candidates offered for WebSocket nodes.
CDN_CANDIDATES=(
  "skk.moe" "ip.sb" "time.is" "bestcf.top"
  "cdn.2020111.xyz" "cf.090227.xyz"
  "cf.xreak.top" "cf.3666888.xyz" "cfsaas.080112.xyz" "cf.92555.xyz"
  "xn--b6gac.eu.org" "cfvip.cf.3666888.xyz" "fn.130519.xyz"
)
# GitHub mirrors used only when the direct download is slow or blocked.
GH_MIRRORS=(
  "https://ghproxy.lvedong.eu.org/"
  "https://accel.cloudflare.nyc.mn/"
)
# Runtime state, filled in as the script runs.
LANG_CODE="E"          # E = English, C = Simplified Chinese
SYS_ID=""              # debian | ubuntu | centos | alpine | armbian | fedora | arch
SYS_PRETTY=""          # human readable OS name
SYS_MAJOR=0
ARCH_RAW=""            # uname -m
ARCH_SB=""             # amd64 | arm64
ARCH_JQ=""             # amd64 | arm64
IS_INSTALLED=0
SB_RUNNING=""          # running | stopped | not-installed
RUN_COUNT=""           # cumulative interactive menu runs (v1.0.15)
ARGO_RUNNING=""
NGINX_RUNNING=""
SB_VERSION_INSTALLED=""
ARGO_VERSION_INSTALLED=""
NGINX_VERSION_INSTALLED=""
WAN4="" WAN6="" COUNTRY4="" COUNTRY6="" ASN4="" ASN6=""
WARP4="" WARP6=""
VIRT_KIND=""
# Wizard answers (empty = ask the user, or fall back to a default).
WIZ_PROTOCOLS=""       # e.g. "b c d" or "a"
WIZ_START_PORT=""
WIZ_SERVER_ADDR=""
WIZ_UUID=""
WIZ_NODE_NAME=""
WIZ_CDN=""
WIZ_SUBSCRIBE=""       # yes | no | dynamic
WIZ_ARGO=""            # yes | no
WIZ_ARGO_AUTH=""
WIZ_ARGO_DOMAIN=""
WIZ_NGINX_PORT=""
WIZ_HY2_HOP=""         # e.g. "20000:21000"
WIZ_HY2_REALM=""       # yes | no
WIZ_HY2_IGNORE="false" # Hysteria2 ignore_client_bandwidth (BBR CC) flag
WIZ_HY2_UP=""          # Hysteria2 upload bandwidth, Mbps (default 200)
WIZ_HY2_DOWN=""        # Hysteria2 download bandwidth, Mbps (default 1000)
# v1.0.20: TCP brutal availability, computed by check_brutal() at
# config-write time (brutal only when the kernel module is loaded).
# "true" / "false", used as a JSON boolean.
IS_BRUTAL=false
WIZ_BIND_IFACE=""
WIZ_REALITY_PRIV=""
WIZ_FINGERPRINT=""
WIZ_SNI=""
FAST_INSTALL=0
QUIET_INSTALL=0
CONFIG_FILE=""
INPUT_ERRORS=0
MAX_INPUT_ERRORS=5
# Per-protocol ports, filled by assign_ports().
declare -a PORT_FOR=()
declare -a UUID_FOR=()
# Reality key pair, generated once per install.
REALITY_PRIV_KEY=""
REALITY_PUB_KEY=""
# Hysteria2 password (shared secret).
HY2_SECRET=""
# Shadowsocks / trojan passwords.
SS_PASSWORD=""
SS256_PASSWORD=""    # Shadowsocks 2022 AES-256 (32-byte key, base64)
SS2022_PASSWORD=""   # Shadowsocks 2022 (16-byte key, base64)
TROJAN_PASSWORD=""
TUIC_PASSWORD=""

export DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# 2. Small helpers: cleanup, colours, logging
# ---------------------------------------------------------------------------
cleanup_tmp() {
  rm -rf "$SB_TMP"
}
trap cleanup_tmp EXIT
trap 'cleanup_tmp; printf "\n"; exit 1' INT QUIT TERM
mkdir -p "$SB_TMP"

# Colour helpers. Keep them tiny; the menu uses them everywhere.
c_red()    { printf '\033[31m\033[01m%s\033[0m\n' "$*"; }
c_green()  { printf '\033[32m\033[01m%s\033[0m\n' "$*"; }
c_yellow() { printf '\033[33m\033[01m%s\033[0m\n' "$*"; }
c_blue()   { printf '\033[34m\033[01m%s\033[0m\n' "$*"; }
c_bold()   { printf '\033[01m%s\033[0m\n' "$*"; }
msg_ok()   { c_green "$*"; }
msg_warn() { c_yellow "$*"; }
msg_err()  { c_red "$*"; }
msg_info() { c_blue "$*"; }
die() { msg_err "$*"; exit 1; }

# Count a failed input. After MAX_INPUT_ERRORS failures the script stops
# instead of looping forever on a broken terminal or a bot.
note_bad_input() {
  INPUT_ERRORS=$((INPUT_ERRORS + 1))
  if [ "$INPUT_ERRORS" -ge "$MAX_INPUT_ERRORS" ]; then
    msg_err "$(tr_text too_many_errors)"
    exit 1
  fi
}
reset_bad_input() { INPUT_ERRORS=0; }

# Read one line from the user. First argument is the prompt (already
# translated), second is the variable name to store the answer in.
# Returns 0 on success.
ask_line() {
  local prompt="$1" var="$2" answer=""
  printf '%s ' "$prompt"
  IFS= read -r answer || answer=""
  printf -v "$var" '%s' "$answer"
}

# Like ask_line, but the option-selection prompt ("请选择：")
# is printed in bold green (v1.0.15). Used for every "choose an option"
# prompt in the menus; value prompts (SNI, node name, ...) stay plain.
ask_choice() {
  local var="$1" answer=""
  printf '\033[32m\033[01m%s\033[0m ' "$(tr_text choose_option)"
  IFS= read -r answer || answer=""
  printf -v "$var" '%s' "$answer"
}

# Like ask_choice, but with a caller-supplied prompt printed in bold
# green (v1.0.16). Used for selection/confirm prompts inside submenus
# whose text is not the generic "请选择：" (protocol letters,
# remove/add/confirm, upgrade yes/no, ...). Value prompts (SNI,
# node name, token, ...) stay plain ask_line.
ask_prompt() {
  local prompt="$1" var="$2" answer=""
  printf '\033[32m\033[01m%s\033[0m ' "$prompt"
  IFS= read -r answer || answer=""
  printf -v "$var" '%s' "$answer"
}

# Yes / no helper: returns 0 for yes, 1 for no. Default is given by $2
# ("y" or "n"). Accepts y/yes/n/no in either case, plus an empty answer.
ask_yes_no() {
  local prompt="$1" def="${2:-n}" ans=""
  while true; do
    if [ "$def" = "y" ]; then
      ask_prompt "${prompt} [Y/n]:" ans
      ans="${ans:-y}"
    else
      ask_prompt "${prompt} [y/N]:" ans
      ans="${ans:-n}"
    fi
    case "${ans,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *) msg_warn "$(tr_text invalid_choice)"; note_bad_input ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# 3. Bilingual messages
# ---------------------------------------------------------------------------
# This is deliberately NOT an indexed E[]/C[] copy of any other script.
# Messages are stored as "english|chinese" pairs in one associative
# array, keyed by a short English slug that describes the meaning.
# Adding a language later only means adding a third field.
declare -A MSG=(
  [too_many_errors]="Too many invalid inputs, exiting.|输入错误次数过多，脚本退出。"
  [invalid_choice]="Invalid choice, please try again.|输入无效，请重新输入。"
  [need_root]="Please run this script as root.|请使用 root 用户运行本脚本。"
  [unsupported_os]="This system is not supported. Supported: Debian, Ubuntu, CentOS, Alpine, Armbian, Fedora, Arch.|当前系统不受支持。支持 Debian、Ubuntu、CentOS、Alpine、Armbian、Fedora、Arch。"
  [os_too_old]="Your system version is too old for this installer.|当前系统版本过低，不支持安装。"
  [unsupported_arch]="Your CPU architecture is not supported.|当前 CPU 架构不受支持。"
  [choose_lang]="Choose language:|请选择语言："
  [lang_en]="1. English (default)"
  [lang_zh]="2. 简体中文"
  [checking_system]="Checking system information...|正在检查系统信息..."
  [installing_deps]="Installing dependencies:|正在安装依赖："
  [deps_ok]="All dependencies are already installed.|所有依赖均已安装，无需额外安装。"
  [downloading_sb]="Downloading sing-box, please wait...|正在下载 sing-box，请稍候..."
  [download_failed]="Download failed. Please check your network and try again.|下载失败，请检查网络后重试。"
  [core_auto_install]="Sing-box core not found. Auto-installing the core only (no protocols will be installed)...|检测到 sing-box 主程序缺失，正在自动补装主程序（不安装协议）..."
  [core_auto_ok]="Sing-box core installed.|sing-box 主程序补装成功。"
  [core_auto_failed]="Failed to auto-install the sing-box core. Please install it from the menu and try again.|sing-box 主程序自动补装失败，请从菜单安装后重试。"
  [argo_auto_failed]="Failed to auto-install cloudflared (Argo). You can still use the menu; Argo will be installed when needed.|cloudflared（Argo）自动补装失败，菜单仍可使用，需要时再装 Argo。"
  [install_done]="sing-box has been installed successfully.|sing-box 安装成功。"
  [uninstall_done]="sing-box has been completely removed.|sing-box 已彻底卸载。"
  [not_installed]="sing-box is not installed yet.|sing-box 尚未安装。"
  [no_protocols_yet]="No protocols installed yet. Add some from menu 8 (Add / remove protocols).|暂无协议，请从菜单 8 增加 / 删除协议里添加。"
  [sb_start_failed]="Sing-box failed to start after saving. Check 'systemctl status sing-box' and the config.|sing-box 服务保存后启动失败，请用 systemctl status sing-box 检查服务和配置。"
  [sub_not_running]="Subscription is not running: nginx is stopped, so the subscription link above will not open. Enable subscription from menu 5 or re-run menu 8.|订阅未启动：nginx 未运行，上面这个订阅链接打不开。请从菜单 5 开启订阅，或重新跑一次菜单 8。"
  [sub_auto_failed]="Failed to enable the subscription (nginx). Node links are saved, but the subscription link will not open until nginx starts.|订阅（nginx）自动启用失败。节点链接已保存，但订阅链接在 nginx 启动前打不开。"
  [nginx_port_busy]="The subscription port is already used by another program (not nginx). Stop that program or change the subscription port, then try again.|订阅端口已被其他程序（不是 nginx）占用。请停掉那个程序或换个订阅端口，再试一次。"
  [nginx_reloaded]="nginx reloaded with the new config; the old nginx process was already listening, so no new master was started.|nginx 已用新配置重载；旧 nginx 进程已在监听，不再另起新进程。"
  [argo_none]="3. No Argo tunnel (CF nodes may not connect)|3. 不启用 Argo（CF 节点可能不通）"
  [argo_ask_cf]="CF protocols are selected. Their inbounds listen on 127.0.0.1 behind nginx, so they can only be reached through an Argo tunnel (or a CDN domain). Choose an Argo tunnel:|已选择走 CF 的协议，它们的入站只监听在 127.0.0.1 上，要靠 Argo 隧道（或 CDN 域名）才能从外面访问，请选择 Argo 隧道："
  [argo_try_wait]="Starting the temporary tunnel, waiting for its domain...|正在启动临时隧道，等待分配域名..."
  [argo_try_ok]="Temporary tunnel is up.|临时隧道已开通。"
  [argo_started]="Argo tunnel started.|Argo 隧道已启动。"
  [argo_try_failed]="Temporary tunnel started but no domain was found. Check 'systemctl status argo' and '/var/log/argo.log'. CF nodes will use the CDN domain for now.|临时隧道已启动但没拿到域名，请检查 systemctl status argo 和 /var/log/argo.log。CF 节点暂时仍用 CDN 域名。"
  [argo_start_failed]="Failed to start the Argo tunnel. Check 'systemctl status argo'.|Argo 隧道启动失败，请检查 systemctl status argo。"
  [argo_no_cf_warn]="Argo is not enabled. CF nodes need an Argo tunnel or a CDN domain to be reachable.|未启用 Argo，CF 节点需要 Argo 隧道或 CDN 域名才能访问。"
  [argo_domain_is]="Argo tunnel domain:|Argo 隧道域名："
  [service_started]="Service started.|服务已启动。"
  [service_stopped]="Service stopped.|服务已停止。"
  [service_failed]="Service operation failed.|服务操作失败。"
  [choose_option]="Choose an option:|请选择："
  [option_out_of_range]="Please enter a number in the range shown.|请输入菜单中显示的数字范围。"
  [press_enter]="Press Enter to continue...|按回车键继续..."
  [script_version]="Script version|脚本版本"
  [new_features]="What's new|功能新增"
  [system_info]="System information|系统信息"
  [os_label]="Operating system|当前操作系统"
  [kernel_label]="Kernel|内核"
  [arch_label]="Architecture|处理器架构"
  [virt_label]="Virtualization|虚拟化"
  [view_nodes]="View node links|查看节点信息"
  [close_sb]="Close Sing-box|关闭 Sing-box"
  [open_sb]="Open Sing-box|开启 Sing-box"
  [close_argo]="Close Argo|关闭 Argo"
  [open_argo]="Open Argo|开启 Argo"
  [toggle_sb]="Toggle sing-box service|开/关 sing-box"
  [toggle_argo]="Toggle Argo tunnel|开/关 Argo"
  [change_argo]="Change Argo tunnel|更换 Argo 隧道"
  [change_config]="Modify node configuration|修改节点配置"
  [check_update]="Sync Sing-box and Argo to the latest version|同步 Sing-box 和 Argo 至最新版本"
  [update_script]="Upgrade script to the latest version|升级脚本至最新版本"
  [script_up_to_date]="Script is already the latest version.|脚本已是最新版本。"
  [script_updated]="Script updated to %s. It takes effect the next time you run sb.|脚本已更新到 %s，下次运行 sb 时生效。"
  [script_verify_failed]="Downloaded script failed verification. The current script was not changed.|下载的脚本校验失败，当前脚本未改动。"
  [speed_test]="Network speed test|网络测速"
  [kernel_bbr]="Upgrade kernel, install BBR, DD script|升级内核、安装BBR、DD脚本"
  [change_protocols]="Add / remove protocols|增加 / 删除协议"
  [installed_protocols]="Installed protocols.|已安装的协议"
  [uninstalled_protocols]="Uninstalled protocols.|未安装的协议"
  [remove_protocols_prompt]="Please select the protocols to be removed (type 'all' to remove all installed protocols, multiple selections possible. Press Enter to skip):|请选择需要删除的协议（输入 all 删除全部已安装协议，也可以多选，回车跳过）："
  [add_protocols_prompt]="Please select the protocols to be added (type 'all' to add all uninstalled protocols, multiple choices possible. Press Enter to skip):|请选择需要增加的协议（输入 all 一键安装全部未安装协议，也可以多选，回车跳过）："
  [confirm_reinstall]="Confirm all protocols for reloading.|确认重装的所有协议"
  [keep_protocols]="Keep protocols|保留协议"
  [add_protocols_label]="Add protocols|新增协议"
  [confirm_continue]="Press [n] if there is an error, other keys to continue:|如有错误请按 [n]，其他键继续："
  [selected_order]="The order of the selected protocols and ports is as follows:|选择的协议及端口次序如下："
  [uninstall]="Uninstall|卸载"
  [argo_tool]="Install ArgoX script (argo + xray)|安装 ArgoX 脚本 (argo + xray)"
  [subscribe_tool]="Install sba script (argo + sing-box)|安装 sba 脚本 (argo + sing-box)"
  [hy2_tool]="Install TCP brutal|安装 TCP brutal"
  [exit_menu]="Exit|退出"
  [fast_install]="Quick install (all protocols)|一键快速安装（全部协议）"
  [install_with_sub_argo]="Install + subscription + Argo|安装 + 订阅 + Argo"
  [install_with_argo]="Install + Argo|安装 + Argo"
  [install_with_sub]="Install + subscription|安装 + 订阅"
  [custom_install]="Custom install|自定义安装"
  [select_protocols]="Select protocols to install (a = all, e.g. b c, or a):|请选择要安装的协议（a = 全部，例如输入 b c，也可以只输入 a）："
  [enter_start_port]="Enter the starting port|请输入起始端口"
  [port_range_hint]="Port must be between 100 and 65520, and the following consecutive ports must be free|端口须在 100-65520 之间，且以下连续端口必须空闲"
  [enter_server]="Enter server address, IP or domain|请输入服务器地址（IP 或域名）"
  [enter_uuid]="Enter UUID (leave empty for a random one)|请输入 UUID（留空则随机生成）"
  [uuid_bad]="UUID must be 36 characters long, please re-enter|UUID 须为 36 位字符，请重新输入"
  [enter_node_name]="Enter node name|请输入节点名称"
  [enter_cdn]="Enter preferred address / CDN domain|请输入优选地址 / CDN 域名"
  [choose_fingerprint]="Choose client fingerprint|请选择客户端指纹"
  [enter_reality_priv]="Enter Reality private key (leave empty to generate one)|请输入 Reality 私钥（留空则自动生成）"
  [choose_hy2_realm]="Use Realm for Hysteria2?|Hysteria2 是否使用 Realm？"
  [choose_hopping]="Use port hopping for Hysteria2?|Hysteria2 是否使用端口跳跃？"
  [enter_hop_range]="Enter Hysteria2 port hopping range, e.g. 20000:21000 (Enter to skip, no port hopping)|请输入 Hysteria2 端口跳跃范围，例如 20000:21000（直接回车跳过，不用端口跳跃）"
  [enter_hy2_bandwidth]="Enter Hysteria2 bandwidth in Mbps, upload/download, e.g. 200/1000 (Enter for the default 200/1000)|请输入 Hysteria2 带宽（Mbps，上行/下行，例如 200/1000，直接回车用默认 200/1000）"
  [hop_explain]="Port hopping: some carriers throttle or block a single UDP port. Port hopping spreads Hysteria2 traffic over a range of UDP ports so one blocked port does not stop the node. Use about 1000 ports (for example 20000:21000). On a NAT VPS only 20-30 ports may be open; hopping ports that are not open will make the node unreachable, so be careful. Leave it empty to turn port hopping off (default).|端口跳跃说明：有些运营商会限速或阻断单个 UDP 端口。端口跳跃把 Hysteria2 的流量分散到一段 UDP 端口上，一个端口被封也不会导致节点全断。推荐用 1000 个左右的端口（例如 20000:21000）。NAT 小鸡能用的端口一般只有 20-30 个，填了没开放的端口会导致节点不通，请慎用。直接回车表示不开启端口跳跃（默认）。"
  [argo_guide]="How to get Argo credentials (Cloudflare): 1. Open https://dash.cloudflare.com/ , go to Zero Trust > Networks > Connectors, create a tunnel and choose Cloudflared; the token is shown there. 2. Or get a JSON credential from a tunnel you already created. 3. Or use a Cloudflare API token: https://dash.cloudflare.com/profile/api-tokens > Create Token > Create Custom Token, and grant these permissions: Account > Cloudflare One Connector: Cloudflared > Edit, and Zone > DNS > Edit; Account Resources: Include > your account; Zone Resources: Include > Specific zone > your domain. Without these permissions the API call will fail.|获取 Argo 凭证的方法（Cloudflare）：1. 打开 https://dash.cloudflare.com/ ，进入 Zero Trust > 网络 > 连接器，创建隧道并选择 Cloudflared，Token 就显示在那里。2. 或者用已建隧道的 JSON 凭证。3. 或者用 Cloudflare API 令牌：https://dash.cloudflare.com/profile/api-tokens > 创建令牌 > 创建自定义令牌，授予以下权限：帐户 > Cloudflare One 连接器：Cloudflared > 编辑，以及区域 > DNS > 编辑；帐户资源：包括 > 你的账户；区域资源：包括 > 特定区域 > 你的域名。权限不够时 API 调用会失败。"
  [enter_nginx_port]="Enter the nginx subscription port|请输入 nginx 订阅端口"
  [choose_argo_type]="Choose Argo tunnel type|请选择 Argo 隧道类型"
  [enter_argo_auth]="Enter Argo Token, JSON, or Cloudflare API credentials|请输入 Argo Token、JSON 或 Cloudflare API 信息"
  [enter_domain]="Enter domain for the tunnel|请输入隧道域名"
  [config_saved]="Configuration saved.|配置已保存。"
  [config_check_ok]="Configuration check passed.|配置校验通过。"
  [config_check_bad]="Configuration check failed, please check the JSON files.|配置校验失败，请检查 JSON 文件。"
  [restarting]="Restarting services...|正在重启服务..."
  [updating]="Checking for updates...|正在检查更新..."
  [already_latest]="You are already on the latest version.|当前已是最新版本。"
  [update_available]="A new version is available.|发现新版本。"
  [no_change]="No change made.|未做任何修改。"
  [back]="Back|返回"
  [confirm_uninstall]="This will remove sing-box, its configuration and the sb shortcut. Continue?|将删除 sing-box、配置文件和 sb 快捷命令，确定继续吗？"
  [enter_port]="Enter port|请输入端口"
  [port_in_use]="Port is already in use, please choose another one|端口已被占用，请换一个"
  [port_bad]="Invalid port number|端口号无效"
  [domain_bad]="Invalid domain or IP address|域名或 IP 地址无效"
  [generating_keys]="Generating keys...|正在生成密钥..."
  [fetching_ip]="Detecting public IP address...|正在检测公网 IP..."
  [warp_register]="Registering a free WARP account...|正在注册免费 WARP 账户..."
  [firewall_sync]="Syncing firewall rules...|正在同步防火墙规则..."
  [subscribe_on]="Subscription: enabled|订阅：已开启"
  [subscribe_off]="Subscription: disabled|订阅：已关闭"
  [dynamic_on]="Dynamic subscription: enabled|动态订阅：已开启"
  [dynamic_off]="Dynamic subscription: disabled|动态订阅：已关闭"
  [change_what]="Please select what to modify:|请选择修改项目："
  [cdn_label]="Preferred CDN|优选域名/IP"
  [sni_label]="Reality SNI|Reality SNI"
  [ports_label]="Listen ports|监听端口"
  [node_name_label]="Node name|节点名称"
  [uuid_label]="UUID / Password / PSK|UUID / 密码 / PSK"
  [server_label]="Server address|服务器地址"
  [fp_label]="Client Fingerprint|客户端指纹"
  [bind_label]="Bind network interface|指定网络出口"
  [sub_enable]="Enable subscription|开启订阅"
  [sub_disable]="Disable subscription|关闭订阅"
  [dyn_enable]="Enable dynamic subscription|开启动态订阅"
  [dyn_disable]="Disable dynamic subscription|关闭动态订阅"
  [hy2_cc_bbr]="Hysteria2 force clients to use the BBR CC -> the declared up/down, i.e. Hysteria CC|Hysteria2 强制客户端使用 BBR 拥塞控制 -> 声明的 up/down，即 Hysteria CC"
  [hy2_cc_declared]="Hysteria2 the declared up/down, i.e. Hysteria CC (default) -> force clients to use the BBR CC|Hysteria2 声明的 up/down，即 Hysteria CC（默认）-> 强制客户端使用 BBR 拥塞控制"
  [hy2_bw_label]="Hysteria2 bandwidth|Hysteria2 带宽"
  [hy2_hop_label]="Hysteria2 Port Hopping|Hysteria2 端口跳跃"
  [hy2_hop_disabled]="disabled|禁用"
  [realm_close]="Close Realm|关闭 Realm"
  [realm_open]="Open Realm|开启 Realm"
  [xtls_to_mux]="Switch XTLS reality to Multiplex (current: vision)|XTLS reality 切换为多路复用（当前：vision）"
  [xtls_to_vision]="Switch XTLS reality to Vision (current: multiplex)|XTLS reality 切换为 vision（当前：多路复用）"
  [custom_route_label]="Custom warp-ep outbounds rules|自定义 warp-ep 出站路由规则"
  [warp_change]="Change WARP account|更换 WARP 账户"
  [enter_hy2_up]="Please enter Hysteria2 client upload speed in Mbps (e.g. 200)|请输入 Hysteria2 客户端上行速率 Mbps（纯数字，如 200）"
  [enter_hy2_down]="Please enter Hysteria2 client download speed in Mbps (e.g. 1000)|请输入 Hysteria2 客户端下行速率 Mbps（纯数字，如 1000）"
  [positive_int]="Invalid input, please enter a positive integer.|输入无效，请输入正整数。"
  [hop_realm_confirm]="Port hopping is enabled. Enabling Realm will disable port hopping. Continue? [y/N] (default N)|端口跳跃已开启，启用 Realm 将关闭端口跳跃。是否继续？[y/N]（默认 N）"
  [realm_hop_confirm]="Realm is enabled. Enabling port hopping will disable Realm. Continue? [y/N] (default N)|Realm 已开启，启用端口跳跃将关闭 Realm。是否继续？[y/N]（默认 N）"
  [enter_hop_disable]="Enter the port range, e.g. 50000:51000. Leave blank to disable|请输入端口范围，例如 50000:51000，如要禁用请留空"
  [enter_domain_suffix]="Enter domain suffix (comma-separated, e.g. google.com,telegram.org)|输入域名后缀（逗号分隔，如 google.com,telegram.org）"
  [enter_ruleset]="Enter rule_set name (comma-separated, e.g. geosite-google,geosite-telegram)|输入规则集名称（逗号分隔，如 geosite-google,geosite-telegram）"
  [ruleset_common]="Common rule_set: openai / google / youtube / netflix / telegram / tiktok / twitter / anthropic / google-gemini. Enter name will auto-prefix geosite- and validate existence|常用规则集：openai / google / youtube / netflix / telegram / tiktok / twitter / anthropic / google-gemini。输入名称会自动补全 geosite- 前缀"
  [domain_bad_format]="Invalid domain format|无效的域名格式"
  [warp_ipv6]="Enter the WARP IPv6 address|请输入 WARP IPv6 地址"
  [warp_privkey]="Enter the WARP private key|请输入 WARP Private Key"
  [warp_reserved]="Enter WARP reserved values (format: 123,456,789)|请输入 WARP reserved 保留值（格式：123,456,789）"
  [warp_reserved_bad]="Invalid reserved format. Please enter 3 numbers like 123,456,789|reserved 格式错误，请输入 3 个数字，如 123,456,789"
  [warp_register_failed]="New account registration failed. Please try again later. The existing account is kept.|注册新账户失败，请稍后再试。已保留原有账户。"
  [remove_nginx]="Whether to uninstall Nginx [y/N] (default is N)|是否卸载 Nginx [y/N] (默认为 N)"
  [remove_fcgi]="To uninstall fcgiwrap / spawn-fcgi press [y], they are not uninstalled by default|如要卸载 fcgiwrap / spawn-fcgi 请按 [y]，默认不卸载"
  [apply_changes]="Apply the changes [y/N] (default N)|是否应用以上修改 [y/N] (默认为 N)"
  [ports_updated]="Ports updated and hot-reloaded.|端口已更新并已热加载。"
  [whether_upgrade]="Whether to upgrade [y/N] (default is N)|是否升级 [y/N] (默认为 N)"
  [no_upgrade]="No upgrade required.|不需要升级"
  [argo_try]="1. Try|1. 临时隧道（try）"
  [argo_token]="2. Token or Json. Including created through Cloudflare API|2. Token 或者 Json，包括通过 Cloudflare API 创建"
  [add_rule]="Add rule|添加规则"
  [view_rules]="View rules|查看规则"
  [delete_rule]="Delete rule|删除规则"
  [enter_rule_domain]="Enter a domain suffix, e.g. example.com|请输入域名后缀，例如 example.com"
  [rule_added]="Rule added.|规则已添加。"
  [rule_deleted]="Rule deleted.|规则已删除。"
  [no_rules]="No custom rules yet.|暂无自定义规则。"
  [traffic_label]="Traffic|流量"
  [memory_label]="Memory|内存"
  # --- v1.0.15 ---
  [cdn_current]=" (current)| （当前）"
  [run_count_total]="Total runs: %s|累计运行 %s 次"
  [status_running]="Running|开启"
  [status_stopped]="Stopped|关闭"
  [status_not_installed]="Not installed|未安装"
  [current_value]=" (current: %s)| （当前：%s）"
  [leave_blank_disable]=" [leave blank to disable]| [留空禁用]"
  [hy2_bw_current]="up %s Mbps, down %s Mbps|上行 %s Mbps，下行 %s Mbps"
  [argo_tunnel_is]="Argo tunnel is: %s|Argo 隧道类型：%s"
  [argo_domain_line]="The domain is: %s|隧道域名：%s"
  [rule_type_title]="Select rule type:|选择规则类型："
  [enter_rule_delete]="Enter rule number to delete (0 = cancel):|输入要删除的规则编号（0 = 取消）："
  [port_mode_title]="Port modification mode:|修改端口方式："
  [port_mode_start]="1. Modify start port (protocols occupy sequential ports, default)|1. 修改开始端口（各协议按顺序占用，默认）"
  [port_mode_each]="2. Set an independent port for each protocol|2. 给每个协议单独设端口"
  [start_port_preview]="Start port %s -> %s: %s protocol ports will become %s - %s.|起始端口 %s -> %s：%s 个协议端口将变为 %s - %s。"
  [installed_protocols_list]="Installed protocols:|已安装的协议："
  [proto_port_line]="  - %s (port %s)|  - %s（端口 %s）"
  [port_for_prompt]="Port for %s (current: %s):|%s 的端口（当前：%s）："
  [port_changes_title]="Port changes:|端口变化："
  [warp_account_title]="Select WARP account operation:|选择 WARP 账户操作："
  [warp_register_new]="1. Register a new free account|1. 重新注册免费账户"
  [warp_enter_manual]="2. Enter account info manually|2. 手动输入账户信息"
  [argo_version_newest]="Argo local version: %s. The newest version: %s|Argo 本地版本：%s，最新版本：%s"
  [sb_version_newest]="Sing-box local version: %s. The newest version: %s|sing-box 本地版本：%s，最新版本：%s"
  [argo_check_failed]="Could not check the latest Argo version; keeping the installed one.|无法检查 Argo 最新版本，保留已安装的版本。"
  [net_ifaces]="Network interfaces:|网络接口："
  [picker_all]="a. ALL (all 19 protocols)|a. 全部（全部 19 种协议）"
  [picker_top]="--- Top protocols ---|--- 置顶协议 ---"
  [picker_cf]="--- Cloudflare (CF) protocols ---|--- Cloudflare (CF) 协议 ---"
  [picker_other]="--- Other protocols ---|--- 其他协议 ---"
  [new_features_list]="quick install, subscription, Argo, port hopping, WARP|一键安装、订阅、Argo、端口跳跃、WARP"
  # --- v1.0.16 ---
  [argo_sync_not_installed]="Not installed, nothing to sync.|未安装，无需同步。"
  [argo_sync_fixed]="Fixed tunnel, nothing to sync.|固定隧道，无需同步。"
  [argo_sync_off]="Argo is off, nothing to sync.|Argo 未开启，无需同步。"
  [argo_sync_no_domain]="No tunnel domain found in the log.|日志里没有找到隧道域名。"
  [argo_sync_no_change]="Argo domain unchanged: %s|Argo 域名没有变化：%s"
  [argo_sync_done]="Argo domain updated to %s; subscription re-exported.|Argo 域名已更新为 %s，订阅已重新生成。"
  [tunnel_fixed]="Fixed tunnel|固定隧道"
  [tunnel_try]="Temporary tunnel|临时隧道"
)

# Translate a key. If LANG_CODE is C return the Chinese half, else English.
tr_text() {
  local key="$1"
  local pair="${MSG[$key]:-$key}"
  if [ "$LANG_CODE" = "C" ]; then
    printf '%s' "${pair#*|}"
  else
    printf '%s' "${pair%%|*}"
  fi
}

# Print the two-line language picker used at startup.
pick_language() {
  if [ -n "$LANG_CODE" ] && [ "$LANG_CODE" != "E" ] && [ "$LANG_CODE" != "C" ]; then
    LANG_CODE="E"
  fi
  # If the caller already set the language via -E / -C / --LANGUAGE,
  # do not ask again.
  if [ "${LANG_PRESET:-0}" = "1" ]; then
    return 0
  fi
  c_green "$(tr_text choose_lang)"
  c_yellow " $(tr_text lang_en)"
  c_yellow " $(tr_text lang_zh)"
  local ans=""
  ask_choice ans
  case "$ans" in
    2|c|C|zh|ZH) LANG_CODE="C" ;;
    *) LANG_CODE="E" ;;
  esac
}

# ---------------------------------------------------------------------------
# 4. Generic utilities
# ---------------------------------------------------------------------------
# Is the string a valid IPv4 address?
is_ipv4() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local IFS='.' part
  for part in $ip; do
    [ "$part" -le 255 ] 2>/dev/null || return 1
  done
  return 0
}
# Is the string a valid IPv6 address (loose check, brackets optional)?
is_ipv6() {
  local ip="${1#[}"; ip="${ip%]}"
  [[ "$ip" == *:* ]] || return 1
  [[ "$ip" =~ ^[0-9a-fA-F:]+$ ]] || return 1
  return 0
}
# Is the string a plausible domain name?
is_domain() {
  local d="$1"
  [[ "$d" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$ ]] || return 1
  return 0
}
is_ip_or_domain() { is_ipv4 "$1" || is_ipv6 "$1" || is_domain "$1"; }

# UUID validation: 8-4-4-4-12 hex, case-insensitive.
is_valid_uuid() {
  [[ "$1" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]
}
make_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen
  elif [ -r /proc/sys/kernel/random/uuid ]; then
    cat /proc/sys/kernel/random/uuid
  else
    # Fallback built from /dev/urandom.
    local h
    h=$(od -An -tx1 -N16 /dev/urandom | tr -d ' \n')
    printf '%s-%s-%s-%s-%s' "${h:0:8}" "${h:8:4}" "${h:12:4}" "${h:16:4}" "${h:20:12}"
  fi
}
make_password() {
  # URL-safe random string, default length 16.
  local n="${1:-16}"
  tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$n"
  printf '\n'
}
# Shadowsocks 2022-blake3-aes-128-gcm needs a 16-byte key, base64
# encoded (24 characters). A plain random string is rejected by
# sing-box with "bad key", so generate a real key here.
make_ss_key() {
  head -c 16 /dev/urandom | base64 | tr -d '\n'
  printf '\n'
}
# Shadowsocks 2022-blake3-aes-256-gcm needs a 32-byte key, base64
# encoded (44 characters).
make_ss_key_256() {
  head -c 32 /dev/urandom | base64 | tr -d '\n'
  printf '\n'
}
# Port helpers.
is_port_number() {
  [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge "$PORT_MIN" ] && [ "$1" -le "$PORT_MAX" ]
}
is_port_free() {
  local p="$1"
  if command -v ss >/dev/null 2>&1; then
    ! ss -tuln 2>/dev/null | grep -qE "[:.]${p}[[:space:]]"
  elif command -v netstat >/dev/null 2>&1; then
    ! netstat -tuln 2>/dev/null | grep -qE "[:.]${p}[[:space:]]"
  else
    # No listener tool: try to bind briefly with bash /dev/tcp.
    ! (exec 3<>"/dev/tcp/127.0.0.1/${p}") 2>/dev/null
  fi
}
# Are $2 consecutive ports starting at $1 all free?
ports_free_range() {
  local start="$1" count="$2" i p
  for ((i = 0; i < count; i++)); do
    p=$((start + i))
    is_port_free "$p" || return 1
  done
  return 0
}
# Find a free port at or after $1.
find_free_port_from() {
  local p="$1"
  while [ "$p" -le "$PORT_MAX" ]; do
    is_port_free "$p" && { printf '%s' "$p"; return 0; }
    p=$((p + 1))
  done
  return 1
}
# Human readable byte count, e.g. 1536 -> 1.50 KiB style (uses B/KB/MB).
human_bytes() {
  local n="${1:-0}"
  if [ "$n" -ge 1073741824 ]; then
    awk -v v="$n" 'BEGIN{printf "%.2f GB", v/1073741824}'
  elif [ "$n" -ge 1048576 ]; then
    awk -v v="$n" 'BEGIN{printf "%.2f MB", v/1048576}'
  elif [ "$n" -ge 1024 ]; then
    awk -v v="$n" 'BEGIN{printf "%.2f KB", v/1024}'
  else
    printf '%s B' "$n"
  fi
}
# Download a URL to a file, trying direct, then the mirrors.
# $1 = url, $2 = output file. Returns 0 on success.
fetch_file() {
  local url="$1" out="$2"
  if curl -fsSL --retry 2 --connect-timeout 15 "$url" -o "$out" 2>/dev/null; then
    [ -s "$out" ] && return 0
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -q --tries=2 --timeout=15 -O "$out" "$url" 2>/dev/null && [ -s "$out" ] && return 0
  fi
  local m
  for m in "${GH_MIRRORS[@]}"; do
    case "$url" in
      *github.com*|*raw.githubusercontent.com*|*objects.githubusercontent.com*)
        curl -fsSL --retry 1 --connect-timeout 15 "${m}${url}" -o "$out" 2>/dev/null && [ -s "$out" ] && return 0
        ;;
    esac
  done
  return 1
}
# GET a URL to stdout (for small JSON API calls).
fetch_text() {
  curl -fsSL --retry 2 --connect-timeout 10 "$1" 2>/dev/null
}

# ---------------------------------------------------------------------------
# 5. System detection and dependency installation
# ---------------------------------------------------------------------------
require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    msg_err "$(tr_text need_root)"
    exit 1
  fi
}
detect_arch() {
  ARCH_RAW="$(uname -m)"
  case "$ARCH_RAW" in
    x86_64|amd64) ARCH_SB="amd64"; ARCH_JQ="amd64" ;;
    aarch64|arm64) ARCH_SB="arm64"; ARCH_JQ="arm64" ;;
    *) msg_err "$(tr_text unsupported_arch) ($ARCH_RAW)"; exit 1 ;;
  esac
}
detect_os() {
  # Sets SYS_ID, SYS_PRETTY, SYS_MAJOR, VIRT_KIND.
  local id="" ver="" pretty=""
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-}"; ver="${VERSION_ID:-}"; pretty="${PRETTY_NAME:-$id}"
  fi
  SYS_PRETTY="$pretty"
  case "$id" in
    debian)  SYS_ID="debian";  SYS_MAJOR="${ver%%.*}" ;;
    ubuntu)  SYS_ID="ubuntu";  SYS_MAJOR="${ver%%.*}" ;;
    centos|rhel|rocky|almalinux|ol)
      SYS_ID="centos"; SYS_MAJOR="${ver%%.*}" ;;
    alpine)  SYS_ID="alpine";  SYS_MAJOR="${ver%%.*}" ;;
    armbian) SYS_ID="armbian"; SYS_MAJOR="${ver%%.*}" ;;
    fedora)  SYS_ID="fedora";  SYS_MAJOR="${ver%%.*}" ;;
    arch|archarm|manjaro) SYS_ID="arch"; SYS_MAJOR="${ver:-0}" ;;
    *) msg_err "$(tr_text unsupported_os)"; exit 1 ;;
  esac
  # Minimum versions, kept deliberately conservative.
  case "$SYS_ID" in
    debian)  [ "${SYS_MAJOR:-0}" -lt 10 ] && { msg_err "$(tr_text os_too_old)"; exit 1; } ;;
    ubuntu)  [ "${SYS_MAJOR:-0}" -lt 18 ] && { msg_err "$(tr_text os_too_old)"; exit 1; } ;;
    centos)  [ "${SYS_MAJOR:-0}" -lt 7 ]  && { msg_err "$(tr_text os_too_old)"; exit 1; } ;;
    alpine)  [ "${SYS_MAJOR:-0}" -lt 3 ]  && { msg_err "$(tr_text os_too_old)"; exit 1; } ;;
    fedora)  [ "${SYS_MAJOR:-0}" -lt 32 ] && { msg_err "$(tr_text os_too_old)"; exit 1; } ;;
  esac
  # Virtualization, best effort.
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT_KIND="$(systemd-detect-virt 2>/dev/null || echo unknown)"
  elif [ -r /proc/cpuinfo ] && grep -qi hypervisor /proc/cpuinfo; then
    VIRT_KIND="vm"
  else
    VIRT_KIND="unknown"
  fi
  [ "$VIRT_KIND" = "none" ] && VIRT_KIND="bare-metal"
}
# Does this host use systemd or OpenRC?
uses_openrc() {
  [ -d /run/openrc ] || command -v rc-service >/dev/null 2>&1
}
# Install a list of packages with the native package manager.
# Missing tools are collected first so the user sees one summary.
install_deps() {
  local wanted=("$@") missing=() tool
  for tool in "${wanted[@]}"; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
  done
  if [ "${#missing[@]}" -eq 0 ]; then
    msg_ok "$(tr_text deps_ok)"
    return 0
  fi
  msg_info "$(tr_text installing_deps) ${missing[*]}"
  case "$SYS_ID" in
    debian|ubuntu|armbian)
      apt-get update -qq 2>/dev/null || true
      DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}" 2>/dev/null || \
        apt-get install -y "${missing[@]}"
      ;;
    centos)
      if command -v dnf >/dev/null 2>&1; then dnf install -y -q "${missing[@]}"; else yum install -y -q "${missing[@]}"; fi
      ;;
    fedora)
      dnf install -y -q "${missing[@]}"
      ;;
    alpine)
      apk add --no-cache "${missing[@]}"
      ;;
    arch)
      pacman -Sy --noconfirm --needed "${missing[@]}"
      ;;
  esac
}
# v1.0.19: qrencode draws the subscription QR code (terminal ANSI
# art + /sub/qr PNG). A fresh server may not have it, and without it
# the QR is silently skipped. Install it on startup when missing so
# the QR shows without a manual install. Best-effort only: never
# abort the script when the install fails (the QR is then skipped
# exactly as before).
ensure_qrencode() {
  command -v qrencode >/dev/null 2>&1 && return 0
  case "${SYS_ID:-}" in
    debian|ubuntu|armbian)
      (apt-get update -qq 2>/dev/null; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq qrencode 2>/dev/null) || true
      ;;
    centos)
      if command -v dnf >/dev/null 2>&1; then (dnf install -y -q qrencode 2>/dev/null) || true; else (yum install -y -q qrencode 2>/dev/null) || true; fi
      ;;
    fedora)
      (dnf install -y -q qrencode 2>/dev/null) || true
      ;;
    alpine)
      (apk add --no-cache qrencode 2>/dev/null) || true
      ;;
    arch)
      (pacman -Sy --noconfirm --needed qrencode 2>/dev/null) || true
      ;;
  esac
  return 0
}
# Ensure jq exists as a standalone binary under $SB_HOME (used by the
# config writers even if the distro jq is old).
ensure_jq() {
  if [ -x "$SB_JQ" ]; then return 0; fi
  if command -v jq >/dev/null 2>&1; then
    mkdir -p "$SB_HOME"
    cp "$(command -v jq)" "$SB_JQ" 2>/dev/null || ln -sf "$(command -v jq)" "$SB_JQ"
    return 0
  fi
  mkdir -p "$SB_HOME"
  local jq_url="https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-${ARCH_JQ}"
  if fetch_file "$jq_url" "$SB_TMP/jq"; then
    chmod +x "$SB_TMP/jq"
    mv "$SB_TMP/jq" "$SB_JQ"
  else
    msg_warn "jq download failed; JSON editing will use the system jq if present."
  fi
}
jq_bin() {
  if [ -x "$SB_JQ" ]; then printf '%s' "$SB_JQ";
  elif command -v jq >/dev/null 2>&1; then command -v jq;
  else printf '%s' "jq"; fi
}

# ---------------------------------------------------------------------------
# 6. Network detection: public IP, country, WARP status
# ---------------------------------------------------------------------------
detect_public_ip() {
  # Sets WAN4 / WAN6 / COUNTRY4 / COUNTRY6 / ASN4 / ASN6 / WARP4 / WARP6.
  # Uses a public IP API; failures are tolerated (fields stay empty).
  local body=""
  body="$(fetch_text "https://ip.cloudflare.now.cc" 2>/dev/null || true)"
  if [ -z "$body" ]; then
    body="$(fetch_text "https://ip.sb" 2>/dev/null || true)"
  fi
  if [ -n "$body" ]; then
    WAN4="$(printf '%s' "$body" | grep -oE '"ip"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | cut -d'"' -f4)"
    # Fallback: the body may be plain text.
    if [ -z "$WAN4" ]; then
      WAN4="$(printf '%s' "$body" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)"
    fi
  fi
  if [ -z "$WAN4" ]; then
    WAN4="$(curl -fsSL --max-time 8 https://api.ipify.org 2>/dev/null || true)"
  fi
  # Some IP APIs answer with an IPv6 address first; keep the fields
  # honest instead of showing an IPv6 address in the IPv4 slot.
  if [ -n "$WAN4" ] && ! is_ipv4 "$WAN4"; then
    if is_ipv6 "$WAN4" && [ -z "$WAN6" ]; then WAN6="$WAN4"; fi
    WAN4=""
  fi
  # v1.0.17: if the first source answered with an IPv6 address, WAN4
  # was just cleared and the api.ipify.org fallback above never ran
  # (WAN4 was non-empty at that point). Retry the IPv4-only API so
  # the IPv4 slot (and the provider name that depends on it) is not
  # left blank on IPv6-preferring networks.
  if [ -z "$WAN4" ]; then
    WAN4="$(curl -fsSL --max-time 8 https://api.ipify.org 2>/dev/null || true)"
    if [ -n "$WAN4" ] && ! is_ipv4 "$WAN4"; then WAN4=""; fi
  fi
  if [ -z "$WAN6" ]; then
    WAN6="$(curl -fsSL --max-time 8 https://api64.ipify.org 2>/dev/null || true)"
    if [ "$WAN6" = "$WAN4" ]; then WAN6=""; fi
  fi
  # WARP detection: Cloudflare trace reports warp=on when traffic goes
  # through WARP.
  local trace=""
  trace="$(curl -fsSL --max-time 8 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null || true)"
  if printf '%s' "$trace" | grep -q "warp=on"; then WARP4="WARP"; fi
  if printf '%s' "$trace" | grep -q "warp=plus"; then WARP4="WARP+"; fi
}
# Which address should node links use by default?
default_server_addr() {
  if [ -n "$WAN4" ]; then printf '%s' "$WAN4";
  elif [ -n "$WAN6" ]; then printf '[%s]' "$WAN6";
  else printf '127.0.0.1'; fi
}
# v1.0.17: VPS provider (ISP) for the public IPv4, shown after
# the IP in the system-info block (e.g. "IPv4: 1.2.3.4 (HostPapa)").
# Fetched from ip-api.com with a 3s timeout and cached under
# SB_HOME keyed by IP, so the menu does not query on every
# display; re-fetch only when the cache is missing or the IP
# changed. The `isp` field is preferred over `org`: for the
# user's IP the org field is a generic "NOC Operator" while isp
# is the recognizable network operator ("HostPapa"); org is the
# fallback when isp is empty. The name comes from the public IP
# database, so it is the network operator / ISP, not the VPS
# reseller brand (no public database returns "Dedirock" for this
# IP). Any failure returns empty — never blocks or breaks the
# menu. The same provider is shown after the IPv6 address too
# (same VPS).
# v1.0.19: map an ip-api.com country code to a Chinese country
# name for the system-info display. Falls back to the English
# country name (2nd arg) and then to the code itself when unmapped.
country_zh() {
  local code="$1" en="$2"
  case "$code" in
    US) printf '美国' ;; CN) printf '中国' ;; HK) printf '中国香港' ;;
    TW) printf '中国台湾' ;; MO) printf '中国澳门' ;;
    JP) printf '日本' ;; KR) printf '韩国' ;; SG) printf '新加坡' ;;
    MY) printf '马来西亚' ;; TH) printf '泰国' ;; VN) printf '越南' ;;
    PH) printf '菲律宾' ;; ID) printf '印度尼西亚' ;; IN) printf '印度' ;;
    PK) printf '巴基斯坦' ;; BD) printf '孟加拉国' ;;
    DE) printf '德国' ;; GB) printf '英国' ;; FR) printf '法国' ;;
    NL) printf '荷兰' ;; IE) printf '爱尔兰' ;; BE) printf '比利时' ;;
    CH) printf '瑞士' ;; AT) printf '奥地利' ;; SE) printf '瑞典' ;;
    NO) printf '挪威' ;; FI) printf '芬兰' ;; DK) printf '丹麦' ;;
    IT) printf '意大利' ;; ES) printf '西班牙' ;; PT) printf '葡萄牙' ;;
    PL) printf '波兰' ;; CZ) printf '捷克' ;; SK) printf '斯洛伐克' ;;
    HU) printf '匈牙利' ;; GR) printf '希腊' ;; RO) printf '罗马尼亚' ;;
    BG) printf '保加利亚' ;; HR) printf '克罗地亚' ;; RS) printf '塞尔维亚' ;;
    UA) printf '乌克兰' ;; RU) printf '俄罗斯' ;; TR) printf '土耳其' ;;
    IL) printf '以色列' ;; AE) printf '阿联酋' ;; SA) printf '沙特阿拉伯' ;;
    QA) printf '卡塔尔' ;; KW) printf '科威特' ;; BH) printf '巴林' ;;
    OM) printf '阿曼' ;; JO) printf '约旦' ;; LB) printf '黎巴嫩' ;;
    IQ) printf '伊拉克' ;; IR) printf '伊朗' ;; YE) printf '也门' ;;
    EG) printf '埃及' ;; ZA) printf '南非' ;; NG) printf '尼日利亚' ;;
    KE) printf '肯尼亚' ;; GH) printf '加纳' ;; MA) printf '摩洛哥' ;;
    DZ) printf '阿尔及利亚' ;; TN) printf '突尼斯' ;;
    CA) printf '加拿大' ;; MX) printf '墨西哥' ;; BR) printf '巴西' ;;
    AR) printf '阿根廷' ;; CL) printf '智利' ;; CO) printf '哥伦比亚' ;;
    PE) printf '秘鲁' ;; VE) printf '委内瑞拉' ;; UY) printf '乌拉圭' ;;
    AU) printf '澳大利亚' ;; NZ) printf '新西兰' ;;
    KZ) printf '哈萨克斯坦' ;; UZ) printf '乌兹别克斯坦' ;;
    GE) printf '格鲁吉亚' ;; AM) printf '亚美尼亚' ;; AZ) printf '阿塞拜疆' ;;
    IS) printf '冰岛' ;; LU) printf '卢森堡' ;; MT) printf '马耳他' ;;
    CY) printf '塞浦路斯' ;; EE) printf '爱沙尼亚' ;; LV) printf '拉脱维亚' ;;
    LT) printf '立陶宛' ;; SI) printf '斯洛文尼亚' ;;
    *) if [ -n "$en" ]; then printf '%s' "$en"; else printf '%s' "$code"; fi ;;
  esac
}
provider_for_ip() {
  local ip="$1" cache="${SB_HOME}/provider_cache" cached_ip="" cached_org="" cached_cc="" cached_en="" isp="" org="" cc="" en="" body=""
  [ -n "$ip" ] || return 0
  if [ -s "$cache" ]; then
    cached_ip="$(sed -n '1p' "$cache" 2>/dev/null || true)"
    cached_org="$(sed -n '2p' "$cache" 2>/dev/null || true)"
    cached_cc="$(sed -n '3p' "$cache" 2>/dev/null || true)"
    cached_en="$(sed -n '4p' "$cache" 2>/dev/null || true)"
    if [ "$cached_ip" = "$ip" ] && [ -n "$cached_org" ] && [ -n "$cached_cc" ]; then
      printf '%s\n%s' "$cached_org" "$(country_zh "$cached_cc" "$cached_en")"
      return 0
    fi
  fi
  # NOTE: ip-api.com free tier is HTTP-only; https returns 403, so
  # the lookup would silently fail and the provider would never
  # show. The data is public IP metadata (the server's own
  # public-IP record), so plain HTTP is fine here.
  body="$(curl -fsSL --max-time 3 "http://ip-api.com/json/${ip}?fields=isp,org,countryCode,country" 2>/dev/null || true)"
  isp="$(printf '%s' "$body" | grep -oE '"isp"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)"
  org="$(printf '%s' "$body" | grep -oE '"org"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)"
  cc="$(printf '%s' "$body" | grep -oE '"countryCode"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)"
  en="$(printf '%s' "$body" | grep -oE '"country"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)"
  # Prefer isp (recognizable network operator); fall back to org.
  if [ -z "$isp" ]; then isp="$org"; fi
  if [ -n "$isp" ]; then
    { printf '%s\n%s\n%s\n%s\n' "$ip" "$isp" "$cc" "$en" > "$cache"; } 2>/dev/null || true
    if [ -n "$cc" ]; then
      printf '%s\n%s' "$isp" "$(country_zh "$cc" "$en")"
    else
      printf '%s' "$isp"
    fi
  fi
}

# ---------------------------------------------------------------------------
# 7. Installation state, service helpers
# ---------------------------------------------------------------------------
refresh_status() {
  # Re-read installed versions and service states into globals.
  if [ -x "$SB_BIN" ]; then
    IS_INSTALLED=1
    SB_VERSION_INSTALLED="$("$SB_BIN" version 2>/dev/null | head -1 | awk '{print $3}')"
    [ -z "$SB_VERSION_INSTALLED" ] && SB_VERSION_INSTALLED="installed"
  else
    IS_INSTALLED=0
    SB_VERSION_INSTALLED=""
  fi
  if command -v cloudflared >/dev/null 2>&1 || [ -x "$SB_ARGO_BIN" ]; then
    ARGO_VERSION_INSTALLED="$(cloudflared --version 2>/dev/null | awk '{print $3}' | head -1)"
    [ -z "$ARGO_VERSION_INSTALLED" ] && ARGO_VERSION_INSTALLED="installed"
  fi
  if command -v nginx >/dev/null 2>&1; then
    NGINX_VERSION_INSTALLED="$(nginx -v 2>&1 | awk -F/ '{print $2}')"
  fi
  SB_RUNNING="not-installed"; ARGO_RUNNING="not-installed"; NGINX_RUNNING="not-installed"
  if [ "$IS_INSTALLED" = "1" ]; then
    if uses_openrc; then
      rc-service sing-box status >/dev/null 2>&1 && SB_RUNNING="running" || SB_RUNNING="stopped"
      rc-service argo status >/dev/null 2>&1 && ARGO_RUNNING="running" || ARGO_RUNNING="stopped"
      rc-service nginx status >/dev/null 2>&1 && NGINX_RUNNING="running" || NGINX_RUNNING="stopped"
    elif command -v systemctl >/dev/null 2>&1; then
      systemctl is-active --quiet sing-box 2>/dev/null && SB_RUNNING="running" || SB_RUNNING="stopped"
      systemctl is-active --quiet argo 2>/dev/null && ARGO_RUNNING="running" || ARGO_RUNNING="stopped"
      systemctl is-active --quiet nginx 2>/dev/null && NGINX_RUNNING="running" || NGINX_RUNNING="stopped"
    fi
  fi
}
# Wrapper so systemd and OpenRC call sites look the same.
svc() {
  # svc <action> <service> ; action = start|stop|restart|enable|disable|reload|status
  local action="$1" svcname="$2"
  if uses_openrc; then
    case "$action" in
      enable)  rc-update add "$svcname" default >/dev/null 2>&1 ;;
      disable) rc-update del "$svcname" default >/dev/null 2>&1 ;;
      reload)  rc-service "$svcname" reload >/dev/null 2>&1 || rc-service "$svcname" restart >/dev/null 2>&1 ;;
      status)  rc-service "$svcname" status >/dev/null 2>&1 ;;
      *)       rc-service "$svcname" "$action" >/dev/null 2>&1 ;;
    esac
  else
    systemctl "$action" "$svcname" >/dev/null 2>&1
  fi
}
svc_is_active() {
  if uses_openrc; then rc-service "$1" status >/dev/null 2>&1;
  else systemctl is-active --quiet "$1" 2>/dev/null; fi
}
# Memory used by a service's main process, best effort.
svc_memory() {
  local name="$1" pid=""
  if uses_openrc; then
    pid="$(cat "/var/run/${name}.pid" 2>/dev/null || true)"
  elif command -v systemctl >/dev/null 2>&1; then
    pid="$(systemctl show -p MainPID "$name" 2>/dev/null | cut -d= -f2)"
  fi
  if [ -n "$pid" ] && [ "$pid" != "0" ] && [ -r "/proc/${pid}/status" ]; then
    local kb
    kb="$(awk '/VmRSS/{print $2}' "/proc/${pid}/status" 2>/dev/null)"
    [ -n "$kb" ] && human_bytes $((kb * 1024))
  fi
}

# ---------------------------------------------------------------------------
# 8. Port assignment and wizard questions
# ---------------------------------------------------------------------------
# Assign consecutive ports starting at $1, one per selected protocol.
# Selected protocols are in SELECTED_IDX (indexes into PROTO_NAMES).
declare -a SELECTED_IDX=()
assign_ports() {
  local start="$1" i idx
  PORT_FOR=()
  for ((i = 0; i < ${#SELECTED_IDX[@]}; i++)); do
    idx="${SELECTED_IDX[$i]}"
    PORT_FOR[$idx]=$((start + i))
  done
}
# Is protocol index $1 selected?
proto_selected() {
  local want="$1" idx
  for idx in "${SELECTED_IDX[@]}"; do [ "$idx" = "$want" ] && return 0; done
  return 1
}
# Is any Cloudflare (CF) protocol selected? PROTO_CF marks 7-10 (0-based).
has_cf_protocol() {
  local idx
  for idx in "${SELECTED_IDX[@]}"; do [ "${PROTO_CF[$idx]:-0}" = "1" ] && return 0; done
  return 1
}
# Parse a protocol answer such as "a", "b c", "bcd", "B, C", "1 2 14".
# Letters: a = all, b..t = protocols 1..19. Numbers 1..19 also work.
# Sets SELECTED_IDX.
# Returns 1 when nothing valid was chosen.
parse_protocol_answer() {
  local raw="$1" token idx
  raw="${raw,,}"
  raw="${raw//,/ }"
  if [[ "$raw" =~ (^|[[:space:]])a([[:space:]]|$) ]]; then
    SELECTED_IDX=($(seq 0 18))
    return 0
  fi
  SELECTED_IDX=()
  for token in $raw; do
    if [[ "$token" =~ ^[0-9]+$ ]] && [ "$token" -ge 1 ] && [ "$token" -le 19 ]; then
      SELECTED_IDX+=($((token - 1))); continue
    fi
    # A token of single letters, e.g. "bcd", is split into letters.
    local i ch
    for ((i = 0; i < ${#token}; i++)); do
      ch="${token:$i:1}"
      case "$ch" in
        [b-t]) SELECTED_IDX+=($(( $(printf '%d' "'$ch") - 98 ))) ;;
      esac
    done
  done
  # De-duplicate, keep the order the user typed.
  local uniq=() seen="" idx
  for idx in "${SELECTED_IDX[@]}"; do
    case " $seen " in *" $idx "*) ;; *) uniq+=("$idx"); seen="$seen $idx";; esac
  done
  SELECTED_IDX=("${uniq[@]}")
  [ "${#SELECTED_IDX[@]}" -gt 0 ]
}
# Print the protocol picker, grouped: top 7, Cloudflare (CF) 8-11,
# other protocols 12-19. Names are full names, never abbreviated.
show_protocol_picker() {
  local i letter line
  printf -v line '  %s' "$(tr_text picker_all)"; c_yellow "$line"
  printf '%s\n' ""
  printf -v line '  %s' "$(tr_text picker_top)"; c_green "$line"
  for ((i = 0; i < 7; i++)); do
    letter="${PROTO_LETTERS[$((i + 1))]}"
    printf -v line '  %s. %s' "$letter" "${PROTO_NAMES[$i]}"; c_yellow "$line"
  done
  printf '%s\n' ""
  printf -v line '  %s' "$(tr_text picker_cf)"; c_green "$line"
  for ((i = 7; i < 11; i++)); do
    letter="${PROTO_LETTERS[$((i + 1))]}"
    printf -v line '  %s. %s' "$letter" "${PROTO_NAMES[$i]}"; c_yellow "$line"
  done
  printf '%s\n' ""
  printf -v line '  %s' "$(tr_text picker_other)"; c_green "$line"
  for ((i = 11; i < 19; i++)); do
    letter="${PROTO_LETTERS[$((i + 1))]}"
    printf -v line '  %s. %s' "$letter" "${PROTO_NAMES[$i]}"; c_yellow "$line"
  done
}
ask_wizard_protocols() {
  if [ -n "$WIZ_PROTOCOLS" ]; then
    parse_protocol_answer "$WIZ_PROTOCOLS" && return 0
    WIZ_PROTOCOLS=""
  fi
  while true; do
    show_protocol_picker
    local ans=""
    ask_prompt "$(tr_text select_protocols)" ans
    ans="${ans:-a}"
    if parse_protocol_answer "$ans"; then reset_bad_input; return 0; fi
    msg_warn "$(tr_text invalid_choice)"; note_bad_input
  done
}
ask_wizard_start_port() {
  local need="${#SELECTED_IDX[@]}"
  if [ -n "$WIZ_START_PORT" ] && is_port_number "$WIZ_START_PORT" \
     && ports_free_range "$WIZ_START_PORT" "$need"; then
    return 0
  fi
  while true; do
    local ans=""
    printf '%s (%s %s-%s, %s %s %s): ' \
      "$(tr_text enter_start_port)" "$(tr_text port_range_hint)" \
      "$PORT_MIN" "$PORT_MAX" "$need" \
      "$([ "$LANG_CODE" = C ] && echo "个连续空闲端口" || echo "consecutive free ports")" \
      "$([ "$LANG_CODE" = C ] && echo "，默认" || echo "default") $DEFAULT_START_PORT"
    ask_line "" ans
    ans="${ans:-$DEFAULT_START_PORT}"
    if ! is_port_number "$ans"; then msg_warn "$(tr_text port_bad)"; note_bad_input; continue; fi
    if ! ports_free_range "$ans" "$need"; then msg_warn "$(tr_text port_in_use)"; note_bad_input; continue; fi
    WIZ_START_PORT="$ans"; reset_bad_input; return 0
  done
}
ask_wizard_server() {
  if [ -n "$WIZ_SERVER_ADDR" ] && is_ip_or_domain "$WIZ_SERVER_ADDR"; then return 0; fi
  local def
  def="$(default_server_addr)"
  while true; do
    local ans=""
    ask_line "$(tr_text enter_server) (default: ${def}):" ans
    ans="${ans:-$def}"
    if is_ip_or_domain "$ans"; then WIZ_SERVER_ADDR="$ans"; reset_bad_input; return 0; fi
    msg_warn "$(tr_text domain_bad)"; note_bad_input
  done
}
ask_wizard_uuid() {
  if [ -n "$WIZ_UUID" ]; then
    is_valid_uuid "$WIZ_UUID" && return 0
    WIZ_UUID=""
  fi
  local def
  def="$(make_uuid)"
  while true; do
    local ans=""
    ask_line "$(tr_text enter_uuid) (default: ${def}):" ans
    ans="${ans:-$def}"
    if is_valid_uuid "$ans"; then WIZ_UUID="$ans"; reset_bad_input; return 0; fi
    msg_warn "$(tr_text uuid_bad)"; note_bad_input
  done
}
# Set WIZ_NODE_NAME from a prompt answer. Empty input (just Enter)
# -> the default name ("<J>"); whitespace-only input (e.g. a single
# space) -> empty (no prefix at all); anything else -> the typed
# name as-is. v1.0.16: a space must NOT fall back to the default.
# v1.0.18: the default is "<J>" (with angle brackets).
apply_node_name_input() {
  local ans="$1" def="${2:-<J>}"
  if [ -z "$ans" ]; then
    WIZ_NODE_NAME="$def"
  elif [ -z "${ans//[[:space:]]/}" ]; then
    WIZ_NODE_NAME=""
  else
    WIZ_NODE_NAME="$ans"
  fi
}
# Combine a node name and a protocol name for display. When the node
# name is empty (or whitespace-only), the result is just the protocol
# name — no leading space. v1.0.16.
display_name_for() {
  local n="$1" p="$2"
  if [ -z "${n//[[:space:]]/}" ]; then printf '%s' "$p"; else printf '%s %s' "$n" "$p"; fi
}
ask_wizard_node_name() {
  if [ -n "$WIZ_NODE_NAME" ]; then return 0; fi
  local def="<J>"
  local ans=""
  ask_line "$(tr_text enter_node_name) (default: ${def}):" ans
  apply_node_name_input "$ans" "$def"
}
ask_wizard_fingerprint() {
  if [ -n "$WIZ_FINGERPRINT" ]; then return 0; fi
  c_green "$(tr_text choose_fingerprint):"
  printf -v line '  1. chrome (default)'; c_yellow "$line"
  printf -v line '  2. firefox'; c_yellow "$line"
  local ans=""
  ask_choice ans
  case "$ans" in
    2) WIZ_FINGERPRINT="firefox" ;;
    *) WIZ_FINGERPRINT="chrome" ;;
  esac
}
# $1 (optional): the current CDN, shown with a marker in the list.
# When given, an empty answer keeps it instead of resetting to the
# default (v1.0.15: in menu 5 the old code cleared WIZ_CDN first, so
# pressing Enter silently switched the CDN to the default).
ask_wizard_cdn() {
  local current="${1:-}"
  # Only needed when a Cloudflare (CF) protocol is selected.
  has_cf_protocol || return 0
  if [ -n "$WIZ_CDN" ]; then return 0; fi
  c_green "$(tr_text enter_cdn):"
  local i line
  for ((i = 0; i < ${#CDN_CANDIDATES[@]}; i++)); do
    line="  $((i + 1)). ${CDN_CANDIDATES[$i]}"
    if [ -n "$current" ] && [ "${CDN_CANDIDATES[$i]}" = "$current" ]; then
      line="$line$(tr_text cdn_current)"
    fi
    c_yellow "$line"
  done
  local ans=""
  ask_choice ans
  if [[ "$ans" =~ ^[0-9]+$ ]] && [ "$ans" -ge 1 ] && [ "$ans" -le "${#CDN_CANDIDATES[@]}" ]; then
    WIZ_CDN="${CDN_CANDIDATES[$((ans - 1))]}"
  elif [ -n "$ans" ]; then
    WIZ_CDN="$ans"
  else
    # Empty answer: keep the current CDN when one was passed in
    # (menu 5); otherwise the install-wizard default.
    if [ -n "$current" ]; then WIZ_CDN="$current"; else WIZ_CDN="$DEFAULT_CDN_HOST"; fi
  fi
}
ask_wizard_hy2() {
  proto_selected 0 || return 0
  # Realm: only ask when not preset.
  if [ -z "$WIZ_HY2_REALM" ]; then
    if ask_yes_no "$(tr_text choose_hy2_realm)" "n"; then WIZ_HY2_REALM="yes"; else WIZ_HY2_REALM="no"; fi
  fi
  # Bandwidth (upload/download, Mbps). Asked once; Enter = 200/1000.
  if [ -z "$WIZ_HY2_UP" ] || [ -z "$WIZ_HY2_DOWN" ]; then
    local bw=""
    ask_line "$(tr_text enter_hy2_bandwidth):" bw
    bw="${bw:-200/1000}"
    if [[ "$bw" =~ ^([0-9]+)/([0-9]+)$ ]]; then
      WIZ_HY2_UP="${BASH_REMATCH[1]}"; WIZ_HY2_DOWN="${BASH_REMATCH[2]}"
    elif [[ "$bw" =~ ^[0-9]+$ ]]; then
      WIZ_HY2_UP="$bw"; WIZ_HY2_DOWN="$bw"
    else
      WIZ_HY2_UP="200"; WIZ_HY2_DOWN="1000"
    fi
  fi
  # Port hopping, one step: the range is asked right here, in the
  # middle of the install wizard. Enter = skip, no port hopping.
  if [ -z "${WIZ_HY2_HOP_SET:-}" ]; then
    c_bold "$(tr_text hop_explain)"
    local ans=""
    while true; do
      ask_line "$(tr_text enter_hop_range):" ans
      if [ -z "$ans" ]; then WIZ_HY2_HOP=""; WIZ_HY2_HOP_SET="1"; break; fi
      ans="${ans//-/:}"
      if [[ "$ans" =~ ^([0-9]+):([0-9]+)$ ]] && [ "${BASH_REMATCH[1]}" -ge "$HOP_MIN" ] \
         && [ "${BASH_REMATCH[2]}" -le "$HOP_MAX" ] && [ "${BASH_REMATCH[1]}" -lt "${BASH_REMATCH[2]}" ]; then
        WIZ_HY2_HOP="$ans"; WIZ_HY2_HOP_SET="1"; break
      fi
      msg_warn "$(tr_text invalid_choice)"; note_bad_input
    done
  fi
}
ask_wizard_argo() {
  # Only relevant when a Cloudflare (CF) protocol is selected
  # (0-based 7-10).
  has_cf_protocol || return 0
  c_bold "$(tr_text argo_guide)"
  printf '%s\n' ""
  # Already answered try/token: do not ask again. A stale "no" from a
  # core-only install is asked again here (fresh install wizard).
  if [ "$WIZ_ARGO" = "try" ] || [ "$WIZ_ARGO" = "token" ]; then return 0; fi
  c_green "$(tr_text choose_argo_type):"
  local line
  printf -v line '  %s' "$(tr_text argo_try)"; c_yellow "$line"
  printf -v line '  %s' "$(tr_text argo_token)"; c_yellow "$line"
  printf -v line '  %s' "$(tr_text argo_none)"; c_yellow "$line"
  local ans=""
  ask_choice ans
  case "$ans" in
    2) WIZ_ARGO="token" ;;
    3) WIZ_ARGO="no" ;;
    *) WIZ_ARGO="try" ;;
  esac
  if [ "$WIZ_ARGO" = "token" ] && [ -z "$WIZ_ARGO_AUTH" ]; then
    ask_line "$(tr_text enter_argo_auth):" WIZ_ARGO_AUTH
  fi
}

# ---------------------------------------------------------------------------
# 9. Configuration files (JSON, built with jq where practical)
# ---------------------------------------------------------------------------
# Write one inbound file per selected protocol into $SB_CONF_DIR.
# Files are named NN_<tag>_inbounds.json so the order is stable.
write_base_config() {
  mkdir -p "$SB_CONF_DIR"
  local api_port
  api_port="$(find_free_port_from 9090)"
  cat > "${SB_CONF_DIR}/00_base.json" <<EOF
{
  "log": { "level": "info", "timestamp": true },
  "dns": {
    "servers": [
      { "tag": "dns-remote", "type": "https", "server": "1.1.1.1" }
    ],
    "final": "dns-remote"
  },
  "ntp": { "enabled": true, "server": "time.apple.com" }
}
EOF
  # Note: the "dns" outbound type was removed in sing-box 1.13, so
  # DNS traffic is handled with a hijack-dns rule action instead.
  cat > "${SB_CONF_DIR}/02_outbounds.json" <<'EOF'
{
  "outbounds": [
    { "type": "direct", "tag": "direct" },
    { "type": "block", "tag": "block" }
  ]
}
EOF
  cat > "${SB_CONF_DIR}/03_route.json" <<'EOF'
{
  "route": {
    "rules": [
      { "protocol": "dns", "action": "hijack-dns" },
      { "ip_is_private": true, "outbound": "direct" }
    ],
    "final": "direct",
    "default_domain_resolver": "dns-remote",
    "auto_detect_interface": true
  }
}
EOF
  cat > "${SB_CONF_DIR}/04_experimental.json" <<EOF
{
  "experimental": {
    "clash_api": { "external_controller": "127.0.0.1:${api_port}", "external_ui": "ui" },
    "cache_file": { "enabled": true }
  }
}
EOF
  printf '%s' "$api_port" > "${SB_HOME}/clash_api_port"
}
# Reality key pair via the sing-box binary itself.
generate_reality_keys() {
  if [ -n "$WIZ_REALITY_PRIV" ]; then
    REALITY_PRIV_KEY="$WIZ_REALITY_PRIV"
  else
    msg_info "$(tr_text generating_keys)"
    local out=""
    out="$("$SB_BIN" generate reality-keypair 2>/dev/null || true)"
    REALITY_PRIV_KEY="$(printf '%s' "$out" | awk '/PrivateKey/{print $2}')"
    REALITY_PUB_KEY="$(printf '%s' "$out" | awk '/PublicKey/{print $2}')"
    if [ -z "$REALITY_PRIV_KEY" ]; then
      # Fallback: random base64 key material; the public key is derived
      # by sing-box on first check, so we store the private key and let
      # export_list derive the public key from the binary output.
      REALITY_PRIV_KEY="$(head -c 32 /dev/urandom | base64 | tr -d '\n' | tr '/+' '_-')"
      REALITY_PUB_KEY=""
    fi
  fi
  if [ -z "$REALITY_PUB_KEY" ] && [ -n "$REALITY_PRIV_KEY" ]; then
    # sing-box can print the public key for a private key via generate.
    REALITY_PUB_KEY="$(printf '%s' "$REALITY_PRIV_KEY" | "$SB_BIN" generate reality-keypair --private-key - 2>/dev/null | awk '/PublicKey/{print $2}')"
  fi
  printf '%s' "$REALITY_PRIV_KEY" > "${SB_HOME}/reality_private.key"
  printf '%s' "$REALITY_PUB_KEY" > "${SB_HOME}/reality_public.key"
}
# One inbound JSON object per protocol, written with jq so quoting is safe.
# Arguments: protocol index, port, uuid, node name.
# Indexes follow the final 19-protocol order (see PROTO_NAMES).
# Replaced protocols: 11 is Shadowsocks 2022 AES-256 (the requested
# Shadowsocks + WebSocket has no transport field in official sing-box),
# 10 is Trojan + HTTP (the requested XHTTP transport does not exist
# in official sing-box; HTTP is the supported equivalent).
# v1.0.20: check whether the TCP brutal kernel module is loaded
# (same logic as the reference implementation). Sets IS_BRUTAL=true
# only when the module is present (lsmod) or can be loaded
# (modprobe); otherwise false.
# The CF inbounds bake ${IS_BRUTAL} into their multiplex block, so
# a machine without the module gets brutal off, exactly like
# the reference script — never assume it is available.
check_brutal() {
  IS_BRUTAL=false && command -v lsmod >/dev/null 2>&1 && lsmod 2>/dev/null | grep -q 'brutal' && IS_BRUTAL=true
  [ "$IS_BRUTAL" = 'false' ] && command -v modprobe >/dev/null 2>&1 && modprobe brutal 2>/dev/null && IS_BRUTAL=true
}
write_inbound() {
  local idx="$1" port="$2" uuid="$3" node="$4"
  local tag="${PROTO_TAGS[$idx]}" file=""
  local jq
  jq="$(jq_bin)"
  # v1.0.20: refresh the brutal flag at every config write, so the
  # CF multiplex blocks always reflect the current kernel state.
  check_brutal
  file="$(printf '%s/01_%s_inbounds.json' "$SB_CONF_DIR" "$tag")"
  local sni="${WIZ_SNI:-$DEFAULT_TLS_HOST}" fp="${WIZ_FINGERPRINT:-$DEFAULT_FINGERPRINT}"
  case "$idx" in
    0) # Hysteria2 (bandwidth from the wizard, default 200/1000 Mbps)
      HY2_SECRET="${HY2_SECRET:-$(make_password 16)}"
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg pass "$HY2_SECRET" \
        --argjson up "${WIZ_HY2_UP:-100}" --argjson down "${WIZ_HY2_DOWN:-100}" \
        --argjson ignore "${WIZ_HY2_IGNORE:-false}" \
        '{inbounds: [{type: "hysteria2", tag: $tag, listen: "::", listen_port: $port,
          users: [{password: $pass}], up_mbps: $up, down_mbps: $down,
          ignore_client_bandwidth: $ignore,
          tls: {enabled: true, alpn: ["h3"],
            certificate_path: "/etc/sing-box/cert.pem", key_path: "/etc/sing-box/key.pem"}}]}' > "$file"
      ;;
    1) # VLESS + Reality (no Vision flow)
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg uuid "$uuid" \
        --arg sni "$sni" --arg fp "$fp" --arg priv "$REALITY_PRIV_KEY" \
        '{inbounds: [{type: "vless", tag: $tag, listen: "::", listen_port: $port,
          users: [{uuid: $uuid}],
          tls: {enabled: true, server_name: $sni,
            reality: {enabled: true, handshake: {server: $sni, server_port: 443},
              private_key: $priv, short_id: [""]},
            alpn: ["h2", "http/1.1"]}}]}' > "$file"
      ;;
    2) # VLESS + Reality (Vision) / XTLS + Reality
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg uuid "$uuid" \
        --arg sni "$sni" --arg fp "$fp" --arg priv "$REALITY_PRIV_KEY" \
        '{inbounds: [{type: "vless", tag: $tag, listen: "::", listen_port: $port,
          users: [{uuid: $uuid, flow: "xtls-rprx-vision"}],
          tls: {enabled: true, server_name: $sni,
            reality: {enabled: true, handshake: {server: $sni, server_port: 443},
              private_key: $priv, short_id: [""]},
            alpn: ["h2", "http/1.1"]}}]}' > "$file"
      ;;
    3) # AnyTLS
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg uuid "$uuid" \
        '{inbounds: [{type: "anytls", tag: $tag, listen: "::", listen_port: $port,
          users: [{name: "user", password: $uuid}],
          tls: {enabled: true, alpn: ["h2", "http/1.1"],
            certificate_path: "/etc/sing-box/cert.pem", key_path: "/etc/sing-box/key.pem"}}]}' > "$file"
      ;;
    4) # TUIC
      TUIC_PASSWORD="${TUIC_PASSWORD:-$(make_password 12)}"
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg uuid "$uuid" --arg pass "$TUIC_PASSWORD" \
        '{inbounds: [{type: "tuic", tag: $tag, listen: "::", listen_port: $port,
          users: [{uuid: $uuid, password: $pass}],
          congestion_control: "bbr",
          tls: {enabled: true, alpn: ["h3"],
            certificate_path: "/etc/sing-box/cert.pem", key_path: "/etc/sing-box/key.pem"}}]}' > "$file"
      ;;
    5) # Trojan
      TROJAN_PASSWORD="${TROJAN_PASSWORD:-$(make_password 16)}"
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg pass "$TROJAN_PASSWORD" \
        '{inbounds: [{type: "trojan", tag: $tag, listen: "::", listen_port: $port,
          users: [{password: $pass}],
          tls: {enabled: true, alpn: ["http/1.1"],
            certificate_path: "/etc/sing-box/cert.pem", key_path: "/etc/sing-box/key.pem"}}]}' > "$file"
      ;;
    6) # Shadowsocks (2022-blake3-aes-128-gcm)
      SS_PASSWORD="${SS_PASSWORD:-$(make_ss_key)}"
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg pass "$SS_PASSWORD" \
        '{inbounds: [{type: "shadowsocks", tag: $tag, listen: "::", listen_port: $port,
          method: "2022-blake3-aes-128-gcm", password: $pass}]}' > "$file"
      ;;
    7) # VLESS + WebSocket + TLS (CF, behind nginx)
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg uuid "$uuid" \
        --argjson brutal_enabled "${IS_BRUTAL:-false}" \
        '{inbounds: [{type: "vless", tag: $tag, listen: "::", listen_port: $port,
          users: [{uuid: $uuid, flow: ""}],
          tls: {enabled: true, min_version: "1.3", max_version: "1.3", alpn: ["http/1.1"],
            certificate_path: "/etc/sing-box/cert.pem", key_path: "/etc/sing-box/key.pem"},
          multiplex: {enabled: true, padding: true, brutal: {enabled: $brutal_enabled, up_mbps: 1000, down_mbps: 1000}},
          transport: {type: "ws", path: "/vless-ws-tls", max_early_data: 2560, early_data_header_name: "Sec-WebSocket-Protocol"}}]}' > "$file"
      ;;
    8) # Trojan + WebSocket (CF, behind nginx)
      TROJAN_PASSWORD="${TROJAN_PASSWORD:-$(make_password 16)}"
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg pass "$TROJAN_PASSWORD" \
        --argjson brutal_enabled "${IS_BRUTAL:-false}" \
        '{inbounds: [{type: "trojan", tag: $tag, listen: "::", listen_port: $port,
          users: [{password: $pass}],
          tls: {enabled: true, min_version: "1.3", max_version: "1.3", alpn: ["http/1.1"],
            certificate_path: "/etc/sing-box/cert.pem", key_path: "/etc/sing-box/key.pem"},
          multiplex: {enabled: true, padding: true, brutal: {enabled: $brutal_enabled, up_mbps: 1000, down_mbps: 1000}},
          transport: {type: "ws", path: "/trojan-ws", max_early_data: 2560, early_data_header_name: "Sec-WebSocket-Protocol"}}]}' > "$file"
      ;;
    9) # VMess + WebSocket + TLS (CF, behind nginx)
      # v1.0.19: no TLS on this inbound — nginx proxies to it over
      # plain HTTP; the client still connects
      # with TLS to the Cloudflare edge, so the links are unchanged.
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg uuid "$uuid" \
        --argjson brutal_enabled "${IS_BRUTAL:-false}" \
        '{inbounds: [{type: "vmess", tag: $tag, listen: "::", listen_port: $port,
          users: [{uuid: $uuid, alterId: 0}],
          multiplex: {enabled: true, padding: true, brutal: {enabled: $brutal_enabled, up_mbps: 1000, down_mbps: 1000}},
          transport: {type: "ws", path: "/vmess-ws-tls", max_early_data: 2560, early_data_header_name: "Sec-WebSocket-Protocol"}}]}' > "$file"
      ;;
    10) # Trojan + HTTP (CF, behind nginx; replacement for Trojan + XHTTP)
      TROJAN_PASSWORD="${TROJAN_PASSWORD:-$(make_password 16)}"
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg pass "$TROJAN_PASSWORD" \
        --argjson brutal_enabled "${IS_BRUTAL:-false}" \
        '{inbounds: [{type: "trojan", tag: $tag, listen: "::", listen_port: $port,
          users: [{password: $pass}],
          tls: {enabled: true, min_version: "1.3", max_version: "1.3", alpn: ["http/1.1"],
            certificate_path: "/etc/sing-box/cert.pem", key_path: "/etc/sing-box/key.pem"},
          multiplex: {enabled: true, padding: true, brutal: {enabled: $brutal_enabled, up_mbps: 1000, down_mbps: 1000}},
          transport: {type: "http", path: "/trojan-http"}}]}' > "$file"
      ;;
    11) # Shadowsocks 2022 AES-256 (replacement for Shadowsocks + WebSocket; direct-only, not CF — v1.0.10)
      SS256_PASSWORD="${SS256_PASSWORD:-$(make_ss_key_256)}"
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg pass "$SS256_PASSWORD" \
        '{inbounds: [{type: "shadowsocks", tag: $tag, listen: "::", listen_port: $port,
          method: "2022-blake3-aes-256-gcm", password: $pass}]}' > "$file"
      ;;
    12) # VLESS + WebSocket + Reality
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg uuid "$uuid" \
        --arg sni "$sni" --arg fp "$fp" --arg priv "$REALITY_PRIV_KEY" \
        '{inbounds: [{type: "vless", tag: $tag, listen: "::", listen_port: $port,
          users: [{uuid: $uuid}],
          tls: {enabled: true, server_name: $sni,
            reality: {enabled: true, handshake: {server: $sni, server_port: 443},
              private_key: $priv, short_id: [""]},
            alpn: ["h2", "http/1.1"]},
          transport: {type: "ws", path: "/vless-ws-reality"}}]}' > "$file"
      ;;
    13) # VLESS + TCP + TLS (Vision)
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg uuid "$uuid" \
        --arg sni "$sni" --arg fp "$fp" \
        '{inbounds: [{type: "vless", tag: $tag, listen: "::", listen_port: $port,
          users: [{uuid: $uuid, flow: "xtls-rprx-vision"}],
          tls: {enabled: true, server_name: $sni, alpn: ["h2", "http/1.1"],
            certificate_path: "/etc/sing-box/cert.pem", key_path: "/etc/sing-box/key.pem"}}]}' > "$file"
      ;;
    14) # Trojan + Reality
      TROJAN_PASSWORD="${TROJAN_PASSWORD:-$(make_password 16)}"
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg pass "$TROJAN_PASSWORD" \
        --arg sni "$sni" --arg fp "$fp" --arg priv "$REALITY_PRIV_KEY" \
        '{inbounds: [{type: "trojan", tag: $tag, listen: "::", listen_port: $port,
          users: [{password: $pass}],
          tls: {enabled: true, server_name: $sni,
            reality: {enabled: true, handshake: {server: $sni, server_port: 443},
              private_key: $priv, short_id: [""]},
            alpn: ["h2", "http/1.1"]}}]}' > "$file"
      ;;
    15) # Shadowsocks 2022 (2022-blake3-aes-128-gcm, own key)
      SS2022_PASSWORD="${SS2022_PASSWORD:-$(make_ss_key)}"
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg pass "$SS2022_PASSWORD" \
        '{inbounds: [{type: "shadowsocks", tag: $tag, listen: "::", listen_port: $port,
          method: "2022-blake3-aes-128-gcm", password: $pass}]}' > "$file"
      ;;
    16) # H2 + Reality
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg uuid "$uuid" \
        --arg sni "$sni" --arg fp "$fp" --arg priv "$REALITY_PRIV_KEY" \
        '{inbounds: [{type: "vless", tag: $tag, listen: "::", listen_port: $port,
          users: [{uuid: $uuid}],
          tls: {enabled: true, server_name: $sni, alpn: ["h2"],
            reality: {enabled: true, handshake: {server: $sni, server_port: 443},
              private_key: $priv, short_id: [""]}},
          transport: {type: "http"}}]}' > "$file"
      ;;
    17) # gRPC + Reality
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg uuid "$uuid" \
        --arg sni "$sni" --arg priv "$REALITY_PRIV_KEY" \
        '{inbounds: [{type: "vless", tag: $tag, listen: "::", listen_port: $port,
          users: [{uuid: $uuid}],
          tls: {enabled: true, server_name: $sni,
            reality: {enabled: true, handshake: {server: $sni, server_port: 443},
              private_key: $priv, short_id: [""]}},
          transport: {type: "grpc", service_name: "grpc"}}]}' > "$file"
      ;;
    18) # AnyTLS + Reality
      "$jq" -n \
        --arg tag "$tag" --argjson port "$port" --arg uuid "$uuid" \
        --arg sni "$sni" --arg priv "$REALITY_PRIV_KEY" \
        '{inbounds: [{type: "anytls", tag: $tag, listen: "::", listen_port: $port,
          users: [{name: "user", password: $uuid}],
          tls: {enabled: true, server_name: $sni,
            reality: {enabled: true, handshake: {server: $sni, server_port: 443},
              private_key: $priv, short_id: [""]},
            alpn: ["h2", "http/1.1"]}}]}' > "$file"
      ;;
  esac
  printf '%s=%s\n' "$tag" "$port" >> "${SB_HOME}/ports.env"
}
# Self-signed certificate for TLS inbounds that need one.
make_self_signed_cert() {
  if [ -s /etc/sing-box/cert.pem ] && [ -s /etc/sing-box/key.pem ]; then return 0; fi
  if ! command -v openssl >/dev/null 2>&1; then
    install_deps openssl
  fi
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout /etc/sing-box/key.pem -out /etc/sing-box/cert.pem \
    -subj "/CN=${WIZ_SNI:-$DEFAULT_TLS_HOST}" >/dev/null 2>&1 || true
}
# Validate the whole configuration directory.
check_config() {
  if [ ! -x "$SB_BIN" ]; then return 1; fi
  "$SB_BIN" check -C "$SB_CONF_DIR" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# 10. Downloading sing-box and cloudflared
# ---------------------------------------------------------------------------
# Ask the GitHub API for the newest sing-box release tag (vX.Y.Z).
latest_sb_tag() {
  local api body tag
  body="$(fetch_text "https://api.github.com/repos/SagerNet/sing-box/releases/latest" || true)"
  tag="$(printf '%s' "$body" | grep -oE '"tag_name"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | cut -d'"' -f4)"
  if [ -n "$tag" ]; then printf '%s' "$tag"; else printf 'v%s' "$FALLBACK_SB_VERSION"; fi
}
install_singbox_binary() {
  msg_info "$(tr_text downloading_sb)"
  local tag version file url
  tag="$(latest_sb_tag)"
  version="${tag#v}"
  file="sing-box-${version}-linux-${ARCH_SB}.tar.gz"
  url="https://github.com/SagerNet/sing-box/releases/download/${tag}/${file}"
  mkdir -p "$SB_TMP" "$SB_HOME"
  if ! fetch_file "$url" "$SB_TMP/$file"; then
    die "$(tr_text download_failed)"
  fi
  tar -xzf "$SB_TMP/$file" -C "$SB_TMP" 2>/dev/null || die "$(tr_text download_failed)"
  local found
  found="$(find "$SB_TMP" -name sing-box -type f | head -1)"
  [ -n "$found" ] || die "$(tr_text download_failed)"
  cp "$found" "$SB_BIN"
  chmod +x "$SB_BIN"
  printf '%s\n' "$version" > "${SB_HOME}/version"
  printf '%s\n' "$tag" > "${SB_HOME}/release_tag"
}
install_cloudflared() {
  if [ -x "$SB_ARGO_BIN" ] || command -v cloudflared >/dev/null 2>&1; then return 0; fi
  local url=""
  case "$ARCH_SB" in
    amd64) url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" ;;
    arm64) url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64" ;;
  esac
  fetch_file "$url" "$SB_TMP/cloudflared" || return 1
  chmod +x "$SB_TMP/cloudflared"
  mv "$SB_TMP/cloudflared" "$SB_ARGO_BIN"
}
# v1.0.3: non-exiting version of install_singbox_binary() for the
# first-run core auto-install. The original helper calls die() (exit 1)
# on any download failure, which would kill the whole script; this
# version reuses latest_sb_tag() and fetch_file() but returns 1 on
# every failure instead, so the caller can stay in the uninstalled
# menu and explain what happened. Only installs the sing-box binary
# itself: no config, no service, no nginx, no protocols.
install_singbox_binary_safe() {
  local tag version file url found
  tag="$(latest_sb_tag)"
  version="${tag#v}"
  file="sing-box-${version}-linux-${ARCH_SB}.tar.gz"
  url="https://github.com/SagerNet/sing-box/releases/download/${tag}/${file}"
  mkdir -p "$SB_TMP" "$SB_HOME" || return 1
  fetch_file "$url" "$SB_TMP/$file" || return 1
  tar -xzf "$SB_TMP/$file" -C "$SB_TMP" 2>/dev/null || return 1
  found="$(find "$SB_TMP" -name sing-box -type f | head -1)"
  [ -n "$found" ] || return 1
  cp "$found" "$SB_BIN" || return 1
  chmod +x "$SB_BIN" || return 1
  "$SB_BIN" version >/dev/null 2>&1 || return 1
  printf '%s\n' "$version" > "${SB_HOME}/version"
  printf '%s\n' "$tag" > "${SB_HOME}/release_tag"
  return 0
}
# v1.0.4: create an empty install state after a core-only
# auto-install. Menu 1 (export_list), menu 5 (change_config_menu)
# and menu 8 (change_protocols_menu) all refuse to run without
# /etc/sing-box/install.env, which save_install_env() only writes
# during a full protocol install. v1.0.3 installed only the binary,
# so those menus still reported "not installed" even though the
# binary was there and the 1-12 menu was showing. This fills
# install.env with defaults and zero protocols (SELECTED_IDX=())
# so the menus open and protocols can be added from menu 8. It
# never overwrites an existing install.env.
# It also writes the protocol-independent base files that adding a
# protocol needs: the base config (write_base_config, no inbounds),
# the self-signed TLS cert, the Reality key pair and the systemd /
# OpenRC service units (written only, never enabled or started).
# Without them, menu 8 would fail writing inbounds (no conf dir)
# and `sing-box check` would fail (no cert / empty Reality private
# key), and menu 2 / menu 8's restart would silently do nothing (no
# unit file). No protocol config is created and no service is started.
ensure_empty_install_env() {
  [ -s "${SB_HOME}/install.env" ] && return 0
  SELECTED_IDX=()
  [ -n "$WIZ_SERVER_ADDR" ] || WIZ_SERVER_ADDR="$(default_server_addr)"
  [ -n "$WIZ_UUID" ] || WIZ_UUID="$(make_uuid)"
  [ -n "$WIZ_NODE_NAME" ] || WIZ_NODE_NAME="<J>"
  [ -n "$WIZ_START_PORT" ] || WIZ_START_PORT="$DEFAULT_START_PORT"
  [ -n "$WIZ_FINGERPRINT" ] || WIZ_FINGERPRINT="$DEFAULT_FINGERPRINT"
  [ -n "$WIZ_SNI" ] || WIZ_SNI="$DEFAULT_TLS_HOST"
  [ -n "$WIZ_CDN" ] || WIZ_CDN="$DEFAULT_CDN_HOST"
  [ -n "$WIZ_SUBSCRIBE" ] || WIZ_SUBSCRIBE="no"
  [ -n "$WIZ_ARGO" ] || WIZ_ARGO="no"
  [ -n "$WIZ_ARGO_AUTH" ] || WIZ_ARGO_AUTH=""
  [ -n "$WIZ_ARGO_DOMAIN" ] || WIZ_ARGO_DOMAIN=""
  [ -n "$WIZ_NGINX_PORT" ] || WIZ_NGINX_PORT="8080"
  [ -n "$WIZ_HY2_HOP" ] || WIZ_HY2_HOP=""
  [ -n "$WIZ_HY2_REALM" ] || WIZ_HY2_REALM="no"
  [ -n "$WIZ_HY2_IGNORE" ] || WIZ_HY2_IGNORE="false"
  [ -n "$WIZ_HY2_UP" ] || WIZ_HY2_UP="200"
  [ -n "$WIZ_HY2_DOWN" ] || WIZ_HY2_DOWN="1000"
  [ -n "$WIZ_BIND_IFACE" ] || WIZ_BIND_IFACE=""
  [ -n "$WIZ_REALITY_PRIV" ] || WIZ_REALITY_PRIV=""
  [ -n "$HY2_SECRET" ] || HY2_SECRET="$(make_password 16)"
  [ -n "$SS_PASSWORD" ] || SS_PASSWORD="$(make_ss_key)"
  [ -n "$SS256_PASSWORD" ] || SS256_PASSWORD="$(make_ss_key_256)"
  [ -n "$SS2022_PASSWORD" ] || SS2022_PASSWORD="$(make_ss_key)"
  [ -n "$TROJAN_PASSWORD" ] || TROJAN_PASSWORD="$(make_password 16)"
  [ -n "$TUIC_PASSWORD" ] || TUIC_PASSWORD="$(make_password 16)"
  save_install_env
  # Base config (no inbounds), TLS cert, Reality keys and service
  # units: the prerequisites for adding a protocol from menu 8.
  # Without the units, menu 2 (toggle) and menu 8's restart after
  # adding a protocol would silently do nothing. Units are written
  # only, never enabled or started here.
  [ -s "${SB_CONF_DIR}/00_base.json" ] || write_base_config
  if uses_openrc; then
    [ -x /etc/init.d/sing-box ] || write_services
  else
    [ -s /etc/systemd/system/sing-box.service ] || write_services
  fi
  make_self_signed_cert
  if [ -z "$REALITY_PRIV_KEY" ] && [ -s "${SB_HOME}/reality_private.key" ]; then
    REALITY_PRIV_KEY="$(cat "${SB_HOME}/reality_private.key")"
  fi
  if [ -z "$REALITY_PRIV_KEY" ]; then
    generate_reality_keys
    WIZ_REALITY_PRIV="$REALITY_PRIV_KEY"
    save_install_env
  elif [ -z "$REALITY_PUB_KEY" ] && [ -s "${SB_HOME}/reality_public.key" ]; then
    REALITY_PUB_KEY="$(cat "${SB_HOME}/reality_public.key")"
    save_install_env
  fi
  return 0
}
# v1.0.3: first-run core auto-install, called from main() only on the
# interactive-menu path (after refresh_status(), before
# create_shortcut() / main_menu()). -h, -K/-L quick install and the
# single-action flags (-s/-a/-t/-d/-u/-n/-v/-b/-r) all exit in
# parse_args() or before this point, so this runs once per menu entry
# and never inside a full install. If the core is missing it installs
# only the sing-box binary plus cloudflared (Argo); it does not
# create any protocol config, does not write config.json, does not
# start any service, and does not install nginx / subscription /
# ArgoX / xray. v1.0.4: whether the binary was just installed or was
# already there, an empty install state is created when install.env
# is missing (ensure_empty_install_env: empty install.env /
# selected.env / ports.env plus the protocol-independent base config,
# TLS cert, Reality keys and service units), so menus 1/5/8 work
# with zero protocols. On success refresh_status() is re-run so
# IS_INSTALLED becomes 1 and main_menu() shows the installed 1-12
# menu with no protocols yet (add them from menu 8). On core failure
# it returns 1 and the uninstalled 1-9 menu is shown instead; a
# cloudflared failure only warns and does not block the menu.
ensure_core_installed() {
  if [ -x "$SB_BIN" ]; then
    ensure_empty_install_env
    return 0
  fi
  msg_info "$(tr_text core_auto_install)"
  if ! install_singbox_binary_safe; then
    msg_err "$(tr_text core_auto_failed)"
    return 1
  fi
  msg_ok "$(tr_text core_auto_ok)"
  if ! install_cloudflared; then
    msg_warn "$(tr_text argo_auto_failed)"
  fi
  ensure_empty_install_env
  refresh_status
  return 0
}
# Download the WARP client helper (wgcf) when WARP is requested.
install_wgcf() {
  if command -v wgcf >/dev/null 2>&1; then return 0; fi
  local url=""
  case "$ARCH_SB" in
    amd64) url="https://github.com/ViRb3/wgcf/releases/latest/download/wgcf_2.2.23_linux_amd64" ;;
    arm64) url="https://github.com/ViRb3/wgcf/releases/latest/download/wgcf_2.2.23_linux_arm64" ;;
  esac
  fetch_file "$url" "$SB_TMP/wgcf" && chmod +x "$SB_TMP/wgcf" && mv "$SB_TMP/wgcf" /usr/local/bin/wgcf
}

# ---------------------------------------------------------------------------
# 11. systemd / OpenRC service files
# ---------------------------------------------------------------------------
write_services() {
  if uses_openrc; then
    cat > /etc/init.d/sing-box <<'EOS'
#!/sbin/openrc-run
name="sing-box"
description="sing-box proxy platform"
command="/etc/sing-box/sing-box"
command_args="run -C /etc/sing-box/conf"
command_background="yes"
pidfile="/var/run/sing-box.pid"
depend() { need net; after firewall; }
EOS
    chmod +x /etc/init.d/sing-box
    cat > /etc/init.d/argo <<'EOS'
#!/sbin/openrc-run
name="argo"
description="Cloudflare Argo tunnel"
command="/usr/local/bin/cloudflared"
command_args="tunnel --edge-ip-version auto --protocol http2 --no-autoupdate run --token $(cat /etc/sing-box/argo_token 2>/dev/null)"
command_background="yes"
output_log="/var/log/argo.log"
error_log="/var/log/argo.log"
pidfile="/var/run/argo.pid"
depend() { need net; after sing-box; }
EOS
    chmod +x /etc/init.d/argo
  else
    mkdir -p /etc/systemd/system
    cat > /etc/systemd/system/sing-box.service <<'EOS'
[Unit]
Description=sing-box proxy platform
Documentation=https://sing-box.sagernet.org/
After=network.target nss-lookup.target
Wants=network.target

[Service]
Type=simple
User=root
ExecStart=/etc/sing-box/sing-box run -C /etc/sing-box/conf
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOS
    cat > /etc/systemd/system/argo.service <<'EOS'
[Unit]
Description=Cloudflare Argo tunnel
After=network.target sing-box.service
Wants=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/argo-daemon
# v1.0.6: log the tunnel output so resolve_try_domain() can find the
# temporary trycloudflare.com domain (before this nothing wrote the log).
StandardOutput=append:/var/log/argo.log
StandardError=append:/var/log/argo.log
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOS
    systemctl daemon-reload 2>/dev/null || true
  fi
}
# The argo daemon wrapper reads the stored token / json at start time,
# so the service file itself never contains a secret.
write_argo_daemon() {
  cat > "$SB_ARGO_DAEMON" <<'EOS'
#!/usr/bin/env bash
# Small launcher for the Argo tunnel. Reads credentials from
# /etc/sing-box/argo_token or /etc/sing-box/argo.json at start time.
set -e
if [ -s /etc/sing-box/argo_token ]; then
  exec /usr/local/bin/cloudflared tunnel --edge-ip-version auto --protocol http2 --no-autoupdate run --token "$(cat /etc/sing-box/argo_token)"
elif [ -s /etc/sing-box/argo.json ]; then
  exec /usr/local/bin/cloudflared tunnel --edge-ip-version auto --protocol http2 --no-autoupdate --config /etc/sing-box/argo.json run
else
  exec /usr/local/bin/cloudflared tunnel --edge-ip-version auto --protocol http2 --no-autoupdate --url "http://127.0.0.1:8080"
fi
EOS
  chmod +x "$SB_ARGO_DAEMON"
}
create_shortcut() {
  # Both `sb` and `cj` open the same menu; `cj` is the shortcut to
  # jump straight to the menu. Both forward their arguments, so
  # `cj -n`, `cj -d`, `cj -s` work exactly like `sb -n`, `sb -d`, `sb -s`.
  #
  # v1.0.2 fix -- two real bugs, not a menu-text issue:
  # 1) v1.0.1 only called this from run_install(), so on a machine
  #    that had never been installed there was no `sb` / `cj` at all
  #    and typing `cj` gave "command not found". main() now calls
  #    this once before entering main_menu(), whether installed or not.
  # 2) The old code did `cp "$0" /etc/sing-box/installer.sh`. With the
  #    one-liner `bash <(wget -qO- URL)` $0 is /dev/fd/63 (a pipe, not
  #    a file), so cp failed and installer.sh was never written, and
  #    even a created `sb` / `cj` would then say "Installer script
  #    not found". So: first try a real file ($0, then
  #    ${BASH_SOURCE[0]}); if the only source is a /dev/fd/* pipe,
  #    try cat from that fd, and if that copy does not verify (in
  #    practice it never does -- see below), fall back to writing
  #    installer.sh as a re-download wrapper (INSTALLER_URL).
  #    /dev/fd is a symlink to /proc/self/fd on Linux, so the fd path
  #    is the same file the shell is already reading.
  local name src="" fd_source="" candidate installer="${SB_HOME}/installer.sh"
  mkdir -p "$SB_HOME" 2>/dev/null || true
  for candidate in "$0" "${BASH_SOURCE[0]:-}"; do
    [ -n "$candidate" ] || continue
    case "$candidate" in /dev/fd/*) continue ;; esac
    if [ -f "$candidate" ]; then src="$candidate"; break; fi
  done
  if [ -z "$src" ]; then
    for candidate in "${BASH_SOURCE[0]:-}" "$0"; do
      [ -n "$candidate" ] || continue
      case "$candidate" in
        /dev/fd/*) if [ -r "$candidate" ]; then fd_source="$candidate"; break; fi ;;
      esac
    done
  fi
  # v1.0.9: copy into a TEMP file and verify it before moving it
  # into place. The old code copied straight onto installer.sh, so
  # a truncated `cat` from /dev/fd/* destroyed a previously good
  # local copy before the verification step could reject it.
  local copied=0 tmp_copy="${installer}.tmp.$$"
  rm -f "$tmp_copy" 2>/dev/null || true
  if [ -n "$src" ]; then
    cp "$src" "$tmp_copy" 2>/dev/null && copied=1 || copied=0
  elif [ -n "$fd_source" ]; then
    cat "$fd_source" > "$tmp_copy" 2>/dev/null && copied=1 || copied=0
  fi
  for name in sb cj; do
    cat > "/usr/local/bin/$name" <<'EOS'
#!/usr/bin/env bash
# Shortcut created by the independent sing-box installer.
SCRIPT="/etc/sing-box/installer.sh"
if [ -s "$SCRIPT" ]; then
  # Mark the run as coming from a shortcut: main() then defaults
  # to Chinese and goes straight to the menu instead of asking for
  # a language again (see main()).
  SB_VIA_SHORTCUT=1 exec bash "$SCRIPT" "$@"
else
  echo "Installer script not found at $SCRIPT" >&2
  exit 1
fi
EOS
    chmod +x "/usr/local/bin/$name" 2>/dev/null || true
  done
  # Verify the copy before claiming success. A missing / truncated /
  # broken installer must not silently break `sb` / `cj` later.
  if [ "$copied" = "1" ] && [ -s "$tmp_copy" ]; then
    local sz=0
    sz="$(wc -c < "$tmp_copy" 2>/dev/null || echo 0)"
    if [ "${sz:-0}" -gt 10240 ] && bash -n "$tmp_copy" 2>/dev/null; then
      mv "$tmp_copy" "$installer" 2>/dev/null || true
      chmod +x "$installer" 2>/dev/null || true
      return 0
    fi
  fi
  rm -f "$tmp_copy" 2>/dev/null || true
  # A usable full copy already exists (e.g. from a local-file
  # install): keep it. A re-download wrapper is strictly worse --
  # it fails whenever the network or the repo is unreachable --
  # so never replace a good local copy with one.
  if [ -s "$installer" ]; then
    local old_sz=0
    old_sz="$(wc -c < "$installer" 2>/dev/null || echo 0)"
    if [ "${old_sz:-0}" -gt 10240 ] && bash -n "$installer" 2>/dev/null; then
      return 0
    fi
  fi
  # Fallback for the one-liner case. `cat` from /dev/fd/* only yields
  # the unread tail of the script (tested: 24 bytes out of a 251KB
  # script when called from main(), because bash has already consumed
  # almost everything by then), so a truncated copy is useless and
  # must NOT be kept. Write installer.sh as a re-download wrapper
  # instead -- the same approach the original script's sb.sh uses:
  # `sb` / `cj` re-fetch the installer from its repo URL every time
  # they run. That is the only way a shortcut can work after a
  # one-liner install, and it is why the repo must be public.
  # Failure here only warns; it never aborts the menu.
  local url="${SB_INSTALLER_URL:-$INSTALLER_URL}"
  cat > "$installer" <<EOF
#!/usr/bin/env bash
# Re-download wrapper created by the independent sing-box installer.
# The installer was run via a one-liner, so there is no local file to
# copy; fetch it again from its repo URL on every run.
# v1.0.9: download to a temp file and verify it FIRST. The old
# version did \`exec bash <(wget -qO- URL)\`, which runs an empty
# script and exits 0 with no message at all when the download fails
# (network blocked, repo private, 404) -- \`cj\` then looked
# completely dead ("no reaction"). A failed download now prints a
# clear error instead of silently doing nothing.
INSTALLER_URL="$url"
_tmp="\$(mktemp)"
_ok=0
if command -v wget >/dev/null 2>&1; then
  wget --no-check-certificate -qO "\$_tmp" "\$INSTALLER_URL" 2>/dev/null && _ok=1 || true
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL -o "\$_tmp" "\$INSTALLER_URL" 2>/dev/null && _ok=1 || true
else
  echo "Cannot download the installer: neither wget nor curl is available." >&2
  exit 1
fi
if [ "\$_ok" != "1" ] || [ ! -s "\$_tmp" ] || ! head -1 "\$_tmp" | grep -q '^#!' || ! bash -n "\$_tmp" 2>/dev/null; then
  echo "下载安装脚本失败：无法从 \$INSTALLER_URL 拉取脚本。" >&2
  echo "请检查：1) 网络是否能访问 raw.githubusercontent.com；2) 仓库 https://github.com/caoj8898-tech/jiaoben 是否公开、main 分支根目录下是否有 sing-box.sh。" >&2
  echo "Failed to download the installer from \$INSTALLER_URL. Check the network and that the repo is public." >&2
  rm -f "\$_tmp" 2>/dev/null || true
  exit 1
fi
exec bash "\$_tmp" "\$@"
EOF
  chmod +x "$installer" 2>/dev/null || true
  if bash -n "$installer" 2>/dev/null; then
    return 0
  fi
  msg_warn "Warning: could not save a working copy of the installer to $installer; 'sb' / 'cj' may not work until you install from a downloaded file."
  return 0
}

# ---------------------------------------------------------------------------
# 12. nginx + subscription (static and dynamic)
# ---------------------------------------------------------------------------
# The subscription is a base64 list of node links, served by nginx.
# Static mode: one file rendered at install time.
# Dynamic mode: nginx renders the list per request Host, so a direct
# node's server field follows the address the client actually used.
# Dynamic mode is implemented with a tiny CGI-style helper served
# through fcgiwrap when available; when fcgiwrap is missing it falls
# back to the static file (documented in README).
write_nginx_conf() {
  local nginx_port="${WIZ_NGINX_PORT:-8080}"
  mkdir -p /etc/nginx/conf.d "${SB_HOME}/subscribe"
  # Store the chosen mode so the manage menu can show it.
  printf '%s\n' "${WIZ_SUBSCRIBE:-no}" > "${SB_HOME}/subscribe/mode"
  printf '%s\n' "$nginx_port" > "${SB_HOME}/subscribe/port"
  if [ -d /etc/nginx/conf.d ]; then
    {
      printf '# Managed by the independent sing-box installer. Do not edit by hand\n'
      printf '# unless you know what you are doing; use `sb -d` to change it.\n'
      # v1.0.13: do NOT put `http2` on the listen sockets. v1.0.9
      # added it so cloudflared could speak HTTP/2 cleartext (h2c)
      # to nginx for gRPC, but `listen ... http2` makes the socket
      # h2c-only: a plain HTTP/1.1 request (the /sub subscription,
      # curl, a client syncing the subscription) gets a response
      # that is not valid HTTP at all — curl reports
      # "Received HTTP/0.9 when not allowed" and the client sees a
      # connection error and pulls no nodes, while the script sees
      # only "port 8080 is listening" and reports no error. The
      # same port must serve HTTP/1.1 (/sub) and proxy WS / HTTP,
      # and cloudflared connects to nginx with
      # `--url http://127.0.0.1:8080` (HTTP/1.1) anyway, so a plain
      # listen is correct.
      # v1.0.17: per-client subscription formats. The `map` picks a
      # format from the client's User-Agent for /sub/auto (adaptive).
      # `map` lives in the http context; this file is included there
      # (Ubuntu/Debian nginx includes conf.d inside `http`), so it
      # is valid here. First regex match wins; default is v2rayn.
      printf 'map $http_user_agent $sb_sub_format {\n'
      printf '    default "v2rayn";\n'
      printf '    "~*clash|mihomo" "clash";\n'
      printf '    "~*sing-box|sfa|sfi|sfm" "sing-box";\n'
      printf '    "~*shadowrocket" "shadowrocket";\n'
      printf '    "~*throne" "throne";\n'
      printf '}\n'
      printf 'server {\n    listen %s;\n    listen [::]:%s;\n    server_name _;\n' "$nginx_port" "$nginx_port"
      printf '    location /sub {\n        alias %s/subscribe/list.txt;\n        default_type text/plain;\n        add_header Content-Disposition '"'"'attachment; filename="sub.txt"'"'"';\n    }\n' "$SB_HOME"
      # v1.0.17: per-client subscription endpoints. These are exact
      # locations (longest match wins over the /sub prefix), so the
      # existing /sub and the CF locations below are untouched.
      # Files are generated by write_perclient_subs() (called from
      # export_list); a missing file answers 404 until export_list
      # runs, same as /sub when list.txt does not exist yet.
      printf '    location = /sub/index {\n        alias %s/subscribe/index.html;\n        default_type text/html;\n    }\n' "$SB_HOME"
      printf '    location = /sub/qr {\n        alias %s/subscribe/qr.png;\n        default_type image/png;\n    }\n' "$SB_HOME"
      printf '    location = /sub/v2rayn {\n        alias %s/subscribe/list.txt;\n        default_type text/plain;\n        add_header Content-Disposition '"'"'attachment; filename="v2rayn.txt"'"'"';\n    }\n' "$SB_HOME"
      printf '    location = /sub/throne {\n        alias %s/subscribe/list.txt;\n        default_type text/plain;\n        add_header Content-Disposition '"'"'attachment; filename="throne.txt"'"'"';\n    }\n' "$SB_HOME"
      printf '    location = /sub/shadowrocket {\n        alias %s/subscribe/shadowrocket.b64;\n        default_type text/plain;\n        add_header Content-Disposition '"'"'attachment; filename="shadowrocket.txt"'"'"';\n    }\n' "$SB_HOME"
      printf '    location = /sub/clash {\n        alias %s/subscribe/clash.yaml;\n        default_type text/yaml;\n        add_header Content-Disposition '"'"'attachment; filename="clash.yaml"'"'"';\n    }\n' "$SB_HOME"
      printf '    location = /sub/clash2 {\n        alias %s/subscribe/clash2.yaml;\n        default_type text/yaml;\n        add_header Content-Disposition '"'"'attachment; filename="clash2.yaml"'"'"';\n    }\n' "$SB_HOME"
      printf '    location = /sub/sing-box {\n        alias %s/subscribe/sing-box.json;\n        default_type application/json;\n        add_header Content-Disposition '"'"'attachment; filename="sing-box.json"'"'"';\n    }\n' "$SB_HOME"
      printf '    location = /sub/auto {\n        rewrite ^ /sub/$sb_sub_format last;\n    }\n'
      # Reverse-proxy locations for the CF inbounds. This is what
      # makes the Cloudflare (CF) protocols work: the CDN / Argo
      # tunnel reaches nginx, and nginx forwards the path to the
      # matching local inbound. Direct protocols do not go through
      # nginx and need no location here.
      # v1.0.9: the WS / HTTP inbounds have TLS enabled
      # (self-signed cert), so nginx must proxy to them over TLS
      # (https:// with verification off); the old plain http://
      # proxy sent a cleartext request to an inbound waiting for a
      # TLS handshake, so every CF node behind nginx timed out.
      # v1.0.19: VMess-WS-TLS is the exception — its inbound has
      # no TLS, so nginx proxies to it over
      # plain http://. The other three CF inbounds keep TLS and
      # get proxy_ssl_protocols TLSv1.3.
      # Shadowsocks 2022 has no transport for nginx to proxy, so it
      # has no location (direct-only).
      # v1.0.14: the HTTP / HTTPUpgrade / gRPC CF protocols are
      # removed (they timed out), so only four locations remain:
      # /vless-ws-tls, /vmess-ws-tls, /trojan-ws and /trojan-http.
      local idx tag path port scheme ssl_lines ws_guard
      for idx in "${SELECTED_IDX[@]}"; do
        tag="${PROTO_TAGS[$idx]}"
        case "$tag" in
          vless-ws-tls) path="/vless-ws-tls" ;;
          vmess-ws-tls) path="/vmess-ws-tls" ;;
          trojan-ws-tls) path="/trojan-ws" ;;
          trojan-http) path="/trojan-http" ;;
          *) path="" ;;
        esac
        [ -n "$path" ] || continue
        port="${PORT_FOR[$idx]:-}"
        [ -n "$port" ] || continue
        if [ "$tag" = "vmess-ws-tls" ]; then
          scheme="http"
          ssl_lines=""
        else
          scheme="https"
          ssl_lines=$'\n        proxy_ssl_verify off;\n        proxy_ssl_protocols TLSv1.3;'
        fi
        # v1.0.20: the reference CF blocks reject non-WebSocket requests
        # with 404. Trojan-HTTP uses plain HTTP transport (no Upgrade
        # header), so it gets no guard.
        ws_guard=""
        if [ "$tag" != "trojan-http" ]; then
          ws_guard=$'\n        if ($http_upgrade != "websocket") {\n            return 404;\n        }'
        fi
        printf "    location %s {%s\\n        proxy_pass %s://127.0.0.1:%s;\\n        proxy_http_version 1.1;\\n        proxy_set_header Upgrade \$http_upgrade;\\n        proxy_set_header Connection \"upgrade\";\\n        proxy_set_header X-Real-IP \$remote_addr;\\n        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\\n        proxy_set_header Host \$host;\\n        proxy_redirect off;%s\\n    }\\n" "$path" "$ws_guard" "$scheme" "$port" "$ssl_lines"
      done
      printf '    location / {\n        return 200 "sing-box subscription server\\n";\n        add_header Content-Type text/plain;\n    }\n}\n'
    } > /etc/nginx/conf.d/sing-box-sub.conf
  fi
}
# Start nginx safely (v1.0.6). User report 2026-11-24: `nginx -t` was
# fine, but `systemctl start nginx` failed with
# "bind() to 0.0.0.0:8080 failed (98: Address already in use)" because
# an old nginx master (pid 79018, not managed by systemd) was already
# listening on 8080 with the OLD config (no /sub). Starting a second
# master can never bind, so the service stays failed and the
# subscription never opens. This function therefore:
#  - runs `nginx -t` first and prints its output when it fails;
#  - if any nginx master is already running, reloads it
#    (`nginx -s reload`) instead of starting a new master, then
#    verifies /sub answers; only if reload fails does it quit
#    the old master and start fresh;
#  - if the port is held by a program that is NOT nginx, refuses to
#    kill it and reports who holds the port;
#  - otherwise enables + starts nginx via systemd and verifies /sub.
# Returns 0 when /sub answers, 1 otherwise. Never kills a
# non-nginx process. Port and path are unchanged (8080, /sub).
start_nginx_safe() {
  local nginx_port="${WIZ_NGINX_PORT:-8080}"
  local t_out="" i=""
  if ! command -v nginx >/dev/null 2>&1; then
    msg_err "$(tr_text sub_auto_failed)"
    return 1
  fi
  # 1. Config check first; print the real error when it fails.
  t_out="$(nginx -t 2>&1 || true)"
  if ! printf '%s' "$t_out" | grep -q "test is successful"; then
    printf '%s\n' "$t_out"
    msg_err "$(tr_text sub_auto_failed)"
    return 1
  fi
  # Helpers: is any nginx process running / kill all nginx masters.
  # pgrep/pkill (procps) are standard on Ubuntu but may be missing on
  # minimal systems, so fall back to ss / pid files.
  _nginx_running() {
    if command -v pgrep >/dev/null 2>&1; then pgrep -x nginx >/dev/null 2>&1;
    elif command -v ss >/dev/null 2>&1; then ss -tlnp 2>/dev/null | grep -qE ":${nginx_port}[[:space:]].*nginx";
    else ps aux 2>/dev/null | grep -q "[n]ginx: master"; fi
  }
  _nginx_kill() {
    local sig="$1" pid=""
    if command -v pkill >/dev/null 2>&1; then pkill "$sig" -x nginx 2>/dev/null || true;
    else
      for pid in $(cat /run/nginx.pid /var/run/nginx.pid 2>/dev/null); do kill "$sig" "$pid" 2>/dev/null || true; done
    fi
  }
  # Helper: does /sub answer with the NEW config? The old config has
  # no /sub location, so /sub falls through to `location /` and
  # answers 200 with the body "sing-box subscription server". The new
  # config answers with the base64 list (200) or 404 when list.txt
  # does not exist yet (export_list writes it afterwards), so 404
  # also counts as "nginx is serving the new config". Anything else
  # (connection refused, old-config body) means it is not.
  # v1.0.13: a curl exit with HTTP code 000 means nginx answered with
  # something that is not valid HTTP at all (e.g. an HTTP/0.9-style
  # reply, which is what an http2-only listen socket sends to a
  # plain HTTP/1.1 request — the v1.0.9 regression). _sub_ok already
  # returns 1 for that case; the failure branch below now also
  # prints the code so it is visible instead of a generic warning.
  _sub_ok() {
    local body code
    body="$(curl -fsS --max-time 3 "http://127.0.0.1:${nginx_port}/sub" 2>/dev/null || true)"
    if [ -n "$body" ] && [ "$body" != "sing-box subscription server" ]; then return 0; fi
    code="$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://127.0.0.1:${nginx_port}/sub" 2>/dev/null || echo 000)"
    [ "$code" = "404" ]
  }
  # Helper: is the subscription port currently listening?
  _port_busy() { ! is_port_free "$nginx_port"; }
  # 2. A nginx master is already running: reload it so it picks up
  # the new config instead of starting a new master that can never
  # bind. This must NOT be limited to "port busy": the 2026-11-24
  # user report was the opposite case, a running master with NO
  # 8080 listener at all (old config, curl 8080 connection
  # refused). With the port free the old code skipped the reload
  # and fell through to `systemctl start`, which is a no-op on an
  # already-active service, so the new config (with /sub) never
  # loaded until the user ran `nginx -s reload` by hand.
  if _nginx_running; then
    nginx -s reload 2>/dev/null || true
    sleep 1
    if _sub_ok; then
      msg_ok "$(tr_text nginx_reloaded)"
      return 0
    fi
    # Reload did not take (stale master, bad pid file, ...): quit the
    # old master gracefully, wait for the port to free, then start
    # fresh below. Kill only nginx processes, never anything else.
    nginx -s quit 2>/dev/null || true
    for i in 1 2 3 4 5; do is_port_free "$nginx_port" && break; sleep 1; done
    if ! is_port_free "$nginx_port" && _nginx_running; then
      _nginx_kill "-TERM"
      for i in 1 2 3 4 5; do is_port_free "$nginx_port" && break; sleep 1; done
    fi
    if ! is_port_free "$nginx_port" && _nginx_running; then
      _nginx_kill "-KILL"
      for i in 1 2 3 4 5; do is_port_free "$nginx_port" && break; sleep 1; done
    fi
  fi
  # 3. Port held by something that is not nginx: do not kill it.
  if _port_busy && ! _nginx_running; then
    if command -v ss >/dev/null 2>&1; then
      ss -tlnp 2>/dev/null | grep -E ":${nginx_port}[[:space:]]" || true
    fi
    msg_err "$(tr_text nginx_port_busy)"
    return 1
  fi
  # 4. No nginx process at all (or the old one is gone): start
  # via systemd.
  svc enable nginx
  svc start nginx
  sleep 2
  if ! svc_is_active nginx; then svc start nginx; sleep 2; fi
  if svc_is_active nginx && _sub_ok; then
    return 0
  fi
  # Last resort: the service is active but /sub still does not
  # answer (e.g. the master started with a stale config). One
  # explicit reload, then check again before giving up.
  if svc_is_active nginx; then
    nginx -s reload 2>/dev/null || true
    sleep 1
    if _sub_ok; then
      msg_ok "$(tr_text nginx_reloaded)"
      return 0
    fi
  fi
  # Failed: print the real diagnostics instead of only a generic
  # "auto-enable failed" warning.
  printf '%s\n' "$t_out"
  # v1.0.13: also print the actual HTTP code from /sub. 000 means
  # nginx answered with something that is not valid HTTP at all
  # (connection failed, or an HTTP/0.9-style reply from a broken
  # listen config), which is exactly the failure a "port is
  # listening" check cannot see.
  local _code=""
  _code="$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "http://127.0.0.1:${nginx_port}/sub" 2>/dev/null || echo 000)"
  printf '  /sub HTTP code: %s\n' "$_code"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl status nginx --no-pager 2>/dev/null | grep -E "Active:|bind\(\)|failed|error" | head -10 || true
  fi
  # v1.0.16: final re-check before warning. The _sub_ok checks
  # above can run during the nginx restart transition and give up
  # too early (the 2026-11-25 false alarm: /sub was already 200 by
  # the time this branch printed its diagnostics). Wait a moment
  # and check once more; only warn if it still fails.
  sleep 2
  if _sub_ok; then
    msg_ok "$(tr_text nginx_reloaded)"
    return 0
  fi
  msg_warn "$(tr_text sub_auto_failed)"
  return 1
}
# Render the dynamic-subscription helper script. It reads the stored
# node list, replaces the direct-node server field with the request
# Host, and prints a base64 subscription. Kept deliberately small.
write_dynamic_render() {
  mkdir -p "${SB_HOME}/subscribe/dynamic"
  cat > "${SB_HOME}/subscribe/dynamic/render.sh" <<'EOS'
#!/usr/bin/env bash
# Dynamic subscription renderer (see README, "Dynamic subscription").
# Input: $HTTP_HOST from the web server. Output: base64 node list.
HOST="${HTTP_HOST:-}"
LIST="/etc/sing-box/subscribe/list_plain.txt"
[ -s "$LIST" ] || exit 0
if [ -n "$HOST" ]; then
  # Only direct nodes follow the Host; WebSocket / Argo nodes keep their
  # configured address, because their server is a CDN or tunnel.
  sed -E "s#@([0-9a-zA-Z.-]+|\[[0-9a-fA-F:]+\]):#@${HOST}:#g" "$LIST" | base64 -w0
else
  base64 -w0 "$LIST"
fi
printf '\n'
EOS
  chmod +x "${SB_HOME}/subscribe/dynamic/render.sh"
  printf 'dynamic\n' > "${SB_HOME}/subscribe/mode"
}
# Cloudflare API: create a tunnel and a DNS record, store the token.
# $1 = api token, $2 = account id, $3 = zone id, $4 = domain.
create_argo_via_api() {
  local token="$1" account="$2" zone="$3" domain="$4"
  local api="https://api.cloudflare.com/client/v4"
  local body resp tunnel_id tunnel_token
  body="$(printf '{"name":"sing-box-%s","config_src":"cloudflare"}' "$(date +%s)")"
  resp="$(curl -fsSL --max-time 20 -X POST "$api/accounts/${account}/cfd_tunnel" \
    -H "Authorization: Bearer ${token}" -H "Content-Type: application/json" \
    -d "$body" 2>/dev/null || true)"
  tunnel_id="$(printf '%s' "$resp" | grep -oE '"id"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | cut -d'"' -f4)"
  tunnel_token="$(printf '%s' "$resp" | grep -oE '"token"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | cut -d'"' -f4)"
  [ -n "$tunnel_id" ] || return 1
  # DNS record pointing at the tunnel.
  curl -fsSL --max-time 20 -X POST "$api/zones/${zone}/dns_records" \
    -H "Authorization: Bearer ${token}" -H "Content-Type: application/json" \
    -d "{\"type\":\"CNAME\",\"name\":\"${domain}\",\"content\":\"${tunnel_id}.cfargotunnel.com\",\"proxied\":true}" >/dev/null 2>&1 || true
  printf '%s' "$tunnel_token" > "${SB_HOME}/argo_token"
  printf '%s' "$domain" > "${SB_HOME}/argo_domain"
  return 0
}
setup_argo() {
  # Called during install when a WebSocket protocol is present and the user
  # chose Argo. Returns 0 when a tunnel is configured.
  [ -n "$WIZ_ARGO" ] && [ "$WIZ_ARGO" != "no" ] || return 1
  install_cloudflared || return 1
  write_argo_daemon
  case "$WIZ_ARGO" in
    token)
      if [ -n "$WIZ_ARGO_AUTH" ]; then
        case "$WIZ_ARGO_AUTH" in
          \{*)
            # Real JSON credentials (a "{" object, containing
            # TunnelSecret): store as-is and let cloudflared use
            # them as a config file.
            printf '%s' "$WIZ_ARGO_AUTH" > "$SB_ARGO_CONF"
            ;;
          *)
            # Anything else is a tunnel token. A Cloudflare tunnel
            # token is a JWT starting with "eyJ"; argo-daemon runs
            # it with `cloudflared tunnel run --token`. (v1.0.16:
            # the old pattern also matched "eyJ*" as JSON and wrote
            # the token to argo.json, where cloudflared failed to
            # parse it as YAML and the service looped on exit 1.)
            printf '%s' "$WIZ_ARGO_AUTH" > "${SB_HOME}/argo_token"
            ;;
        esac
      fi
      ;;
    try|*)
      # Temporary tunnel: cloudflared picks a random trycloudflare.com
      # domain at runtime. The domain is resolved after first start
      # by reading the daemon log.
      rm -f "${SB_HOME}/argo_token" "$SB_ARGO_CONF"
      ;;
  esac
  if [ -n "$WIZ_ARGO_DOMAIN" ]; then
    printf '%s' "$WIZ_ARGO_DOMAIN" > "${SB_HOME}/argo_domain"
  fi
  return 0
}
# After the tunnel starts, find its public domain from the log.
# v1.0.16: the log is chronological, so take the NEWEST domain
# (tail -1), not the oldest (head -1). A restarted tunnel gets a new
# domain and the old one is dead (that is how a stale domain got
# written before). Used by `sb --sync-argo` and the 5-minute timer.
resolve_try_domain() {
  local log="/var/log/argo.log" domain=""
  if [ -s "$log" ]; then
    domain="$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$log" | tail -1 | sed 's#https://##')"
  fi
  # v1.0.6: nothing wrote /var/log/argo.log before (the argo.service
  # unit had no log redirect), so also try the systemd journal.
  if [ -z "$domain" ] && command -v journalctl >/dev/null 2>&1; then
    domain="$(journalctl -u argo --no-pager -n 300 2>/dev/null | grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' | tail -1 | sed 's#https://##')"
  fi
  if [ -n "$domain" ]; then printf '%s' "$domain" > "${SB_HOME}/argo_domain"; printf '%s' "$domain"; fi
}

# v1.0.19: detect the fixed (Token) tunnel hostname from the argo
# log. When cloudflared starts with a token it fetches the tunnel
# config from Cloudflare and logs "Updated to new configuration"
# with the ingress JSON, which carries the public hostname. One
# token = one tunnel = one hostname, so the hostname follows the
# token and must be detected, never hardcoded. Parses the NEWEST
# such line (tail -1) from /var/log/argo.log (falls back to the
# systemd journal). On success writes ${SB_HOME}/argo_domain,
# updates WIZ_ARGO_DOMAIN + install.env, and prints the hostname.
# On failure prints nothing and returns 1; callers must not break
# the setup flow when detection fails.
resolve_fixed_domain() {
  [ "${WIZ_ARGO:-}" = "token" ] || return 1
  local log="/var/log/argo.log" domain="" line=""
  if [ -s "$log" ]; then
    line="$(grep 'Updated to new configuration' "$log" 2>/dev/null | tail -1)"
  fi
  if [ -z "$line" ] && command -v journalctl >/dev/null 2>&1; then
    line="$(journalctl -u argo --no-pager -n 300 2>/dev/null | grep 'Updated to new configuration' | tail -1)"
  fi
  [ -n "$line" ] || return 1
  # The log embeds the ingress JSON with escaped quotes:
  # config="{\"ingress\":[{\"hostname\":\"example.com\", ...}]}"
  domain="$(printf '%s' "$line" | grep -oE '\\"hostname\\":\\"[^\\"]+' | head -1 | sed 's/.*\\"//')"
  if [ -z "$domain" ]; then
    domain="$(printf '%s' "$line" | grep -oE '"hostname":"[^"]+' | head -1 | sed 's/.*:"//')"
  fi
  [ -n "$domain" ] || return 1
  printf '%s' "$domain" > "${SB_HOME}/argo_domain"
  WIZ_ARGO_DOMAIN="$domain"
  if grep -q "^WIZ_ARGO_DOMAIN=" "${SB_HOME}/install.env" 2>/dev/null; then
    sed -i "s|^WIZ_ARGO_DOMAIN='.*'|WIZ_ARGO_DOMAIN='${domain}'|" "${SB_HOME}/install.env"
  else
    printf "WIZ_ARGO_DOMAIN='%s'\n" "$domain" >> "${SB_HOME}/install.env"
  fi
  printf '%s' "$domain"
}

# v1.0.16: `sb --sync-argo` — refresh the try-tunnel domain.
# Reads the NEWEST tunnel domain from the argo log and, if it differs
# from the stored one, updates argo_domain + install.env and
# re-exports the subscription. Token tunnels have a fixed domain, so
# this is a no-op for them; Argo off is a no-op too. Only touches the
# subscription file; no sing-box/nginx restart. Run every 5 minutes
# by the sb-sync-argo timer (see install_argo_sync_timer).
sync_argo_domain() {
  local stored="" newest="" line=""
  load_install_env 2>/dev/null || { msg_info "$(tr_text argo_sync_not_installed)"; return 0; }
  case "${WIZ_ARGO:-no}" in
    token)
      msg_info "$(tr_text argo_sync_fixed)"
      return 0
      ;;
    try) ;;
    *)
      msg_info "$(tr_text argo_sync_off)"
      return 0
      ;;
  esac
  stored="$(cat "${SB_HOME}/argo_domain" 2>/dev/null || true)"
  [ -n "$stored" ] || stored="${WIZ_ARGO_DOMAIN:-}"
  newest="$(resolve_try_domain)"
  if [ -z "$newest" ]; then
    msg_info "$(tr_text argo_sync_no_domain)"
    return 0
  fi
  if [ "$newest" = "$stored" ] && [ "$newest" = "${WIZ_ARGO_DOMAIN:-}" ]; then
    printf -v line "$(tr_text argo_sync_no_change)" "$newest"
    msg_info "$line"
    return 0
  fi
  printf '%s' "$newest" > "${SB_HOME}/argo_domain"
  WIZ_ARGO_DOMAIN="$newest"
  if grep -q "^WIZ_ARGO_DOMAIN=" "${SB_HOME}/install.env" 2>/dev/null; then
    sed -i "s|^WIZ_ARGO_DOMAIN='.*'|WIZ_ARGO_DOMAIN='${newest}'|" "${SB_HOME}/install.env"
  else
    printf "WIZ_ARGO_DOMAIN='%s'\n" "$newest" >> "${SB_HOME}/install.env"
  fi
  export_list >/dev/null
  printf -v line "$(tr_text argo_sync_done)" "$newest"
  msg_ok "$line"
}

# v1.0.16: install + enable the 5-minute Argo sync timer.
# A oneshot service runs `installer.sh --sync-argo`; the timer fires
# every 5 minutes (and 1 minute after boot). systemd only; on
# non-systemd machines, or when the unit dir is not writable, this
# is a silent no-op. Called from run_install (fresh install) and
# show_version / menu 6 (upgrade), so existing installs get it too.
# SB_SYNC_TIMER_DIR overrides the unit dir (tests only).
install_argo_sync_timer() {
  local unit_dir="${SB_SYNC_TIMER_DIR:-/etc/systemd/system}"
  command -v systemctl >/dev/null 2>&1 || return 0
  [ -d "$unit_dir" ] || return 0
  [ -w "$unit_dir" ] || return 0
  cat > "$unit_dir/sb-sync-argo.service" <<'EOS'
[Unit]
Description=Sync Argo tunnel domain and re-export subscription
After=network.target

[Service]
Type=oneshot
ExecStart=/etc/sing-box/installer.sh --sync-argo
EOS
  cat > "$unit_dir/sb-sync-argo.timer" <<'EOS'
[Unit]
Description=Sync Argo tunnel domain every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOS
  systemctl daemon-reload 2>/dev/null || true
  systemctl enable --now sb-sync-argo.timer 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# 13. Firewall and port hopping
# ---------------------------------------------------------------------------
firewall_backend() {
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qi active; then printf 'ufw';
  elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state 2>/dev/null | grep -q running; then printf 'firewalld';
  elif command -v nft >/dev/null 2>&1; then printf 'nft';
  elif command -v iptables >/dev/null 2>&1; then printf 'iptables';
  else printf 'none'; fi
}
allow_port() {
  local port="$1" proto="${2:-tcp}" backend
  backend="$(firewall_backend)"
  mkdir -p "$SB_FIREWALL_DIR"
  grep -qx "$port/$proto" "$SB_FIREWALL_PORTS_FILE" 2>/dev/null || printf '%s/%s\n' "$port" "$proto" >> "$SB_FIREWALL_PORTS_FILE"
  case "$backend" in
    ufw) ufw allow "${port}/${proto}" >/dev/null 2>&1 || true ;;
    firewalld) firewall-cmd --permanent --add-port="${port}/${proto}" >/dev/null 2>&1; firewall-cmd --reload >/dev/null 2>&1 || true ;;
    nft) nft add rule inet filter input "${proto}" dport "$port" accept 2>/dev/null || true ;;
    iptables) iptables -C INPUT -p "$proto" --dport "$port" -j ACCEPT 2>/dev/null || iptables -I INPUT -p "$proto" --dport "$port" -j ACCEPT 2>/dev/null || true ;;
  esac
}
remove_port_rule() {
  local port="$1" proto="${2:-tcp}" backend
  backend="$(firewall_backend)"
  sed -i "\#^${port}/${proto}\$#d" "$SB_FIREWALL_PORTS_FILE" 2>/dev/null || true
  case "$backend" in
    ufw) ufw delete allow "${port}/${proto}" >/dev/null 2>&1 || true ;;
    firewalld) firewall-cmd --permanent --remove-port="${port}/${proto}" >/dev/null 2>&1; firewall-cmd --reload >/dev/null 2>&1 || true ;;
    nft) nft delete rule inet filter input "${proto}" dport "$port" accept 2>/dev/null || true ;;
    iptables) iptables -D INPUT -p "$proto" --dport "$port" -j ACCEPT 2>/dev/null || true ;;
  esac
}
sync_firewall() {
  msg_info "$(tr_text firewall_sync)"
  local idx port
  for idx in "${SELECTED_IDX[@]}"; do
    port="${PORT_FOR[$idx]:-}"
    [ -n "$port" ] || continue
    allow_port "$port" tcp
    # UDP inbounds need UDP too: Hysteria2 (0, QUIC/UDP), TUIC (4,
    # QUIC/UDP), Shadowsocks (6, UDP relay), Shadowsocks 2022
    # AES-256 (11, UDP relay, direct-only) and Shadowsocks 2022
    # (15, UDP relay). The CF group (7-10) and all VLESS/VMess/
    # Trojan/H2/gRPC/AnyTLS inbounds are TCP-only.
    case "$idx" in 0|4|6|11|15) allow_port "$port" udp ;; esac
  done
  if [ -n "$WIZ_NGINX_PORT" ]; then allow_port "$WIZ_NGINX_PORT" tcp; fi
}
# Hysteria2 port hopping: forward a range of UDP ports to the real port
# with nftables (preferred) or iptables NAT.
add_hopping_nat() {
  local real_port="$1" range="$2"  # range like 20000:21000
  local start="${range%%:*}" end="${range##*:}"
  if command -v nft >/dev/null 2>&1; then
    nft add table inet sb-hop 2>/dev/null || true
    nft add chain inet sb-hop prerouting '{ type nat hook prerouting priority -100; }' 2>/dev/null || true
    nft add rule inet sb-hop prerouting udp dport "${start}-${end}" redirect to ":${real_port}" 2>/dev/null || true
  elif command -v iptables >/dev/null 2>&1; then
    iptables -t nat -A PREROUTING -p udp --dport "${start}:${end}" -j REDIRECT --to-port "$real_port" 2>/dev/null || true
  fi
  printf '%s %s\n' "$real_port" "$range" > "${SB_HOME}/hopping.env"
}
remove_hopping_nat() {
  [ -s "${SB_HOME}/hopping.env" ] || return 0
  local real_port range
  read -r real_port range < "${SB_HOME}/hopping.env"
  local start="${range%%:*}" end="${range##*:}"
  if command -v nft >/dev/null 2>&1; then
    nft delete table inet sb-hop 2>/dev/null || true
  elif command -v iptables >/dev/null 2>&1; then
    iptables -t nat -D PREROUTING -p udp --dport "${start}:${end}" -j REDIRECT --to-port "$real_port" 2>/dev/null || true
  fi
  rm -f "${SB_HOME}/hopping.env"
}
# ---------------------------------------------------------------------------
# 14. WARP (Cloudflare WARP as an outbound)
# ---------------------------------------------------------------------------
register_warp_account() {
  # Registers a free WARP account via the public API and writes the
  # credentials into $SB_HOME/warp.env. Returns 1 on failure.
  msg_info "$(tr_text warp_register)"
  install_wgcf || return 1
  local priv pub
  priv="$(wgcf generate 2>/dev/null | grep -i private | awk '{print $NF}')"
  # wgcf register writes wgcf-account.toml in the current directory.
  (cd "$SB_TMP" && wgcf register --accept-tos >/dev/null 2>&1 || true)
  if [ -s "$SB_TMP/wgcf-account.toml" ]; then
    cp "$SB_TMP/wgcf-account.toml" "${SB_HOME}/warp-account.toml"
    return 0
  fi
  # API fallback: create an account directly.
  local key resp
  key="$(head -c 32 /dev/urandom | base64 | tr -d '\n')"
  resp="$(curl -fsSL --max-time 20 -X POST https://api.cloudflareclient.com/v0a4005/reg \
    -H "Content-Type: application/json" \
    -d "{\"install_id\":\"$(make_uuid)\",\"tos\":\"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",\"model\":\"PC\",\"fcm_token\":\"\",\"key\":\"${key}\",\"locale\":\"en-US\"}" 2>/dev/null || true)"
  if printf '%s' "$resp" | grep -q '"id"'; then
    printf '%s' "$resp" > "${SB_HOME}/warp-account.json"
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# 15. Node links, subscription file and client configs
# ---------------------------------------------------------------------------
# URL-encode a node name for use in a link fragment.
url_encode_name() {
  local s="$1" out="" i c
  for ((i = 0; i < ${#s}; i++)); do
    c="${s:$i:1}"
    case "$c" in
      [A-Za-z0-9._~-]) out+="$c" ;;
      ' ') out+="%20" ;;
      *) out+=$(printf '%%%02X' "'$c") ;;
    esac
  done
  printf '%s' "$out"
}
# Build one link per selected protocol and append it to the plain list.
# Globals read: WIZ_SERVER_ADDR, WIZ_UUID, WIZ_NODE_NAME, PORT_FOR,
# REALITY_PUB_KEY, HY2_SECRET, SS_PASSWORD, SS256_PASSWORD,
# SS2022_PASSWORD, TROJAN_PASSWORD, TUIC_PASSWORD, WIZ_CDN,
# WIZ_ARGO_DOMAIN.
# The "#" suffix uses the protocol name (PROTO_LINK_NAMES),
# with WS as the user-required abbreviation for WebSocket (v1.0.5).
# The query parameters (type=ws, type=http,
# flow, security, ...) are the standard client-link format.
# v1.0.16: true when every selected protocol is a CF protocol
# (PROTO_CF=1: VLESS-WS-TLS, Trojan-WS, VMess-WS-TLS, Trojan-HTTP).
# An empty selection is false. Used by the CF auto-switch: when all
# selected protocols are CF, CF links use the tunnel domain as the
# server instead of the preferred domain.
cf_only_selected() {
  local idx
  if [ "${#SELECTED_IDX[@]}" -eq 0 ] && [ -s "${SB_HOME}/selected.env" ]; then
    # shellcheck disable=SC1091
    . "${SB_HOME}/selected.env"
  fi
  [ "${#SELECTED_IDX[@]}" -gt 0 ] || return 1
  for idx in "${SELECTED_IDX[@]}"; do
    [ "${PROTO_CF[$idx]:-0}" = "1" ] || return 1
  done
  return 0
}
build_link_for() {
  local idx="$1" port="$2" server="$3" name="$4" enc="" suffix=""
  # v1.0.16: a whitespace-only node name means "no prefix" — treat
  # it as empty so link names have no leading space (a stored/CLI
  # space must not leak one in either).
  if [ -z "${name//[[:space:]]/}" ]; then name=""; fi
  enc="$(url_encode_name "$name")"
  suffix="$(url_encode_name "${PROTO_LINK_NAMES[$idx]}")"
  # The "#" fragment: "<name>%20<protocol>" normally, just
  # "<protocol>" when the name is empty. Build it once and use it
  # in every branch below (pname is the same name for VMess "ps").
  local frag="" pname=""
  if [ -n "$name" ]; then frag="${enc}%20${suffix}"; pname="${name} ${PROTO_LINK_NAMES[$idx]}"; else frag="$suffix"; pname="${PROTO_LINK_NAMES[$idx]}"; fi
  local sni="${WIZ_SNI:-$DEFAULT_TLS_HOST}"
  local fp="${WIZ_FINGERPRINT:-$DEFAULT_FINGERPRINT}"
  local cdn="${WIZ_CDN:-$server}"
  # v1.0.6: when an Argo tunnel is up, CF protocols are reached
  # through the tunnel domain, not the CDN preferred domain. The
  # tunnel only serves 443, so CF links use the tunnel domain on
  # 443 (query params / paths are unchanged). Without Argo, CF
  # links keep using the CDN domain and the local port as before.
  local cf_host="$cdn" cf_port="$port"
  if [ -n "${WIZ_ARGO_DOMAIN:-}" ] && { [ "${WIZ_ARGO:-no}" = "try" ] || [ "${WIZ_ARGO:-no}" = "token" ]; }; then
    cf_port="443"
    # v1.0.16 CF auto-switch: when every selected protocol is a CF
    # protocol, CF links use the tunnel domain itself as the server
    # (the user asked for the tunnel address); otherwise they keep
    # the preferred domain as the server. SNI/Host stays the tunnel
    # domain in both cases (see cf_sni below).
    if cf_only_selected; then cf_host="$WIZ_ARGO_DOMAIN"; fi
  fi
  # CF SNI fix: when the link goes through the Argo tunnel, the TLS SNI
  # must be the tunnel domain itself. Cloudflare edge rejects a handshake
  # whose SNI (addons.mozilla.org) matches no cert/tunnel it hosts
  # (SSL alert 40), so every CF node timed out.
  local cf_sni="$sni"
  if [ -n "${WIZ_ARGO_DOMAIN:-}" ] && { [ "${WIZ_ARGO:-no}" = "try" ] || [ "${WIZ_ARGO:-no}" = "token" ]; }; then
    cf_sni="$WIZ_ARGO_DOMAIN"
  fi
  case "$idx" in
    0) printf 'hysteria2://%s@%s:%s?insecure=1&sni=%s#%s\n' \
        "$HY2_SECRET" "$server" "$port" "$sni" "$frag" ;;
    1) printf 'vless://%s@%s:%s?encryption=none&security=reality&sni=%s&fp=%s&pbk=%s&sid=&type=tcp#%s\n' \
        "$WIZ_UUID" "$server" "$port" "$sni" "$fp" "$REALITY_PUB_KEY" "$frag" ;;
    2) printf 'vless://%s@%s:%s?encryption=none&flow=xtls-rprx-vision&security=reality&sni=%s&fp=%s&pbk=%s&sid=&type=tcp#%s\n' \
        "$WIZ_UUID" "$server" "$port" "$sni" "$fp" "$REALITY_PUB_KEY" "$frag" ;;
    3) printf 'anytls://%s@%s:%s?insecure=1&sni=%s#%s\n' \
        "$WIZ_UUID" "$server" "$port" "$sni" "$frag" ;;
    4) printf 'tuic://%s:%s@%s:%s?congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#%s\n' \
        "$WIZ_UUID" "$TUIC_PASSWORD" "$server" "$port" "$frag" ;;
    5) printf 'trojan://%s@%s:%s?security=tls&sni=%s&allowInsecure=1#%s\n' \
        "$TROJAN_PASSWORD" "$server" "$port" "$sni" "$frag" ;;
    6) printf 'ss://%s@%s:%s#%s\n' \
        "$(printf '2022-blake3-aes-128-gcm:%s' "$SS_PASSWORD" | base64 -w0)" "$server" "$port" "$frag" ;;
    7) printf 'vless://%s@%s:%s?encryption=none&security=tls&sni=%s&type=ws&host=%s&path=/vless-ws-tls#%s\n' \
        "$WIZ_UUID" "$cf_host" "$cf_port" "$cf_sni" "$cf_sni" "$frag" ;;
    8) printf 'trojan://%s@%s:%s?security=tls&sni=%s&type=ws&host=%s&path=/trojan-ws#%s\n' \
        "$TROJAN_PASSWORD" "$cf_host" "$cf_port" "$cf_sni" "$cf_sni" "$frag" ;;
    9) printf 'vmess://%s\n' \
        "$(printf '{"v":"2","ps":"%s","add":"%s","port":"%s","id":"%s","aid":"0","scy":"auto","net":"ws","type":"none","host":"%s","path":"/vmess-ws-tls","tls":"tls"}' \
          "$pname" "$cf_host" "$cf_port" "$WIZ_UUID" "$cf_sni" | base64 -w0)" ;;
    10) printf 'trojan://%s@%s:%s?security=tls&sni=%s&type=http&host=%s&path=/trojan-http#%s\n' \
        "$TROJAN_PASSWORD" "$cf_host" "$cf_port" "$cf_sni" "$cf_sni" "$frag" ;;
    11) printf 'ss://%s@%s:%s#%s\n' \
        "$(printf '2022-blake3-aes-256-gcm:%s' "$SS256_PASSWORD" | base64 -w0)" "$server" "$port" "$frag" ;;
    # NOTE (v1.0.9, v1.0.10): Shadowsocks 2022 AES-256 is
    # direct-only. Shadowsocks has no WS / HTTP / gRPC transport,
    # so neither nginx nor an Argo tunnel can proxy it: there is
    # nothing for nginx to reverse-proxy and nothing for
    # Cloudflare to route. Its inbound listens on "::" and the
    # link must use the server IP and its own local port. Using
    # $cf_port here was a bug: with Argo on, cf_port is 443 while
    # the inbound listens on $port, so the node could never connect.
    # v1.0.10 dropped the "(CF)" from its name and moved it after
    # the CF group (now no. 12).
    12) printf 'vless://%s@%s:%s?encryption=none&security=reality&sni=%s&fp=%s&pbk=%s&type=ws&host=%s&path=/vless-ws-reality#%s\n' \
        "$WIZ_UUID" "$server" "$port" "$sni" "$fp" "$REALITY_PUB_KEY" "$server" "$frag" ;;
    13) printf 'vless://%s@%s:%s?encryption=none&flow=xtls-rprx-vision&security=tls&sni=%s&allowInsecure=1#%s\n' \
        "$WIZ_UUID" "$server" "$port" "$sni" "$frag" ;;
    14) printf 'trojan://%s@%s:%s?security=reality&sni=%s&fp=%s&pbk=%s&type=tcp#%s\n' \
        "$TROJAN_PASSWORD" "$server" "$port" "$sni" "$fp" "$REALITY_PUB_KEY" "$frag" ;;
    15) printf 'ss://%s@%s:%s#%s\n' \
        "$(printf '2022-blake3-aes-128-gcm:%s' "$SS2022_PASSWORD" | base64 -w0)" "$server" "$port" "$frag" ;;
    16) printf 'vless://%s@%s:%s?encryption=none&security=reality&sni=%s&fp=%s&pbk=%s&type=http#%s\n' \
        "$WIZ_UUID" "$server" "$port" "$sni" "$fp" "$REALITY_PUB_KEY" "$frag" ;;
    17) printf 'vless://%s@%s:%s?encryption=none&security=reality&sni=%s&fp=%s&pbk=%s&type=grpc&serviceName=grpc#%s\n' \
        "$WIZ_UUID" "$server" "$port" "$sni" "$fp" "$REALITY_PUB_KEY" "$frag" ;;
    18) printf 'anytls://%s@%s:%s?security=reality&sni=%s&fp=%s&pbk=%s#%s\n' \
        "$WIZ_UUID" "$server" "$port" "$sni" "$fp" "$REALITY_PUB_KEY" "$frag" ;;
  esac
}
# Per-node links grouped by client (v1.0.18). v1.0.17 only listed
# per-client SUBSCRIPTION URLs; the per-node links themselves were
# never grouped by client. For each installed node, show the link
# in each client's format, grouped by client:
#   V2rayN       — the standard link (same as the main list)
#   ShadowRocket — the base64 link (WS nodes carry ShadowRocket's
#                  native WS parameters; the rest are standard)
#   Clash        — the Mihomo YAML proxy entry for that node
# Called inside export_list's display block, so its output goes
# into $SB_LIST_FILE (display only — never into list.txt /
# list_plain.txt, which are the subscription data). Links are
# green+bold (standing rule); groups are separated by several
# blank lines so the links are not crowded together.
print_pernode_client_links() {
  local server="$1" name="$2"
  local idx port
  local sel=()
  [ -s "${SB_HOME}/selected.env" ] && . "${SB_HOME}/selected.env"
  sel=("${SELECTED_IDX[@]}")
  [ "${#sel[@]}" -eq 0 ] && return 0
  c_bold 'Per-node links by client:'
  printf '\n\n\n'
  c_bold '  V2rayN:'
  for idx in "${sel[@]}"; do
    port="$(grep "^${PROTO_TAGS[$idx]}=" "${SB_HOME}/ports.env" 2>/dev/null | cut -d= -f2)"
    [ -n "$port" ] || continue
    c_green "$(build_link_for "$idx" "$port" "$server" "$name")"
  done
  printf '\n\n\n'
  c_bold '  ShadowRocket:'
  for idx in "${sel[@]}"; do
    port="$(grep "^${PROTO_TAGS[$idx]}=" "${SB_HOME}/ports.env" 2>/dev/null | cut -d= -f2)"
    [ -n "$port" ] || continue
    c_green "$(shadowrocket_link_for "$idx" "$port" "$server" "$name")"
  done
  printf '\n\n\n'
  c_bold '  Clash:'
  for idx in "${sel[@]}"; do
    port="$(grep "^${PROTO_TAGS[$idx]}=" "${SB_HOME}/ports.env" 2>/dev/null | cut -d= -f2)"
    [ -n "$port" ] || continue
    c_green "$(clash_proxy_for "$idx" "$port" "$server" "$name")"
  done
}
# Regenerate the node list, subscription file and Clash config from the
# stored wizard answers in $SB_HOME/install.env.
export_list() {
  local mode="${1:-}"
  [ -s "${SB_HOME}/install.env" ] || { msg_err "$(tr_text not_installed)"; return 1; }
  # shellcheck disable=SC1091
  . "${SB_HOME}/install.env"
  mkdir -p "${SB_HOME}/subscribe"
  : > "${SB_HOME}/subscribe/list_plain.txt"
  : > "$SB_LIST_FILE"
  local idx port server name
  server="$WIZ_SERVER_ADDR"
  name="$WIZ_NODE_NAME"
  # Load the selected indexes back from install.env.
  local saved_idx=()
  # shellcheck disable=SC1091
  [ -s "${SB_HOME}/selected.env" ] && . "${SB_HOME}/selected.env"
  saved_idx=("${SELECTED_IDX[@]}")
  for idx in "${saved_idx[@]}"; do
    port="$(grep "^${PROTO_TAGS[$idx]}=" "${SB_HOME}/ports.env" 2>/dev/null | cut -d= -f2)"
    [ -n "$port" ] || continue
    build_link_for "$idx" "$port" "$server" "$name" >> "${SB_HOME}/subscribe/list_plain.txt"
  done
  base64 -w0 "${SB_HOME}/subscribe/list_plain.txt" > "${SB_HOME}/subscribe/list.txt"
  # Human-readable list file (display only — `cat`ed to the
  # terminal; the subscription data files stay plain). Every link
  # is green+bold (standing rule), and link groups are separated
  # by several blank lines so they are not crowded together.
  {
    if [ -n "$name" ]; then printf 'sing-box nodes -- %s\n' "$name"; else printf 'sing-box nodes\n'; fi
    printf 'Server: %s\n\n' "$server"
    # Standard node links, green+bold. Read them from
    # list_plain.txt (the subscription data stays plain).
    local _link=""
    while IFS= read -r _link || [ -n "$_link" ]; do
      [ -n "$_link" ] && c_green "$_link"
    done < "${SB_HOME}/subscribe/list_plain.txt"
    # Per-node links grouped by client (v1.0.18).
    printf '\n\n\n'
    print_pernode_client_links "$server" "$name"
    printf '\n\n\n'
    c_green "Subscription: http://${server}:${WIZ_NGINX_PORT:-8080}/sub"
    printf '\n\n\n'
    c_bold 'Per-client subscriptions:'
    c_green "  Index:         http://${server}:${WIZ_NGINX_PORT:-8080}/sub/index"
    printf '\n\n\n'
    c_green "  V2rayN:        http://${server}:${WIZ_NGINX_PORT:-8080}/sub/v2rayn"
    printf '\n\n\n'
    c_green "  ShadowRocket:  http://${server}:${WIZ_NGINX_PORT:-8080}/sub/shadowrocket"
    printf '\n\n\n'
    c_green "  Clash:         http://${server}:${WIZ_NGINX_PORT:-8080}/sub/clash"
    printf '\n\n\n'
    c_green "  Clash 2:       http://${server}:${WIZ_NGINX_PORT:-8080}/sub/clash2"
    printf '\n\n\n'
    c_green "  sing-box:      http://${server}:${WIZ_NGINX_PORT:-8080}/sub/sing-box"
    printf '\n\n\n'
    c_green "  Throne:        http://${server}:${WIZ_NGINX_PORT:-8080}/sub/throne"
    printf '\n\n\n'
    c_green "  QR:            http://${server}:${WIZ_NGINX_PORT:-8080}/sub/qr"
    printf '\n\n\n'
    c_green "  Auto:          http://${server}:${WIZ_NGINX_PORT:-8080}/sub/auto"
  } > "$SB_LIST_FILE"
  # Clash YAML (subset: proxies + groups).
  write_clash_yaml
  # v1.0.17: per-client subscription files (Clash 2, sing-box
  # JSON, ShadowRocket, Index page, QR). Generated here so every
  # node-list refresh regenerates them.
  write_perclient_subs
  if [ "$mode" = "install" ]; then
    cat "$SB_LIST_FILE"
  else
    cat "$SB_LIST_FILE"
    # v1.0.4: a core-only machine has zero protocols, so the list is
    # header-only. Say so plainly instead of showing an empty list.
    if [ "${#saved_idx[@]}" -eq 0 ]; then
      printf '\n'; c_bold "$(tr_text no_protocols_yet)"
    elif ! svc_is_active nginx; then
      # v1.0.5: the subscription link printed above is served by
      # nginx; if nginx is stopped the link does not open. Say so
      # instead of leaving a dead link with no explanation.
      printf '\n'; c_bold "$(tr_text sub_not_running)"
    elif command -v qrencode >/dev/null 2>&1; then
      printf '\n'; c_bold 'Subscription QR:'
      qrencode -t ANSIUTF8 "http://${server}:${WIZ_NGINX_PORT:-8080}/sub" 2>/dev/null || true
    fi
  fi
  # v1.0.16: show the run counter at the end of the node list too
  # (same right-aligned line as the main menu). Do NOT increment
  # here — the count only grows on main-menu display
  # (bump_run_count). Create the file with 1 if missing so the
  # very first install shows "累计运行 1 次"; skip silently if it
  # cannot be created.
  local rc_file="${SB_HOME}/run_count" rc_val=""
  if [ -s "$rc_file" ]; then
    rc_val="$(cat "$rc_file" 2>/dev/null || true)"
    [[ "$rc_val" =~ ^[0-9]+$ ]] || rc_val=""
  fi
  if [ -z "$rc_val" ]; then
    if printf '1\n' > "$rc_file" 2>/dev/null; then rc_val="1"; fi
  fi
  if [ -n "$rc_val" ]; then
    RUN_COUNT="$rc_val"
    print_run_count
  fi
}
# One Clash proxy entry per installed protocol, expanded (not
# commented out). Names are "<node name> <full protocol name>".
clash_proxy_for() {
  local idx="$1" port="$2" server="$3" name="$4"
  local sni="${WIZ_SNI:-$DEFAULT_TLS_HOST}" fp="${WIZ_FINGERPRINT:-$DEFAULT_FINGERPRINT}"
  local cdn="${WIZ_CDN:-$server}" pname="$(display_name_for "$name" "${PROTO_NAMES[$idx]}")"
  # v1.0.6: same Argo matching as build_link_for (see above).
  local cf_host="$cdn" cf_port="$port"
  if [ -n "${WIZ_ARGO_DOMAIN:-}" ] && { [ "${WIZ_ARGO:-no}" = "try" ] || [ "${WIZ_ARGO:-no}" = "token" ]; }; then
    cf_port="443"
    # v1.0.16 CF auto-switch: same as build_link_for — when every
    # selected protocol is CF, use the tunnel domain as the server.
    if cf_only_selected; then cf_host="$WIZ_ARGO_DOMAIN"; fi
  fi
  # CF SNI fix: when the link goes through the Argo tunnel, the TLS SNI
  # must be the tunnel domain itself. Cloudflare edge rejects a handshake
  # whose SNI (addons.mozilla.org) matches no cert/tunnel it hosts
  # (SSL alert 40), so every CF node timed out.
  local cf_sni="$sni"
  if [ -n "${WIZ_ARGO_DOMAIN:-}" ] && { [ "${WIZ_ARGO:-no}" = "try" ] || [ "${WIZ_ARGO:-no}" = "token" ]; }; then
    cf_sni="$WIZ_ARGO_DOMAIN"
  fi
  case "$idx" in
    0) printf '  - {name: "%s", type: hysteria2, server: %s, port: %s, password: "%s", sni: %s, skip-cert-verify: true}\n' "$pname" "$server" "$port" "$HY2_SECRET" "$sni" ;;
    1) printf '  - {name: "%s", type: vless, server: %s, port: %s, uuid: %s, tls: true, servername: %s, reality-opts: {public-key: "%s", short-id: ""}, client-fingerprint: %s}\n' "$pname" "$server" "$port" "$WIZ_UUID" "$sni" "$REALITY_PUB_KEY" "$fp" ;;
    2) printf '  - {name: "%s", type: vless, server: %s, port: %s, uuid: %s, flow: xtls-rprx-vision, tls: true, servername: %s, reality-opts: {public-key: "%s", short-id: ""}, client-fingerprint: %s}\n' "$pname" "$server" "$port" "$WIZ_UUID" "$sni" "$REALITY_PUB_KEY" "$fp" ;;
    3) printf '  - {name: "%s", type: anytls, server: %s, port: %s, password: "%s", sni: %s, skip-cert-verify: true}\n' "$pname" "$server" "$port" "$WIZ_UUID" "$sni" ;;
    4) printf '  - {name: "%s", type: tuic, server: %s, port: %s, uuid: %s, password: "%s", alpn: [h3], skip-cert-verify: true}\n' "$pname" "$server" "$port" "$WIZ_UUID" "$TUIC_PASSWORD" ;;
    5) printf '  - {name: "%s", type: trojan, server: %s, port: %s, password: "%s", sni: %s, skip-cert-verify: true}\n' "$pname" "$server" "$port" "$TROJAN_PASSWORD" "$sni" ;;
    6) printf '  - {name: "%s", type: ss, server: %s, port: %s, cipher: 2022-blake3-aes-128-gcm, password: "%s"}\n' "$pname" "$server" "$port" "$SS_PASSWORD" ;;
    7) printf '  - {name: "%s", type: vless, server: %s, port: %s, uuid: %s, tls: true, servername: %s, network: ws, ws-opts: {path: /vless-ws-tls, headers: {Host: %s}}}\n' "$pname" "$cf_host" "$cf_port" "$WIZ_UUID" "$cf_sni" "$cf_sni" ;;
    8) printf '  - {name: "%s", type: trojan, server: %s, port: %s, password: "%s", sni: %s, network: ws, ws-opts: {path: /trojan-ws, headers: {Host: %s}}}\n' "$pname" "$cf_host" "$cf_port" "$TROJAN_PASSWORD" "$cf_sni" "$cf_sni" ;;
    9) printf '  - {name: "%s", type: vmess, server: %s, port: %s, uuid: %s, alterId: 0, cipher: auto, tls: true, servername: %s, network: ws, ws-opts: {path: /vmess-ws-tls, headers: {Host: %s}}}\n' "$pname" "$cf_host" "$cf_port" "$WIZ_UUID" "$cf_sni" "$cf_sni" ;;
    10) printf '  - {name: "%s", type: trojan, server: %s, port: %s, password: "%s", sni: %s, network: http, http-opts: {path: [/trojan-http], headers: {Host: [%s]}}}\n' "$pname" "$cf_host" "$cf_port" "$TROJAN_PASSWORD" "$cf_sni" "$cf_sni" ;;
    11) printf '  - {name: "%s", type: ss, server: %s, port: %s, cipher: 2022-blake3-aes-256-gcm, password: "%s"}\n' "$pname" "$server" "$port" "$SS256_PASSWORD" ;;
    # NOTE (v1.0.9, v1.0.10): Shadowsocks has no transport for
    # nginx / Argo to proxy, so this entry is direct-only (see
    # build_link_for); v1.0.10 dropped the "(CF)" from its name.
    12) printf '  - {name: "%s", type: vless, server: %s, port: %s, uuid: %s, tls: true, servername: %s, reality-opts: {public-key: "%s", short-id: ""}, client-fingerprint: %s, network: ws, ws-opts: {path: /vless-ws-reality, headers: {Host: %s}}}\n' "$pname" "$server" "$port" "$WIZ_UUID" "$sni" "$REALITY_PUB_KEY" "$fp" "$server" ;;
    13) printf '  - {name: "%s", type: vless, server: %s, port: %s, uuid: %s, flow: xtls-rprx-vision, tls: true, servername: %s, skip-cert-verify: true}\n' "$pname" "$server" "$port" "$WIZ_UUID" "$sni" ;;
    14) printf '  - {name: "%s", type: trojan, server: %s, port: %s, password: "%s", tls: true, servername: %s, reality-opts: {public-key: "%s", short-id: ""}, client-fingerprint: %s}\n' "$pname" "$server" "$port" "$TROJAN_PASSWORD" "$sni" "$REALITY_PUB_KEY" "$fp" ;;
    15) printf '  - {name: "%s", type: ss, server: %s, port: %s, cipher: 2022-blake3-aes-128-gcm, password: "%s"}\n' "$pname" "$server" "$port" "$SS2022_PASSWORD" ;;
    16) printf '  - {name: "%s", type: vless, server: %s, port: %s, uuid: %s, tls: true, servername: %s, reality-opts: {public-key: "%s", short-id: ""}, client-fingerprint: %s, network: http}\n' "$pname" "$server" "$port" "$WIZ_UUID" "$sni" "$REALITY_PUB_KEY" "$fp" ;;
    17) printf '  - {name: "%s", type: vless, server: %s, port: %s, uuid: %s, tls: true, servername: %s, reality-opts: {public-key: "%s", short-id: ""}, client-fingerprint: %s, network: grpc, grpc-opts: {grpc-service-name: grpc}}\n' "$pname" "$server" "$port" "$WIZ_UUID" "$sni" "$REALITY_PUB_KEY" "$fp" ;;
    18) printf '  - {name: "%s", type: anytls, server: %s, port: %s, password: "%s", sni: %s, reality-opts: {public-key: "%s", short-id: ""}}\n' "$pname" "$server" "$port" "$WIZ_UUID" "$sni" "$REALITY_PUB_KEY" ;;
  esac
}
write_clash_yaml() {
  local out="${SB_HOME}/subscribe/clash.yaml"
  local server="$WIZ_SERVER_ADDR" name="$WIZ_NODE_NAME"
  {
    printf 'port: 7890\nsocks-port: 7891\nallow-lan: false\nmode: rule\nlog-level: info\n'
    printf 'external-controller: 127.0.0.1:9090\n'
    printf 'proxies:\n'
    local idx port
    [ -s "${SB_HOME}/selected.env" ] && . "${SB_HOME}/selected.env"
    for idx in "${SELECTED_IDX[@]}"; do
      port="$(grep "^${PROTO_TAGS[$idx]}=" "${SB_HOME}/ports.env" 2>/dev/null | cut -d= -f2)"
      [ -n "$port" ] || continue
      clash_proxy_for "$idx" "$port" "$server" "$name"
    done
    printf 'proxy-groups:\n  - name: PROXY\n    type: select\n    proxies:\n'
    for idx in "${SELECTED_IDX[@]}"; do
      printf '      - "%s"\n' "$(display_name_for "$name" "${PROTO_NAMES[$idx]}")"
    done
    printf '      - DIRECT\n'
    printf 'rules:\n  - MATCH,PROXY\n'
  } > "$out"
}
# ---------------------------------------------------------------------------
# 15b. Per-client subscriptions (v1.0.17)
# ---------------------------------------------------------------------------
# Per-client subscription endpoints under the existing subscription
# server (port WIZ_NGINX_PORT, default 8080), alongside the
# existing /sub (unchanged):
#   /sub/index        Index page (all clients + QR)
#   /sub/qr           QR code image of the /sub subscription URL
#   /sub/v2rayn       V2rayN / V2rayNG (standard base64 links)
#   /sub/throne       Throne (standard base64 links)
#   /sub/shadowrocket ShadowRocket (base64 links; VLESS-WS and
#                     Trojan-WS carry ShadowRocket's native WS
#                     parameters, the rest are standard links)
#   /sub/clash        Clash / Mihomo YAML (clash.yaml)
#   /sub/clash2       Clash YAML variant 2 (auto group + TUN + DNS)
#   /sub/sing-box     sing-box client JSON (SFI / SFA / SFM)
#   /sub/auto         Adaptive: the format is picked from the
#                     client's User-Agent (nginx map, see
#                     write_nginx_conf).
# Additive only: these generators read the same install.env /
# selected.env / ports.env as export_list and reuse
# build_link_for / clash_proxy_for. They never change the
# existing /sub, list.txt or clash.yaml output.
# JSON string escaping (for sing-box.json tags and names).
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}
# One ShadowRocket-style link for a protocol. VLESS-WS-TLS and
# Trojan-WS get ShadowRocket's native WS parameters (obfs /
# obfsParam / peer / tls + early-data ed=2560, matching the
# server's max_early_data 2560) on top of the standard link
# parameters; every other protocol uses the standard link from
# build_link_for (ShadowRocket already imports those).
shadowrocket_link_for() {
  local idx="$1" port="$2" server="$3" name="$4"
  local sni="${WIZ_SNI:-$DEFAULT_TLS_HOST}"
  local cdn="${WIZ_CDN:-$server}"
  local cf_host="$cdn" cf_port="$port"
  if [ -n "${WIZ_ARGO_DOMAIN:-}" ] && { [ "${WIZ_ARGO:-no}" = "try" ] || [ "${WIZ_ARGO:-no}" = "token" ]; }; then
    cf_port="443"
    if cf_only_selected; then cf_host="$WIZ_ARGO_DOMAIN"; fi
  fi
  local cf_sni="$sni"
  if [ -n "${WIZ_ARGO_DOMAIN:-}" ] && { [ "${WIZ_ARGO:-no}" = "try" ] || [ "${WIZ_ARGO:-no}" = "token" ]; }; then
    cf_sni="$WIZ_ARGO_DOMAIN"
  fi
  if [ -z "${name//[[:space:]]/}" ]; then name=""; fi
  local enc="" suffix="" frag="" pname=""
  enc="$(url_encode_name "$name")"
  suffix="$(url_encode_name "${PROTO_LINK_NAMES[$idx]}")"
  if [ -n "$name" ]; then frag="${enc}%20${suffix}"; pname="${name} ${PROTO_LINK_NAMES[$idx]}"; else frag="$suffix"; pname="${PROTO_LINK_NAMES[$idx]}"; fi
  local remarks="$(url_encode_name "$pname")"
  case "$idx" in
    7) printf 'vless://%s@%s:%s?encryption=none&security=tls&sni=%s&type=ws&host=%s&path=/vless-ws-tls?ed=2560&remarks=%s&obfs=websocket&obfsParam=%s&tls=1&peer=%s#%s\n' \
        "$WIZ_UUID" "$cf_host" "$cf_port" "$cf_sni" "$cf_sni" "$remarks" "$cf_sni" "$cf_sni" "$frag" ;;
    8) printf 'trojan://%s@%s:%s?security=tls&sni=%s&type=ws&host=%s&path=/trojan-ws?ed=2560&remarks=%s&obfs=websocket&obfsParam=%s&tls=1&peer=%s#%s\n' \
        "$TROJAN_PASSWORD" "$cf_host" "$cf_port" "$cf_sni" "$cf_sni" "$remarks" "$cf_sni" "$cf_sni" "$frag" ;;
    *) build_link_for "$idx" "$port" "$server" "$name" ;;
  esac
}
# One sing-box client outbound (JSON, single line) for a protocol.
# Mirrors build_link_for / clash_proxy_for: same server / port /
# SNI / Reality keys / CF auto-switch, so the sing-box JSON
# subscription connects to the same inbounds. Names are the
# display names (display_name_for), JSON-escaped.
singbox_outbound_for() {
  local idx="$1" port="$2" server="$3" name="$4"
  local sni="${WIZ_SNI:-$DEFAULT_TLS_HOST}" fp="${WIZ_FINGERPRINT:-$DEFAULT_FINGERPRINT}"
  local cdn="${WIZ_CDN:-$server}" pname="$(display_name_for "$name" "${PROTO_NAMES[$idx]}")"
  local jname="$(json_escape "$pname")"
  local cf_host="$cdn" cf_port="$port"
  if [ -n "${WIZ_ARGO_DOMAIN:-}" ] && { [ "${WIZ_ARGO:-no}" = "try" ] || [ "${WIZ_ARGO:-no}" = "token" ]; }; then
    cf_port="443"
    if cf_only_selected; then cf_host="$WIZ_ARGO_DOMAIN"; fi
  fi
  local cf_sni="$sni"
  if [ -n "${WIZ_ARGO_DOMAIN:-}" ] && { [ "${WIZ_ARGO:-no}" = "try" ] || [ "${WIZ_ARGO:-no}" = "token" ]; }; then
    cf_sni="$WIZ_ARGO_DOMAIN"
  fi
  local juuid="$(json_escape "$WIZ_UUID")"
  local jpub="$(json_escape "$REALITY_PUB_KEY")"
  local jsni="$(json_escape "$sni")"
  local jfp="$(json_escape "$fp")"
  local jcfhost="$(json_escape "$cf_host")"
  local jcfsni="$(json_escape "$cf_sni")"
  local jserver="$(json_escape "$server")"
  local jhy2="$(json_escape "$HY2_SECRET")"
  local jtrojan="$(json_escape "$TROJAN_PASSWORD")"
  local jtuic="$(json_escape "$TUIC_PASSWORD")"
  local jss="$(json_escape "$SS_PASSWORD")"
  local jss256="$(json_escape "$SS256_PASSWORD")"
  local jss2022="$(json_escape "$SS2022_PASSWORD")"
  local jreality="\"tls\":{\"enabled\":true,\"server_name\":\"$jsni\",\"utls\":{\"enabled\":true,\"fingerprint\":\"$jfp\"},\"reality\":{\"enabled\":true,\"public_key\":\"$jpub\",\"short_id\":\"\"}}"
  case "$idx" in
    0) printf '{"type":"hysteria2","tag":"%s","server":"%s","server_port":%s,"password":"%s","up_mbps":%s,"down_mbps":%s,"tls":{"enabled":true,"server_name":"%s","insecure":true,"alpn":["h3"]}}' \
        "$jname" "$jserver" "$port" "$jhy2" "${WIZ_HY2_UP:-200}" "${WIZ_HY2_DOWN:-1000}" "$jsni" ;;
    1) printf '{"type":"vless","tag":"%s","server":"%s","server_port":%s,"uuid":"%s",%s}' \
        "$jname" "$jserver" "$port" "$juuid" "$jreality" ;;
    2) printf '{"type":"vless","tag":"%s","server":"%s","server_port":%s,"uuid":"%s","flow":"xtls-rprx-vision",%s}' \
        "$jname" "$jserver" "$port" "$juuid" "$jreality" ;;
    3) printf '{"type":"anytls","tag":"%s","server":"%s","server_port":%s,"password":"%s","tls":{"enabled":true,"server_name":"%s","insecure":true}}' \
        "$jname" "$jserver" "$port" "$juuid" "$jsni" ;;
    4) printf '{"type":"tuic","tag":"%s","server":"%s","server_port":%s,"uuid":"%s","password":"%s","congestion_control":"bbr","udp_relay_mode":"native","tls":{"enabled":true,"server_name":"%s","alpn":["h3"],"insecure":true}}' \
        "$jname" "$jserver" "$port" "$juuid" "$jtuic" "$jsni" ;;
    5) printf '{"type":"trojan","tag":"%s","server":"%s","server_port":%s,"password":"%s","tls":{"enabled":true,"server_name":"%s","insecure":true}}' \
        "$jname" "$jserver" "$port" "$jtrojan" "$jsni" ;;
    6) printf '{"type":"shadowsocks","tag":"%s","server":"%s","server_port":%s,"method":"2022-blake3-aes-128-gcm","password":"%s"}' \
        "$jname" "$jserver" "$port" "$jss" ;;
    7) printf '{"type":"vless","tag":"%s","server":"%s","server_port":%s,"uuid":"%s","tls":{"enabled":true,"server_name":"%s"},"transport":{"type":"ws","path":"/vless-ws-tls","headers":{"Host":"%s"},"max_early_data":2560,"early_data_header_name":"Sec-WebSocket-Protocol"}}' \
        "$jname" "$jcfhost" "$cf_port" "$juuid" "$jcfsni" "$jcfsni" ;;
    8) printf '{"type":"trojan","tag":"%s","server":"%s","server_port":%s,"password":"%s","tls":{"enabled":true,"server_name":"%s"},"transport":{"type":"ws","path":"/trojan-ws","headers":{"Host":"%s"},"max_early_data":2560,"early_data_header_name":"Sec-WebSocket-Protocol"}}' \
        "$jname" "$jcfhost" "$cf_port" "$jtrojan" "$jcfsni" "$jcfsni" ;;
    9) printf '{"type":"vmess","tag":"%s","server":"%s","server_port":%s,"uuid":"%s","security":"auto","alter_id":0,"tls":{"enabled":true,"server_name":"%s"},"transport":{"type":"ws","path":"/vmess-ws-tls","headers":{"Host":"%s"},"max_early_data":2560,"early_data_header_name":"Sec-WebSocket-Protocol"}}' \
        "$jname" "$jcfhost" "$cf_port" "$juuid" "$jcfsni" "$jcfsni" ;;
    10) printf '{"type":"trojan","tag":"%s","server":"%s","server_port":%s,"password":"%s","tls":{"enabled":true,"server_name":"%s"},"transport":{"type":"http","host":"%s","path":"/trojan-http"}}' \
        "$jname" "$jcfhost" "$cf_port" "$jtrojan" "$jcfsni" "$jcfsni" ;;
    11) printf '{"type":"shadowsocks","tag":"%s","server":"%s","server_port":%s,"method":"2022-blake3-aes-256-gcm","password":"%s"}' \
        "$jname" "$jserver" "$port" "$jss256" ;;
    12) printf '{"type":"vless","tag":"%s","server":"%s","server_port":%s,"uuid":"%s",%s,"transport":{"type":"ws","path":"/vless-ws-reality","headers":{"Host":"%s"}}}' \
        "$jname" "$jserver" "$port" "$juuid" "$jreality" "$jserver" ;;
    13) printf '{"type":"vless","tag":"%s","server":"%s","server_port":%s,"uuid":"%s","flow":"xtls-rprx-vision","tls":{"enabled":true,"server_name":"%s","insecure":true}}' \
        "$jname" "$jserver" "$port" "$juuid" "$jsni" ;;
    14) printf '{"type":"trojan","tag":"%s","server":"%s","server_port":%s,"password":"%s",%s}' \
        "$jname" "$jserver" "$port" "$jtrojan" "$jreality" ;;
    15) printf '{"type":"shadowsocks","tag":"%s","server":"%s","server_port":%s,"method":"2022-blake3-aes-128-gcm","password":"%s"}' \
        "$jname" "$jserver" "$port" "$jss2022" ;;
    16) printf '{"type":"vless","tag":"%s","server":"%s","server_port":%s,"uuid":"%s",%s,"transport":{"type":"http","host":"%s"}}' \
        "$jname" "$jserver" "$port" "$juuid" "$jreality" "$jsni" ;;
    17) printf '{"type":"vless","tag":"%s","server":"%s","server_port":%s,"uuid":"%s",%s,"transport":{"type":"grpc","service_name":"grpc"}}' \
        "$jname" "$jserver" "$port" "$juuid" "$jreality" ;;
    18) printf '{"type":"anytls","tag":"%s","server":"%s","server_port":%s,"password":"%s",%s}' \
        "$jname" "$jserver" "$port" "$juuid" "$jreality" ;;
  esac
}
# Full sing-box client config (SFI / SFA / SFM) for the selected
# protocols: TUN + mixed inbounds, one outbound per protocol, a
# `proxy` selector, direct / block / dns outbounds and routing.
# Written to ${SB_HOME}/subscribe/sing-box.json and served at
# /sub/sing-box. Validated with `sing-box check` in tests.
write_singbox_json() {
  local out="${SB_HOME}/subscribe/sing-box.json"
  local server="$WIZ_SERVER_ADDR" name="$WIZ_NODE_NAME"
  {
    printf '{\n  "log": {"level": "info", "timestamp": true},\n'
    printf '  "dns": {\n    "servers": [\n      {"tag": "google", "type": "tls", "server": "8.8.8.8"},\n      {"tag": "local", "type": "udp", "server": "223.5.5.5", "detour": "direct"}\n    ],\n    "rules": [{"server": "local", "domain_suffix": [".cn"]}],\n    "final": "google",\n    "strategy": "ipv4_only"\n  },\n'
    printf '  "inbounds": [\n    {"type": "tun", "tag": "tun-in", "interface_name": "tun0", "address": ["172.19.0.1/30"], "auto_route": true, "strict_route": false, "stack": "mixed"},\n    {"type": "mixed", "tag": "mixed-in", "listen": "127.0.0.1", "listen_port": 2080}\n  ],\n'
    printf '  "outbounds": [\n'
    local tags="" first="" idx port
    [ -s "${SB_HOME}/selected.env" ] && . "${SB_HOME}/selected.env"
    for idx in "${SELECTED_IDX[@]}"; do
      local t
      t="$(display_name_for "$name" "${PROTO_NAMES[$idx]}")"
      tags+="\"$(json_escape "$t")\", "
      [ -z "$first" ] && first="$t"
    done
    tags="${tags%, }"
    if [ -n "$first" ]; then
      printf '    {"type": "selector", "tag": "proxy", "outbounds": [%s, "direct"], "default": "%s"},\n' "$tags" "$(json_escape "$first")"
    else
      printf '    {"type": "selector", "tag": "proxy", "outbounds": ["direct"], "default": "direct"},\n'
    fi
    # Every protocol outbound ends with a comma: direct / block /
    # dns always follow, so no counting is needed.
    for idx in "${SELECTED_IDX[@]}"; do
      port="$(grep "^${PROTO_TAGS[$idx]}=" "${SB_HOME}/ports.env" 2>/dev/null | cut -d= -f2)"
      [ -n "$port" ] || continue
      printf '    '
      singbox_outbound_for "$idx" "$port" "$server" "$name"
      printf ',\n'
    done
    printf '    {"type": "direct", "tag": "direct"},\n'
    printf '    {"type": "block", "tag": "block"}\n'
    printf '  ],\n'
    printf '  "route": {\n    "rules": [\n      {"protocol": "dns", "action": "hijack-dns"},\n      {"ip_is_private": true, "outbound": "direct"},\n      {"domain_suffix": [".cn"], "outbound": "direct"}\n    ],\n    "final": "proxy",\n    "auto_detect_interface": true,\n    "default_domain_resolver": "google"\n  },\n'
    printf '  "experimental": {"cache_file": {"enabled": true}}\n}\n'
  } > "$out"
}
# Clash YAML variant 2 (served at /sub/clash2): same proxies as
# clash.yaml, plus an `auto` url-test group, a TUN section and a
# DNS section. clash.yaml stays the plain variant (proxies +
# PROXY select + MATCH).
write_clash2_yaml() {
  local out="${SB_HOME}/subscribe/clash2.yaml"
  local server="$WIZ_SERVER_ADDR" name="$WIZ_NODE_NAME"
  {
    printf 'port: 7890\nsocks-port: 7891\nallow-lan: false\nmode: rule\nlog-level: info\n'
    printf 'external-controller: 127.0.0.1:9090\n'
    printf 'tun:\n  enable: true\n  stack: system\n  auto-route: true\n  auto-detect-interface: true\n'
    printf 'dns:\n  enable: true\n  nameserver:\n    - 8.8.8.8\n    - 1.1.1.1\n  fallback:\n    - tls://8.8.8.8:853\n    - tls://1.1.1.1:853\n'
    printf 'proxies:\n'
    local idx port
    [ -s "${SB_HOME}/selected.env" ] && . "${SB_HOME}/selected.env"
    for idx in "${SELECTED_IDX[@]}"; do
      port="$(grep "^${PROTO_TAGS[$idx]}=" "${SB_HOME}/ports.env" 2>/dev/null | cut -d= -f2)"
      [ -n "$port" ] || continue
      clash_proxy_for "$idx" "$port" "$server" "$name"
    done
    printf 'proxy-groups:\n  - name: PROXY\n    type: select\n    proxies:\n'
    for idx in "${SELECTED_IDX[@]}"; do
      printf '      - "%s"\n' "$(display_name_for "$name" "${PROTO_NAMES[$idx]}")"
    done
    printf '      - auto\n      - DIRECT\n'
    printf '  - name: auto\n    type: url-test\n    url: http://www.gstatic.com/generate_204\n    interval: 300\n    proxies:\n'
    for idx in "${SELECTED_IDX[@]}"; do
      printf '      - "%s"\n' "$(display_name_for "$name" "${PROTO_NAMES[$idx]}")"
    done
    printf 'rules:\n  - MATCH,PROXY\n'
  } > "$out"
}
# ShadowRocket subscription: one ShadowRocket-style link per
# protocol (plain text), then base64. Served at
# /sub/shadowrocket (shadowrocket.b64).
write_shadowrocket_sub() {
  local server="$WIZ_SERVER_ADDR" name="$WIZ_NODE_NAME"
  : > "${SB_HOME}/subscribe/shadowrocket.txt"
  local idx port
  [ -s "${SB_HOME}/selected.env" ] && . "${SB_HOME}/selected.env"
  for idx in "${SELECTED_IDX[@]}"; do
    port="$(grep "^${PROTO_TAGS[$idx]}=" "${SB_HOME}/ports.env" 2>/dev/null | cut -d= -f2)"
    [ -n "$port" ] || continue
    shadowrocket_link_for "$idx" "$port" "$server" "$name" >> "${SB_HOME}/subscribe/shadowrocket.txt"
  done
  base64 -w0 "${SB_HOME}/subscribe/shadowrocket.txt" > "${SB_HOME}/subscribe/shadowrocket.b64"
}
# Subscription Index page (served at /sub/index): a clean list of
# every per-client subscription URL plus the QR code. Modelled on
# the reference Index page layout (client name + URL + QR).
write_sub_index() {
  local server="$WIZ_SERVER_ADDR" port="${WIZ_NGINX_PORT:-8080}"
  local base="http://${server}:${port}"
  local out="${SB_HOME}/subscribe/index.html"
  local esc_name
  esc_name="$(printf '%s' "${WIZ_NODE_NAME:-（无前缀）}" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g')"
  cat > "$out" <<EOF
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>BOSS J 订阅中心</title>
<style>
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,"PingFang SC","Microsoft YaHei",sans-serif;background:#fff;color:#000;margin:0;padding:24px;line-height:1.6}
h1{font-size:22px;margin:0 0 4px}
p.sub{color:#333;margin:0 0 18px}
table{border-collapse:collapse;width:100%;max-width:760px}
th,td{border:1px solid #000;padding:8px 10px;text-align:left;font-size:14px}
th{background:#000;color:#fff}
td a{color:#000;word-break:break-all}
.qr{margin-top:22px}
.qr img{image-rendering:pixelated;border:1px solid #000}
.note{color:#333;font-size:13px;max-width:760px}
</style>
</head>
<body>
<h1>BOSS J 订阅中心</h1>
<p class="sub">服务器 ${server} · 订阅端口 ${port} · 节点名 ${esc_name}</p>
<table>
<tr><th>客户端</th><th>订阅地址</th></tr>
<tr><td>订阅中心（本页）</td><td><a href="${base}/sub/index">${base}/sub/index</a></td></tr>
<tr><td>通用订阅（V2rayN / 通用）</td><td><a href="${base}/sub">${base}/sub</a></td></tr>
<tr><td>V2rayN</td><td><a href="${base}/sub/v2rayn">${base}/sub/v2rayn</a></td></tr>
<tr><td>ShadowRocket</td><td><a href="${base}/sub/shadowrocket">${base}/sub/shadowrocket</a></td></tr>
<tr><td>Clash / Mihomo</td><td><a href="${base}/sub/clash">${base}/sub/clash</a></td></tr>
<tr><td>Clash 2（自动测速 + TUN）</td><td><a href="${base}/sub/clash2">${base}/sub/clash2</a></td></tr>
<tr><td>sing-box（SFI / SFA / SFM）</td><td><a href="${base}/sub/sing-box">${base}/sub/sing-box</a></td></tr>
<tr><td>Throne</td><td><a href="${base}/sub/throne">${base}/sub/throne</a></td></tr>
<tr><td>自适应（按客户端自动识别）</td><td><a href="${base}/sub/auto">${base}/sub/auto</a></td></tr>
</table>
<div class="qr">
<h2>订阅二维码</h2>
<p>扫码导入通用订阅（${base}/sub）：</p>
<img src="/sub/qr" alt="订阅二维码">
</div>
<p class="note">自适应地址（/sub/auto）按客户端的 User-Agent 自动返回对应格式：Clash / Mihomo 返回 Clash YAML，SFI / SFA / SFM 返回 sing-box JSON，ShadowRocket 返回 ShadowRocket 格式，其他返回通用 base64 订阅。二维码是纯黑白高对比图，黑色 #000000、白色 #FFFFFF，无灰色抗锯齿。</p>
</body>
</html>
EOF
}
# QR code image of the /sub subscription URL (served at /sub/qr
# and embedded in the Index page). High black-white contrast:
# qrencode PNG output is pure black (#000000) on pure white
# (#FFFFFF) with crisp module edges — no gray anti-aliasing, no
# blur. Module size 10px and a 4-module margin keep it sharp and
# easy to scan. Skipped silently if qrencode is missing.
write_sub_qr() {
  local server="$WIZ_SERVER_ADDR" port="${WIZ_NGINX_PORT:-8080}"
  local url="http://${server}:${port}/sub"
  if command -v qrencode >/dev/null 2>&1; then
    qrencode -t PNG -s 10 -m 4 -o "${SB_HOME}/subscribe/qr.png" "$url" 2>/dev/null || true
  fi
}
# Generate all per-client subscription files. Called from
# export_list after write_clash_yaml, so every node-list refresh
# (install, menu 5, menu 8, sb -n, sync-argo) regenerates them.
write_perclient_subs() {
  mkdir -p "${SB_HOME}/subscribe"
  write_clash2_yaml
  write_singbox_json
  write_shadowrocket_sub
  write_sub_index
  write_sub_qr
}
# Save the wizard answers so later `sb -d` / `sb -n` runs can reuse them.
save_install_env() {
  cat > "${SB_HOME}/install.env" <<EOF
WIZ_SERVER_ADDR='${WIZ_SERVER_ADDR}'
WIZ_UUID='${WIZ_UUID}'
WIZ_NODE_NAME='${WIZ_NODE_NAME}'
WIZ_CDN='${WIZ_CDN}'
WIZ_SUBSCRIBE='${WIZ_SUBSCRIBE}'
WIZ_ARGO='${WIZ_ARGO}'
WIZ_ARGO_AUTH='${WIZ_ARGO_AUTH}'
WIZ_ARGO_DOMAIN='${WIZ_ARGO_DOMAIN}'
WIZ_NGINX_PORT='${WIZ_NGINX_PORT}'
WIZ_HY2_HOP='${WIZ_HY2_HOP}'
WIZ_HY2_REALM='${WIZ_HY2_REALM}'
WIZ_HY2_IGNORE='${WIZ_HY2_IGNORE:-false}'
WIZ_HY2_UP='${WIZ_HY2_UP:-200}'
WIZ_HY2_DOWN='${WIZ_HY2_DOWN:-1000}'
WIZ_BIND_IFACE='${WIZ_BIND_IFACE}'
WIZ_REALITY_PRIV='${WIZ_REALITY_PRIV}'
WIZ_FINGERPRINT='${WIZ_FINGERPRINT}'
WIZ_SNI='${WIZ_SNI}'
WIZ_START_PORT='${WIZ_START_PORT}'
REALITY_PUB_KEY='${REALITY_PUB_KEY}'
HY2_SECRET='${HY2_SECRET}'
SS_PASSWORD='${SS_PASSWORD}'
SS256_PASSWORD='${SS256_PASSWORD}'
SS2022_PASSWORD='${SS2022_PASSWORD}'
TROJAN_PASSWORD='${TROJAN_PASSWORD}'
TUIC_PASSWORD='${TUIC_PASSWORD}'
EOF
  printf 'SELECTED_IDX=(%s)\n' "${SELECTED_IDX[*]}" > "${SB_HOME}/selected.env"
  : > "${SB_HOME}/ports.env"
  local idx
  for idx in "${SELECTED_IDX[@]}"; do
    printf '%s=%s\n' "${PROTO_TAGS[$idx]}" "${PORT_FOR[$idx]}" >> "${SB_HOME}/ports.env"
  done
}
load_install_env() {
  [ -s "${SB_HOME}/install.env" ] || return 1
  # shellcheck disable=SC1091
  . "${SB_HOME}/install.env"
  [ -s "${SB_HOME}/selected.env" ] && . "${SB_HOME}/selected.env"
  # Restore per-protocol ports from ports.env (independent ports survive
  # here); fall back to consecutive ports from the start port.
  local idx port
  for idx in "${SELECTED_IDX[@]}"; do
    port="$(grep "^${PROTO_TAGS[$idx]}=" "${SB_HOME}/ports.env" 2>/dev/null | cut -d= -f2)"
    [ -n "$port" ] && PORT_FOR[$idx]="$port"
  done
  if [ "${#PORT_FOR[@]}" -eq 0 ] && [ -n "${WIZ_START_PORT:-}" ]; then
    assign_ports "$WIZ_START_PORT"
  fi
  return 0
}

# ---------------------------------------------------------------------------
# 16. Full install flow
# ---------------------------------------------------------------------------
run_install() {
  require_root
  detect_os
  detect_arch
  msg_info "$(tr_text checking_system)"
  install_deps curl wget jq tar openssl socat iproute2 qrencode
  ensure_jq
  detect_public_ip
  # Wizard (skipped values come from flags / config file).
  ask_wizard_protocols
  ask_wizard_start_port
  ask_wizard_server
  ask_wizard_uuid
  ask_wizard_node_name
  ask_wizard_fingerprint
  # Reality keys are needed before writing inbounds.
  if proto_selected 1 || proto_selected 2 || proto_selected 12 || proto_selected 14 || proto_selected 16 || proto_selected 17 || proto_selected 18; then
    if [ -z "$WIZ_REALITY_PRIV" ] && [ "$QUIET_INSTALL" -eq 0 ]; then
      local ans=""
      ask_line "$(tr_text enter_reality_priv):" ans
      [ -n "$ans" ] && WIZ_REALITY_PRIV="$ans"
    fi
  fi
  ask_wizard_hy2
  ask_wizard_cdn
  # Subscription / Argo defaults for the WebSocket protocols.
  if has_cf_protocol; then
    if [ -z "$WIZ_SUBSCRIBE" ]; then
      if ask_yes_no "Enable subscription (nginx)?" "y"; then WIZ_SUBSCRIBE="yes"; else WIZ_SUBSCRIBE="no"; fi
    fi
    if [ -z "$WIZ_ARGO" ]; then
      if ask_yes_no "Enable Argo tunnel for WebSocket nodes?" "y"; then WIZ_ARGO="try"; else WIZ_ARGO="no"; fi
    fi
    if [ "$WIZ_SUBSCRIBE" != "no" ] && [ -z "$WIZ_NGINX_PORT" ]; then
      local ans=""
      while true; do
        ask_line "$(tr_text enter_nginx_port) (default 8080):" ans
        ans="${ans:-8080}"
        is_port_number "$ans" && is_port_free "$ans" && { WIZ_NGINX_PORT="$ans"; break; }
        msg_warn "$(tr_text port_bad)"; note_bad_input
      done
    fi
    # v1.0.6: the block above already asked enable/disable when
    # WIZ_ARGO was empty, so only ask the tunnel type when it was
    # not already answered "no" (avoids asking twice).
    if [ "${WIZ_ARGO:-}" != "no" ]; then ask_wizard_argo; fi
  fi
  assign_ports "$WIZ_START_PORT"
  install_singbox_binary
  make_self_signed_cert
  generate_reality_keys
  write_base_config
  # WARP outbound for hysteria2 Realm, best effort.
  if [ "$WIZ_HY2_REALM" = "yes" ]; then
    register_warp_account || msg_warn "WARP registration failed; Hysteria2 will run without Realm."
  fi
  local idx
  for idx in "${SELECTED_IDX[@]}"; do
    write_inbound "$idx" "${PORT_FOR[$idx]}" "$WIZ_UUID" "$WIZ_NODE_NAME"
  done
  save_install_env
  if ! check_config; then
    msg_err "$(tr_text config_check_bad)"
    exit 1
  fi
  msg_ok "$(tr_text config_check_ok)"
  # Subscription + Argo.
  if [ "$WIZ_SUBSCRIBE" != "no" ] && [ -n "$WIZ_SUBSCRIBE" ]; then
    install_deps nginx
    write_nginx_conf
    if [ "$WIZ_SUBSCRIBE" = "dynamic" ]; then write_dynamic_render; fi
  fi
  if [ "$WIZ_ARGO" != "no" ] && [ -n "$WIZ_ARGO" ]; then
    setup_argo || msg_warn "Argo setup did not complete; WebSocket nodes will use direct mode."
  fi
  write_services
  install_argo_sync_timer
  sync_firewall
  if [ -n "$WIZ_HY2_HOP" ] && proto_selected 0; then
    add_hopping_nat "${PORT_FOR[0]}" "$WIZ_HY2_HOP"
    # Open the hopping range in the firewall as UDP.
    local hop_start="${WIZ_HY2_HOP%%:*}" hop_end="${WIZ_HY2_HOP##*:}"
    local p
    for ((p = hop_start; p <= hop_end; p += 500)); do allow_port "$p" udp; done
  fi
  # Start everything.
  msg_info "$(tr_text restarting)"
  svc enable sing-box
  svc start sing-box
  if [ -s "${SB_HOME}/argo_token" ] || [ -s "$SB_ARGO_CONF" ] || [ "$WIZ_ARGO" = "try" ]; then
    svc enable argo
    svc start argo
    sleep 2
    resolve_try_domain || true
    # v1.0.19: token tunnel — detect its hostname from the argo log.
    resolve_fixed_domain || true
  fi
  if [ "$WIZ_SUBSCRIBE" != "no" ] && [ -n "$WIZ_SUBSCRIBE" ]; then
    # v1.0.6: use the safe starter — a stale nginx master outside
    # systemd would make a plain `systemctl start` fail on bind.
    start_nginx_safe || true
  fi
  export_list install
  create_shortcut
  msg_ok "$(tr_text install_done)"
}
apply_quiet_defaults() {
  # Fill every wizard answer with a safe default for non-interactive use.
  [ -n "$WIZ_PROTOCOLS" ] || WIZ_PROTOCOLS="a"
  parse_protocol_answer "$WIZ_PROTOCOLS"
  [ -n "$WIZ_START_PORT" ] || WIZ_START_PORT="$DEFAULT_START_PORT"
  [ -n "$WIZ_SERVER_ADDR" ] || { detect_public_ip; WIZ_SERVER_ADDR="$(default_server_addr)"; }
  [ -n "$WIZ_UUID" ] || WIZ_UUID="$(make_uuid)"
  [ -n "$WIZ_NODE_NAME" ] || WIZ_NODE_NAME="<J>"
  [ -n "$WIZ_FINGERPRINT" ] || WIZ_FINGERPRINT="$DEFAULT_FINGERPRINT"
  [ -n "$WIZ_CDN" ] || WIZ_CDN="$DEFAULT_CDN_HOST"
  [ -n "$WIZ_SUBSCRIBE" ] || WIZ_SUBSCRIBE="no"
  [ -n "$WIZ_ARGO" ] || WIZ_ARGO="no"
  [ -n "$WIZ_NGINX_PORT" ] || WIZ_NGINX_PORT="8080"
  QUIET_INSTALL=1
}

# ---------------------------------------------------------------------------
# 17. Manage: change config (sb -d), change protocols (sb -r)
# ---------------------------------------------------------------------------
# Custom route rules live in 03_route.json as extra rules. The menu can
# add (domain_suffix or rule_set), list and delete them.
custom_route_count() {
  local jq
  jq="$(jq_bin)"
  if [ -s "${SB_CONF_DIR}/03_route.json" ]; then
    "$jq" -r '.route.rules | length' "${SB_CONF_DIR}/03_route.json" 2>/dev/null || echo 0
  else
    echo 0
  fi
}
custom_route_add() {
  local jq
  jq="$(jq_bin)"
  # Rule type first, as in the original (text 152).
  printf '\n'; c_green "$(tr_text rule_type_title)"
  local line
  printf -v line '  1. domain_suffix'; c_yellow "$line"
  printf -v line '  2. rule_set'; c_yellow "$line"
  local kind=""
  ask_choice kind
  case "$kind" in
    1) ;;
    2) ;;
    *) msg_info "$(tr_text no_change)"; return 0 ;;
  esac
  local file="${SB_CONF_DIR}/03_route.json"
  if [ "$kind" = "1" ]; then
    local input="" d ok=0
    ask_line "$(tr_text enter_domain_suffix):" input
    [ -n "$input" ] || { msg_info "$(tr_text no_change)"; return 0; }
    local IFS=','
    read -r -a _doms <<< "$input"
    for d in "${_doms[@]}"; do
      d="$(printf '%s' "$d" | tr -d ' ' | sed 's/。/./g' | tr '[:upper:]' '[:lower:]')"
      if [[ "$d" =~ ^[a-z0-9]([a-z0-9.-]*[a-z0-9])?\.[a-z]{2,}$ ]]; then
        "$jq" --arg v "$d" '.route.rules += [{domain_suffix: [$v], outbound: "direct"}]' "$file" > "${SB_TMP}/route.json" && mv "${SB_TMP}/route.json" "$file"
        ok=1
      else
        msg_warn "$(tr_text domain_bad_format): $d"
      fi
    done
    [ "$ok" = "1" ] && msg_ok "$(tr_text rule_added)" || msg_warn "$(tr_text no_change)"
  else
    c_bold "$(tr_text ruleset_common)"
    local input="" name
    ask_line "$(tr_text enter_ruleset):" input
    [ -n "$input" ] || { msg_info "$(tr_text no_change)"; return 0; }
    local IFS=','
    read -r -a _sets <<< "$input"
    for name in "${_sets[@]}"; do
      name="$(printf '%s' "$name" | tr -d ' ' | tr '[:upper:]' '[:lower:]' | sed -E 's#^.*/##; s/\.srs$//')"
      [[ "$name" =~ ^geo(site|ip)- ]] || name="geosite-$name"
      [ -n "$name" ] && [ "$name" != "geosite-" ] || continue
      "$jq" --arg v "$name" '.route.rules += [{rule_set: [$v], outbound: "direct"}] | .route.rule_set = ((.route.rule_set // []) + [{tag: $v, type: "remote", format: "binary", url: ("https://github.com/SagerNet/sing-geosite/raw/rule-set/" + $v + ".srs"), download_detour: "direct"}] | unique_by(.tag))' "$file" > "${SB_TMP}/route.json" && mv "${SB_TMP}/route.json" "$file"
    done
    msg_ok "$(tr_text rule_added)"
  fi
}
custom_route_view() {
  local jq
  jq="$(jq_bin)"
  if [ ! -s "${SB_CONF_DIR}/03_route.json" ]; then msg_info "$(tr_text no_rules)"; return 0; fi
  "$jq" -r '.route.rules[]? | tostring' "${SB_CONF_DIR}/03_route.json" 2>/dev/null || msg_info "$(tr_text no_rules)"
}
custom_route_delete() {
  local jq
  jq="$(jq_bin)"
  custom_route_view
  [ "$(custom_route_count)" = "0" ] && { msg_info "$(tr_text no_change)"; return 0; }
  local n=""
  ask_prompt "$(tr_text enter_rule_delete)" n
  [ -n "$n" ] || { msg_info "$(tr_text no_change)"; return 0; }
  local file="${SB_CONF_DIR}/03_route.json"
  local IFS=','
  read -r -a _nums <<< "$n"
  local num ok=0 sorted
  sorted="$(printf '%s
' "${_nums[@]}" | tr -cd '0-9
' | sort -rn)"
  while IFS= read -r num; do
    [ -n "$num" ] && [ "$num" != "0" ] || continue
    "$jq" --argjson i "$((num - 1))" 'del(.route.rules[$i])' "$file" > "${SB_TMP}/route.json" && mv "${SB_TMP}/route.json" "$file"
    ok=1
  done <<< "$sorted"
  [ "$ok" = "1" ] && msg_ok "$(tr_text rule_deleted)" || msg_info "$(tr_text no_change)"
}
custom_route_menu() {
  while true; do
    printf -v line '%s (rules: %s)' "$(tr_text custom_route_label)" "$(custom_route_count)"
    printf '\n'; c_green "$line"
    local line
    printf -v line '  1. %s' "$(tr_text add_rule)"; c_yellow "$line"
    printf -v line '  2. %s' "$(tr_text view_rules)"; c_yellow "$line"
    printf -v line '  3. %s' "$(tr_text delete_rule)"; c_yellow "$line"
    printf -v line '  0. %s' "$(tr_text back)"; c_yellow "$line"
    local ans=""
    ask_choice ans
    case "$ans" in
      1) custom_route_add ;;
      2) custom_route_view ;;
      3) custom_route_delete ;;
      0) return 0 ;;
      *) msg_info "$(tr_text no_change)"; return 0 ;;
    esac
  done
}
# Helpers for the dynamic sb -d menu and the port menus.
hy2_listen_port() {
  local f
  f="$(ls "${SB_CONF_DIR}/01_${PROTO_TAGS[0]}_inbounds.json" 2>/dev/null | head -1)"
  [ -n "$f" ] && [ -s "$f" ] && "$(jq_bin)" -r '.inbounds[0].listen_port // empty' "$f" 2>/dev/null
}
hy2_ignore_now() {
  local f
  f="$(ls "${SB_CONF_DIR}/01_${PROTO_TAGS[0]}_inbounds.json" 2>/dev/null | head -1)"
  if [ -n "$f" ] && [ -s "$f" ]; then
    "$(jq_bin)" -r '.inbounds[0].ignore_client_bandwidth // false' "$f" 2>/dev/null || echo false
  else
    printf '%s' "${WIZ_HY2_IGNORE:-false}"
  fi
}
xtls_mode_now() {
  local f
  f="$(ls "${SB_CONF_DIR}/01_${PROTO_TAGS[2]}_inbounds.json" 2>/dev/null | head -1)"
  if [ -n "$f" ] && [ -s "$f" ]; then
    local flow
    flow="$("$(jq_bin)" -r '.inbounds[0].users[0].flow // empty' "$f" 2>/dev/null)"
    [ "$flow" = "xtls-rprx-vision" ] && printf 'vision' || printf 'multiplex'
  else
    printf 'vision'
  fi
}
warp_configured() {
  [ -s "${SB_HOME}/warp-account.toml" ] || [ -s "${SB_HOME}/warp-account.json" ] || [ -s "${SB_HOME}/warp.env" ]
}
ports_display() {
  local idx out=""
  for idx in "${SELECTED_IDX[@]}"; do
    [ -n "$out" ] && out+=", "
    out+="${PORT_FOR[$idx]}"
  done
  printf '%s' "$out"
}
hy2_rewrite() {
  write_inbound 0 "${PORT_FOR[0]}" "$WIZ_UUID" "$WIZ_NODE_NAME"
}
apply_ports_post() {
  local hy2_old="$1" hy2_new="$2"
  write_nginx_conf 2>/dev/null || true
  # v1.0.9: port changes rewrite the nginx reverse-proxy locations,
  # so a running nginx must reload to pick them up.
  if [ "${WIZ_SUBSCRIBE:-no}" != "no" ]; then start_nginx_safe 2>/dev/null || true; fi
  if check_config; then
    svc reload sing-box
    sync_firewall
    msg_ok "$(tr_text ports_updated)"
  else
    msg_err "$(tr_text config_check_bad)"
    return 1
  fi
  if [ -n "$hy2_old" ] && [ -n "$hy2_new" ] && [ "$hy2_old" != "$hy2_new" ] && [ -n "$WIZ_HY2_HOP" ]; then
    remove_hopping_nat 2>/dev/null || true
    add_hopping_nat "$hy2_new" "$WIZ_HY2_HOP" 2>/dev/null || true
  fi
  export_list >/dev/null
}
# Port modification mode, as in the original (text 161): 1 = change the
# start port (protocols keep consecutive ports, default), 2 = an
# independent port per protocol. Invalid input is retried.
change_ports_menu() {
  local mode="" errors=0
  while true; do
    printf '\n'; c_green "$(tr_text port_mode_title)"
    local line
    printf -v line '  %s' "$(tr_text port_mode_start)"; c_yellow "$line"
    printf -v line '  %s' "$(tr_text port_mode_each)"; c_yellow "$line"
    ask_choice mode
    case "${mode:-1}" in
      1) change_start_port; return 0 ;;
      2) change_independent_port; return 0 ;;
      *)
        msg_warn "$(tr_text positive_int)"
        errors=$((errors + 1))
        [ "$errors" -ge 5 ] && { msg_err "$(tr_text too_many_errors)"; return 1; }
        ;;
    esac
  done
}
# Way 1: change the start port, with a preview and a confirm step.
change_start_port() {
  load_install_env
  local old_start new_start count new_end hy2_old hy2_new
  old_start="${WIZ_START_PORT:-$DEFAULT_START_PORT}"
  count="${#SELECTED_IDX[@]}"
  local new=""
  ask_line "$(tr_text enter_start_port) (default: $old_start):" new
  new="${new:-$old_start}"
  is_port_number "$new" || { msg_warn "$(tr_text port_bad)"; return 1; }
  [ "$new" = "$old_start" ] && { msg_info "$(tr_text no_change)"; return 0; }
  new_end=$((new + count - 1))
  local preview=""
  printf -v preview "$(tr_text start_port_preview)" "$old_start" "$new" "$count" "$new" "$new_end"
  printf '\n'; c_bold "$preview"
  local confirm=""
  ask_prompt "$(tr_text apply_changes)" confirm
  case "${confirm,,}" in y|yes) ;; *) msg_info "$(tr_text no_change)"; return 0 ;; esac
  hy2_old="$(hy2_listen_port)"
  assign_ports "$new"
  WIZ_START_PORT="$new"
  save_install_env
  local idx
  for idx in "${SELECTED_IDX[@]}"; do write_inbound "$idx" "${PORT_FOR[$idx]}" "$WIZ_UUID" "$WIZ_NODE_NAME"; done
  hy2_new="$(hy2_listen_port)"
  apply_ports_post "$hy2_old" "$hy2_new"
}
# Way 2: pick installed protocols by letter (a = all, Enter = skip),
# ask a new port for each, preview, confirm, then apply.
change_independent_port() {
  load_install_env
  c_green "$(tr_text installed_protocols_list)"
  local idx
  local line
  for idx in "${SELECTED_IDX[@]}"; do printf -v line "$(tr_text proto_port_line)" "${PROTO_NAMES[$idx]}" "${PORT_FOR[$idx]}"; c_yellow "$line"; done
  show_protocol_picker
  local ans=""
  ask_choice ans
  [ -n "$ans" ] || { msg_info "$(tr_text no_change)"; return 0; }
  local old_sel=("${SELECTED_IDX[@]}")
  parse_protocol_answer "$ans" || { msg_info "$(tr_text no_change)"; return 0; }
  local chosen=() c ok
  for c in "${SELECTED_IDX[@]}"; do
    ok=0
    for idx in "${old_sel[@]}"; do [ "$c" = "$idx" ] && ok=1; done
    [ "$ok" = "1" ] && chosen+=("$c")
  done
  SELECTED_IDX=("${old_sel[@]}")
  [ "${#chosen[@]}" -gt 0 ] || { msg_info "$(tr_text no_change)"; return 0; }
  local -a new_ports=()
  local i port
  for i in "${!chosen[@]}"; do
    idx="${chosen[$i]}"
    port=""
    local pprompt=""
    printf -v pprompt "$(tr_text port_for_prompt)" "${PROTO_NAMES[$idx]}" "${PORT_FOR[$idx]}"
    ask_line "$pprompt" port
    if [ -z "$port" ]; then new_ports[$i]="${PORT_FOR[$idx]}"; continue; fi
    if is_port_number "$port" && is_port_free "$port"; then new_ports[$i]="$port"; else msg_warn "$(tr_text port_bad)"; new_ports[$i]="${PORT_FOR[$idx]}"; fi
  done
  printf '\n'; c_green "$(tr_text port_changes_title)"
  for i in "${!chosen[@]}"; do
    idx="${chosen[$i]}"
    printf -v line '  %s: %s -> %s' "${PROTO_NAMES[$idx]}" "${PORT_FOR[$idx]}" "${new_ports[$i]}"; c_yellow "$line"
  done
  local confirm=""
  ask_prompt "$(tr_text apply_changes)" confirm
  case "${confirm,,}" in y|yes) ;; *) msg_info "$(tr_text no_change)"; return 0 ;; esac
  local hy2_old hy2_new
  hy2_old="$(hy2_listen_port)"
  for i in "${!chosen[@]}"; do
    idx="${chosen[$i]}"
    PORT_FOR[$idx]="${new_ports[$i]}"
    write_inbound "$idx" "${new_ports[$i]}" "$WIZ_UUID" "$WIZ_NODE_NAME"
  done
  save_install_env
  hy2_new="$(hy2_listen_port)"
  apply_ports_post "$hy2_old" "$hy2_new"
}
# Change the WARP account (original submenu, text 175): register a new
# free account, or enter the account info manually.
warp_account_menu() {
  while true; do
    printf '\n'; c_green "$(tr_text warp_account_title)"
    local line
    printf -v line '  %s' "$(tr_text warp_register_new)"; c_yellow "$line"
    printf -v line '  %s' "$(tr_text warp_enter_manual)"; c_yellow "$line"
    printf -v line '  0. %s' "$(tr_text back)"; c_yellow "$line"
    local ans=""
    ask_choice ans
    case "$ans" in
      1)
        if register_warp_account; then msg_ok "$(tr_text config_saved)"; else msg_warn "$(tr_text warp_register_failed)"; fi
        ;;
      2) warp_account_manual ;;
      0) return 0 ;;
      *) msg_info "$(tr_text no_change)" ;;
    esac
  done
}
warp_account_manual() {
  local addr="" key="" reserved="" r1 r2 r3
  while true; do
    ask_line "$(tr_text warp_ipv6):" addr
    [[ "$addr" == *:* ]] && break
    msg_warn "$(tr_text domain_bad)"
  done
  ask_line "$(tr_text warp_privkey):" key
  while true; do
    ask_line "$(tr_text warp_reserved):" reserved
    if [[ "$reserved" =~ ^([0-9]+),([0-9]+),([0-9]+)$ ]]; then
      r1="${BASH_REMATCH[1]}"; r2="${BASH_REMATCH[2]}"; r3="${BASH_REMATCH[3]}"
      break
    fi
    msg_warn "$(tr_text warp_reserved_bad)"
  done
  {
    printf 'WARP_ADDRESS6=%s
' "$addr"
    printf 'WARP_PRIVATE_KEY=%s
' "$key"
    printf 'WARP_RESERVED=%s,%s,%s
' "$r1" "$r2" "$r3"
  } > "${SB_HOME}/warp.env"
  printf '%s
' "$key" > "${SB_HOME}/warp-private.key"
  msg_ok "$(tr_text config_saved)"
}
# Hysteria2 helpers used by the dynamic sb -d menu.
hy2_bandwidth_change() {
  local up="" down=""
  while true; do
    ask_line "$(tr_text enter_hy2_up):" up
    [[ "$up" =~ ^[1-9][0-9]*$ ]] && break
    msg_warn "$(tr_text positive_int)"
  done
  while true; do
    ask_line "$(tr_text enter_hy2_down):" down
    [[ "$down" =~ ^[1-9][0-9]*$ ]] && break
    msg_warn "$(tr_text positive_int)"
  done
  WIZ_HY2_UP="$up"; WIZ_HY2_DOWN="$down"
  save_install_env; hy2_rewrite
  check_config && svc reload sing-box
  export_list >/dev/null
  msg_ok "$(tr_text config_saved)"
}
hy2_realm_toggle() {
  if [ "${WIZ_HY2_REALM:-no}" = "yes" ]; then
    WIZ_HY2_REALM="no"; save_install_env
    check_config && svc reload sing-box
    export_list >/dev/null
    return 0
  fi
  # Enabling Realm while port hopping is on disables hopping (original).
  if [ -n "$WIZ_HY2_HOP" ]; then
    local confirm=""
    ask_prompt "$(tr_text hop_realm_confirm)" confirm
    case "${confirm,,}" in y|yes) ;; *) msg_info "$(tr_text no_change)"; return 0 ;; esac
    remove_hopping_nat 2>/dev/null || true
    WIZ_HY2_HOP=""
  fi
  WIZ_HY2_REALM="yes"
  save_install_env
  check_config && svc reload sing-box
  export_list >/dev/null
}
hy2_hopping_change() {
  # Enabling hopping while Realm is on disables Realm (original).
  if [ "${WIZ_HY2_REALM:-no}" = "yes" ]; then
    local confirm=""
    ask_prompt "$(tr_text realm_hop_confirm)" confirm
    case "${confirm,,}" in y|yes) ;; *) msg_info "$(tr_text no_change)"; return 0 ;; esac
    WIZ_HY2_REALM="no"
  fi
  printf '\n'; c_bold "$(tr_text hop_explain)"
  local ans="" errors=0
  while true; do
    ask_line "$(tr_text enter_hop_disable):" ans
    ans="${ans//-/:}"
    if [ -z "$ans" ] || [[ "${ans,,}" =~ ^(n|no)$ ]]; then
      remove_hopping_nat 2>/dev/null || true
      WIZ_HY2_HOP=""
      save_install_env; export_list >/dev/null
      return 0
    fi
    if [[ "$ans" =~ ^([0-9]{4,5}):([0-9]{4,5})$ ]] && [ "${BASH_REMATCH[1]}" -lt "${BASH_REMATCH[2]}" ] && [ "${BASH_REMATCH[1]}" -ge "$HOP_MIN" ] && [ "${BASH_REMATCH[2]}" -le "$HOP_MAX" ]; then
      remove_hopping_nat 2>/dev/null || true
      WIZ_HY2_HOP="$ans"
      save_install_env
      add_hopping_nat "$(hy2_listen_port)" "$ans" 2>/dev/null || true
      export_list >/dev/null
      return 0
    fi
    msg_warn "$(tr_text positive_int)"
    errors=$((errors + 1))
    [ "$errors" -ge 5 ] && { msg_err "$(tr_text too_many_errors)"; return 1; }
  done
}
xtls_mux_toggle() {
  local f
  f="$(ls "${SB_CONF_DIR}/01_${PROTO_TAGS[2]}_inbounds.json" 2>/dev/null | head -1)"
  [ -n "$f" ] && [ -s "$f" ] || { msg_err "$(tr_text not_installed)"; return 1; }
  local jq
  jq="$(jq_bin)"
  if [ "$(xtls_mode_now)" = "vision" ]; then
    "$jq" '.inbounds[0].users[0].flow = "" | .inbounds[0].multiplex = {enabled: true, padding: true}' "$f" > "${SB_TMP}/xtls.json" && mv "${SB_TMP}/xtls.json" "$f"
  else
    "$jq" '.inbounds[0].users[0].flow = "xtls-rprx-vision" | .inbounds[0].multiplex.enabled = false' "$f" > "${SB_TMP}/xtls.json" && mv "${SB_TMP}/xtls.json" "$f"
  fi
  if check_config; then svc reload sing-box; else msg_err "$(tr_text config_check_bad)"; return 1; fi
  export_list >/dev/null
}
change_bind_interface() {
  local -a ifaces=()
  if command -v ip >/dev/null 2>&1; then
    while read -r _ iface; do
      iface="${iface%%:*}"; iface="${iface%%@*}"
      [ "$iface" != "lo" ] && [ -n "$iface" ] && ifaces+=("$iface")
    done < <(ip -o link show up 2>/dev/null)
  fi
  if [ "${#ifaces[@]}" -eq 0 ]; then
    local i
    for i in /sys/class/net/*; do i="${i##*/}"; [ "$i" != "lo" ] && ifaces+=("$i"); done
  fi
  c_green "$(tr_text net_ifaces)"
  local i
  local line
  for i in "${!ifaces[@]}"; do printf -v line '  %s. %s' "$((i + 1))" "${ifaces[$i]}"; c_yellow "$line"; done
  local ans=""
  ask_choice ans
  if [ -z "$ans" ]; then
    WIZ_BIND_IFACE=""; save_install_env
  elif [[ "$ans" =~ ^[0-9]+$ ]] && [ "$ans" -ge 1 ] && [ "$ans" -le "${#ifaces[@]}" ]; then
    WIZ_BIND_IFACE="${ifaces[$((ans - 1))]}"; save_install_env
  else
    WIZ_BIND_IFACE="$ans"; save_install_env
  fi
  local jq
  jq="$(jq_bin)"
  if [ -s "${SB_CONF_DIR}/02_outbounds.json" ]; then
    if [ -n "$WIZ_BIND_IFACE" ]; then
      "$jq" --arg iface "$WIZ_BIND_IFACE" '.outbounds |= map(if .type == "direct" then . + {bind_interface: $iface} else . end)' "${SB_CONF_DIR}/02_outbounds.json" > "${SB_TMP}/out.json" && mv "${SB_TMP}/out.json" "${SB_CONF_DIR}/02_outbounds.json"
    else
      "$jq" '.outbounds |= map(del(.bind_interface))' "${SB_CONF_DIR}/02_outbounds.json" > "${SB_TMP}/out.json" && mv "${SB_TMP}/out.json" "${SB_CONF_DIR}/02_outbounds.json"
    fi
  fi
  check_config && svc reload sing-box
}
# Suffix " (current: X)" / "（当前：X）" for the menu-5
# labels (v1.0.15). The format comes from our own message table.
current_suffix() {
  local fmt
  fmt="$(tr_text current_value)"
  # shellcheck disable=SC2059
  printf "$fmt" "$1"
}
# The `sb -d` menu, as in the original: a dynamic list, in the original
# order, showing only the items that apply to this install, each with
# its current value. One change per visit; an invalid choice prints
# "No change was made." and returns to the main menu.
change_config_menu() {
  load_install_env || { msg_err "$(tr_text not_installed)"; return 1; }
  local -a keys=() labels=()
  local has_ws=0 has_reality=0
  if proto_selected 7 || proto_selected 8 || proto_selected 9 || proto_selected 12; then has_ws=1; fi
  if proto_selected 1 || proto_selected 2 || proto_selected 12 || proto_selected 14 || proto_selected 16 || proto_selected 17 || proto_selected 18; then has_reality=1; fi
  if [ "$has_ws" = "1" ]; then keys+=(cdn); labels+=("$(tr_text cdn_label)$(current_suffix "${WIZ_CDN}")"); fi
  if [ "$has_reality" = "1" ]; then keys+=(sni); labels+=("$(tr_text sni_label)$(current_suffix "${WIZ_SNI:-$DEFAULT_TLS_HOST}")"); fi
  keys+=(ports); labels+=("$(tr_text ports_label)$(current_suffix "$(ports_display)")")
  keys+=(name); labels+=("$(tr_text node_name_label)$(current_suffix "${WIZ_NODE_NAME}")")
  keys+=(uuid); labels+=("$(tr_text uuid_label)$(current_suffix "${WIZ_UUID}")")
  keys+=(serverip); labels+=("$(tr_text server_label)$(current_suffix "${WIZ_SERVER_ADDR}")")
  keys+=(fingerprint); labels+=("$(tr_text fp_label)$(current_suffix "${WIZ_FINGERPRINT:-chrome}")")
  keys+=(bindinterface); labels+=("$(tr_text bind_label)$(current_suffix "${WIZ_BIND_IFACE:-default}")")
  if [ "${WIZ_SUBSCRIBE:-no}" = "no" ]; then keys+=(subscribe); labels+=("$(tr_text sub_enable)"); else keys+=(subscribe); labels+=("$(tr_text sub_disable)"); fi
  if [ "${WIZ_SUBSCRIBE:-no}" != "no" ]; then
    if [ "$WIZ_SUBSCRIBE" = "dynamic" ]; then keys+=(dynamic_subscribe); labels+=("$(tr_text dyn_disable)"); else keys+=(dynamic_subscribe); labels+=("$(tr_text dyn_enable)"); fi
  fi
  if proto_selected 0; then
    if [ "$(hy2_ignore_now)" = "true" ]; then keys+=(hy2cc); labels+=("$(tr_text hy2_cc_bbr)"); else keys+=(hy2cc); labels+=("$(tr_text hy2_cc_declared)"); fi
    if [ "$(hy2_ignore_now)" != "true" ]; then local bw_cur=""; printf -v bw_cur "$(tr_text hy2_bw_current)" "${WIZ_HY2_UP:-200}" "${WIZ_HY2_DOWN:-1000}"; keys+=(hy2bw); labels+=("$(tr_text hy2_bw_label)$(current_suffix "$bw_cur")"); fi
    if [ "${WIZ_HY2_REALM:-no}" = "yes" ]; then keys+=(hy2realm); labels+=("$(tr_text realm_close)"); else keys+=(hy2realm); labels+=("$(tr_text realm_open)"); fi
    keys+=(hy2hopping); labels+=("$(tr_text hy2_hop_label)$(current_suffix "${WIZ_HY2_HOP:-$(tr_text hy2_hop_disabled)}")$(tr_text leave_blank_disable)")
  fi
  if proto_selected 2; then
    if [ "$(xtls_mode_now)" = "multiplex" ]; then keys+=(xtlsmux); labels+=("$(tr_text xtls_to_vision)"); else keys+=(xtlsmux); labels+=("$(tr_text xtls_to_mux)"); fi
  fi
  if warp_configured; then
    keys+=(customroute); labels+=("$(tr_text custom_route_label)  (rules: $(custom_route_count))")
    keys+=(warpaccount); labels+=("$(tr_text warp_change)")
  fi
  [ "${#keys[@]}" -eq 0 ] && { msg_err "$(tr_text not_installed)"; return 1; }
  printf '\n'; c_green "$(tr_text change_what)"
  local i line
  for i in "${!keys[@]}"; do printf -v line ' %2d. %s' "$((i + 1))" "${labels[$i]}"; c_yellow "$line"; done
  printf '
'
  local ans=""
  ask_choice ans
  if ! [[ "$ans" =~ ^[0-9]+$ ]] || [ "$ans" -lt 1 ] || [ "$ans" -gt "${#keys[@]}" ]; then
    msg_info "$(tr_text no_change)"
    return 0
  fi
  local key="${keys[$((ans - 1))]}"
  case "$key" in
    cdn) local old_cdn="$WIZ_CDN"; WIZ_CDN=""; ask_wizard_cdn "$old_cdn"; save_install_env; export_list >/dev/null ;;
    sni)
      local sni=""
      ask_line "SNI$(current_suffix "${WIZ_SNI:-$DEFAULT_TLS_HOST}"):" sni
      [ -n "$sni" ] && WIZ_SNI="$sni"
      save_install_env
      local idx
      for idx in 1 2 12 14 16 17 18; do proto_selected "$idx" && write_inbound "$idx" "${PORT_FOR[$idx]}" "$WIZ_UUID" "$WIZ_NODE_NAME"; done
      check_config && svc reload sing-box
      export_list >/dev/null
      ;;
    ports) change_ports_menu ;;
    name)
      local new_name=""
      ask_line "$(tr_text enter_node_name):" new_name
      apply_node_name_input "$new_name" "<J>"
      save_install_env; export_list >/dev/null
      ;;
    uuid)
      local u=""
      ask_line "$(tr_text enter_uuid):" u
      if is_valid_uuid "$u"; then
        WIZ_UUID="$u"; save_install_env
        local idx
        for idx in "${SELECTED_IDX[@]}"; do write_inbound "$idx" "${PORT_FOR[$idx]}" "$WIZ_UUID" "$WIZ_NODE_NAME"; done
        check_config && svc reload sing-box && msg_ok "$(tr_text config_saved)"
      else msg_warn "$(tr_text uuid_bad)"; fi
      ;;
    serverip) WIZ_SERVER_ADDR=""; ask_wizard_server; save_install_env; export_list >/dev/null ;;
    fingerprint) WIZ_FINGERPRINT=""; ask_wizard_fingerprint; save_install_env; export_list >/dev/null ;;
    bindinterface) change_bind_interface ;;
    subscribe)
      # v1.0.9: write the config BEFORE starting nginx, and use the
      # safe starter so a running nginx actually reloads it. The
      # old order (start first, write after, never reload) left a
      # running nginx serving the old config with no /sub.
      if [ "$WIZ_SUBSCRIBE" = "no" ]; then WIZ_SUBSCRIBE="yes"; else WIZ_SUBSCRIBE="no"; fi
      save_install_env; write_nginx_conf
      if [ "$WIZ_SUBSCRIBE" = "yes" ]; then start_nginx_safe || true; else svc stop nginx; fi
      ;;
    dynamic_subscribe)
      if [ "$WIZ_SUBSCRIBE" = "dynamic" ]; then WIZ_SUBSCRIBE="yes"; else WIZ_SUBSCRIBE="dynamic"; write_dynamic_render; fi
      save_install_env
      ;;
    hy2cc)
      if [ "$(hy2_ignore_now)" = "true" ]; then WIZ_HY2_IGNORE="false"; else WIZ_HY2_IGNORE="true"; fi
      save_install_env; hy2_rewrite
      check_config && svc reload sing-box
      export_list >/dev/null
      ;;
    hy2bw) hy2_bandwidth_change ;;
    hy2realm) hy2_realm_toggle ;;
    hy2hopping) hy2_hopping_change ;;
    xtlsmux) xtls_mux_toggle ;;
    customroute) custom_route_menu ;;
    warpaccount) warp_account_menu ;;
  esac
  return 0
}
# Parse a per-list letter answer (e.g. "b d" or "bcd") into
# 0-based positions within a list of at most 19 items. Letters are
# per-list (a = first item of that list), NOT the global picker
# (where a = all). Result in PARSED_POS.
parse_list_letters() {
  local raw="$1" max="$2" letters=(a b c d e f g h i j k l m n o p q r s t)
  local token ch pos seen=""
  PARSED_POS=()
  raw="${raw,,}"
  raw="${raw//,/ }"
  for token in $raw; do
    local i
    for ((i = 0; i < ${#token}; i++)); do
      ch="${token:$i:1}"
      for pos in "${!letters[@]}"; do [ "${letters[$pos]}" = "$ch" ] && [ "$pos" -lt "$max" ] && case " $seen " in *" $pos "*) ;; *) PARSED_POS+=("$pos"); seen="$seen $pos";; esac; done
    done
  done
}

# Wait for a temporary (try) tunnel to get its public domain, polling
# resolve_try_domain() for up to ~30s. Prints the domain on stdout.
wait_try_domain() {
  local i domain=""
  for i in $(seq 1 15); do
    domain="$(resolve_try_domain || true)"
    [ -n "$domain" ] && { printf '%s' "$domain"; return 0; }
    sleep 2
  done
  return 1
}
# v1.0.6: after protocols are added in menu 8, CF protocols need an
# Argo tunnel to be reachable (their inbounds listen on 127.0.0.1
# behind nginx; without a tunnel the CF node links never connect,
# while direct nodes work fine). Ask which tunnel to use, start it,
# resolve the temporary domain and match it to the CF node links
# (build_link_for / clash_proxy_for use WIZ_ARGO_DOMAIN on 443 when
# an Argo tunnel is up). Reuses setup_argo / resolve_try_domain.
prompt_argo_for_cf() {
  has_cf_protocol || return 0
  # Already configured and running: refresh the try domain (it
  # changes on every tunnel restart) and do not ask again.
  if { [ "${WIZ_ARGO:-no}" = "try" ] || [ "${WIZ_ARGO:-no}" = "token" ]; } && svc_is_active argo; then
    if [ "${WIZ_ARGO}" = "try" ]; then
      local d=""; d="$(wait_try_domain || true)"
      if [ -n "$d" ] && [ "$d" != "${WIZ_ARGO_DOMAIN:-}" ]; then WIZ_ARGO_DOMAIN="$d"; save_install_env; fi
    elif [ "${WIZ_ARGO}" = "token" ] && [ -z "${WIZ_ARGO_DOMAIN:-}" ]; then
      # v1.0.19: fixed tunnel running but no domain stored yet.
      resolve_fixed_domain >/dev/null || true
      save_install_env
    fi
    return 0
  fi
  # Configured but stopped: restart it instead of asking again.
  if [ "${WIZ_ARGO:-no}" = "try" ] || [ "${WIZ_ARGO:-no}" = "token" ]; then
    write_services; setup_argo || { msg_warn "$(tr_text argo_start_failed)"; return 1; }
    svc enable argo; svc start argo; sleep 2
    if ! svc_is_active argo; then sleep 2; svc start argo; sleep 2; fi
    if svc_is_active argo; then
      if [ "${WIZ_ARGO}" = "try" ]; then
        local d=""; d="$(wait_try_domain || true)"
        if [ -n "$d" ]; then
          WIZ_ARGO_DOMAIN="$d"; save_install_env
          printf -v line '%s %s' "$(tr_text argo_domain_is)" "$d"; c_bold "$line"
        else
          msg_warn "$(tr_text argo_try_failed)"; WIZ_ARGO_DOMAIN=""; save_install_env
        fi
      elif [ "${WIZ_ARGO}" = "token" ]; then
        # v1.0.19: detect the fixed tunnel hostname from the argo log.
        resolve_fixed_domain >/dev/null || true
        save_install_env
      fi
      return 0
    fi
    msg_err "$(tr_text argo_start_failed)"; return 1
  fi
  # Not configured yet: ask which tunnel to use.
  printf '\n'; c_green "$(tr_text argo_ask_cf)"
  local line
  printf -v line '  %s' "$(tr_text argo_try)"; c_yellow "$line"
  printf -v line '  %s' "$(tr_text argo_token)"; c_yellow "$line"
  printf -v line '  %s' "$(tr_text argo_none)"; c_yellow "$line"
  local ans=""; ask_choice ans
  case "$ans" in
    2)
      c_bold "$(tr_text argo_guide)"
      WIZ_ARGO="token"
      ask_line "$(tr_text enter_argo_auth):" WIZ_ARGO_AUTH
      save_install_env
      write_services; setup_argo || { msg_err "$(tr_text argo_start_failed)"; return 1; }
      svc enable argo; svc start argo; sleep 2
      if ! svc_is_active argo; then sleep 2; svc start argo; sleep 2; fi
      if svc_is_active argo; then
        # v1.0.19: detect the fixed tunnel hostname from the argo log.
        resolve_fixed_domain >/dev/null || true
        save_install_env
        msg_ok "$(tr_text argo_started)"; return 0
      fi
      msg_err "$(tr_text argo_start_failed)"; return 1
      ;;
    3)
      WIZ_ARGO="no"; WIZ_ARGO_DOMAIN=""; save_install_env
      msg_warn "$(tr_text argo_no_cf_warn)"; return 0
      ;;
    *)
      WIZ_ARGO="try"; WIZ_ARGO_AUTH=""; save_install_env
      write_services; setup_argo || { msg_err "$(tr_text argo_start_failed)"; return 1; }
      svc enable argo; svc start argo
      msg_info "$(tr_text argo_try_wait)"
      sleep 2
      if ! svc_is_active argo; then sleep 2; svc start argo; sleep 2; fi
      if svc_is_active argo; then
        local d=""; d="$(wait_try_domain || true)"
        if [ -n "$d" ]; then
          WIZ_ARGO_DOMAIN="$d"; save_install_env
          printf -v line '%s %s' "$(tr_text argo_domain_is)" "$d"; c_bold "$line"
          msg_ok "$(tr_text argo_try_ok)"
        else
          msg_warn "$(tr_text argo_try_failed)"; WIZ_ARGO_DOMAIN=""; save_install_env
        fi
        return 0
      fi
      msg_err "$(tr_text argo_start_failed)"; return 1
      ;;
  esac
}
# Add / remove protocols after install (sb -r).
# Original flow: list installed protocols with per-list letters and
# pick removals, list uninstalled protocols with per-list letters and
# pick additions, show keep/add lists and confirm, and when nothing
# is kept ask the start port and node name like a fresh install.
change_protocols_menu() {
  load_install_env || { msg_err "$(tr_text not_installed)"; return 1; }
  local keep=() add=() i line
  local list_letters=(a b c d e f g h i j k l m n o p q r s t)
  # --- remove: letters are relative to the installed list ---
  if [ "${#SELECTED_IDX[@]}" -gt 0 ]; then
    printf -v line '%s (%s)' "$(tr_text installed_protocols)" "${#SELECTED_IDX[@]}"; printf '\n'; c_green "$line"
    for i in "${!SELECTED_IDX[@]}"; do
      printf -v line ' %s. %s' "${list_letters[$i]}" "${PROTO_NAMES[${SELECTED_IDX[$i]}]}"; c_yellow "$line"
    done
    local rem=""
    ask_prompt "$(tr_text remove_protocols_prompt)" rem
    # v1.0.13: one-click removal of all installed protocols. Only the
    # whole word "all" (case-insensitive) means "all"; a single "a" is
    # still just the first protocol in the installed list, as before
    # (parse_list_letters would otherwise read "all" as letters
    # a+l+l). Symmetric with the v1.0.8 "all" handling on the add
    # side below. Nothing is deleted yet: the confirm step still
    # shows keep (empty) + add and [n] cancels.
    local rem_norm="${rem,,}"
    rem_norm="${rem_norm//[[:space:],]/}"
    if [ "$rem_norm" = "all" ]; then
      keep=()
    else
      parse_list_letters "$rem" "${#SELECTED_IDX[@]}"
      local drop pos
      for i in "${!SELECTED_IDX[@]}"; do
        drop=0
        for pos in "${PARSED_POS[@]}"; do [ "$pos" = "$i" ] && drop=1; done
        [ "$drop" = "0" ] && keep+=("${SELECTED_IDX[$i]}")
      done
    fi
  fi
  # --- add: letters are relative to the uninstalled list ---
  local not_inst=() idx
  for idx in "${!PROTO_NAMES[@]}"; do
    local found=0 k
    for k in "${SELECTED_IDX[@]}"; do [ "$k" = "$idx" ] && found=1; done
    [ "$found" = "0" ] && not_inst+=("$idx")
  done
  if [ "${#not_inst[@]}" -gt 0 ]; then
    printf -v line '%s (%s)' "$(tr_text uninstalled_protocols)" "${#not_inst[@]}"; printf '\n'; c_green "$line"
    for i in "${!not_inst[@]}"; do
      printf -v line ' %s. %s' "${list_letters[$i]}" "${PROTO_NAMES[${not_inst[$i]}]}"; c_yellow "$line"
    done
    local addans=""
    ask_prompt "$(tr_text add_protocols_prompt)" addans
    # v1.0.8: one-click install of all uninstalled protocols. Only the
    # whole word "all" (case-insensitive) means "all"; a single "a" is
    # still just the first protocol in the uninstalled list, as before
    # (parse_list_letters would otherwise read "all" as letters a+l+l).
    local addans_norm="${addans,,}"
    addans_norm="${addans_norm//[[:space:],]/}"
    if [ "$addans_norm" = "all" ]; then
      add=("${not_inst[@]}")
    else
      parse_list_letters "$addans" "${#not_inst[@]}"
      for pos in "${PARSED_POS[@]}"; do add+=("${not_inst[$pos]}"); done
    fi
  fi
  # --- confirm: keep + add lists, [n] aborts ---
  local reinstall=("${keep[@]}" "${add[@]}")
  printf -v line '%s (%s)' "$(tr_text confirm_reinstall)" "${#reinstall[@]}"; printf '\n'; c_green "$line"
  if [ "${#keep[@]}" -gt 0 ]; then
    printf -v line '%s (%s)' "$(tr_text keep_protocols)" "${#keep[@]}"; printf '\n'; c_green "$line"
    for i in "${!keep[@]}"; do printf -v line ' %s. %s' "$((i + 1))" "${PROTO_NAMES[${keep[$i]}]}"; c_yellow "$line"; done
  fi
  if [ "${#add[@]}" -gt 0 ]; then
    printf -v line '%s (%s)' "$(tr_text add_protocols_label)" "${#add[@]}"; printf '\n'; c_green "$line"
    for i in "${!add[@]}"; do printf -v line ' %s. %s' "$((i + 1))" "${PROTO_NAMES[${add[$i]}]}"; c_yellow "$line"; done
  fi
  local confirm=""
  ask_prompt "$(tr_text confirm_continue)" confirm
  [ "${confirm,,}" = "n" ] && { msg_info "$(tr_text no_change)"; return 0; }
  # No protocol kept: ask the start port and node name like a fresh
  # install, then assign ports in the new 19-protocol order.
  if [ "${#reinstall[@]}" -gt 0 ] && [ "${#keep[@]}" -eq 0 ]; then
    WIZ_START_PORT=""; WIZ_NODE_NAME=""
    ask_wizard_start_port
    ask_wizard_node_name
  fi
  # Keep the new 19-protocol order (numeric sort by protocol index).
  SELECTED_IDX=($(printf '%s\n' "${reinstall[@]}" | sort -n))
  assign_ports "${WIZ_START_PORT:-$DEFAULT_START_PORT}"
  # Show the selected protocols and their ports, as in the original.
  printf '\n'; c_green "$(tr_text selected_order)"
  for i in "${!SELECTED_IDX[@]}"; do printf -v line ' %s. %s %s' "$((i + 1))" "${PROTO_NAMES[${SELECTED_IDX[$i]}]}" "${PORT_FOR[${SELECTED_IDX[$i]}]}"; c_yellow "$line"; done
  # v1.0.4: menu 8 runs in a fresh process, so the Reality private
  # key is not in memory (load_install_env only restores
  # REALITY_PUB_KEY). Restore it from the saved file, or generate it
  # once if this is a core-only machine that never had one;
  # otherwise Reality inbounds would be written with an empty
  # private key and `sing-box check` would fail.
  if [ -z "$REALITY_PRIV_KEY" ] && [ -s "${SB_HOME}/reality_private.key" ]; then
    REALITY_PRIV_KEY="$(cat "${SB_HOME}/reality_private.key")"
  fi
  if [ -z "$REALITY_PRIV_KEY" ]; then
    local need_reality=0 idx2
    for idx2 in "${SELECTED_IDX[@]}"; do
      case "$idx2" in 1|2|12|14|16|17|18) need_reality=1 ;; esac
    done
    if [ "$need_reality" = "1" ]; then
      generate_reality_keys
      WIZ_REALITY_PRIV="$REALITY_PRIV_KEY"
    fi
  fi
  # A core-only machine has no conf dir / cert yet; create the
  # protocol-independent base files before writing inbounds.
  [ -s "${SB_CONF_DIR}/00_base.json" ] || write_base_config
  make_self_signed_cert
  # Delete inbound files for removed protocols, write new ones.
  local tag
  for tag in "${PROTO_TAGS[@]}"; do
    rm -f "${SB_CONF_DIR}/01_${tag}_inbounds.json"
  done
  for idx in "${SELECTED_IDX[@]}"; do
    write_inbound "$idx" "${PORT_FOR[$idx]}" "$WIZ_UUID" "$WIZ_NODE_NAME"
  done
  save_install_env
  if check_config; then
    # v1.0.5: a bare `svc restart sing-box` silently did nothing on
    # machines where the service was never enabled, so nodes printed
    # fine but never listened (user report: Sing-box: stopped after
    # adding protocols in menu 8). Make sure the service file exists,
    # enable it, restart it, and verify it is actually running.
    [ -s /etc/systemd/system/sing-box.service ] || [ -x /etc/init.d/sing-box ] || write_services
    svc enable sing-box
    svc restart sing-box
    if ! svc_is_active sing-box; then sleep 2; svc start sing-box; sleep 2; fi
    if ! svc_is_active sing-box; then
      msg_err "$(tr_text sb_start_failed)"
    fi
    # v1.0.5: the subscription link printed by export_list is served
    # by nginx, but a core-only machine defaults to WIZ_SUBSCRIBE=no
    # and menu 8 never wrote the nginx config or started nginx, so
    # the /sub link did not open. When protocols were added, enable
    # the subscription automatically: install nginx if missing, write
    # the config (it reverse-proxies the WS / HTTP inbounds), and
    # enable + start nginx.
    if [ "${#SELECTED_IDX[@]}" -gt 0 ]; then
      if [ "${WIZ_SUBSCRIBE:-no}" = "no" ]; then
        WIZ_SUBSCRIBE="yes"
        save_install_env
      fi
      if ! command -v nginx >/dev/null 2>&1; then install_deps nginx; fi
      write_nginx_conf
      if [ "${WIZ_SUBSCRIBE}" = "dynamic" ]; then write_dynamic_render; fi
      # v1.0.6: use the safe starter — a stale nginx master outside
      # systemd (old pid listening on 8080 with the old config) would
      # make a plain `systemctl start` fail on bind. The safe starter
      # reloads that master instead, and prints the real error when
      # it still cannot start.
      start_nginx_safe || true
    fi
    # v1.0.6: CF inbounds listen on 127.0.0.1 behind nginx; without
    # an Argo tunnel they cannot be reached from outside. Ask which
    # tunnel to use and start it before exporting the links, so the
    # CF links are matched to the tunnel domain.
    prompt_argo_for_cf || true
    sync_firewall; export_list; msg_ok "$(tr_text config_saved)"
  else
    msg_err "$(tr_text config_check_bad)"
  fi
}
change_argo_menu() {
  load_install_env || { msg_err "$(tr_text not_installed)"; return 1; }
  local cur_type cur_domain
  if [ -n "${WIZ_ARGO_AUTH:-}" ]; then cur_type="Token"; else cur_type="Try"; fi
  cur_domain="${WIZ_ARGO_DOMAIN:-$(cat "${SB_HOME}/argo_domain" 2>/dev/null)}"
  local argo_is="" argo_dom=""
  printf -v argo_is "$(tr_text argo_tunnel_is)" "$cur_type"
  printf -v argo_dom "$(tr_text argo_domain_line)" "${cur_domain:-}"
  printf '\n'; c_bold "$argo_is"; c_bold " $argo_dom"
  local tunnel_label=""
  tunnel_label="$(argo_tunnel_label)"
  [ -n "$tunnel_label" ] && c_bold " $tunnel_label"
  c_green "$(tr_text choose_argo_type):"
  local line
  printf -v line '  %s' "$(tr_text argo_try)"; c_yellow "$line"
  printf -v line '  %s' "$(tr_text argo_token)"; c_yellow "$line"
  local ans=""
  ask_choice ans
  case "$ans" in
    1) WIZ_ARGO="try"; WIZ_ARGO_AUTH="" ;;
    2)
      c_bold "$(tr_text argo_guide)"
      WIZ_ARGO="token"; ask_line "$(tr_text enter_argo_auth):" WIZ_ARGO_AUTH
      ;;
    *) msg_info "$(tr_text no_change)"; return 0 ;;
  esac
  save_install_env
  setup_argo
  svc restart argo
  sleep 2
  resolve_try_domain || true
  # v1.0.19: token tunnel — detect its hostname from the argo log
  # (one token = one tunnel = one hostname; never hardcoded).
  resolve_fixed_domain || true
  export_list
}
show_version() {
  printf -v line '%s: %s' "$(tr_text script_version)" "$MY_VERSION"; c_green "$line"
  refresh_status
  printf -v line 'sing-box: %s' "${SB_VERSION_INSTALLED:-$(tr_text not_installed)}"; c_bold "$line"
  printf -v line 'Argo: %s' "${ARGO_VERSION_INSTALLED:-$(tr_text not_installed)}"; c_bold "$line"
  printf -v line 'Nginx: %s' "${NGINX_VERSION_INSTALLED:-$(tr_text not_installed)}"; c_bold "$line"
  # Ask about both upgrades first (Argo first, then sing-box), then
  # upgrade in the same order — as in the original.
  local update_argo="" update_sb=""
  local argo_installed argo_latest argo_body argo_tag argo_dl_url argo_asset
  argo_installed="$(cloudflared --version 2>/dev/null | awk '{print $3}' | head -1)"
  if command -v cloudflared >/dev/null 2>&1 || [ -x "$SB_ARGO_BIN" ]; then
    argo_body="$(fetch_text "https://api.github.com/repos/cloudflare/cloudflared/releases/latest" || true)"
    # v1.0.18: the release tag has NO "v" prefix (tag_name is
    # "2026.11.2", not "v2026.11.2"). The old code stripped the
    # "v" for comparison but then re-added it when building the
    # download URL, so the URL was .../download/v2026.11.2/...
    # and GitHub answered 404 ("下载失败"). Keep the raw tag for
    # the URL and the display; strip the "v" only for the version
    # comparison. Prefer the asset's browser_download_url from
    # the API (the exact URL GitHub gives for this release).
    argo_tag="$(printf '%s' "$argo_body" | grep -oE '"tag_name"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | cut -d'"' -f4)"
    argo_latest="${argo_tag#v}"
    case "$ARCH_SB" in
      amd64) argo_asset="cloudflared-linux-amd64" ;;
      arm64) argo_asset="cloudflared-linux-arm64" ;;
      *) argo_asset="" ;;
    esac
    argo_dl_url=""
    if [ -n "$argo_asset" ] && [ -n "$argo_body" ]; then
      argo_dl_url="$(printf '%s' "$argo_body" | grep -oE "\"browser_download_url\"[[:space:]]*:[[:space:]]*\"[^\"]*${argo_asset}\"" | head -1 | cut -d'"' -f4)"
    fi
    if [ -z "$argo_latest" ]; then
      msg_warn "$(tr_text argo_check_failed)"
    elif [ "$argo_latest" != "$argo_installed" ]; then
      local ver_line=""
      printf -v ver_line "$(tr_text argo_version_newest)" "${argo_installed:-none}" "$argo_tag"
      printf '\n'; c_bold "$ver_line"
      ask_prompt "$(tr_text whether_upgrade)" update_argo
    else
      printf -v line 'Argo: %s' "$(tr_text no_upgrade)"; c_bold "$line"
    fi
  else
    printf -v line 'Argo: %s' "$(tr_text not_installed)"; c_bold "$line"
  fi
  local latest installed
  latest="$(latest_sb_tag)"
  installed="$(cat "${SB_HOME}/release_tag" 2>/dev/null || echo none)"
  if [ "$installed" = "none" ]; then
    printf -v line 'sing-box: %s' "$(tr_text not_installed)"; c_bold "$line"
  elif [ "$latest" != "$installed" ]; then
    local ver_line=""
    printf -v ver_line "$(tr_text sb_version_newest)" "$installed" "$latest"
    printf '\n'; c_bold "$ver_line"
      ask_prompt "$(tr_text whether_upgrade)" update_sb
  else
    printf -v line 'Sing-box: %s' "$(tr_text no_upgrade)"; c_bold "$line"
  fi
  # Upgrade Argo.
  if [[ "${update_argo,,}" =~ ^y(es)?$ ]]; then
    # v1.0.18: prefer the asset's browser_download_url from the
    # API; fall back to the raw tag (no added "v" — the tag has
    # none, and adding one made GitHub return 404).
    local argo_url="${argo_dl_url:-}"
    if [ -z "$argo_url" ]; then
      case "$ARCH_SB" in
        amd64) argo_url="https://github.com/cloudflare/cloudflared/releases/download/${argo_tag}/cloudflared-linux-amd64" ;;
        arm64) argo_url="https://github.com/cloudflare/cloudflared/releases/download/${argo_tag}/cloudflared-linux-arm64" ;;
        *) msg_warn "Unsupported architecture for Argo update." ;;
      esac
    fi
    if [ -n "$argo_url" ]; then
      svc stop argo 2>/dev/null || true
      if fetch_file "$argo_url" "$SB_TMP/cloudflared" && [ -s "$SB_TMP/cloudflared" ]; then
        chmod +x "$SB_TMP/cloudflared"
        mv "$SB_TMP/cloudflared" "$SB_ARGO_BIN"
        svc start argo 2>/dev/null || true
        msg_ok "$(tr_text install_done)"
      else
        msg_warn "$(tr_text download_failed)"
      fi
    fi
  fi
  # Upgrade sing-box, with a backup and a rollback if the new binary
  # cannot run the current configuration.
  if [[ "${update_sb,,}" =~ ^y(es)?$ ]]; then
    svc stop sing-box
    cp "$SB_BIN" "${SB_HOME}/sing-box.bak" 2>/dev/null || true
    cp "${SB_HOME}/release_tag" "${SB_HOME}/release_tag.bak" 2>/dev/null || true
    install_singbox_binary
    if check_config; then
      rm -f "${SB_HOME}/sing-box.bak" "${SB_HOME}/release_tag.bak"
      svc start sing-box
      printf -v line 'New version %s is running successfully, backup file deleted.' "$latest"; c_bold "$line"
    else
      printf -v line 'New version %s failed to run, restoring old version %s ...' "$latest" "$installed"; c_bold "$line"
      mv -f "${SB_HOME}/sing-box.bak" "$SB_BIN" 2>/dev/null || true
      mv -f "${SB_HOME}/release_tag.bak" "${SB_HOME}/release_tag" 2>/dev/null || true
      svc start sing-box
      if svc_is_active sing-box; then printf -v line 'Successfully restored old version %s.' "$installed"; c_bold "$line"; else msg_err "Failed to restore old version $installed, please check manually."; fi
    fi
  fi
  # A fresh Argo binary with a temporary tunnel gets a new domain.
  if [[ "${update_argo,,}" =~ ^y(es)?$ ]] && [ "${WIZ_ARGO:-no}" = "try" ]; then
    resolve_try_domain || true
    export_list >/dev/null
  fi
  # v1.0.16: make sure the 5-minute Argo sync timer is installed
  # (existing installs get it on upgrade, not just fresh installs).
  install_argo_sync_timer
}
# Upgrade the SCRIPT itself to the latest version from the repo
# (v1.0.18, menu 13 / `sb --update-script`). Menu 6 (show_version)
# only upgrades the sing-box and Argo BINARIES — it never touches
# the script — so the installed script version never changed
# through the menu. This is a separate item that does only the
# script: download the latest sing-box.sh, verify it (bash -n +
# MY_VERSION differs), back up the current installer.sh, replace
# it, and re-export so the subscriptions regenerate. It reads
# install.env / selected.env / ports.env and never resets them,
# so the UUID, ports, node name and tunnel are preserved. The new
# script takes effect the next time `sb` runs (this process is
# already running the old copy).
update_script() {
  local url="${SB_INSTALLER_URL:-$INSTALLER_URL}"
  local installer="${SB_HOME}/installer.sh"
  local tmp_new="${installer}.tmp.$$"
  printf -v line '%s: %s' "$(tr_text script_version)" "$MY_VERSION"; c_green "$line"
  rm -f "$tmp_new" 2>/dev/null || true
  if ! fetch_file "$url" "$tmp_new" || [ ! -s "$tmp_new" ]; then
    rm -f "$tmp_new" 2>/dev/null || true
    msg_warn "$(tr_text download_failed)"
    return 1
  fi
  local new_ver="" new_sz=0
  new_sz="$(wc -c < "$tmp_new" 2>/dev/null || echo 0)"
  new_ver="$(grep -m1 '^MY_VERSION=' "$tmp_new" 2>/dev/null | cut -d'"' -f2)"
  if [ "${new_sz:-0}" -le 10240 ] || ! bash -n "$tmp_new" 2>/dev/null || [ -z "$new_ver" ]; then
    rm -f "$tmp_new" 2>/dev/null || true
    msg_warn "$(tr_text script_verify_failed)"
    return 1
  fi
  # v1.0.20: compare against the INSTALLED script's version, not the
  # running one. The one-liner runs the latest script from GitHub, so
  # $MY_VERSION is already the new version — comparing against it
  # always said "up to date" and never upgraded the install (the
  # installed installer.sh stayed on the old version with the old
  # config). Read the installed version from installer.sh; if that
  # file is missing or unreadable, fall back to $MY_VERSION.
  local installed_ver=""
  installed_ver="$(grep -m1 '^MY_VERSION=' "$installer" 2>/dev/null | cut -d'"' -f2)"
  [ -n "$installed_ver" ] || installed_ver="$MY_VERSION"
  if [ "$new_ver" = "$installed_ver" ]; then
    rm -f "$tmp_new" 2>/dev/null || true
    msg_ok "$(tr_text script_up_to_date)"
    return 0
  fi
  # Back up the current script, then replace it. The backup keeps
  # the INSTALLED version in its name so an old copy can be restored.
  local bak="${installer}.bak-${installed_ver%% *}"
  cp "$installer" "$bak" 2>/dev/null || true
  mv "$tmp_new" "$installer" 2>/dev/null || { msg_err "$(tr_text script_verify_failed)"; return 1; }
  chmod +x "$installer" 2>/dev/null || true
  # v1.0.20: regenerate the sing-box config and nginx conf from the
  # stored install state, so config-level fixes in the new script
  # (e.g. multiplex) actually take effect. export_list alone only
  # rewrites the subscription links — it never writes config.json or
  # nginx conf, so a script-only upgrade used to leave the old config
  # (and the old speed) in place.
  if load_install_env >/dev/null 2>&1 && [ "${#SELECTED_IDX[@]}" -gt 0 ]; then
    # write_inbound appends one tag=port line per call; save_install_env
    # AFTER the loop truncates ports.env and rewrites it clean (the
    # same order as menu 8's regeneration — saving first would leave
    # the appended lines duplicated).
    mkdir -p "$SB_CONF_DIR" 2>/dev/null || true
    local idx
    for idx in "${SELECTED_IDX[@]}"; do
      write_inbound "$idx" "${PORT_FOR[$idx]}" "$WIZ_UUID" "$WIZ_NODE_NAME" >/dev/null 2>&1 || true
    done
    write_nginx_conf >/dev/null 2>&1 || true
    save_install_env
    if check_config; then
      svc reload sing-box 2>/dev/null || svc restart sing-box 2>/dev/null || true
      svc reload nginx 2>/dev/null || true
    fi
  fi
  # Regenerate the subscription files with the (unchanged) stored
  # config, so the new script's export format applies at once.
  export_list >/dev/null || true
  local done_line=""
  printf -v done_line "$(tr_text script_updated)" "$new_ver"
  msg_ok "$done_line"
}
# ---------------------------------------------------------------------------
# 18. Uninstall
# ---------------------------------------------------------------------------
run_uninstall() {
  refresh_status
  if [ "$IS_INSTALLED" = "0" ] && [ ! -d "$SB_HOME" ]; then
    msg_err "$(tr_text not_installed)"
    return 1
  fi
  svc stop sing-box 2>/dev/null || true
  svc stop argo 2>/dev/null || true
  svc disable sing-box 2>/dev/null || true
  svc disable argo 2>/dev/null || true
  remove_hopping_nat
  # Remove firewall rules recorded at install time.
  if [ -s "$SB_FIREWALL_PORTS_FILE" ]; then
    while IFS='/' read -r p pr; do [ -n "$p" ] && remove_port_rule "$p" "${pr:-tcp}"; done < "$SB_FIREWALL_PORTS_FILE"
  fi
  # Original behaviour: no "are you sure" prompt for the uninstall
  # itself. Instead it asks whether to also remove the nginx package
  # and fcgiwrap / spawn-fcgi (both default to keep). The package
  # removal runs in the background, as in the original.
  if [ "$QUIET_INSTALL" -eq 0 ]; then
    local pkgs=()
    if command -v nginx >/dev/null 2>&1 && [ -s /etc/nginx/conf.d/sing-box-sub.conf ]; then
      local rm_nginx=""
      ask_prompt "$(tr_text remove_nginx)" rm_nginx
      case "${rm_nginx,,}" in y|yes) pkgs+=(nginx) ;; esac
    fi
    if command -v fcgiwrap >/dev/null 2>&1 || command -v spawn-fcgi >/dev/null 2>&1; then
      local rm_fcgi=""
      ask_prompt "$(tr_text remove_fcgi)" rm_fcgi
      case "${rm_fcgi,,}" in y|yes) pkgs+=(fcgiwrap spawn-fcgi) ;; esac
    fi
    if [ "${#pkgs[@]}" -gt 0 ]; then
      local log="/tmp/sing-box-uninstall.log"
      : > "$log"
      nohup sh -c 'if command -v apt-get >/dev/null 2>&1; then apt-get remove -y "$@"; elif command -v dnf >/dev/null 2>&1; then dnf remove -y "$@"; elif command -v yum >/dev/null 2>&1; then yum remove -y "$@"; elif command -v apk >/dev/null 2>&1; then apk del "$@"; elif command -v pacman >/dev/null 2>&1; then pacman -Rns --noconfirm "$@"; fi' sh "${pkgs[@]}" >"$log" 2>&1 </dev/null &
    fi
  fi
  rm -f /etc/systemd/system/sing-box.service /etc/systemd/system/argo.service
  rm -f /etc/init.d/sing-box /etc/init.d/argo
  command -v systemctl >/dev/null 2>&1 && systemctl daemon-reload 2>/dev/null || true
  rm -f /etc/nginx/conf.d/sing-box-sub.conf
  svc reload nginx 2>/dev/null || true
  rm -rf "$SB_HOME" /usr/local/bin/sb /usr/local/bin/cj
  msg_ok "$(tr_text uninstall_done)"
}
# ---------------------------------------------------------------------------
# 19. Toggle helpers for -s / -a
# ---------------------------------------------------------------------------
toggle_service() {
  local name="$1" label="$2"
  refresh_status
  if svc_is_active "$name"; then
    svc stop "$name"; svc disable "$name"
    sleep 1
    svc_is_active "$name" && msg_err "$label $(tr_text service_failed)" || msg_ok "$label $(tr_text service_stopped)"
  else
    svc enable "$name"; svc start "$name"
    sleep 2
    svc_is_active "$name" && msg_ok "$label $(tr_text service_started)" || msg_err "$label $(tr_text service_failed)"
  fi
}
run_speed_test() {
  # Original behaviour: run the tcpx.sh helper directly. Kernel upgrade,
  # BBR install, DD script and speed test all live in that script.
  bash <(wget --no-check-certificate -qO- https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh)
}

# ---------------------------------------------------------------------------
# 20. Menus
# ---------------------------------------------------------------------------
# Traffic counters from the clash_api, best effort. Returns "↓ X ↑ Y"
# or an empty string when the API is not reachable.
traffic_summary() {
  local port stats down up
  port="$(cat "${SB_HOME}/clash_api_port" 2>/dev/null || echo 9090)"
  stats="$(curl -fsSL --max-time 3 "http://127.0.0.1:${port}/traffic" 2>/dev/null || true)"
  [ -n "$stats" ] || return 0
  # The clash_api /traffic endpoint returns {"up": N, "down": N};
  # older drafts used downloadTotal / uploadTotal, so accept both.
  down="$(printf '%s' "$stats" | grep -oE '"(down|downloadTotal)"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+$' | head -1)"
  up="$(printf '%s' "$stats" | grep -oE '"(up|uploadTotal)"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+$' | head -1)"
  if [ -n "$down" ] || [ -n "$up" ]; then
    printf '  ↓%s ↑%s' "$(human_bytes "${down:-0}")" "$(human_bytes "${up:-0}")"
  fi
}
# v1.0.16: tunnel type label for the Argo status line, e.g.
# "(固定隧道 tunnel.example.com)" or "(临时隧道 xxx.trycloudflare.com)".
# Reads the live WIZ_ARGO / WIZ_ARGO_DOMAIN from install.env (never
# a hardcoded string). Empty when Argo is off or has no domain.
argo_tunnel_label() {
  local argo="" domain=""
  if [ -s "${SB_HOME}/install.env" ]; then
    argo="$(grep '^WIZ_ARGO=' "${SB_HOME}/install.env" 2>/dev/null | cut -d"'" -f2)"
    domain="$(grep '^WIZ_ARGO_DOMAIN=' "${SB_HOME}/install.env" 2>/dev/null | cut -d"'" -f2)"
  fi
  [ -n "$argo" ] || argo="${WIZ_ARGO:-}"
  [ -n "$domain" ] || domain="${WIZ_ARGO_DOMAIN:-}"
  case "$argo" in
    token) [ -n "$domain" ] && printf '(%s %s)' "$(tr_text tunnel_fixed)" "$domain" ;;
    try) [ -n "$domain" ] && printf '(%s %s)' "$(tr_text tunnel_try)" "$domain" ;;
  esac
}
print_header() {
  clear
  printf '================================================================================\n'
  c_green " $(tr_text script_version): $MY_VERSION"
  c_green " $(tr_text new_features): $(tr_text new_features_list)"
  c_green " $(tr_text system_info):"
  printf -v line '\t%s: %s' "$(tr_text os_label)" "$SYS_PRETTY"; c_green "$line"
  printf '\n'
  printf -v line '\t%s: %s' "$(tr_text kernel_label)" "$(uname -r)"; c_green "$line"
  printf '\n'
  printf -v line '\t%s: %s' "$(tr_text arch_label)" "$ARCH_RAW"; c_green "$line"
  printf '\n'
  printf -v line '\t%s: %s' "$(tr_text virt_label)" "$VIRT_KIND"; c_green "$line"
  printf '\n'
  # v1.0.20: provider_for_ip prints provider and country on two
  # lines. The IPv4 line is column-aligned (IP, country,
  # (provider)); IPv6 keeps the v1.0.19 "(provider country)" shape.
  local provider="" country="" ip6_extra="" provider_info=""
  provider_info="$(provider_for_ip "$WAN4")"
  provider="$(printf '%s' "$provider_info" | sed -n '1p' 2>/dev/null)"
  country="$(printf '%s' "$provider_info" | sed -n '2p' 2>/dev/null)"
  if [ -n "$provider" ]; then
    [ -n "$WAN6" ] && ip6_extra=" ($provider${country:+ $country})"
  fi
  if [ -n "$WAN4" ] && [ -n "$provider" ] && [ -n "$country" ]; then
    printf -v line '\tIPv4: %-20s %-15s (%s) %s' "$WAN4" "$country" "$provider" "$WARP4"
  elif [ -n "$provider" ]; then
    printf -v line '\tIPv4: %s (%s) %s' "$WAN4" "$provider" "$WARP4"
  else
    printf -v line '\tIPv4: %s %s' "$WAN4" "$WARP4"
  fi
  c_green "$line"
  printf '\n'
  printf -v line '\tIPv6: %s%s %s' "$WAN6" "$ip6_extra" "$WARP6"; c_green "$line"
  printf '\n'
  local sb_mem argo_mem nginx_mem traffic line
  sb_mem="$(svc_memory sing-box)"
  argo_mem="$(svc_memory argo)"
  nginx_mem="$(svc_memory nginx)"
  traffic="$(traffic_summary)"
  printf -v line '\tSing-box: %-11s %-14s %s%s' "$(status_word "$SB_RUNNING")" "${SB_VERSION_INSTALLED:-$(tr_text status_not_installed)}" "$sb_mem" "$traffic"; c_green "$line"
  printf '\n'
  local tunnel_label="" argo_extra=""
  tunnel_label="$(argo_tunnel_label)"
  [ -n "$tunnel_label" ] && argo_extra=" $tunnel_label"
  printf -v line '\tArgo:     %-11s %-14s %s%s' "$(status_word "$ARGO_RUNNING")" "${ARGO_VERSION_INSTALLED:-$(tr_text status_not_installed)}" "$argo_mem" "$argo_extra"; c_green "$line"
  printf '\n'
  printf -v line '\tNginx:    %-11s %-14s %s' "$(status_word "$NGINX_RUNNING")" "${NGINX_VERSION_INSTALLED:-$(tr_text status_not_installed)}" "$nginx_mem"; c_green "$line"
  printf '================================================================================\n\n'
}
# Display word for a service state (running / stopped /
# not-installed). Only the display is translated; the
# SB_RUNNING / ARGO_RUNNING / NGINX_RUNNING variables keep their
# English values because other code compares them to "running".
status_word() {
  case "$1" in
    running) tr_text status_running ;;
    stopped) tr_text status_stopped ;;
    not-installed) tr_text status_not_installed ;;
    *) printf '%s' "$1" ;;
  esac
}
# Dynamic open/close label for the installed menu: running services
# show "Close ...", stopped ones show "Open ...".
toggle_label() {
  local svc_name="$1"
  if [ "$svc_name" = "sing-box" ]; then
    if [ "$SB_RUNNING" = "running" ]; then tr_text close_sb; else tr_text open_sb; fi
  else
    if [ "$ARGO_RUNNING" = "running" ]; then tr_text close_argo; else tr_text open_argo; fi
  fi
}
# Cumulative run counter, like the reference script (v1.0.15): one
# count per interactive main-menu display. Single-action flags
# (sb -n, sb -s, ...) exit in parse_args and never reach main_menu,
# so they are not counted. The file is data under $SB_HOME, so it
# survives script updates. A missing or damaged file starts at 1;
# an unwritable file is skipped silently and never breaks the menu.
bump_run_count() {
  local f="${SB_HOME}/run_count" cur=0
  RUN_COUNT=1
  if [ -s "$f" ]; then
    cur="$(cat "$f" 2>/dev/null || echo 0)"
    [[ "$cur" =~ ^[0-9]+$ ]] || cur=0
  fi
  RUN_COUNT=$((cur + 1))
  printf '%s\n' "$RUN_COUNT" > "$f" 2>/dev/null || true
}
# Print the counter right-aligned on its own line (terminal width,
# fallback 80 when the width cannot be determined).
print_run_count() {
  [ -n "${RUN_COUNT:-}" ] || return 0
  local text width nbytes nchars wide pad
  printf -v text "$(tr_text run_count_total)" "$RUN_COUNT"
  width="$(tput cols 2>/dev/null || echo 80)"
  [[ "$width" =~ ^[0-9]+$ ]] || width=80
  # Display width: a CJK char is 3 bytes but 1 char and 2 columns.
  # (bytes-chars)/2 counts them; in a non-UTF-8 locale bytes==chars
  # and this degrades to plain byte alignment.
  nbytes="$(printf '%s' "$text" | wc -c)"
  nchars="$(printf '%s' "$text" | wc -m)"
  wide=$(( (nbytes - nchars) / 2 ))
  pad=$((width - nchars - wide))
  [ "$pad" -lt 0 ] && pad=0
  printf '%*s%s\n' "$pad" "" "$text"
}
# The two menus share one loop; the option list depends on install state.
main_menu() {
  while true; do
    refresh_status
    print_header
    bump_run_count
    local -a options=() actions=()
    if [ "$IS_INSTALLED" = "1" ]; then
      # Installed menu, 1-9 (do not reorder):
      # 1. 查看节点信息 (sb -n)  2. 关闭 Sing-box (sb -s)  3. 关闭 Argo (sb -a)
      # 4. 更换 Argo 隧道 (sb -t)  5. 修改节点配置 (sb -d)
      # 6. 同步 Sing-box 和 Argo 至最新版本 (sb -v)
      # 7. 升级内核、安装BBR、DD脚本 (sb -b)  8. 增加 / 删除协议 (sb -r)
      # 9. 卸载 (sb -u)  10. 安装 ArgoX 脚本  11. 安装 sba 脚本  12. 安装 TCP brutal
      # 13. 升级脚本至最新版本 (sb --update-script) — v1.0.18, separate
      #     from menu 6 (menu 6 only upgrades the sing-box / Argo binaries).
      options=(
        "1. $(tr_text view_nodes) (sb -n)"
        "2. $(toggle_label sing-box) (sb -s)"
        "3. $(toggle_label argo) (sb -a)"
        "4. $(tr_text change_argo) (sb -t)"
        "5. $(tr_text change_config) (sb -d)"
        "6. $(tr_text check_update) (sb -v)"
        "7. $(tr_text kernel_bbr) (sb -b)"
        "8. $(tr_text change_protocols) (sb -r)"
        "9. $(tr_text uninstall) (sb -u)"
        "10. $(tr_text argo_tool)"
        "11. $(tr_text subscribe_tool)"
        "12. $(tr_text hy2_tool)"
        "13. $(tr_text update_script) (sb --update-script)"
        "0. $(tr_text exit_menu)"
      )
      actions=(show_nodes toggle_sb toggle_argo change_argo change_config show_version speed change_proto uninstall argo_tool sub_tool hy2_tool update_script)
    else
      options=(
        "1. $(tr_text fast_install)"
        "2. $(tr_text install_with_sub_argo)"
        "3. $(tr_text install_with_argo)"
        "4. $(tr_text install_with_sub)"
        "5. $(tr_text custom_install)"
        "6. $(tr_text speed_test)"
        "7. $(tr_text argo_tool)"
        "8. $(tr_text subscribe_tool)"
        "9. $(tr_text hy2_tool)"
        "0. $(tr_text exit_menu)"
      )
      actions=(fast_install install_sub_argo install_argo install_sub custom_install speed argo_tool sub_tool hy2_tool)
    fi
    local opt
    for opt in "${options[@]}"; do c_yellow " $opt"; done
    print_run_count
    printf '\n'
    local choice=""
    ask_choice choice
    case "$choice" in
      0) exit 0 ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#actions[@]}" ]; then
          local fn="${actions[$((choice - 1))]}"
          case "$fn" in
            quit) exit 0 ;;
            show_nodes) export_list; pause ;;
            toggle_sb) toggle_service sing-box "Sing-box" ;;
            toggle_argo) toggle_service argo "Argo" ;;
            change_argo) change_argo_menu ;;
            change_config) change_config_menu ;;
            show_version) show_version; pause ;;
            update_script) update_script; pause ;;
            speed) run_speed_test; pause ;;
            change_proto) change_protocols_menu ;;
            uninstall) run_uninstall; exit 0 ;;
            argo_tool) run_external_tool argox ;;
            sub_tool) run_external_tool sba ;;
            hy2_tool) run_external_tool hy2 ;;
            fast_install) FAST_INSTALL=1; apply_quiet_defaults; WIZ_SUBSCRIBE="yes"; WIZ_ARGO="try"; run_install; exit 0 ;;
            install_sub_argo) WIZ_SUBSCRIBE="yes"; WIZ_ARGO="try"; run_install; exit 0 ;;
            install_argo) WIZ_SUBSCRIBE="no"; WIZ_ARGO="try"; run_install; exit 0 ;;
            install_sub) WIZ_SUBSCRIBE="yes"; WIZ_ARGO="no"; run_install; exit 0 ;;
            custom_install) run_install; exit 0 ;;
          esac
        else
          msg_warn "$(tr_text option_out_of_range) [0-$(( ${#actions[@]} ))]"
          sleep 1
        fi
        ;;
    esac
  done
}
pause() {
  local dummy=""
  ask_line "$(tr_text press_enter)" dummy
}
# External helper tools (ArgoX / sba / TCP brutal). These are separate
# small projects; the installer downloads and runs them on demand, the
# same way a user would run them by hand. They are optional.
# $L is the current language (E/C), passed through as -$L.
run_external_tool() {
  local kind="$1"
  case "$kind" in
    argox)
      bash <(wget --no-check-certificate -qO- https://raw.githubusercontent.com/fscarmen/argox/main/argox.sh) "-${LANG_CODE}" || msg_warn "ArgoX helper download failed."
      ;;
    sba)
      bash <(wget --no-check-certificate -qO- https://raw.githubusercontent.com/fscarmen/sba/main/sba.sh) "-${LANG_CODE}" || msg_warn "sba helper download failed."
      ;;
    hy2)
      bash <(wget --no-check-certificate -qO- https://tcp.hy2.sh/) || msg_warn "TCP brutal helper download failed."
      ;;
  esac
  pause
}
# ---------------------------------------------------------------------------
# 21. Config file (-f) and command line parsing
# ---------------------------------------------------------------------------
# A config file is a simple KEY=VALUE file, one per line. Keys are the
# WIZ_* names without the prefix, e.g. START_PORT=8881, UUID=..., or
# the long option names in upper case.
load_config_file() {
  local file="$1" key val
  [ -s "$file" ] || return 1
  while IFS='=' read -r key val; do
    key="$(printf '%s' "$key" | tr -d ' \r')"
    val="$(printf '%s' "$val" | tr -d '\r' | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")"
    case "$key" in
      ''|\#*) continue ;;
      CHOOSE_PROTOCOLS) WIZ_PROTOCOLS="$val" ;;
      START_PORT) WIZ_START_PORT="$val" ;;
      PORT_NGINX) WIZ_NGINX_PORT="$val" ;;
      SERVER_IP) WIZ_SERVER_ADDR="$val" ;;
      CDN) WIZ_CDN="$val" ;;
      UUID|UUID_CONFIRM) WIZ_UUID="$val" ;;
      NODE_NAME|NODE_NAME_CONFIRM) WIZ_NODE_NAME="$val" ;;
      SUBSCRIBE) parse_subscribe_value "$val" ;;
      ARGO) case "${val,,}" in true|y|yes|1) WIZ_ARGO="try" ;; false|n|no|0) WIZ_ARGO="no" ;; esac ;;
      ARGO_DOMAIN) WIZ_ARGO_DOMAIN="$val" ;;
      ARGO_AUTH) WIZ_ARGO_AUTH="$val" ;;
      HY2_PORT_HOPPING_RANGE) WIZ_HY2_HOP="${val//-/:}" ;;
      HY2_REALM|REALM) case "${val,,}" in true|1|y|yes) WIZ_HY2_REALM="yes" ;; *) WIZ_HY2_REALM="no" ;; esac ;;
      BIND_INTERFACE) WIZ_BIND_IFACE="$val" ;;
      REALITY_PRIVATE) WIZ_REALITY_PRIV="$val" ;;
      LANGUAGE) case "${val^^}" in C*) LANG_CODE="C" ;; *) LANG_CODE="E" ;; esac; LANG_PRESET=1 ;;
    esac
  done < "$file"
  QUIET_INSTALL=1
}
parse_subscribe_value() {
  case "${1,,}" in
    dynamic) WIZ_SUBSCRIBE="dynamic" ;;
    true|y|yes|1) WIZ_SUBSCRIBE="yes" ;;
    false|n|no|0) WIZ_SUBSCRIBE="no" ;;
    *) WIZ_SUBSCRIBE="yes" ;;
  esac
}
show_help() {
  cat <<'EOF'
Usage: sing-box.sh [options]

`sb` and `cj` are the same shortcut: both open the menu, and both
take the same arguments (`cj -n`, `cj -d`, `cj -s`, ...).

Interactive:
  (no options)        Open the menu (language, install or manage)
                      v1.0.5: on first run, if the sing-box core is
                      missing it is auto-installed (core + cloudflared
                      only, no protocols), and an empty install state
                      is created, then the installed menu (1-12) is
                      shown; add protocols from menu 8. Menu 8 now
                      enables + starts sing-box after saving, and
                      auto-enables the nginx subscription, so added
                      nodes listen and the /sub link opens.
                      v1.0.6: menu 8 asks for an Argo tunnel when CF
                      protocols are added (try / token / none); a try
                      tunnel's domain is resolved and matched to the
                      CF node links (tunnel domain on 443). nginx is
                      started safely (a stale master on 8080 is
                      reloaded first). `sb` / `cj` remember the last
                      language and go straight to the menu.
                      v1.0.8: menu 8 can install all protocols at
                      once — type 'all' at the add-protocols step to
                      add every uninstalled protocol (already
                      installed ones are kept); a single 'a' still
                      means only the first uninstalled protocol.
                      v1.0.9: CF node links fixed (Trojan/VMess gRPC
                      now use the Argo tunnel domain on 443 like the
                      other CF protocols; Shadowsocks 2022 is
                      direct-only); nginx now reverse-proxies
                      HTTPUpgrade and gRPC too, and a running nginx
                      is always reloaded after the config is written
                      so /sub opens. `cj` / `sb` are created before
                      the language prompt, default to Chinese and go
                      straight to the menu; a failed re-download
                      prints a clear error instead of silently
                      doing nothing.
                      v1.0.10: Shadowsocks 2022 AES-256 drops the
                      (CF) label and moves after the CF group (now
                      no. 20, direct-only); VLESS / VMess / Trojan
                      + HTTP move up to 17 / 18 / 19. Machines
                      upgraded from an older version must re-pick
                      protocols in menu 8, because the saved
                      protocol numbers 16-19 have shifted.
                      v1.0.11: firewall UDP allow list fixed
                      (was 1|3|5|15, all TCP-only; now
                      0|4|7|9|19|23: Hysteria2, TUIC,
                      Shadowsocks, Snell v6, Shadowsocks 2022
                      AES-256, Shadowsocks 2022). Re-sync the
                      firewall after upgrading.
                      v1.0.13: the `http2` flag is removed from the
                      nginx listen sockets on 8080 (a v1.0.9
                      regression). An http2-only socket made plain
                      HTTP/1.1 requests to /sub come back as
                      "HTTP/0.9", so clients could not sync the
                      subscription at all. gRPC still goes through
                      `grpc_pass grpcs://` to the inbound.
                      Menu 8 can now remove all installed protocols
                      at once: type `all` at the remove step
                      (a single `a` still removes only the first
                      one); the confirm step still applies.
                      v1.0.14: 8 protocols are removed (19 left):
                      ShadowTLS, Naive, Snell v6, VLESS +
                      HTTPUpgrade, Trojan + gRPC, VMess + gRPC,
                      VLESS + HTTP, VMess + HTTP — all timed out
                      in user tests (CF gRPC is officially
                      unsupported over a public tunnel hostname;
                      CF HTTP transport is fragile; ShadowTLS
                      handshake fails; Naive needs a client that
                      skips cert verification; Snell v6 needs a
                      v6 client). CF links now use the CDN
                      preferred domain as the server address with
                      SNI / Host = Argo tunnel domain, and
                      VLESS + TCP + TLS carries allowInsecure=1.
                      Machines upgraded from an older version
                      must re-pick protocols in menu 8, because
                      the saved protocol numbers have shifted.

Short options:
  -s                  Toggle sing-box service
  -a                  Toggle Argo service
  -t                  Change Argo settings
  -d                  Change configuration
  -u                  Uninstall
  -n                  Show node links
  -v                  Sync Sing-box and Argo to the latest version
  --update-script       Upgrade the script itself to the latest version
  -b                  Upgrade kernel, install BBR, DD script
  -r                  Add / remove protocols
  --sync-argo           Sync the Argo tunnel domain and re-export
                        the subscription (used by the 5-minute timer)
  -E                  English messages
  -C                  Chinese messages (简体中文)
  -K                  Quick install (all protocols, defaults)
  -L                  Quick install, Chinese messages
  -f FILE             Load answers from a KEY=VALUE config file
  -F FILE             Same as -f
  -h, --help          Show this help

Long options (non-interactive install):
  --LANGUAGE en|zh
  --CHOOSE_PROTOCOLS a|b c ...
  --START_PORT 8881
  --PORT_NGINX 8080
  --SERVER_IP 1.2.3.4
  --CDN skk.moe
  --UUID_CONFIRM <uuid>
  --NODE_NAME_CONFIRM <name>
  --SUBSCRIBE yes|no|dynamic
  --ARGO true|false
  --ARGO_DOMAIN example.com
  --ARGO_AUTH <token or json>
  --HY2_PORT_HOPPING_RANGE 20000:21000
  --HY2_REALM true|false
  --BIND_INTERFACE eth0
  --REALITY_PRIVATE <private key>

Examples:
  One-liner install (menu, choose yourself):
    bash <(wget -qO- https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh)
  One-liner quick install, English (all protocols, defaults):
    bash <(wget -qO- https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh) -K
  One-liner quick install, Chinese:
    bash <(wget -qO- https://raw.githubusercontent.com/caoj8898-tech/jiaoben/main/sing-box.sh) -L
  (The repo must be public for the link above to work; a private repo returns 404.)
  bash sing-box.sh -K
  bash sing-box.sh --CHOOSE_PROTOCOLS b --START_PORT 8881 --SERVER_IP 1.2.3.4
  bash sing-box.sh -f /root/install.conf
EOF
}
# Parse arguments. Sets globals and, for action flags, runs the action
# and exits. Install flags fall through to the menu / install logic.
parse_args() {
  local i=0
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) show_help; exit 0 ;;
      -E) LANG_CODE="E"; LANG_PRESET=1 ;;
      -C|-B) LANG_CODE="C"; LANG_PRESET=1 ;;
      -L) LANG_CODE="C"; LANG_PRESET=1; FAST_INSTALL=1 ;;
      -K) FAST_INSTALL=1 ;;
      -s) refresh_status; toggle_service sing-box "Sing-box"; exit 0 ;;
      -a) refresh_status; toggle_service argo "Argo"; exit 0 ;;
      -t) change_argo_menu; exit 0 ;;
      -d) change_config_menu; exit 0 ;;
      -u) QUIET_INSTALL=1; run_uninstall; exit 0 ;;
      -n) export_list; exit 0 ;;
      -v) show_version; exit 0 ;;
      --update-script) update_script; exit 0 ;;
      -b) run_speed_test; exit 0 ;;
      -r) change_protocols_menu; exit 0 ;;
      --sync-argo) sync_argo_domain; exit 0 ;;
      -f|-F) shift; CONFIG_FILE="${1:-}"; [ -n "$CONFIG_FILE" ] && load_config_file "$CONFIG_FILE" ;;
      --LANGUAGE) shift; case "${1^^}" in C*) LANG_CODE="C" ;; *) LANG_CODE="E" ;; esac; LANG_PRESET=1 ;;
      --LANGUAGE=*) case "${1#*=}" in C*|c*) LANG_CODE="C" ;; *) LANG_CODE="E" ;; esac; LANG_PRESET=1 ;;
      --CHOOSE_PROTOCOLS) shift; WIZ_PROTOCOLS="$1"; QUIET_INSTALL=1 ;;
      --CHOOSE_PROTOCOLS=*) WIZ_PROTOCOLS="${1#*=}"; QUIET_INSTALL=1 ;;
      --START_PORT) shift; WIZ_START_PORT="$1" ;;
      --START_PORT=*) WIZ_START_PORT="${1#*=}" ;;
      --PORT_NGINX) shift; WIZ_NGINX_PORT="$1" ;;
      --PORT_NGINX=*) WIZ_NGINX_PORT="${1#*=}" ;;
      --SERVER_IP) shift; WIZ_SERVER_ADDR="$1" ;;
      --SERVER_IP=*) WIZ_SERVER_ADDR="${1#*=}" ;;
      --VMESS_HOST_DOMAIN|--VLESS_HOST_DOMAIN) shift; WIZ_CDN="$1" ;;
      --CDN) shift; WIZ_CDN="$1" ;;
      --CDN=*) WIZ_CDN="${1#*=}" ;;
      --UUID_CONFIRM) shift; WIZ_UUID="$1" ;;
      --UUID_CONFIRM=*) WIZ_UUID="${1#*=}" ;;
      --NODE_NAME_CONFIRM)
        shift
        local names=()
        while [ $# -gt 0 ] && [[ "$1" != -* ]]; do names+=("$1"); shift; done
        WIZ_NODE_NAME="${names[*]}"
        # The while loop stopped on the next flag (or end of args).
        # Continue without the outer shift so that flag is processed
        # normally on the next iteration.
        continue
        ;;
      --SUBSCRIBE) shift; parse_subscribe_value "$1" ;;
      --SUBSCRIBE=*) parse_subscribe_value "${1#*=}" ;;
      --ARGO) shift; case "${1,,}" in true|y|yes|1) WIZ_ARGO="try" ;; false|n|no|0) WIZ_ARGO="no" ;; esac ;;
      --ARGO=*) case "${1#*=}" in true|y|yes|1) WIZ_ARGO="try" ;; *) WIZ_ARGO="no" ;; esac ;;
      --ARGO_DOMAIN) shift; WIZ_ARGO_DOMAIN="$1" ;;
      --ARGO_DOMAIN=*) WIZ_ARGO_DOMAIN="${1#*=}" ;;
      --ARGO_AUTH) shift; WIZ_ARGO_AUTH="$1" ;;
      --ARGO_AUTH=*) WIZ_ARGO_AUTH="${1#*=}" ;;
      --HY2_PORT_HOPPING_RANGE) shift; WIZ_HY2_HOP="${1//-/:}" ;;
      --HY2_PORT_HOPPING_RANGE=*) WIZ_HY2_HOP="${1#*=}"; WIZ_HY2_HOP="${WIZ_HY2_HOP//-/:}" ;;
      --HY2_REALM|--REALM) shift; case "${1,,}" in true|1|y|yes) WIZ_HY2_REALM="yes" ;; *) WIZ_HY2_REALM="no" ;; esac ;;
      --HY2_REALM=*|--REALM=*) case "${1#*=}" in true|1|y|yes) WIZ_HY2_REALM="yes" ;; *) WIZ_HY2_REALM="no" ;; esac ;;
      --BIND_INTERFACE) shift; WIZ_BIND_IFACE="$1"; [ "${WIZ_BIND_IFACE,,}" = "default" ] && WIZ_BIND_IFACE="" ;;
      --BIND_INTERFACE=*) WIZ_BIND_IFACE="${1#*=}" ;;
      --REALITY_PRIVATE) shift; WIZ_REALITY_PRIV="$1" ;;
      --REALITY_PRIVATE=*) WIZ_REALITY_PRIV="${1#*=}" ;;
      -U|--uninstall) QUIET_INSTALL=1; run_uninstall; exit 0 ;;
      *) msg_warn "Unknown option: $1 (use --help)"; ;;
    esac
    shift
    i=$((i + 1))
    [ "$i" -gt 200 ] && break
  done
}
# ---------------------------------------------------------------------------
# 22. Entry point
# ---------------------------------------------------------------------------
main() {
  # -U anywhere means uninstall, even before language selection.
  case " $* " in
    *" -U "*|*" -u "*) : ;;
  esac
  # v1.0.6: `sb` / `cj` remember the last language, so they go
  # straight to the menu instead of asking again. A saved language
  # is only a default: -E / -C / --LANGUAGE in parse_args still
  # override it, and single-action flags (sb -n, cj -d, ...) use it too.
  if [ -s "${SB_HOME}/lang" ]; then
    local _saved_lang=""
    _saved_lang="$(cat "${SB_HOME}/lang" 2>/dev/null || true)"
    case "$_saved_lang" in E|C) LANG_CODE="$_saved_lang"; LANG_PRESET=1 ;; esac
  fi
  # v1.0.9: invoked via `sb` / `cj` with no saved language and no
  # explicit flag: default to Chinese and go straight to the menu.
  # The old behaviour asked for a language on every first run, so
  # `cj` looked like it did nothing -- it was sitting at a language
  # prompt the user did not expect. Explicit -E / -C / --LANGUAGE
  # in parse_args() still override this default.
  if [ "${SB_VIA_SHORTCUT:-0}" = "1" ] && [ "${LANG_PRESET:-0}" != "1" ]; then
    LANG_CODE="C"; LANG_PRESET=1
  fi
  parse_args "$@"
  require_root
  detect_os
  detect_arch
  # v1.0.19: make sure qrencode exists so the subscription QR code
  # shows on a fresh server without a manual install. Best-effort;
  # a failed install never aborts the script.
  ensure_qrencode || true
  # v1.0.9: create sb/cj BEFORE the language prompt. The old code
  # only created them right before main_menu(), so if the user
  # exited at the language prompt (or the script died earlier),
  # `cj` never existed at all. Creating them here costs nothing
  # (create_shortcut is idempotent) and guarantees they exist
  # after even a single interrupted one-liner run.
  create_shortcut
  pick_language
  # Remember the language for the next `sb` / `cj` run.
  mkdir -p "$SB_HOME" 2>/dev/null || true
  printf '%s\n' "$LANG_CODE" > "${SB_HOME}/lang" 2>/dev/null || true
  msg_info "$(tr_text checking_system)"
  detect_public_ip
  refresh_status
  # Non-interactive install: --CHOOSE_PROTOCOLS or a config file.
  if [ "$QUIET_INSTALL" = "1" ] && [ -n "$WIZ_PROTOCOLS" ]; then
    apply_quiet_defaults
    run_install
    exit 0
  fi
  if [ "$FAST_INSTALL" = "1" ]; then
    apply_quiet_defaults
    WIZ_SUBSCRIBE="yes"
    WIZ_ARGO="try"
    run_install
    exit 0
  fi
  # v1.0.3: first-run core auto-install (sing-box binary +
  # cloudflared only, no protocols). Runs once on the interactive
  # menu path; quick installs and single-action flags have already
  # exited above. Failure only warns / stays in the uninstalled menu.
  ensure_core_installed || true
  refresh_status
  # v1.0.2: create sb/cj before showing the menu, whether installed
  # or not. Previously create_shortcut() only ran inside run_install(),
  # so `cj` did not exist at all on a fresh machine.
  create_shortcut
  main_menu
}
main "$@"
