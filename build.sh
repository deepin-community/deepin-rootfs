#!/bin/bash

set -e

apt update

export DEBIAN_FRONTEND=noninteractive

apt install multistrap -y

mkdir -p /beige-rootfs/etc/apt/trusted.gpg.d

cp deepin.gpg /beige-rootfs/etc/apt/trusted.gpg.d

multistrap -f beige-${1}.multistrap

cp sources.list /beige-rootfs/etc/apt/sources.list

# 微软提供的 wsl 启动器会调用adduser,需要将 USERS_GID 和 USERS_GROUP 注释。
sed -i -e 's/USERS_GID=100/#USERS_GID=100/' -e 's/USERS_GROUP=users/#USERS_GROUP=users/' /beige-rootfs/etc/adduser.conf