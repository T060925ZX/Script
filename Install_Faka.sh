#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印彩色信息
echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查并安装git
check_and_install_git() {
    if ! command -v git &> /dev/null; then
        echo_warn "Git未安装，正在安装..."
        
        if [ -f /etc/redhat-release ]; then
            yum update -y && yum install -y git
        elif [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
            apt-get update && apt-get install -y git
        else
            echo_error "无法识别的系统类型，请手动安装git"
            exit 1
        fi
        
        if command -v git &> /dev/null; then
            echo_info "Git安装成功"
        else
            echo_error "Git安装失败，请手动安装"
            exit 1
        fi
    else
        echo_info "Git已安装"
    fi
}

# 通过ping谷歌判断服务器是否在国内
check_server_location() {
    echo_info "正在检测服务器地理位置..."
    if ping -c 2 -W 2 www.google.com &> /dev/null; then
        echo_info "服务器在国外"
        return 1
    else
        echo_info "服务器在国内"
        return 0
    fi
}

# 下载完整项目
download_full_project() {
    local temp_dir="/tmp/acg-faka"
    
    # 清理临时目录
    if [ -d "$temp_dir" ]; then
        echo_info "清理临时目录..."
        rm -rf "$temp_dir"
    fi
    
    # 下载项目
    if check_server_location; then
        echo_info "使用镜像下载完整项目..."
        # 修正镜像URL - 直接使用镜像代理的完整URL
        git clone "https://hubproxy.jiaozi.live/https://github.com/lizhipay/acg-faka.git" "$temp_dir"
    else
        echo_info "直接下载完整项目..."
        git clone "https://github.com/lizhipay/acg-faka.git" "$temp_dir"
    fi
    
    if [ $? -ne 0 ] || [ ! -d "$temp_dir" ]; then
        echo_error "项目下载失败"
        exit 1
    fi
    
    echo_info "项目下载完成"
}

# 显示版本列表并让用户选择
select_version() {
    local temp_dir="/tmp/acg-faka"
    
    if [ ! -d "$temp_dir" ]; then
        echo_error "项目目录不存在"
        exit 1
    fi
    
    cd "$temp_dir" || exit 1
    
    echo_info "正在获取版本列表..."
    echo ""
    echo "=========================================="
    echo "           可用的版本列表"
    echo "=========================================="
    
    # 获取版本列表
    local count=0
    echo_info "最近版本:"
    git log --oneline -20 | grep -E "[0-9]+\.[0-9]+\.[0-9]+" | while read -r line; do
        commit_hash=$(echo "$line" | awk '{print $1}')
        message=$(echo "$line" | cut -d' ' -f2-)
        version=$(echo "$message" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
        if [ -n "$version" ]; then
            printf "%-10s %-40s %s\n" "$version" "$commit_hash" "$message"
            ((count++))
        fi
    done
    
    # 如果没有找到版本，显示所有commit
    if [ $count -eq 0 ]; then
        echo_info "所有commit:"
        git log --oneline -20 | head -10 | while read -r line; do
            commit_hash=$(echo "$line" | awk '{print $1}')
            message=$(echo "$line" | cut -d' ' -f2-)
            printf "%-10s %-40s %s\n" "latest" "$commit_hash" "$message"
        done
    fi
    
    echo "=========================================="
    echo ""
    
    # 用户选择
    read -p "请输入要部署的版本号（例如：3.1.0）: " selected_version
    read -p "请输入对应的Commit Hash（留空自动查找）: " selected_commit
    
    # 如果用户只输入了版本号，尝试自动查找commit
    if [ -n "$selected_version" ] && [ -z "$selected_commit" ]; then
        echo_info "正在查找版本 $selected_version 对应的commit..."
        found_commit=$(git log --oneline --grep="$selected_version" | head -1 | awk '{print $1}')
        if [ -n "$found_commit" ]; then
            selected_commit="$found_commit"
            echo_info "找到commit: $selected_commit"
        else
            echo_error "未找到版本 $selected_version 对应的commit，请手动输入commit hash"
            read -p "请输入Commit Hash: " selected_commit
        fi
    fi
    
    # 设置默认值
    if [ -z "$selected_version" ]; then
        selected_version="3.1.0"
        selected_commit="18eea9bc59d2fd57a439f4bb373aa7d303f3da8a"
        echo_warn "使用默认版本: $selected_version ($selected_commit)"
    fi
    
    # 切换到指定版本
    if [ -n "$selected_commit" ]; then
        echo_info "切换到版本 $selected_version (Commit: $selected_commit)"
        git checkout "$selected_commit"
        if [ $? -ne 0 ]; then
            echo_error "版本切换失败"
            exit 1
        fi
        echo_info "版本切换完成"
    else
        echo_warn "未指定commit，使用最新版本"
    fi
}

# 部署项目
deploy_project() {
    local temp_dir="/tmp/acg-faka"
    
    # 获取站点目录
    echo ""
    read -p "请输入站点目录（例如：/www/wwwroot/pika.iloli.work）: " site_dir
    
    # 清理目录路径
    site_dir=$(echo "$site_dir" | sed 's:/*$::')
    
    # 验证目录
    if [ ! -d "$site_dir" ]; then
        echo_warn "目录不存在，尝试创建..."
        mkdir -p "$site_dir"
        if [ $? -ne 0 ]; then
            echo_error "目录创建失败，请检查权限"
            exit 1
        fi
    fi
    
    # 验证源目录
    if [ ! -d "$temp_dir" ]; then
        echo_error "项目目录不存在，请重新运行脚本"
        exit 1
    fi
    
    # 复制文件
    echo_info "正在复制文件到站点目录..."
    cp -rf "$temp_dir"/* "$site_dir"/
    
    if [ $? -eq 0 ]; then
        echo_info "文件复制完成"
    else
        echo_error "文件复制失败"
        exit 1
    fi
    
    # 设置权限
    echo_info "正在设置目录权限..."
    chmod -R 777 "$site_dir"
    
    if [ $? -eq 0 ]; then
        echo_info "权限设置完成"
    else
        echo_warn "权限设置可能不完整，请手动检查"
    fi
    
    # 显示完成信息
    echo ""
    echo_info "=========================================="
    echo_info "部署完成！"
    echo_info "项目版本: $selected_version"
    echo_info "Commit: $selected_commit"
    echo_info "部署目录: $site_dir"
    echo_info "=========================================="
}

# 主函数
main() {
    echo_info "开始ACG-Faka部署脚本"
    
    # 检查git
    check_and_install_git
    
    # 下载完整项目
    download_full_project
    
    # 选择版本
    select_version
    
    # 部署项目
    deploy_project
    
    echo_info "脚本执行完成"
}

# 运行主函数
main "$@"
