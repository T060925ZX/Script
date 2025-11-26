#!/bin/bash

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测IP是否在国内
check_ip_in_china() {
    log_info "正在检测网络环境..."
    
    # 使用多个API进行检测，提高准确性
    local apis=(
        "http://ip-api.com/json/?fields=countryCode"
        "https://api.ip.sb/geoip"
        "https://ipinfo.io/json"
    )
    
    for api in "${apis[@]}"; do
        local response
        response=$(curl -s --connect-timeout 5 "$api" 2>/dev/null)
        
        if [[ -n "$response" ]]; then
            # 检查响应中是否包含中国相关信息
            if echo "$response" | grep -qiE "CN|China|中国"; then
                log_info "检测到国内网络环境"
                return 0
            elif echo "$response" | grep -qiE "HK|Hong Kong|TW|Taiwan|MO|Macao"; then
                log_info "检测到港澳台网络环境，使用镜像站"
                return 0
            fi
        fi
    done
    
    log_info "检测到国外网络环境"
    return 1
}

# 设置GitHub镜像
setup_github_mirror() {
    if check_ip_in_china; then
        log_info "设置GitHub镜像源..."
        export GITHUB_PROXY="https://hubproxy.jiaozi.live/"
    else
        export GITHUB_PROXY=""
    fi
}

# 检测系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
            log_info "检测到系统: $NAME $VERSION_ID"
            return 0
        else
            log_error "不支持的系统: $ID"
            return 1
        fi
    else
        log_error "无法检测系统类型"
        return 1
    fi
}

# 执行国内特定脚本
run_china_specific_script() {
    if check_ip_in_china && detect_os; then
        log_info "执行国内优化脚本..."
        // bash <(curl -sSL https://linuxmirrors.cn/main.sh)
    fi
}

# 安装基础软件包
install_packages() {
    log_info "开始安装基础软件包..."
    
    # 更新包列表
    sudo apt update
    
    # 要安装的软件包列表
    local packages=("jq" "fish" "curl" "gnupg" "git" "ffmpeg")
    
    # 检查并安装valkey或redis
    if apt-cache show valkey-server &>/dev/null; then
        log_info "安装Valkey-server..."
        sudo apt install -y valkey-server
    elif apt-cache show redis-server &>/dev/null; then
        log_info "安装Redis-server..."
        sudo apt install -y redis-server
    else
        log_warn "未找到Valkey或Redis安装包"
    fi
    
    # 安装其他软件包
    for pkg in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            log_info "$pkg 已安装，跳过"
        else
            log_info "安装 $pkg..."
            sudo apt install -y "$pkg"
        fi
    done
}

# 安装Node.js
install_nodejs() {
    log_info "安装Node.js 24.x..."
    
    # 添加NodeSource仓库
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt install -y nodejs
    
    # 验证安装
    node --version
    npm --version
}

# 安装npm全局包
install_npm_global() {
    log_info "安装npm全局包..."
    
    local packages=("pnpm" "pm2" "yarn")
    
    for pkg in "${packages[@]}"; do
        if npm list -g | grep -q "$pkg"; then
            log_info "$pkg 已安装，跳过"
        else
            log_info "安装 $pkg..."
            sudo npm install -g "$pkg"
        fi
    done
}

# 安装字体
install_fonts() {
    log_info "安装字体..."
    sudo apt install -y fonts-noto-cjk fonts-noto-color-emoji
}

# 克隆Yunzai项目
clone_yunzai() {
    log_info "克隆Yunzai项目..."
    
    if [ -d "Yunzai" ]; then
        log_warn "Yunzai目录已存在，跳过克隆"
        return
    fi
    
    if check_ip_in_china; then
        git clone --depth 1 https://gitee.com/TimeRainStarSky/Yunzai
    else
        git clone --depth 1 https://gitee.com/TimeRainStarSky/Yunzai
    fi
}

# 安装Chromium
install_chromium() {
    if detect_os; then
        log_info "安装Chromium..."
        
        local script_url
        if check_ip_in_china; then
            script_url="https://hubproxy.jiaozi.live/https://raw.githubusercontent.com/T060925ZX/Script/refs/heads/main/Script.sh"
        else
            script_url="https://raw.githubusercontent.com/T060925ZX/Script/refs/heads/main/Script.sh"
        fi
        
        bash <(curl -s "$script_url")
    fi
}

# 安装Yunzai CLI
install_yunzai_cli() {
    log_info "安装Yunzai CLI..."
    
    local cli_url
    if check_ip_in_china; then
        cli_url="https://hubproxy.jiaozi.live/https://raw.githubusercontent.com/T060925ZX/Script/refs/heads/main/yz-cli"
    else
        cli_url="https://raw.githubusercontent.com/T060925ZX/Script/refs/heads/main/yz-cli"
    fi
    
    sudo wget "$cli_url" -O /usr/local/bin/yz
    sudo chmod +x /usr/local/bin/yz
    
    log_info "Yunzai CLI 安装完成"
}

# 安装Yunzai依赖
install_yunzai_deps() {
    log_info "安装Yunzai依赖..."
    
    if [ ! -d "Yunzai" ]; then
        log_error "Yunzai目录不存在，请先克隆项目"
        return 1
    fi
    
    cd Yunzai || {
        log_error "无法进入Yunzai目录"
        return 1
    }
    
    log_info "当前目录: $(pwd)"
    log_info "开始安装依赖..."
    
    # 使用pnpm安装依赖
    pnpm i
    
    local result=$?
    if [ $result -eq 0 ]; then
        log_info "Yunzai依赖安装完成"
    else
        log_error "Yunzai依赖安装失败，退出码: $result"
        return $result
    fi
    
    # 返回原目录
    cd - > /dev/null
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}使用方法: yz [命令]${NC}"
    echo ""
    echo "可用命令:"
    echo "  start    - 启动 TRSS-Yunzai"
    echo "  stop     - 停止 TRSS-Yunzai"
    echo "  restart  - 重启 TRSS-Yunzai"
    echo "  log      - 查看实时日志"
    echo "  status   - 查看运行状态"
    echo "  del      - 从 PM2 中删除 TRSS-Yunzai"
    echo "  help     - 显示此帮助信息"
}

# 主函数
main() {
    log_info "开始执行安装脚本..."
    
    # 设置GitHub镜像
    setup_github_mirror
    
    # 检测系统类型
    if ! detect_os; then
        log_error "脚本仅支持Debian/Ubuntu系统"
        exit 1
    fi
    
    # 执行国内特定脚本
    run_china_specific_script
    
    # 安装基础软件包
    install_packages
    
    # 安装Node.js
    install_nodejs
    
    # 安装npm全局包
    install_npm_global
    
    # 安装字体
    install_fonts
    
    # 克隆Yunzai项目
    clone_yunzai
    
    # 安装Chromium
    install_chromium
    
    # 安装Yunzai CLI
    install_yunzai_cli

    # 安装依赖
    install_yunzai_deps
    
    # 显示帮助信息
    show_help
    
    log_info "安装完成！"
    log_info "可以使用 'yz help' 查看可用命令"
}

# 执行主函数
main "$@"
