
本插件主要实现 macOS 版微信的<a>消息防撤回与自动回复</a>的功能，详细内容，请参考[我的博客](http://www.jianshu.com/p/7f65287a2e7a)
### Demo 演示

消息防撤回   
![消息防撤回.gif](http://upload-images.jianshu.io/upload_images/965383-30cbea645661e627.gif?imageMogr2/auto-orient/strip)

自动回复
![自动回复.gif](http://upload-images.jianshu.io/upload_images/965383-b61b6d983c90e0c5.gif?imageMogr2/auto-orient/strip)

### 安装
* 下载 WeChatPlugin, 先进行 Build (`command + B`)，之后 Run (`command + R`)即可启动微信，此时插件注入完成。
 
* 若 Error，提示无权限，请对 WeChat 赋予权限。
`sudo chmod -R 777 /Applications/WeChat.app`
* 若 Error，提示找不到 Framework，先进行 Build。

* 登录微信，在**菜单栏-帮助**中看到消息防撤回与自动回复即安装成功。
![菜单栏-帮助.png](http://upload-images.jianshu.io/upload_images/965383-7c6ec7a738f81c0c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 使用

* 消息防撤回：点击`开启消息防撤回`或者快捷键`command + t`,即可开启、关闭。
* 自动回复：点击`开启自动回复`或者快捷键`conmand + k`，将弹出自动回复设置的窗口，在窗口中输入关键字与回复内容，点击保存即可。~~(若无关键字保存，则所有消息都会自动回复)~~

![自动回复设置.png](http://upload-images.jianshu.io/upload_images/965383-060903126e9da7a3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 卸载

在 `/Applications/WeChat.app/Contents/MacOS` 目录中，删除 `WeChat` 与 `WeChatPlugin.framework`，将`WeChat_backup` 重命名为 `WeChat` 即可。

