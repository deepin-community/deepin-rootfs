#!/bin/bash

set -e

apt update

# 不进行交互安装
export DEBIAN_FRONTEND=noninteractive

apt install multistrap -y

mkdir -p /beige-rootfs/etc/apt/trusted.gpg.d
cp deepin.gpg /beige-rootfs/etc/apt/trusted.gpg.d

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
suite=beige\n\
" >/beige.multistrap

multistrap -f /beige.multistrap

echo "deb     https://community-packages.deepin.com/beige/ beige main commercial community" > /rootfs/etc/apt/sources.list && \
echo "deb-src https://community-packages.deepin.com/beige/ beige main commercial community" >> /rootfs/etc/apt/sources.list

# 微软提供的 wsl 启动器会调用adduser,需要将 USERS_GID 和 USERS_GROUP 注释。
sed -i -e 's/USERS_GID=100/#USERS_GID=100/' -e 's/USERS_GROUP=users/#USERS_GROUP=users/' /beige-rootfs/etc/adduser.conf

# 生成压缩包
tar -cf deepin-rootfs-$arch.tar.gz -C /beige-rootfs .
