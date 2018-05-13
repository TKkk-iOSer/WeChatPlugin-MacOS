

![wechat assistant.png](./Other/ScreenShots/en/wechatplugin.png)

![platform](https://img.shields.io/badge/platform-macos-lightgrey.svg)  [![release](https://img.shields.io/badge/release-v1.7-brightgreen.svg)](https://github.com/TKkk-iOSer/WeChatPlugin-MacOS/releases)  ![support](https://img.shields.io/badge/support-wechat%202.3.10-blue.svg)  [![Readme](https://img.shields.io/badge/readme-中文-yellow.svg)](./README.md)  [![GitHub license](https://img.shields.io/github/license/TKkk-iOSer/WeChatPlugin-MacOS.svg)](https://github.com/TKkk-iOSer/WeChatPlugin-MacOS/blob/master/LICENSE)

# WeChatPlugin-macOS v1.7

**English | [中文](./README.md)**

[ [Feature](#feature) &bull; [Install](#install) &bull; [Uninstall](#uninstall) &bull; [Usage](#usage)]

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
* Make all session As Read
* Clear all empty session
* Remove url redirect

Remote Control：

- [x] Save Screen
- [x] Empty Trash
- [x] Lock Screen & Sleep  & Shut Down & Restart
- [x] Quit some app, include QQ、WeChat、Chrome、Safari。
- [x] NeteaseMusic(play、pause、next song、previous song、like song、unlike song)
- [x] Assistant(get all directive、prevent recall switch、auto reply switch、auto auth switch)

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
  ![Prevent message recall](./Other/ScreenShots/en/prevent_recall.gif)

* Message auto reply
  ![Message auto reply](./Other/ScreenShots/en/auto_reply.gif)

* Auto Login & Multiple WeChat
  ![Auto Auth & Multiple WeChat](./Other/ScreenShots/en/auto_auth_and_new.gif)

* Remote control (quit Chrome and Save Screen)
  ![remote_control.gif](./Other/ScreenShots/en/remote_control.gif)

* Session multiple delete & session sticky bottom &  delete empty session
  ![wechat assistant.png](./Other/ScreenShots/en/multiselect_and_stick_bottom_and_clear_empty.gif)


* Quick reply to notifications &  make all as Read  
  ![wechat assistant.png](./Other/ScreenShots/en/quick_reply_and_make_read.gif)


* Copy or export sticker  
  <img src="./Other/ScreenShots/en/emotion_copy_export.png" height="400" hspace="50" />

* Reply or Open session by Alfred  [wechat-alfred-workflow](https://github.com/TKkk-iOSer/wechat-alfred-workflow)   
  ![Alfred](./Other/ScreenShots/en/alfred.gif)


---

## Dependency

* [XMLReader](https://github.com/amarcadet/XMLReader)
* [insert_dylib](https://github.com/Tyilo/insert_dylib)
* [fishhook](https://github.com/facebook/fishhook)
* [GCDWebServer](https://github.com/swisspol/GCDWebServer)

---

### I hear somebody want to buy me a cup of coffee😏

<img src="http://upload-images.jianshu.io/upload_images/965383-cbc86dc1d75a6242.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="250" hspace="50"/>&nbsp;&nbsp;&nbsp;<img src="http://upload-images.jianshu.io/upload_images/965383-76a1c7c91b987e1a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="250" hspace="50"  />

