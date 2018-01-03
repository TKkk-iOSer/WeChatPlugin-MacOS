
## WeChatPlugin-MacOS

![](https://img.shields.io/badge/platform-osx-lightgrey.svg) ![](https://img.shields.io/badge/support-wechat%202.2.8-green.svg)
   
微信小助手 v1.4.0   

![微信小助手.png](http://upload-images.jianshu.io/upload_images/965383-31708af611b55ca4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**iOS版本请戳→_→ [WeChatPlugin-iOS](https://github.com/TKkk-iOSer/WeChatPlugin-iOS)**

~~如何制作 mac OS 插件，请参考[我的博客](http://www.tkkk.fun/2017/04/21/macOS%E9%80%86%E5%90%91-%E5%BE%AE%E4%BF%A1%E5%B0%8F%E5%8A%A9%E6%89%8B/)~~

---

### 更新日志

[新增窗口置顶&多选删除等等 (2017-10-11)](https://github.com/TKkk-iOSer/WeChatPlugin-MacOS/releases/tag/v1.4.0)

[新增置底&免认证 (2017-09-17)](https://github.com/TKkk-iOSer/WeChatPlugin-MacOS/releases/tag/v1.3.0)

[修复聊天记录消失的bug (2017-09-11)](https://github.com/TKkk-iOSer/WeChatPlugin-MacOS/releases/tag/v1.2.0)

[重构自动回复，实现多回复 (2017-08-23)](https://github.com/TKkk-iOSer/WeChatPlugin-MacOS/releases/tag/v1.1.0)

**详细内容请查看**[CHANGELOG](https://github.com/TKkk-iOSer/WeChatPlugin-MacOS/blob/master/CHANGELOG.md)

---

### 功能
* 消息自动回复
* 消息防撤回
* 远程控制
* 微信多开
* 第二次登录免认证
* 聊天置底功能(~~类似置顶~~)
* 微信窗口置顶
* 会话多选删除

远程控制：

>远程控制新增指令发送成功回调、发送`获取指令`获得当前所有远程控制信息。

- [x] 屏幕保护
- [x] 清空废纸篓
- [x] 锁屏、休眠、关机、重启
- [x] 退出QQ、WeChat、Chrome、Safari、所有程序
- [x] 网易云音乐(播放、暂停、下一首、上一首、喜欢、取消喜欢)

**若想使用远程控制网易云音乐，请在“系统偏好设置 ==> 安全性与隐私 ==> 隐私 ==> 辅助功能”中添加微信**

---

### TODO
- [ ] 增加`Alfred`搜索
- [ ] 查看单向好友
- [ ] 语音(视频转发)
- [ ] 增加 brew 安装方式
- [ ] 完善自动回复(指定好友回复、图灵机器人、)
- [ ] 完善消息防撤回(显示撤回用户昵称)
- [ ] 清除微信缓存
- [ ] 优化小助手设置(更新后保留相关设置，更新提醒)
- [ ] 群聊屏蔽某成员

---

### Demo 演示

* 消息防撤回   
![消息防撤回.gif](http://upload-images.jianshu.io/upload_images/965383-30cbea645661e627.gif?imageMogr2/auto-orient/strip)

* 自动回复
![自动回复.gif](http://upload-images.jianshu.io/upload_images/965383-d488dce3696ba1b3.gif?imageMogr2/auto-orient/strip)

* 微信多开
![微信多开.gif](http://upload-images.jianshu.io/upload_images/965383-51d8eae02d48fda9.gif?imageMogr2/auto-orient/strip)

* 远程控制 (测试关闭Chrome、QQ、开启屏幕保护)
![远程控制.gif](http://upload-images.jianshu.io/upload_images/965383-0cf50d9b22b02f2f.gif?imageMogr2/auto-orient/strip)

* 免认证 & 置底 & 多选删除
![免认证&置底&多选删除](http://upload-images.jianshu.io/upload_images/965383-170592b03781cbf4.gif?imageMogr2/auto-orient/strip)


---
### 安装

~~第一次安装需要输入密码，仅是为了获取写入微信文件夹的权限~~

**0. 懒癌版安装(适合非程序猿)**

打开`应用程序-实用工具-Terminal(终端)`，执行以下命令并根据提示输入密码即可。~~(需要git支持)~~

`cd ~/Downloads && git clone https://github.com/TKkk-iOSer/WeChatPlugin-MacOS.git && ./WeChatPlugin-MacOS/Other/Install.sh`

**1. 普通安装**

* 点击`clone or download`按钮下载 WeChatPlugin 至`下载`目录并解压，打开Termimal，执行 `~/Downloads/WeChatPlugin-MacOS-master/Other/Install.sh`即可。


**2. 若想修改源码&重编译**

* 先更改微信的 owner 以获取写入微信文件夹的权限，否则会出现类似**Permission denied**的错误。 

`sudo chown -R $(whoami) /Applications/WeChat.app` 

![Permission denied.png](http://upload-images.jianshu.io/upload_images/965383-11e4480553ba086e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

* 下载 WeChatPlugin, 用Xcode打开，先进行 Build (`command + B`)，之后 Run (`command + R`)即可启动微信，此时插件注入完成。
 
* 若 Error，提示找不到 Framework，先进行 Build。
* 若Error, 需要配置环境，请参考[我的博客](http://www.tkkk.fun/2017/04/21/macOS%E9%80%86%E5%90%91-%E5%BE%AE%E4%BF%A1%E5%B0%8F%E5%8A%A9%E6%89%8B/)。

**3. 安装完成**

* 登录微信，在**菜单栏**中看到**微信小助手**即安装成功。 
![微信小助手.png](http://upload-images.jianshu.io/upload_images/965383-31708af611b55ca4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

--- 

### 使用

* 消息防撤回：点击`开启消息防撤回`或者快捷键`command + t`,即可开启、关闭。
* 自动回复：点击`开启自动回复`或者快捷键`conmand + k`，将弹出自动回复设置的窗口，点击红色箭头的按钮设置开关。    

>若关键字为 `*`，则任何信息都回复；
>若关键字为`x|y`,则 x 和 y 都回复；
>若关键字**或者**自动回复为空，则不开启该条自动回复。
>若开启正则，请确认正则表达式书写正确，[在线正则表达式测试](http://tool.oschina.net/regex/)

![自动回复设置.png](http://upload-images.jianshu.io/upload_images/965383-5aa2fd8fadc545c4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


* 微信多开：点击`登录新微信`或者快捷键`command + shift + n`,即可多开微信。

* 远程控制：点击`远程控制 Mac OS`或者快捷键`command + shift + c`,即可打开控制窗口。

![.png](http://upload-images.jianshu.io/upload_images/965383-9c67894ee7092600.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

①为选择是否开启远程控制此功能。   

②为能够触发远程控制的消息内容(仅向自己发送账号有效)。


* 远程控制：发送`获取指令`，手机端可查看所有指令信息。

![远程控制.png](http://upload-images.jianshu.io/upload_images/965383-7c2a4b17e5a6867f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

---

### 卸载

在`Terminal`(终端)打开该项目，运行 `./Other/Uninstall.sh` 即可.


~~或者在 `/Applications/WeChat.app/Contents/MacOS` 目录中，删除 `WeChat` 与 `WeChatPlugin.framework`，将`WeChat_backup` 重命名为 `WeChat` 即可。~~

---
### 依赖

* [XMLReader](https://github.com/amarcadet/XMLReader)
* [insert_dylib](https://github.com/Tyilo/insert_dylib)

---
### Other

若有其他好的想法欢迎 Issue me

---

#### 听说你想请我喝下午茶？😏
 
<img src="http://upload-images.jianshu.io/upload_images/965383-cbc86dc1d75a6242.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="250" hspace="50"/>&nbsp;&nbsp;&nbsp;<img src="http://upload-images.jianshu.io/upload_images/965383-76a1c7c91b987e1a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="250" hspace="50"  />

