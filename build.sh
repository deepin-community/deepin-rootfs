#!/bin/bash

set -e

apt update

# 不进行交互安装
export DEBIAN_FRONTEND=noninteractive

# 稳定源里暂时没有包，暂时手动下载包安装
apt install -y wget && \
    wget http://ftp.kr.debian.org/debian/pool/main/libp/libparse-debian-packages-perl/libparse-debian-packages-perl_0.03-5_all.deb && \
    wget http://ftp.kr.debian.org/debian/pool/main/m/multistrap/multistrap_2.2.11_all.deb && \
    apt install -y ./*deb

arch=${1}
echo -e "[General]\n\
arch=$arch\n\
directory=/beige-rootfs/\n\
cleanup=true\n\
noauth=false\n\
unpack=true\n\
explicitsuite=false\n\
multiarch=\n\
aptsources=Debian\n\
bootstrap=Deepin\n\
[Deepin]\n\
packages=apt ca-certificates locales-all sudo systemd\n\
source=https://community-packages.deepin.com/beige/\n\
keyring=deepin-keyring\n\
suite=beige\n\
" >/beige.multistrap

multistrap -f /beige.multistrap

echo "deb     https://community-packages.deepin.com/beige/ beige main commercial community" > /rootfs/etc/apt/sources.list && \
echo "deb-src https://community-packages.deepin.com/beige/ beige main commercial community" >> /rootfs/etc/apt/sources.list

# 微软提供的 wsl 启动器会调用adduser,需要将 USERS_GID 和 USERS_GROUP 注释。
sed -i -e 's/USERS_GID=100/#USERS_GID=100/' -e 's/USERS_GROUP=users/#USERS_GROUP=users/' /beige-rootfs/etc/adduser.conf

# 生成压缩包
tar -cf deepin-rootfs-$arch.tar.gz -C /beige-rootfs .
