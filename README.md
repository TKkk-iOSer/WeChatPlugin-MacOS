[TOC]
# 震惊！！！ macOS版微信竟可以这样消息防撤回
## 一、 前言
前一阵子入了 iOS 逆向的坑，整了个微信机器人，不过由于是用自己的证书打包，因此只能用7天，之后还得重新打包，实在麻烦。于是就拿macOS动刀了。   

本篇主要制作 mac OS 版微信的插件，实现<a>消息防撤回与自动回复</a>的功能，从而熟悉 mac OS 插件制作,由于 ~~(lan ai)~~ mac OS 逆向分析与 iOS 类似，且不像 iOS 有那么多的工具，因此花费的时间较多，这里暂不阐述。~~之后有时间再整理 iOS 逆向分析过程。~~

* 基本原理：与 iOS 注入动态库类似，通过 app 启动时调用我们注入的动态库，从而进行 hook。
* 插件 GitHub 地址: [WeChatPlugin](https://github.com/tusiji7/WeChatPlugin)
* Demo 演示

消息防撤回   
![消息防撤回.gif](http://upload-images.jianshu.io/upload_images/965383-30cbea645661e627.gif?imageMogr2/auto-orient/strip)

自动回复
![自动回复.gif](http://upload-images.jianshu.io/upload_images/965383-b61b6d983c90e0c5.gif?imageMogr2/auto-orient/strip)

## 二、安装与使用
* 下载 WeChatPlugin, 先进行 build (`command + B`)，之后 run (`command + R`)即可启动微信，此时插件注入完成。~~(若出现 error 请往下看 **3.5 注意** 部分)~~

* 登录微信，可在**菜单栏-帮助**中看到消息防撤回与自动回复。

![菜单栏-帮助.png](http://upload-images.jianshu.io/upload_images/965383-7c6ec7a738f81c0c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

* 消息防撤回：点击`开启消息防撤回`或者快捷键`command + t`,即可开启、关闭。
* 自动回复：点击`开启自动回复`或者快捷键`conmand + k`，将弹出自动回复设置的窗口，在窗口中输入关键字与回复内容，点击保存即可。~~(若无关键字保存，则所有消息都会自动回复)~~

![自动回复设置.png](http://upload-images.jianshu.io/upload_images/965383-060903126e9da7a3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

* 卸载

    在 `/Applications/WeChat.app/Contents/MacOS` 目录中，删除 `WeChat` 与 `WeChatPlugin.framework`，将`WeChat_backup` 重命名为 `WeChat` 即可。

## 三、plugin 制作
### 3.1 创建Framework
使用 Xcode 创建 macOS 的 Cocoa Framework.


![创建Cocoa Framework.png](http://upload-images.jianshu.io/upload_images/965383-f975dee2f0c956f2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 3.2 Edit Scheme…
编辑 scheme，在 debug 模式下启动 WeChat。
![Edit Scheme.png](http://upload-images.jianshu.io/upload_images/965383-26dbb068acb8998f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![choose executable.gif](http://upload-images.jianshu.io/upload_images/965383-7fbd4dc6e8d161dc.gif?imageMogr2/auto-orient/strip)

###3.3 添加Run Script
在 Build Phases 中添加 run script

![add run scripe.gif](http://upload-images.jianshu.io/upload_images/965383-c4c94d035b7def3c.gif?imageMogr2/auto-orient/strip)

script 内容如下

``` bash
#!/bin/bash
# 要注入的的app
app_name="WeChat"
# 此framework名字
framework_name="WeChatPlugin"
app_bundle_path="/Applications/${app_name}.app/Contents/MacOS"
app_executable_path="${app_bundle_path}/${app_name}"
app_executable_backup_path="${app_executable_path}_backup"
framework_path="${app_bundle_path}/${framework_name}.framework"
# 备份WeChat原始可执行文件
if [ ! -f "$app_executable_backup_path" ]
then
cp "$app_executable_path" "$app_executable_backup_path"
fi
cp -r "${BUILT_PRODUCTS_DIR}/${framework_name}.framework" ${app_bundle_path}
# 注入动态库
./insert_dylib --all-yes "${framework_path}/${framework_name}" "$app_executable_backup_path" "$app_executable_path"
```

**其中insert_dylib来源于[github](https://github.com/Tyilo/insert_dylib)(~~与iOS的insert_dylib不同~~)**

### 3.4 创建 main.mm

创建 main.mm 文件，添加构造方法。

![Paste_Image.png](http://upload-images.jianshu.io/upload_images/965383-bd6a3a36c065a8b2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

此时，一运行，即可执行`initalize`中的方法,并启动微信。

<a>因此，我们就可以在这里愉快的进行hook！！！</a>

### 3.5 **注意**

* 若 error，提示无权限，请对 WeChat 赋予权限。
`sudo chmod -R 777 /Applications/WeChat.app`
* 若 error，提示找不到 framework，先进行 build。

## 四、愉快的 hook (以撤回消息为例)
### 4.1 创建 NSObject 分类
新建 NSObject 分类，加入类方法`+(void)hookWeChat;`并在 main.mm 中执行该方法。之后所有的hook都可以在该类方法中进行。

```
#import "WeChat+hook.h"

static void __attribute__((constructor)) initialize(void) {
    NSLog(@"++++++++ WeChatPlugin loaded ++++++++");
    [NSObject hook_WeChat];
}
```

### 4.2 寻找注入点
首先使用`class-dump`,dump 出微信的头文件信息。~~(如何使用请左转[iOS 逆向 - 微信 helloWorld](http://www.jianshu.com/p/04495a429324))~~
因为在 iOS 中，微信撤回的函数为`- (void)onRevokeMsg:(id)arg1;`因此，我们在微信的头文件中搜索该方法，最终在`MessageService.h`中找到。

### 4.3 runtime 登场
到这里就要开始进行 hook 了，在`+(void)hookWeChat;`中进行`methodExchange`。
将`MessageService`的`- (void)onRevokeMsg:(id)arg1;`方法实现替换成`NSObject`的`- (void)hook_onRevokeMsg:(id)msg`方法。

```
+ (void)hookWeChat {
    //      微信撤回消息
    Method originalMethod = class_getInstanceMethod(objc_getClass("MessageService"), @selector(onRevokeMsg:));
    Method swizzledMethod = class_getInstanceMethod([self class], @selector(hook_onRevokeMsg:));
    if(originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)hook_onRevokeMsg:(id)msg {
    NSLog(@"=== TK-LOG-msg = %@===",msg);
    [self hook_onRevokeMsg:msg];
}
```

### 4.4 验证
由于是使用 Xcode，就不用像 iOS 逆向那样只能用 lldb 调试了。可以在`- (void)hook_onRevokeMsg:(id)msg`中打个断点，然后撤回消息看是否会触发。结果证明该方法确实是微信消息撤回的处理方法。

### 4.5 使用 Hopper Disassembler
接着我们在`- (void)hook_onRevokeMsg:(id)msg`中直接`return`就可以了。
然而这时候看不到到底是撤回了哪一条信息。我们可以在用户撤回的时候将下面的内容改成"拦截 xx 的一条撤回消息：xxxx"。
 
![撤回.png](http://upload-images.jianshu.io/upload_images/965383-3ca5031305263ca2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

这时候就要使用神器 `Hopper Disassembler`.用`hopper Disassembler` 进行分析，分析`- (void)onRevokeMsg:(id)arg1;`的实现。~~(分析过程与iOS类似，这里暂不阐述)~~
最终得到了主要的代码实现。~~（完整代码在工程中）~~

```
MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
MessageData *revokeMsgData = [msgService GetMsgData:session svrId:[newmsgid integerValue]];
MessageData *newMsgData = ({
        MessageData *msg = [[objc_getClass("MessageData") alloc] initWithMsgType:0x2710];
        [msg setFromUsrName:revokeMsgData.toUsrName];
        [msg setToUsrName:revokeMsgData.fromUsrName];
        [msg setMsgStatus:4];
        [msg setMsgContent:newMsgContent];
        [msg setMsgCreateTime:[revokeMsgData msgCreateTime]];
        [msg setMesLocalID:[revokeMsgData mesLocalID]];
        
        msg;
    });
    
[msgService AddLocalMsg:session msgData:newMsgData];
```

## 五、效果
点击 `菜单栏-帮助-开启消息防撤回`，当好友撤回消息是可以看到提示。
![消息防撤回.gif](http://upload-images.jianshu.io/upload_images/965383-30cbea645661e627.gif?imageMogr2/auto-orient/strip)

## 六、小结
最终我们得到了拥有消息防撤回与自动回复的 macOS 版微信，虽然整个过程挺简单的，但主要目标是为了熟悉了如何制作 macOS 插件的过程，这样以后就可以给 macOS 上的 app 增加点小功能了。

由于本人还只是个逆向新手，难免会有所疏漏，还请大牛们指正。
本项目仅供学习参考。

## 七、参考

[如何愉快地在Mac上刷朋友圈](http://www.iosre.com/t/mac/7014/2)

