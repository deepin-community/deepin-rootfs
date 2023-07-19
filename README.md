# 说明

制作一个根文件系统来给Docker或者wsl来使用。

# 环境要求

- 系统版本

  - 对于 x64 系统：版本 1903 或更高版本，内部版本 18362 或更高版本。
  - 对于 ARM64 系统：版本 2004 或更高版本，内部版本 19041 或更高版本。
- 使用WSL 需要开启虚拟化。这里使用Vmware17安装Windows11虚拟机。(使用QEMU、Virtualbox、Vmware16版本即使打开了嵌套虚拟化的选项运行WSL还是提示没有开启虚拟化)

  - 在控制面板，程序开启和关闭，打开“适用于Linux的Windows子系统”和“虚拟机平台”两个可选功能。
  - 需要在Vmware设置中为Windows虚拟机启用嵌套虚拟化，即勾选“启用VT-x/AMD-V”和“启用嵌套分页”选项。
- 安装WSL（使用WSL)

  - `wsl --update`
  - `wsl --set-default-version 2`

# 开启虚拟化及子系统功能支持

除了在控制面板手动开启“适用于Linux的Windows子系统”和“虚拟机平台”功能外，也可以使用命令行开启。在Windows菜单栏找到cmd,选择管理员身份运行。

```bash
wsl --install
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
wsl --update
```

输入完成之后建议重启。

# 获取根文件系统

如果想自己创建根文件系统可以参考以下方式，release已经提供了而根文件系统的tar包，以及wsldl的可执行程序。

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
sudo debootstrap --arch=amd64 --include=systemd,dbus,locales,apt,sudo --components=main,commercial,community beige ./deepin-rootfs
```

* –arch=amd64：表示指定目标系统的架构为amd64。
* –include=systemd,dbus,locales,apt：表示指定额外安装一些软件包，用逗号分隔。
* --components=main,commercial,community：需要包含的组件，否则默认只有main，这样有些软件就无法下载。
* beige：表示指定安装的发行版为beige。
* ./deepin-rootfs：表示指定安装的目标目录为当前目录下的deepin-rootfs文件夹。

使用tar命令将解压后的目录打包成一个tar文件

```bash
sudo tar -cf deepin-rootfs.tar -C deepin-rootfs .
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

## 将tar导入

从releases中下载压缩包[deepin.zip](https://github.com/deepin-community/deepin-rootfs/releases/download/v1.0.0/deepin.zip)，在解压后的文件夹打开终端。

```bash
./deepin.exe install deepin-rootfs.tar
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

如果安装了多个发行版可以通过一下指令设置默认发行版。

```bash
wsl -s deepin
```

这样直接使用 `wsl`指令就可以直接启动deepin了。

deepin.exe是使用yuk7提供的[wsldl的可执行文件](https://github.com/yuk7/wsldl/releases/tag/22020900)，将可执行文件重命名为需要安装的发行版的名字，详细使用方法参考[yuk7/wsldl](https://github.com/yuk7/wsldl#wsldl)

## 添加用户

```bash
useradd -m deepin -s /usr/bin/bash
```

添加一个名为deepin的用户，设置默认shell为bash。

```bash
passwd deepin
```

设置密码，设置密码时不会显示，输入完毕后直接回车。

```bash
usermod -aG sudo deepin
```

添加deepin用户到sudo用户组。

## 开启systemd支持

```bash
cat >> /etc/wsl.conf << EOF
[boot]
systemd=true
EOF
```

 输入exit退出。

```
wsl -t deepin
```

停止运行wsl，需要重启wsl才能生效。

```bash
wsl -d deepin
```

重新进入。

## 设置wsl的默认用户

```bash
./deepin.exe config --default-user deepin
```

在deepin.exe所在目录打开终端，执行指令，设置deepin为默认用户。这样进入wsl就是默认deepin用户。

## 配置语言环境

```bash
sudo dpkg-reconfigure locales
```

默认语言环境是英文，需要修改的话，可以用这个指令重新设置。

需要三次回车，输入312，对应选项zh_CN.UTF-8。再输入一次3，对应选项zh_CN.UTF-8。

需要退出，重启wsl才能生效。

# 应用软件

### 公共

#### 需安装的包

- fonts-noto-cjk：字体库，如果不安装可能导致软件字体不正常。
- dde-qt5integration：deepin应用程序和deepin桌面环境的Qt5主题集成插件。它在Qt的基础上实现了许多额外的功能，比如窗口装饰、阴影绘制、高分辨率下的光标支持、当前工作区的窗口列表获取等。
- dde-qt5wayland-plugin：Qt 5 模块，它提供了一些插件和库，用于在 Wayland 上运行或创建 Qt 应用程序。

```bash
sudo apt install fonts-noto-cjk dde-qt5integration dde-qt5wayland-plugin
```

#### 已知问题

- 安装完dde-qt5integration后，在X11模式下应用的设置项无法出现在正确的位置上。
- X11模式下全屏并不能占满整个屏幕。

### 深度终端

```bash
sudo apt install deepin-terminal
```

输入上面的指令安装应用。

需要输入exit退出容器。使用 `wsl -t deepin` 关闭deepin wsl，输入 `wsl` 中心进入，输入一下指令启动。

```bash
deepin-terminal
```

运行软件。

### 看图

```bash
sudo apt install deepin-image-viewer
```

输入上面的指令安装应用。

```bash
deepin-image-viewer
```

运行软件。

### 浏览器

```bash
sudo apt install org.deepin.browser
```

输入上面的指令安装应用。

```bash
browser
```

运行软件。

已知问题：

- 部分页面的链接 图标 字体缺失或者乱码。

### 文件管理器

```bash
sudo apt install dde-file-manager
```

输入上面的指令安装应用。

```bash
dde-file-manager
```

运行软件。

已知问题：

- 不受平台插件管理，出现设置选项位置偏移。
- 无法主题图标。

### 深度音乐

```bash
sudo apt install deepin-music
```

输入上面的指令安装应用。

```bash
deepin-music
```

运行软件。

已知问题：

- 无法运行

### 深度影院

```bash
sudo apt install deepin-movie
```

输入上面的指令安装应用。

```bash
deepin-movie
```

运行软件。

已知问题：

- 无法运行

### 深度相册

```bash
sudo apt install deepin-album
```

输入上面的指令安装应用。

```bash
deepin-album
```

运行软件。

已知问题：

- 运行卡顿。

### 深度画板

```bash
sudo apt install deepin-draw
```

输入上面的指令安装应用。

```bash
deepin-draw
```

运行软件。

# 参考

[通过tar命令将现有的系统打包成docker容器，用于构建镜像文件](https://blog.csdn.net/henni_719/article/details/81009449)

[debootstrap构建自己的debian系统](https://blog.csdn.net/Zhang_Pro/article/details/108414727)

[WSL安装deepin](https://github.com/chenchongbiao/os-study/tree/master/dev-env/wsl)

[deepin-docker](https://github.com/BLumia/deepin-docker)

# 声明

本release使用了以下文件：

- wsldl.exe: 来自[yuk7/wsldl](https://github.com/yuk7/wsldl)仓库的[release](https://github.com/yuk7/wsldl/releases/download/21082800/wsldl.exe)，使用MIT许可证。
