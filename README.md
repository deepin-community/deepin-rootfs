# 说明

制作一个根文件系统来给Docker或者wsl来使用。

# 方式一

原debootstrap是没有beige代号的，需要从deepin-community的包来使用。

这里从ci仓库从下载

```bash
# 需要使用dget指令，先安装devscripts
sudo apt install devscripts
dget https://ci.deepin.com/repo/obs/deepin:/Develop:/community/deepin_develop/debootstrap_1.0.128%2Bnmu2deepin%2Bu001.dsc
# 解压源码
dpkg-source -x debootstrap_1.0.128%2Bnmu2deepin%2Bu001.dsc
cd debootstrap-1.0.128+nmu2deepin+u001
# 安装依赖
sudo apt build-dep .
# 打包
dpkg-buildpackage -us -uc -b
# 安装
sudo apt install ../*.deb
```

通过debootstrap来安装，这里选择版本beige

```bash
sudo debootstrap --arch=amd64 --include=systemd,dbus,locales,apt beige ./deepin-rootfs https://community-packages.deepin.com/beige beige
```

* –arch=amd64：表示指定目标系统的架构为amd64。
* –include=systemd,dbus,locales,apt：表示指定额外安装一些软件包，用逗号分隔。
* beige：表示指定安装的发行版为beige。
* ./deepin-rootfs：表示指定安装的目标目录为当前目录下的deepin-rootfs文件夹。
* https://community-packages.deepin.com/beige/：表示指定安装的软件包来源的仓库。

使用tar命令将解压后的目录打包成一个tar文件

```bash
cd deepin-rootfs
sudo tar -cf rootfs.tar *
```

当前目录会生成rootfs.tar文件。

# 方式二

通过tar命令将现有的系统打包成docker容器，用于构建镜像文件

系统deepin v23 beta

```bash
tar -cvpf /tmp/rootfs.tar --directory=/ --exclude=proc --exclude=sys --exclude=dev --exclude=run --exclude=boot .
```

/proc、/sys、/run、/dev这几个目录是系统启动时自动生成的依赖与系统内核。

# 参考

[通过tar命令将现有的系统打包成docker容器，用于构建镜像文件](https://blog.csdn.net/henni_719/article/details/81009449)

[debootstrap构建自己的debian系统](https://blog.csdn.net/Zhang_Pro/article/details/108414727)

# 声明

本release使用了以下文件：

- wsldl.exe: 来自[yuk7/wsldl](https://github.com/yuk7/wsldl)仓库的[release](https://github.com/yuk7/wsldl/releases/download/21082800/wsldl.exe)，使用MIT许可证。
