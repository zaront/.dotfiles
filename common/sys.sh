################
# System Info
################

# source only once
[ -n "$_sys_sourced" ] && return 0
_sys_sourced=1


get_system_info() {
    # validate 
    [ ! -z "${ENVIRONMENT}" ] && return 0

    _sys_info=$(
        uname -a
        [ -f /etc/os-release ] && cat /etc/os-release
        [ -f /proc/version ] && cat /proc/version
    )
    case "$_sys_info" in
        *WSL2*|*microsoft*) ENVIRONMENT="wsl2" ;;
        *termux*|*Android*|*android*) ENVIRONMENT="termux" ;;
        *) ENVIRONMENT="metal" ;;
    esac
    case "$_sys_info" in
        *proot*|*PROOT*|*PRoot*) CONTAINER="proot" ;;
        *) CONTAINER="none" ;;
    esac
    [ -f /.dockerenv ] && CONTAINER="docker"
    ARCH=$(uname -m)
    OS=$(echo "$_sys_info" | sed -n 's/^ID=//p' | tr -d '"'\')
    VERSION=$(echo "$_sys_info" | sed -n 's/^VERSION_ID=//p' | tr -d '"'\')
}
