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

case $(arch) in
  aarch64|arm64)
    framework=arm64
    ;;
  amd64|x86_64)
    framework=amd64
    ;;
  *)
    echo -e ${red}暂不支持您的设备${background}
    exit
    ;;
esac

function chromium_install(){
apt update -y
if [ ! -x "$(command -v wget)" ];then
apt install -y wget
fi
wget -q --show-progress -O chromium-codecs-ffmpeg-extra.deb -c https://gitee.com/baihu433/chromium/releases/download/${version}_${framework}/chromium-codecs-ffmpeg-extra.deb
wget -q --show-progress -O chromium-browser.deb -c https://gitee.com/baihu433/chromium/releases/download/${version}_${framework}/chromium-browser.deb
wget -q --show-progress -O chromium-browser-l10n.deb -c https://gitee.com/baihu433/chromium/releases/download/${version}_${framework}/chromium-browser-l10n.deb
apt install -yf ./chromium-codecs-ffmpeg-extra.deb 
apt install -yf ./chromium-browser.deb
apt install -yf ./chromium-browser-l10n.deb
rm chromium-browser.deb
rm chromium-browser-l10n.deb
rm chromium-codecs-ffmpeg-extra.deb
}

if awk '{print $2}' /etc/issue | grep -q -E 20.04
    then
        version=20.04
        chromium_install
elif awk '{print $2}' /etc/issue | grep -q -E 22.04
    then
        version=22.04
        chromium_install
elif awk '{print $2}' /etc/issue | grep -q -E 22.10
    then
        version=22.10
        chromium_install
else
    apt install -y chromium-browser || apt install -y chromium
fi

