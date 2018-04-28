

![微信小助手.png](./Other/ScreenShots/wechatplugin.png)

![platform](https://img.shields.io/badge/platform-macos-lightgrey.svg)  [![release](https://img.shields.io/badge/release-v1.6.1-brightgreen.svg)](https://github.com/TKkk-iOSer/WeChatPlugin-MacOS/releases)  ![support](https://img.shields.io/badge/support-wechat%202.3.10-blue.svg)  [![GitHub license](https://img.shields.io/github/license/TKkk-iOSer/WeChatPlugin-MacOS.svg)](https://github.com/TKkk-iOSer/WeChatPlugin-MacOS/blob/master/LICENSE)

# WeChatPlugin-macOS v1.6.1 

[ [Feature](#feature) &bull; [Install](#install) &bull; [Uninstall](#uninstall) &bull; [Usage](#usage) &bull; [Other](#i hear somebody want to buy me a cup of coffee) ]

Other plugin：  
[ [wechat-alfred-workflow](https://github.com/TKkk-iOSer/wechat-alfred-workflow) &bull; [QQPlugin-macOS](https://github.com/TKkk-iOSer/QQPlugin-macOS) &bull; [WeChatPlugin-iOS](https://github.com/TKkk-iOSer/WeChatPlugin-iOS) ]

---

## Feature

* Message auto reply
* Prevent message recall
* Remote control(support voice control)
* Multiple WeChat
* Auto Auth Login
* Session Sticky Bottom
* Windows Sticky Top
* Session multiple delete
* Auto Login Switch
* Quick reply to notifications
* Copy or Export Sticker
* Update plugin
* Reply or Open session by Alfred  (dependency：[wechat-alfred-workflow](https://github.com/TKkk-iOSer/wechat-alfred-workflow))

Remote Control：

- [x] Save Screen
- [x] Empty Trash
- [x] Lock Screen & Sleep  & Shut Down & Restart
- [x] Quit some app, include QQ、WeChat、Chrome、Safari。
- [x] NeteaseMusic(play、pause、next song、previous song、like song、unlike song)

**If you want to control NeteaseMusic, please allow WeChat Control in "System Preferences-Security & Privacy-Privacy-Accessibility"**

---

## Install

**1. If you have installed Git**

open `/Applications/Utilities/Terminal.app`，run command

`cd ~/Downloads && rm -rf WeChatPlugin-MacOS && git clone https://github.com/TKkk-iOSer/WeChatPlugin-MacOS.git --depth=1 && ./WeChatPlugin-MacOS/Other/Install.sh`, and enter the mac password.

**2. Normal install**

* click `clone or download` button to download project and unzip it，open Terminal.app，Drag the `Install.sh` file(in `Other` Folder) to Terminal.

--- 

## Uninstall
open `/Applications/Utilities/Terminal.app`,Drag the `Uninstall.sh` file(in `Other` Folder) to Terminal.

---

## Usage

> A few examples of how to use WeChatPlugin-macOS.

* Prevent message recall   
![消息防撤回.gif](http://upload-images.jianshu.io/upload_images/965383-30cbea645661e627.gif?imageMogr2/auto-orient/strip)

* Message auto reply
![自动回复.gif](http://upload-images.jianshu.io/upload_images/965383-d488dce3696ba1b3.gif?imageMogr2/auto-orient/strip)

* Multiple WeChat
![微信多开.gif](http://upload-images.jianshu.io/upload_images/965383-51d8eae02d48fda9.gif?imageMogr2/auto-orient/strip)

* Remote control (quit Chrome and QQ,Save Screen)
![远程控制.gif](http://upload-images.jianshu.io/upload_images/965383-0cf50d9b22b02f2f.gif?imageMogr2/auto-orient/strip)

* Auto Auth Login & Session Sticky Bottom & Session multiple delete
![免认证&置底&多选删除](http://upload-images.jianshu.io/upload_images/965383-170592b03781cbf4.gif?imageMogr2/auto-orient/strip)

* Quick reply to notifications   
![快捷回复](./Other/ScreenShots/notification_quick_reply.gif)

* Copy or Export Sticker  
<img src="./Other/ScreenShots/emotion_copy_export.png" height="400" hspace="50" />

* Remote control with Voice   
![语音远程控制](./Other/ScreenShots/voice_remote_control.gif)

* Reply or Open session by Alfred  [wechat-alfred-workflow](https://github.com/TKkk-iOSer/wechat-alfred-workflow)   
![alfred](./Other/ScreenShots/alfred_search.gif)

---

## Dependency

* [XMLReader](https://github.com/amarcadet/XMLReader)
* [insert_dylib](https://github.com/Tyilo/insert_dylib)
* [fishhook](https://github.com/facebook/fishhook)
* [GCDWebServer](https://github.com/swisspol/GCDWebServer)

---

### I hear somebody want to buy me a cup of coffee😏
 
<img src="http://upload-images.jianshu.io/upload_images/965383-cbc86dc1d75a6242.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="250" hspace="50"/>&nbsp;&nbsp;&nbsp;<img src="http://upload-images.jianshu.io/upload_images/965383-76a1c7c91b987e1a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="250" hspace="50"  />

