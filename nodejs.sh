#!/bin/env bash
cd $HOME
export red="\033[31m"
export green="\033[32m"
export yellow="\033[33m"
export blue="\033[34m"
export purple="\033[35m"
export cyan="\033[36m"
export white="\033[37m"
export background="\033[0m"

function nodejs_install() {
    echo -e "${green}开始安装 Node.js...${background}"
    
    # 更新软件包列表
    apt update -y
    
    # 安装必要依赖
    if [ ! -x "$(command -v curl)" ]; then
        apt install -y curl
    fi
    
    if [ ! -x "$(command -v gnupg)" ]; then
        apt install -y gnupg
    fi
    
    # 添加 Node.js 24.x 仓库
    echo -e "${yellow}添加 Node.js 24.x 仓库...${background}"
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    
    if [ $? -eq 0 ]; then
        echo -e "${green}Node.js 仓库添加成功${background}"
        
        # 安装 Node.js
        echo -e "${yellow}安装 Node.js...${background}"
        apt install -y nodejs
        
        if [ $? -eq 0 ]; then
            echo -e "${green}Node.js 安装成功！${background}"
            echo -e "${cyan}Node.js 版本: $(node --version)${background}"
            echo -e "${cyan}npm 版本: $(npm --version)${background}"
        else
            echo -e "${red}Node.js 安装失败${background}"
            exit 1
        fi
    else
        echo -e "${red}Node.js 仓库添加失败${background}"
        exit 1
    fi
}

# 检查是否已安装 Node.js
if [ -x "$(command -v node)" ]; then
    echo -e "${yellow}Node.js 已安装，当前版本: $(node --version)${background}"
    echo -e "${yellow}是否重新安装？(y/N): ${background}"
    read -r reinstall
    if [[ $reinstall =~ ^[Yy]$ ]]; then
        nodejs_install
    else
        echo -e "${green}已取消安装${background}"
    fi
else
    nodejs_install
fi
