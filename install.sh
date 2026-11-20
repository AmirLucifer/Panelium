#!/bin/sh
# Panelium offline installer and management menu.
# Required files: this script and one adjacent executable named `panelium`,
# `Panelium`, or `panelium.bin`. The executable carries every package, engine,
# migration, unit, and helper required by the network-free installation.

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

adjacent_binary()
{
    if [ -n "${PANELIUM_BINARY:-}" ]; then
        candidate=$PANELIUM_BINARY
        case "$candidate" in
            /*) ;;
            *) candidate=$script_dir/$candidate ;;
        esac
        if [ -f "$candidate" ] && [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
        printf '%s\n' "PANELIUM_BINARY is not an executable file: $candidate" >&2
        return 1
    fi
    for name in panelium Panelium panelium.bin; do
        candidate=$script_dir/$name
        if [ -f "$candidate" ] && [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    printf '%s\n' "Place the Panelium binary next to this script." >&2
    return 1
}

installer_binary=$(adjacent_binary)

runtime_binary()
{
    if [ -n "${PANELIUM_RUNTIME_BINARY:-}" ]; then
        if [ ! -f "$PANELIUM_RUNTIME_BINARY" ] || [ ! -x "$PANELIUM_RUNTIME_BINARY" ]; then
            printf '%s\n' "PANELIUM_RUNTIME_BINARY is not executable: $PANELIUM_RUNTIME_BINARY" >&2
            return 1
        fi
        printf '%s\n' "$PANELIUM_RUNTIME_BINARY"
    elif [ -x /usr/local/bin/Panelium ]; then
        printf '%s\n' /usr/local/bin/Panelium
    else
        printf '%s\n' "$installer_binary"
    fi
}

require_root()
{
    if [ "$(id -u)" -ne 0 ]; then
        printf '%s\n' "Panelium installation and service changes require root." >&2
        exit 1
    fi
}

usage()
{
    cat <<'EOF'
Usage: ./panelium-install.sh [command] [options]

Commands:
  install [--skip-telegram] [--skip-setup]
      Install exclusively from the payload embedded in the adjacent binary.
  setup [--skip-telegram]
      Configure Panel Settings and administrator credentials.
  reset-admin
      Change the primary administrator username and password as root.
  enable       Enable and start the Panelium web service and gateway.
  disable      Stop and disable the Panelium web service and gateway.
  restart      Restart the Panelium web service and gateway.
  status       Show Panelium service and engine status.
  logs [target] [lines]
      Show journal output for panel/gateway/openvpn/wireguard/xray/l2tp/ipsec/sstp.
      Target defaults to panel and line count defaults to 100.
  backup [output]
      Create a checksum-protected PostgreSQL custom archive. If output is
      omitted, Panelium writes a timestamped archive under its backup folder.
  restore <archive> [--yes]
      Validate and transactionally restore a PostgreSQL custom archive.
  remove [--yes]
      Remove Panelium after preserving a PostgreSQL backup under /root.
  tls [status|issue <v2ray|sstp> <hostname>]
      Inspect TLS configuration, or issue or renew a VPN core certificate.
  menu         Open the interactive 3x-ui-style management menu.
EOF
}

install_panelium()
{
    require_root
    skip_telegram=false
    skip_setup=false
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --skip-telegram) skip_telegram=true ;;
            --skip-setup) skip_setup=true ;;
            *) printf '%s\n' "Unknown install option: $1" >&2; exit 2 ;;
        esac
        shift
    done
    # Keep Ubuntu's APT hook from restarting unrelated services during offline install.
    NEEDRESTART_SUSPEND=1 "$installer_binary" install || return $?
    if ! $skip_setup; then
        if $skip_telegram; then
            /usr/local/bin/Panelium setup --skip-telegram || return $?
        else
            /usr/local/bin/Panelium setup || return $?
        fi
        printf '%s\n' 'Starting Panelium services...'
        /usr/local/bin/Panelium enable || return $?
        printf '%s\n' 'Panelium is ready.'
    fi
}

setup_panelium()
{
    require_root
    case "${1:-}" in
        "") "$(runtime_binary)" setup ;;
        --skip-telegram) "$(runtime_binary)" setup --skip-telegram ;;
        *) printf '%s\n' "Unknown setup option: $1" >&2; exit 2 ;;
    esac
}

reset_admin()
{
    require_root
    if [ "$#" -ne 0 ]; then
        printf '%s\n' 'Usage: ./panelium-install.sh reset-admin' >&2
        return 2
    fi
    # The adjacent binary also supports recovering an older Panelium installation.
    "$installer_binary" reset-admin
}

remove_panelium()
{
    require_root
    case "${1:-}" in
        "") "$(runtime_binary)" remove ;;
        --yes) "$(runtime_binary)" remove --yes ;;
        *) printf '%s\n' "Unknown remove option: $1" >&2; exit 2 ;;
    esac
}

backup_panelium()
{
    require_root
    case "$#" in
        0) "$(runtime_binary)" backup ;;
        1) "$(runtime_binary)" backup --output "$1" ;;
        *) printf '%s\n' 'Usage: ./panelium-install.sh backup [output]' >&2; exit 2 ;;
    esac
}

restore_panelium()
{
    require_root
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        printf '%s\n' 'Usage: ./panelium-install.sh restore <archive> [--yes]' >&2
        exit 2
    fi
    archive=$1
    case "${2:-}" in
        "") "$(runtime_binary)" restore "$archive" ;;
        --yes) "$(runtime_binary)" restore "$archive" --yes ;;
        *) printf '%s\n' 'Usage: ./panelium-install.sh restore <archive> [--yes]' >&2; exit 2 ;;
    esac
}

manage_tls()
{
    require_root
    case "${1:-menu}" in
        status)
            runuser -u postgres -- psql -XAt -d panelium -c \
                "SELECT format('Panel HTTPS: %s | Host: %s | TLS port: %s | Certificate: %s', https_enabled, public_hostname, https_port, certificate_path) FROM panelium.panel_settings WHERE singleton" || return $?
            certbot certificates --non-interactive || return $?
            systemctl list-timers --all certbot.timer
            ;;
        issue)
            if [ "$#" -ne 3 ]; then
                printf '%s\n' 'Usage: ./install.sh tls issue <v2ray|sstp> <hostname>' >&2
                return 2
            fi
            /opt/panelium/bin/panelium-issue-core-cert --protocol "$2" --hostname "$3"
            ;;
        menu)
            while :; do
                printf '\n%s\n' 'TLS certificates' '1. Certificate status and renewal schedule' \
                    '2. Issue or renew a VPN core certificate' '3. Configure panel HTTPS' '0. Back'
                printf 'TLS selection: '
                IFS= read -r selection || return 0
                case "$selection" in
                    1) manage_tls status || printf '%s\n' 'Certificate status could not be read.' >&2 ;;
                    2)
                        printf 'Core (v2ray/sstp): '
                        IFS= read -r protocol || return 0
                        printf 'Certificate hostname: '
                        IFS= read -r hostname || return 0
                        manage_tls issue "$protocol" "$hostname" || printf '%s\n' 'Certificate issuance did not complete.' >&2
                        ;;
                    3) setup_panelium || printf '%s\n' 'Panel HTTPS setup did not complete.' >&2 ;;
                    0) return 0 ;;
                    *) printf '%s\n' 'Invalid TLS selection.' >&2 ;;
                esac
            done
            ;;
        *) printf '%s\n' 'Use tls, tls status or tls issue.' >&2; return 2 ;;
    esac
}

show_menu()
{
    while :; do
        cat <<'EOF'

╔══════════════════════════════════════╗
║          Panelium AIO VPN PANEL      ║
╠══════════════════════════════════════╣
║  1. Install                          ║
║  2. Setup / reconfigure              ║
║  3. Enable panel                     ║
║  4. Disable panel                    ║
║  5. Restart panel                    ║
║  6. Status                           ║
║  7. Logs                             ║
║  8. Backup database                  ║
║  9. Restore database                 ║
║ 10. Remove                           ║
║ 11. TLS certificates                 ║
║ 12. Change administrator login       ║
║  0. Exit                             ║
╚══════════════════════════════════════╝
EOF
        printf 'Selection: '
        IFS= read -r selection
        case "$selection" in
            1) install_panelium || printf '%s\n' 'Installation did not complete. Review the error before retrying.' >&2 ;;
            2) setup_panelium ;;
            3) require_root; "$(runtime_binary)" enable ;;
            4) require_root; "$(runtime_binary)" disable ;;
            5) require_root; "$(runtime_binary)" restart ;;
            6) "$(runtime_binary)" status ;;
            7) "$(runtime_binary)" service panel logs --lines 100 ;;
            8) backup_panelium ;;
            9)
                printf 'Backup archive path: '
                IFS= read -r archive
                restore_panelium "$archive"
                ;;
            10) remove_panelium ;;
            11) manage_tls ;;
            12) reset_admin || printf '%s\n' 'Administrator login was not changed.' >&2 ;;
            0) exit 0 ;;
            *) printf '%s\n' 'Invalid selection.' >&2 ;;
        esac
    done
}

command=${1:-menu}
if [ "$#" -gt 0 ]; then
    shift
fi
case "$command" in
    install) install_panelium "$@" ;;
    setup) setup_panelium "$@" ;;
    reset-admin) reset_admin "$@" ;;
    enable) require_root; "$(runtime_binary)" enable ;;
    disable) require_root; "$(runtime_binary)" disable ;;
    restart) require_root; "$(runtime_binary)" restart ;;
    status) "$(runtime_binary)" status ;;
    logs)
        target=${1:-panel}
        lines=${2:-100}
        case "$target" in
            panel|gateway|openvpn|wireguard|xray|l2tp|ipsec|sstp) ;;
            *) printf '%s\n' 'Unknown Panelium log target.' >&2; exit 2 ;;
        esac
        case "$lines" in
            ''|*[!0-9]*) printf '%s\n' 'Log line count must be numeric.' >&2; exit 2 ;;
        esac
        "$(runtime_binary)" service "$target" logs --lines "$lines"
        ;;
    backup) backup_panelium "$@" ;;
    restore) restore_panelium "$@" ;;
    tls) manage_tls "$@" ;;
    remove|uninstall) remove_panelium "$@" ;;
    menu) show_menu ;;
    -h|--help|help) usage ;;
    *) usage >&2; exit 2 ;;
esac
