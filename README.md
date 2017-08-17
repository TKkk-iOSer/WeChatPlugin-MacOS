
## WeChatPlugin-MacOS

![](https://img.shields.io/badge/platform-osx-lightgrey.svg) ![](https://img.shields.io/badge/support-wechat%202.2.8-green.svg)
   
微信小助手 v1.0.0   

![微信小助手.png](http://upload-images.jianshu.io/upload_images/965383-80c56cbc5c192604.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)   

~~主要实现 macOS 版微信的<a>消息防撤回与自动回复</a>的功能，详细内容，请参考[我的博客](http://www.jianshu.com/p/7f65287a2e7a)~~

---

### 功能
* 消息自动回复
* 消息防撤回
* 远程控制
* 微信多开

远程控制：

- [x] 屏幕保护
- [x] 清空废纸篓
- [x] 锁屏、休眠、关机、重启
- [x] 退出QQ、Chrome、Safari、所有程序
- [x] 网易云音乐(播放、暂停、下一首、上一首、喜欢、取消喜欢)

**若想使用远程控制网易云音乐，请在“系统偏好设置 ==> 安全性与隐私 ==> 隐私 ==> 辅助功能”中添加微信**

---

### Demo 演示

* 消息防撤回   
![消息防撤回.gif](http://upload-images.jianshu.io/upload_images/965383-30cbea645661e627.gif?imageMogr2/auto-orient/strip)

* 自动回复
![自动回复.gif](http://upload-images.jianshu.io/upload_images/965383-b61b6d983c90e0c5.gif?imageMogr2/auto-orient/strip)

* 微信多开
![微信多开.gif](http://upload-images.jianshu.io/upload_images/965383-51d8eae02d48fda9.gif?imageMogr2/auto-orient/strip)



* 远程控制 (测试关闭Chrome、QQ、开启屏幕保护)
![远程控制.gif](http://upload-images.jianshu.io/upload_images/965383-0cf50d9b22b02f2f.gif?imageMogr2/auto-orient/strip)

---
### 安装
**1. 已安装Xcode**

* 下载 WeChatPlugin, 用Xcode打开，先进行 Build (`command + B`)，之后 Run (`command + R`)即可启动微信，此时插件注入完成。
 
* 若提示**Permission denied**，请对 WeChat 赋予权限。
`sudo chmod -R 777 /Applications/WeChat.app`
* 若 Error，提示找不到 Framework，先进行 Build。

**2. 无安装Xcode**

* 下载WeChatPlugin，用 Termimal 打开项目当前目录，执行 `./Other/Install.sh`即可。
* 若提示**Permission denied**，请对 WeChat 、Install.sh 赋予权限。
![Permission denied.png](http://upload-images.jianshu.io/upload_images/965383-11e4480553ba086e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


```
sudo chmod -R 777 /Applications/WeChat.app
sudo chmod 777 ./Other/Install.sh
```

**3. 安装完成**

* 登录微信，在**菜单栏**中看到**微信小助手**即安装成功。 
![微信小助手.png](http://upload-images.jianshu.io/upload_images/965383-80c56cbc5c192604.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


--- 

### 使用

* 消息防撤回：点击`开启消息防撤回`或者快捷键`command + t`,即可开启、关闭。
* 自动回复：点击`开启自动回复`或者快捷键`conmand + k`，将弹出自动回复设置的窗口，在窗口中输入关键字与回复内容，点击保存即可。~~(若无关键字保存，则所有消息都会自动回复)~~

![自动回复设置.png](http://upload-images.jianshu.io/upload_images/965383-060903126e9da7a3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

* 微信多开：点击`登录新微信`或者快捷键`command + shift + n`,即可多开微信。

* 远程控制：点击`远程控制Mac OS`或者快捷键`command + shift + c`,即可打开控制窗口。

![.png](http://upload-images.jianshu.io/upload_images/965383-9c67894ee7092600.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

①为选择是否开启远程控制此功能。   

②为能够触发远程控制的消息内容(仅向自己发送账号有效)。

---

### 卸载

在Terminal中，运行 `./Other/Uninstall.sh` 即可

~~在 `/Applications/WeChat.app/Contents/MacOS` 目录中，删除 `WeChat` 与 `WeChatPlugin.framework`，将`WeChat_backup` 重命名为 `WeChat` 即可。~~

### Other

若有其他好的想法、需求欢迎 Issue me。


