#!/bin/bash

set -e -u -x

sudo apt update

# 不进行交互安装
export DEBIAN_FRONTEND=noninteractive
ROOTFS=`mktemp -d`
dist_version="beige"
dist_name="deepin"
SOURCES_FILE=config/apt/sources.list
readarray -t REPOS < $SOURCES_FILE
OUT_DIR=rootfs

mkdir -p $OUT_DIR

sudo apt update -y && sudo apt install -y curl git mmdebstrap qemu-user-static usrmerge systemd-container usrmerge
# 开启异架构支持
sudo systemctl start systemd-binfmt

function build_rootfs() {
    sudo mmdebstrap \
        --hook-dir=/usr/share/mmdebstrap/hooks/merged-usr \
        --include=$PACKAGES \
        --components="main,commercial,community" \
        --variant=minbase \
        --architectures=${arch} \
        --customize=./config/hooks.chroot/second-stage \
        $dist_version \
        $ROOTFS \
        "${REPOS[@]}"

    # 判断是否构建 wsl 的根文件系统，体内钾 wsl.conf 默认开启systemd
    if [[ $TARGET=="wsl" ]];
    then
        sudo tee $ROOTFS/etc/wsl.conf <<EOF
[boot]
systemd=true
EOF
    fi

    # 生成压缩包
    pushd $OUT_DIR
    rm -rf $dist_name-$TARGET-rootfs-$arch.tar.gz
    sudo tar -zcf $dist_name-$TARGET-rootfs-$arch.tar.gz -C $ROOTFS .
    # 删除临时文件夹
    sudo rm -rf  $ROOTFS
    popd
}

TARGET=wsl
PACKAGES=`cat config/packages.list/$TARGET-packages.list | grep -v "^-" | xargs | sed -e 's/ /,/g'`
for arch in amd64 arm64; do
    build_rootfs
done

TARGET=docker
PACKAGES=`cat config/packages.list/$TARGET-packages.list | grep -v "^-" | xargs | sed -e 's/ /,/g'`
for arch in amd64 arm64 riscv64 loong64 i386; do
    build_rootfs
done
