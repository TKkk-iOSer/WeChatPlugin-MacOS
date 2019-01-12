

## Install

**第一次安装需要输入密码，仅是为了获取写入微信文件夹的权限**

**0. 懒癌版安装&升级**

打开`应用程序-实用工具-Terminal(终端)`，执行下面的命令安装 [Oh My WeChat](https://github.com/lmk123/oh-my-wechat)：

```sh
curl -o- -L https://raw.githubusercontent.com/lmk123/oh-my-wechat/master/install.sh | bash -s
```

然后运行 `omw` 即可。

> 可以访问 [Oh My WeChat 的项目主页](https://github.com/lmk123/oh-my-wechat#oh-my-wechat)查看更多用法。

**1. 普通安装**

* 点击`clone or download`按钮下载 WeChatPlugin 并解压

![clone or download](./Other/ScreenShots/install_download.png)

* 从`应用程序-实用工具`中打开Terminal(终端)

![terminal](./Other/ScreenShots/terminal_path.png)

* 拖动解压后`Install.sh` 文件到终端中回车即可.

![terminal](./Other/ScreenShots/install_terminal.png)

**2. 若想修改源码&重编译(需要安装Cocoapods)**

* 先更改微信的 owner 以获取写入微信文件夹的权限，否则会出现类似**Permission denied**的错误。

`sudo chown -R $(whoami) /Applications/WeChat.app`

![Permission denied.png](http://upload-images.jianshu.io/upload_images/965383-11e4480553ba086e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

* 下载 WeChatPlugin, 进行`Pod install`。
* 用Xcode打开，编辑 Scheme，在 Debug 模式下启动 WeChat。
![](http://upload-images.jianshu.io/upload_images/965383-26dbb068acb8998f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![edit scheme](http://upload-images.jianshu.io/upload_images/965383-7fbd4dc6e8d161dc.gif?imageMogr2/auto-orient/strip)
* 之后 Run (`command + R`)即可启动微信，此时插件注入完成。

* 若 Error，提示找不到 Framework，先进行 Build。
* 若Error, 需要配置环境，请参考[我的博客](http://www.tkkk.fun/2017/04/21/macOS%E9%80%86%E5%90%91-%E5%BE%AE%E4%BF%A1%E5%B0%8F%E5%8A%A9%E6%89%8B/)。

## 卸载

* 打开Terminal(终端)，拖动解压后`Uninstall.sh` 文件到 Terminal 回车即可。