# 说明

制作一个根文件系统来给Docker或者wsl来使用。

# 环境要求

- 系统版本

  - 对于 x64 系统：版本 1903 或更高版本，内部版本 18362 或更高版本。
  - 对于 ARM64 系统：版本 2004 或更高版本，内部版本 19041 或更高版本。
- 使用WSL 需要开启虚拟化。这里使用virtualbox安装windows11虚拟机。

  - 在控制面板，程序开启和关闭，打开“适用于Linux的Windows子系统”和“虚拟机平台”两个可选功能。
  - 在virtualbox安装windows虚拟机，需要在设置中为windows虚拟机启用嵌套虚拟化，即勾选“启用VT-x/AMD-V”和“启用嵌套分页”选项。
- 安装wsl（使用wsl2)

  - `wsl --update`
  - `wsl --set-default-version 2`

# 获取根文件系统

## 方式一

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

## 方式二

通过tar命令将现有的系统打包成docker容器，用于构建镜像文件

系统deepin v23 beta

```bash
tar -cvpf /tmp/rootfs.tar --directory=/ --exclude=proc --exclude=sys --exclude=dev --exclude=run --exclude=boot .
```

/proc、/sys、/run、/dev这几个目录是系统启动时自动生成的依赖与系统内核。

# 使用

## wsl

### 将tar导入

从releases中下载压缩包[deepin.zip](https://github.com/chenchongbiao/deepin-rootfs/releases/download/untagged-484bdf5b00538d9f22f6/deepin.zip)，在解压后的文件夹打开终端。

```bash
./deepin.exe install rootfs.tar
```

等待安装完成。

可通过指令查看已经安装的wsl。

```bash
wsl -l
```

运行

```bash
./deepin.exe 或 wsl -d deepin
```

deepin.exe是使用yuk7提供的，[wsldl的可执行文件](https://github.com/yuk7/wsldl/releases/tag/22020900)，将可执行文件重命名为需要安装的发行版的名字，详细使用方法参考[yuk7/wsldl](https://github.com/yuk7/wsldl#wsldl)

## docker

从releases中下载压缩包[deepin.zip](https://github.com/chenchongbiao/deepin-rootfs/releases/download/untagged-484bdf5b00538d9f22f6/deepin.zip)，在解压后的文件夹打开终端。

```bash
cat rootfs.tar | sudo docker import - deepin:v23
```

将rootfs.tar导入到docker中，镜像名为deepin:v23，可以自己修改。

```bash
sudo docker run --name v23 -itd deepin:v23 bash
```

运行容器。

# 参考

[通过tar命令将现有的系统打包成docker容器，用于构建镜像文件](https://blog.csdn.net/henni_719/article/details/81009449)

[debootstrap构建自己的debian系统](https://blog.csdn.net/Zhang_Pro/article/details/108414727)

[WSL安装deepin](https://github.com/chenchongbiao/os-study/tree/master/dev-env/wsl)

# 声明

本release使用了以下文件：

- wsldl.exe: 来自[yuk7/wsldl](https://github.com/yuk7/wsldl)仓库的[release](https://github.com/yuk7/wsldl/releases/download/21082800/wsldl.exe)，使用MIT许可证。
