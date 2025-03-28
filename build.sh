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


# 检测容器环境
is_docker() {
    # 是否存在 /.dockerenv 文件（Docker 特有）
    if [[ -f /.dockerenv ]]; then
        return 1  # 是容器
    fi
    return 0
}


sudo apt update -y && sudo apt install -y curl git mmdebstrap qemu-user-static usrmerge
if [[ ! is_docker ]];
then
    # 开启异架构支持
    sudo systemctl restart systemd-binfmt

fi

if [[ is_docker ]];
then
    # 让 mmdebstrap 的 loong64 指向 loongarch64
    sudo sed -i "/riscv64  => 'riscv64',/a\            loong64  => 'loongarch64'," /usr/bin/mmdebstrap
    sudo mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
fi

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

mkdir -p $OUT_DIR

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

if [[ is_docker ]];
then
    sudo umount /proc/sys/fs/binfmt_misc
fi
