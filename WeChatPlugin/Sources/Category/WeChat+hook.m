//
//  WeChat+hook.m
//  WeChatPlugin
//
//  Created by TK on 2017/4/19.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "WeChat+hook.h"
#import "WeChatPlugin.h"
#import "XMLReader.h"
#import "fishhook.h"
#import "TKIgnoreSessonModel.h"
#import "TKRemoteControlController.h"
#import "TKAutoReplyWindowController.h"
#import "TKRemoteControlWindowController.h"
#import "TKVersionManager.h"
#import "TKWebServerManager.h"

static char tkAutoReplyWindowControllerKey;         //  自动回复窗口的关联 key
static char tkRemoteControlWindowControllerKey;     //  远程控制窗口的关联 key

@implementation NSObject (WeChatHook)

+ (void)hookWeChat {
    //      微信撤回消息
    tk_hookMethod(objc_getClass("MessageService"), @selector(onRevokeMsg:), [self class], @selector(hook_onRevokeMsg:));
    //      微信消息同步
    tk_hookMethod(objc_getClass("MessageService"), @selector(OnSyncBatchAddMsgs:isFirstSync:), [self class], @selector(hook_OnSyncBatchAddMsgs:isFirstSync:));
    //      微信多开
    tk_hookClassMethod(objc_getClass("CUtility"), @selector(HasWechatInstance), [self class], @selector(hook_HasWechatInstance));
    //      免认证登录
    tk_hookMethod(objc_getClass("MMLoginOneClickViewController"), @selector(onLoginButtonClicked:), [self class], @selector(hook_onLoginButtonClicked:));
    tk_hookMethod(objc_getClass("LogoutCGI"), @selector(sendLogoutCGIWithCompletion:), [self class], @selector(hook_sendLogoutCGIWithCompletion:));
    //      自动登录
    tk_hookMethod(objc_getClass("MMLoginOneClickViewController"), @selector(viewWillAppear), [self class], @selector(hook_viewWillAppear));
    //      置底
    tk_hookMethod(objc_getClass("MMSessionMgr"), @selector(sortSessions), [self class], @selector(hook_sortSessions));
    //      窗口置顶
    tk_hookMethod(objc_getClass("NSWindow"), @selector(makeKeyAndOrderFront:), [self class], @selector(hook_makeKeyAndOrderFront:));
    //      快捷回复
    tk_hookMethod(objc_getClass("_NSConcreteUserNotificationCenter"), @selector(deliverNotification:), [self class], @selector(hook_deliverNotification:));
    tk_hookMethod(objc_getClass("MMNotificationService"), @selector(userNotificationCenter:didActivateNotification:), [self class], @selector(hook_userNotificationCenter:didActivateNotification:));
    tk_hookMethod(objc_getClass("MMNotificationService"), @selector(getNotificationContentWithMsgData:), [self class], @selector(hook_getNotificationContentWithMsgData:));
    
    //      登录逻辑
    tk_hookMethod(objc_getClass("WeChat"), @selector(onAuthOK:), [self class], @selector(hook_onAuthOK:));
    
    //      替换沙盒路径
    rebind_symbols((struct rebinding[2]) {
        { "NSSearchPathForDirectoriesInDomains", swizzled_NSSearchPathForDirectoriesInDomains, (void *)&original_NSSearchPathForDirectoriesInDomains },
        { "NSHomeDirectory", swizzled_NSHomeDirectory, (void *)&original_NSHomeDirectory }
    }, 2);
    
    [self setup];
    [self checkPluginVersion];
}

+ (void)setup {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addAssistantMenuItem];
        
        BOOL onTop = [[TKWeChatPluginConfig sharedConfig] onTop];
        WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
        wechat.mainWindowController.window.level = onTop == NSControlStateValueOn ? NSNormalWindowLevel+2 : NSNormalWindowLevel;
    });
    //    监听 NSWindow 最小化通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowsWillMiniaturize:) name:NSWindowWillMiniaturizeNotification object:nil];
}

+ (void)checkPluginVersion {
    if ([[TKWeChatPluginConfig sharedConfig] forbidCheckVersion]) return;
    
    [[TKVersionManager shareManager] checkVersionFinish:^(TKVersionStatus status, NSString *message) {
        if (status == TKVersionStatusNew) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:TKLocalizedString(@"assistant.update.alret.confirm")];
                [alert addButtonWithTitle:TKLocalizedString(@"assistant.update.alret.forbid")];
                [alert addButtonWithTitle:TKLocalizedString(@"assistant.update.alret.cancle")];
                [alert setMessageText:TKLocalizedString(@"assistant.update.alret.title")];
                [alert setInformativeText:message];
                NSModalResponse respose = [alert runModal];
                if (respose == NSAlertFirstButtonReturn) {
                    NSURL *url = [NSURL URLWithString:@"https://github.com/TKkk-iOSer/WeChatPlugin-MacOS"];
                    [[NSWorkspace sharedWorkspace] openURL:url];
                } else if (respose == NSAlertSecondButtonReturn) {
                    [[TKWeChatPluginConfig sharedConfig] setForbidCheckVersion:YES];
                }
            });
        }
    }];
}

/**
 菜单栏添加 menuItem
 */
+ (void)addAssistantMenuItem {
    //        消息防撤回
    NSMenuItem *preventRevokeItem = [[NSMenuItem alloc] initWithTitle:TKLocalizedString(@"assistant.menu.revoke")
                                                               action:@selector(onPreventRevoke:)
                                                        keyEquivalent:@"t"];
    preventRevokeItem.state = [[TKWeChatPluginConfig sharedConfig] preventRevokeEnable];
    //        自动回复
    NSMenuItem *autoReplyItem = [[NSMenuItem alloc] initWithTitle:TKLocalizedString(@"assistant.menu.autoReply")
                                                           action:@selector(onAutoReply:)
                                                    keyEquivalent:@"k"];
    //        登录新微信
    NSMenuItem *newWeChatItem = [[NSMenuItem alloc] initWithTitle:TKLocalizedString(@"assistant.menu.newWeChat")
                                                           action:@selector(onNewWechatInstance:)
                                                    keyEquivalent:@"N"];
    //        远程控制
    NSMenuItem *commandItem = [[NSMenuItem alloc] initWithTitle:TKLocalizedString(@"assistant.menu.remoteControl")
                                                         action:@selector(onRemoteControl:)
                                                  keyEquivalent:@"C"];
    //        微信窗口置顶
    NSMenuItem *onTopItem = [[NSMenuItem alloc] initWithTitle:TKLocalizedString(@"assistant.menu.windowSticky")
                                                       action:@selector(onWechatOnTopControl:)
                                                keyEquivalent:@"D"];
    onTopItem.state = [[TKWeChatPluginConfig sharedConfig] onTop];
    //        免认证登录
    NSMenuItem *autoAuthItem = [[NSMenuItem alloc] initWithTitle:TKLocalizedString(@"assistant.menu.freeLogin")
                                                          action:@selector(onAutoAuthControl:)
                                                   keyEquivalent:@"M"];
    autoAuthItem.state = [[TKWeChatPluginConfig sharedConfig] autoAuthEnable];
    //        更新小助手
    NSMenuItem *updatePluginItem = [[NSMenuItem alloc] initWithTitle:TKLocalizedString(@"assistant.menu.updateAssistant")
                                                              action:@selector(onUpdatePluginControl:)
                                                       keyEquivalent:@""];
    
    NSMenu *subMenu = [[NSMenu alloc] initWithTitle:TKLocalizedString(@"assistant.menu.title")];
    [subMenu addItems:@[preventRevokeItem,
                        autoReplyItem,
                        commandItem,
                        newWeChatItem,
                        onTopItem,
                        autoAuthItem,
                        updatePluginItem]];
    
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    [menuItem setTitle:TKLocalizedString(@"assistant.menu.title")];
    [menuItem setSubmenu:subMenu];

    [[[NSApplication sharedApplication] mainMenu] addItem:menuItem];
    menuItem.enabled = NO;
}

#pragma mark - menuItem 的点击事件
/**
 菜单栏-微信小助手-消息防撤回 设置
 
 @param item 消息防撤回的item
 */
- (void)onPreventRevoke:(NSMenuItem *)item {
    item.state = !item.state;
    [[TKWeChatPluginConfig sharedConfig] setPreventRevokeEnable:item.state];
}

/**
 菜单栏-微信小助手-自动回复 设置
 
 @param item 自动回复设置的item
 */
- (void)onAutoReply:(NSMenuItem *)item {
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    TKAutoReplyWindowController *autoReplyWC = objc_getAssociatedObject(wechat, &tkAutoReplyWindowControllerKey);
    
    if (!autoReplyWC) {
        autoReplyWC = [[TKAutoReplyWindowController alloc] initWithWindowNibName:@"TKAutoReplyWindowController"];
        objc_setAssociatedObject(wechat, &tkAutoReplyWindowControllerKey, autoReplyWC, OBJC_ASSOCIATION_RETAIN);
    }
    
    [autoReplyWC showWindow:autoReplyWC];
    [autoReplyWC.window center];
    [autoReplyWC.window makeKeyWindow];
}

/**
 打开新的微信
 
 @param item 登录新微信的item
 */
- (void)onNewWechatInstance:(NSMenuItem *)item {
    [TKRemoteControlController executeShellCommand:@"open -n /Applications/WeChat.app"];
}

/**
 菜单栏-帮助-远程控制 MAC OS 设置
 
 @param item 远程控制的item
 */
- (void)onRemoteControl:(NSMenuItem *)item {
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    TKRemoteControlWindowController *remoteControlWC = objc_getAssociatedObject(wechat, &tkRemoteControlWindowControllerKey);
    
    if (!remoteControlWC) {
        remoteControlWC = [[TKRemoteControlWindowController alloc] initWithWindowNibName:@"TKRemoteControlWindowController"];
        objc_setAssociatedObject(wechat, &tkRemoteControlWindowControllerKey, remoteControlWC, OBJC_ASSOCIATION_RETAIN);
    }
    
    [remoteControlWC showWindow:remoteControlWC];
    [remoteControlWC.window center];
    [remoteControlWC.window makeKeyWindow];
}

/**
 菜单栏-微信小助手-免认证登录 设置
 
 @param item 免认证登录的 item
 */
- (void)onAutoAuthControl:(NSMenuItem *)item {
    item.state = !item.state;
    [[TKWeChatPluginConfig sharedConfig] setAutoAuthEnable:item.state];
}

/**
 菜单栏-微信小助手-微信窗口置顶
 
 @param item 免认证登录的 item
 */
- (void)onWechatOnTopControl:(NSMenuItem *)item {
    item.state = !item.state;
    [[TKWeChatPluginConfig sharedConfig] setOnTop:item.state];

    NSArray *windows = [[NSApplication sharedApplication] windows];
    [windows enumerateObjectsUsingBlock:^(NSWindow *window, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![window.className isEqualToString:@"NSStatusBarWindow"]) {
            window.level = item.state == NSControlStateValueOn ? NSNormalWindowLevel+2 : NSNormalWindowLevel;
        }
    }];
}

/**
 菜单栏-微信小助手-更新小助手
 
 @param item 更新小助手的 item
 */
- (void)onUpdatePluginControl:(NSMenuItem *)item {
    [[TKWeChatPluginConfig sharedConfig] setForbidCheckVersion:NO];
    [[TKVersionManager shareManager] checkVersionFinish:^(TKVersionStatus status, NSString *message) {
        if (status == TKVersionStatusNew) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:TKLocalizedString(@"assistant.update.alret.confirm")];
            [alert addButtonWithTitle:TKLocalizedString(@"assistant.update.alret.cancle")];
            [alert setMessageText:TKLocalizedString(@"assistant.update.alret.title")];
            [alert setInformativeText:message];
            NSModalResponse respose = [alert runModal];
            if (respose == NSAlertFirstButtonReturn) {
                NSURL *url = [NSURL URLWithString:@"https://github.com/TKkk-iOSer/WeChatPlugin-MacOS"];
                [[NSWorkspace sharedWorkspace] openURL:url];
            }
        } else {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:TKLocalizedString(@"assistant.update.alret.latest")];
            [alert setInformativeText:message];
            [alert runModal];
        }
    }];
}

/**
 登录界面-自动登录
 
 @param btn 自动登录按钮
 */
- (void)selectAutoLogin:(NSButton *)btn {
    [[TKWeChatPluginConfig sharedConfig] setAutoLoginEnable:btn.state];
}

#pragma mark - hook 微信方法
/**
 hook 微信是否已启动
 
 */
+ (BOOL)hook_HasWechatInstance {
    return NO;
}

/**
 hook 微信撤回消息
 
 */
- (void)hook_onRevokeMsg:(id)msg {
    if (![[TKWeChatPluginConfig sharedConfig] preventRevokeEnable]) {
        [self hook_onRevokeMsg:msg];
        return;
    }
    if ([msg rangeOfString:@"<sysmsg"].length <= 0) return;
    
    //      转换群聊的 msg
    NSString *msgContent = [msg substringFromIndex:[msg rangeOfString:@"<sysmsg"].location];
    
    //      xml 转 dict
    NSError *error;
    NSDictionary *msgDict = [XMLReader dictionaryForXMLString:msgContent error:&error];
    
    if (!error && msgDict && msgDict[@"sysmsg"] && msgDict[@"sysmsg"][@"revokemsg"]) {
        NSString *newmsgid = msgDict[@"sysmsg"][@"revokemsg"][@"newmsgid"][@"text"];
        NSString *session =  msgDict[@"sysmsg"][@"revokemsg"][@"session"][@"text"];
        msgDict = nil;
        
        NSMutableSet *revokeMsgSet = [[TKWeChatPluginConfig sharedConfig] revokeMsgSet];
        //      该消息已进行过防撤回处理
        if ([revokeMsgSet containsObject:newmsgid] || !newmsgid) {
            return;
        }
        [revokeMsgSet addObject:newmsgid];
        
        //      获取原始的撤回提示消息
        MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
        MessageData *revokeMsgData = [msgService GetMsgData:session svrId:[newmsgid integerValue]];
        NSString *msgContent = [revokeMsgData getRealMessageContent];

        NSString *msgType;
        if (revokeMsgData.messageType == 1) {
            msgType = @"";
        } else if ([revokeMsgData isCustomEmojiMsg]) {
            msgType = TKLocalizedString(@"assistant.revokeType.emoji");
        } else if ([revokeMsgData isImgMsg]) {
            msgType = TKLocalizedString(@"assistant.revokeType.image");
        } else if ([revokeMsgData isVideoMsg]) {
            msgType = TKLocalizedString(@"assistant.revokeType.video");
        } else if ([revokeMsgData isVoiceMsg]) {
            msgType = TKLocalizedString(@"assistant.revokeType.voice");
        } else {
            msgType = TKLocalizedString(@"assistant.revokeType.other");
        }
        
        NSString *newMsgContent = [NSString stringWithFormat:@"%@ \n%@",TKLocalizedString(@"assistant.revoke.otherMessage.tip"), msgType];
        //      判断是否是自己发起撤回
        if ([revokeMsgData isSendFromSelf]) {
            if (revokeMsgData.messageType == 1) {       // 判断是否为文本消息
                newMsgContent = [NSString stringWithFormat:@"%@\n %@",TKLocalizedString(@"assistant.revoke.selfMessage.tip"), msgContent];
            } else {
                newMsgContent = [NSString stringWithFormat:@"%@\n %@",TKLocalizedString(@"assistant.revoke.selfMessage.tip"), msgType];
            }
        } else {
            NSString *displayName = [revokeMsgData groupChatSenderDisplayName];
            if (revokeMsgData.messageType == 1) {
                if ([revokeMsgData isChatRoomMessage]) {
                    newMsgContent = [NSString stringWithFormat:@"%@\n%@ : %@",TKLocalizedString(@"assistant.revoke.otherMessage.tip"), displayName, msgContent];
                } else {
                    newMsgContent = [NSString stringWithFormat:@"%@\n%@",TKLocalizedString(@"assistant.revoke.otherMessage.tip"), msgContent];
                }
            } else {
                if ([revokeMsgData isChatRoomMessage]) {
                    newMsgContent = [NSString stringWithFormat:@"%@ \n %@ : %@",TKLocalizedString(@"assistant.revoke.otherMessage.tip"), displayName, msgType];
                }
            }
        }
        MessageData *newMsgData = ({
            MessageData *msg = [[objc_getClass("MessageData") alloc] initWithMsgType:0x2710];
            [msg setFromUsrName:revokeMsgData.toUsrName];
            [msg setToUsrName:revokeMsgData.fromUsrName];
            [msg setMsgStatus:4];
            [msg setMsgContent:newMsgContent];
            [msg setMsgCreateTime:[revokeMsgData msgCreateTime]];
            //   [msg setMesLocalID:[revokeMsgData mesLocalID]];
            
            msg;
        });
        
        [msgService AddLocalMsg:session msgData:newMsgData];
    }
}

/**
 hook 微信消息同步
 
 */
- (void)hook_OnSyncBatchAddMsgs:(NSArray *)msgs isFirstSync:(BOOL)arg2 {
    [self hook_OnSyncBatchAddMsgs:msgs isFirstSync:arg2];
    
    [msgs enumerateObjectsUsingBlock:^(AddMsg *addMsg, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDate *now = [NSDate date];
        NSTimeInterval nowSecond = now.timeIntervalSince1970;
        if (nowSecond - addMsg.createTime > 180) {      // 若是3分钟前的消息，则不进行自动回复与远程控制。
            return;
        }
        
        [self autoReplyWithMsg:addMsg];
        
        NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
        if ([addMsg.fromUserName.string isEqualToString:currentUserName] &&
            [addMsg.toUserName.string isEqualToString:currentUserName]) {
            [self remoteControlWithMsg:addMsg];
            [self replySelfWithMsg:addMsg];
        }
    }];
}

/**
 hook 微信通知消息
 
 */
- (id)hook_getNotificationContentWithMsgData:(MessageData *)arg1 {
    [[TKWeChatPluginConfig sharedConfig] setCurrentUserName:arg1.toUsrName];
    return [self hook_getNotificationContentWithMsgData:arg1];;
}

- (void)hook_deliverNotification:(NSUserNotification *)notification {
    NSMutableDictionary *dict = [notification.userInfo mutableCopy];
    dict[@"currnetName"] = [[TKWeChatPluginConfig sharedConfig] currentUserName];
    notification.userInfo = dict;
    notification.hasReplyButton = YES;
    [self hook_deliverNotification:notification];
}

- (void)hook_userNotificationCenter:(id)notificationCenter didActivateNotification:(NSUserNotification *)notification {
    NSString *chatName = notification.userInfo[@"ChatName"];
    if (chatName && notification.response.string) {
        NSString *instanceUserName = [objc_getClass("CUtility") GetCurrentUserName];
        NSString *currentUserName = notification.userInfo[@"currnetName"];
        if ([instanceUserName isEqualToString:currentUserName]) {
            MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
            [service SendTextMessage:currentUserName toUsrName:chatName msgText:notification.response.string atUserList:nil];
            [service ClearUnRead:chatName FromID:0 ToID:0];
        }
    } else {
        [self hook_userNotificationCenter:notificationCenter didActivateNotification:notification];
    }
}

/**
 hook 自动登录
 
 */
- (void)hook_onLoginButtonClicked:(NSButton *)btn {
    AccountService *accountService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("AccountService")];
    BOOL autoAuthEnable = [[TKWeChatPluginConfig sharedConfig] autoAuthEnable];
    if (autoAuthEnable && [accountService canAutoAuth]) {
        [accountService AutoAuth];
        
        WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
        MMLoginOneClickViewController *loginVC = wechat.mainWindowController.loginViewController.oneClickViewController;
        loginVC.loginButton.hidden = YES;
        ////        [wechat.mainWindowController onAuthOK];
        loginVC.descriptionLabel.stringValue = TKLocalizedString(@"assistant.autoAuth.tip");
        loginVC.descriptionLabel.textColor = TK_RGB(0x88, 0x88, 0x88);
        loginVC.descriptionLabel.hidden = NO;
    } else {
        [self hook_onLoginButtonClicked:btn];
    }
}

- (void)hook_onAuthOK:(BOOL)arg1 {
    [self hook_onAuthOK:arg1];
    NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
    NSMenuItem *pluginMenu = mainMenu.itemArray.lastObject;
    pluginMenu.enabled = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[TKWebServerManager shareManager] startServer];
    });
}

- (void)hook_sendLogoutCGIWithCompletion:(id)arg1 {
    [[TKWebServerManager shareManager] endServer];
    
    BOOL autoAuthEnable = [[TKWeChatPluginConfig sharedConfig] autoAuthEnable];
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    if (autoAuthEnable && wechat.isAppTerminating) return;
    
    return [self hook_sendLogoutCGIWithCompletion:arg1];
}

- (void)hook_viewWillAppear {
    [self hook_viewWillAppear];
    
    BOOL autoAuthEnable = [[TKWeChatPluginConfig sharedConfig] autoAuthEnable];
    if (![self.className isEqualToString:@"MMLoginOneClickViewController"] || !autoAuthEnable) return;

    NSButton *autoLoginButton = ({
        NSButton *btn = [NSButton tk_checkboxWithTitle:@"" target:self action:@selector(selectAutoLogin:)];
        btn.frame = NSMakeRect(110, 60, 80, 30);
        NSMutableParagraphStyle *pghStyle = [[NSMutableParagraphStyle alloc] init];
        pghStyle.alignment = NSTextAlignmentCenter;
        NSDictionary *dicAtt = @{NSForegroundColorAttributeName: kBG4, NSParagraphStyleAttributeName: pghStyle};
        btn.attributedTitle = [[NSAttributedString alloc] initWithString:TKLocalizedString(@"assistant.autoLogin.text") attributes:dicAtt];
        
        btn;
    });
    
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    MMLoginOneClickViewController *loginVC = wechat.mainWindowController.loginViewController.oneClickViewController;
    [loginVC.view addSubview:autoLoginButton];
    
    BOOL autoLogin = [[TKWeChatPluginConfig sharedConfig] autoLoginEnable];
    autoLoginButton.state = autoLogin;
    
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSArray *instances = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleIdentifier];
    BOOL wechatHasRun = instances.count == 1;
    
    if (autoLogin && wechatHasRun) {
        [loginVC onLoginButtonClicked:nil];
    }
}

- (void)hook_sortSessions {
    [self hook_sortSessions];
    
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    NSMutableArray *arrSession = sessionMgr.m_arrSession;
    NSMutableArray *ignoreSessions = [[[TKWeChatPluginConfig sharedConfig] ignoreSessionModels] mutableCopy];
    
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    [ignoreSessions enumerateObjectsUsingBlock:^(TKIgnoreSessonModel *model, NSUInteger index, BOOL * _Nonnull stop) {
        __block NSInteger ignoreIdx = -1;
        [arrSession enumerateObjectsUsingBlock:^(MMSessionInfo *sessionInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([model.userName isEqualToString:sessionInfo.m_nsUserName] && [model.selfContact isEqualToString:currentUserName]) {
                ignoreIdx = idx;
                *stop = YES;
            }
        }];
        
        if (ignoreIdx != -1) {
            MMSessionInfo *sessionInfo = arrSession[ignoreIdx];
            [arrSession removeObjectAtIndex:ignoreIdx];
            [arrSession addObject:sessionInfo];
        }
    }];
    
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    [wechat.chatsViewController.tableView reloadData];
}

#pragma mark - hook 系统方法
- (void)hook_makeKeyAndOrderFront:(nullable id)sender {
    BOOL top = [[TKWeChatPluginConfig sharedConfig] onTop];
    ((NSWindow *)self).level = top == NSControlStateValueOn ? NSNormalWindowLevel+2 : NSNormalWindowLevel;
    
    [self hook_makeKeyAndOrderFront:sender];
}

#pragma mark - Other
/**
 自动回复
 
 @param addMsg 接收的消息
 */
- (void)autoReplyWithMsg:(AddMsg *)addMsg {
    if (addMsg.msgType != 1 && addMsg.msgType != 3) return;
    
    NSString *userName = addMsg.fromUserName.string;
    
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    WCContactData *msgContact = [sessionMgr getContact:userName];
    if ([msgContact isBrandContact] || [msgContact isSelf]) {
        //        该消息为公众号或者本人发送的消息
        return;
    }
    NSArray *autoReplyModels = [[TKWeChatPluginConfig sharedConfig] autoReplyModels];
    [autoReplyModels enumerateObjectsUsingBlock:^(TKAutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!model.enable) return;
        if (!model.replyContent || model.replyContent.length == 0) return;
        
        if (model.enableSpecificReply) {
            if ([model.specificContacts containsObject:userName]) {
                [self replyWithMsg:addMsg model:model];
            }
            return;
        }
        if ([addMsg.fromUserName.string containsString:@"@chatroom"] && !model.enableGroupReply) return;
        if (![addMsg.fromUserName.string containsString:@"@chatroom"] && !model.enableSingleReply) return;
        
        [self replyWithMsg:addMsg model:model];
    }];
}

- (void)replyWithMsg:(AddMsg *)addMsg model:(TKAutoReplyModel *)model {
    NSString *msgContent = addMsg.content.string;
    if ([addMsg.fromUserName.string containsString:@"@chatroom"]) {
        NSRange range = [msgContent rangeOfString:@":\n"];
        if (range.length > 0) {
            msgContent = [msgContent substringFromIndex:range.location + range.length];
        }
    }
    
    NSArray *replyArray = [model.replyContent componentsSeparatedByString:@"|"];
    int index = arc4random() % replyArray.count;
    NSString *randomReplyContent = replyArray[index];
    NSInteger delayTime = model.enableDelay ? model.delayTime : 0;
    
    if (model.enableRegex) {
        NSString *regex = model.keyword;
        NSError *error;
        NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
        if (error) return;
        NSInteger count = [regular numberOfMatchesInString:msgContent options:NSMatchingReportCompletion range:NSMakeRange(0, msgContent.length)];
        if (count > 0) {
            [self sendTextMessage:randomReplyContent toUsrName:addMsg.fromUserName.string delay:delayTime];
        }
    } else {
        NSArray * keyWordArray = [model.keyword componentsSeparatedByString:@"|"];
        [keyWordArray enumerateObjectsUsingBlock:^(NSString *keyword, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([keyword isEqualToString:@"*"] || [msgContent isEqualToString:keyword]) {
                [self sendTextMessage:randomReplyContent toUsrName:addMsg.fromUserName.string delay:delayTime];
                *stop = YES;
            }
        }];
    }
}

- (void)sendTextMessage:(id)msgContent toUsrName:(id)toUser delay:(NSInteger)delayTime {
    MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    
    if (delayTime == 0) {
        [service SendTextMessage:currentUserName toUsrName:toUser msgText:msgContent atUserList:nil];
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
             [service SendTextMessage:currentUserName toUsrName:toUser msgText:msgContent atUserList:nil];
        });
    });
}

/**
 远程控制
 
 @param addMsg 接收的消息
 */
- (void)remoteControlWithMsg:(AddMsg *)addMsg {
    if (addMsg.msgType == 1 || addMsg.msgType == 3) {
        [TKRemoteControlController executeRemoteControlCommandWithMsg:addMsg.content.string];
    } else if (addMsg.msgType == 34) {
        //      此为语音消息
        MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
        MessageData *msgData = [msgService GetMsgData:addMsg.fromUserName.string svrId:addMsg.newMsgId];
        long long mesSvrID = msgData.mesSvrID;
        NSString *sessionName = msgData.fromUsrName;
        [msgService TranscribeVoiceMessage:msgData completion:^ {
            MessageData *callbackMsgData = [msgService GetMsgData:sessionName svrId:mesSvrID];
            dispatch_async(dispatch_get_main_queue(), ^{
                [TKRemoteControlController executeRemoteControlCommandWithVoiceMsg:callbackMsgData.msgVoiceText];
            });
        }];
    }
}

- (void)replySelfWithMsg:(AddMsg *)addMsg {
    if (addMsg.msgType != 1 && addMsg.msgType != 3) return;
    
    if ([addMsg.content.string isEqualToString:TKLocalizedString(@"assistant.remoteControl.getList")]) {
        NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
        NSString *callBack = [TKRemoteControlController remoteControlCommandsString];
        MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
        [service SendTextMessage:currentUserName toUsrName:currentUserName msgText:callBack atUserList:nil];
    }
}

- (void)windowsWillMiniaturize:(NSNotification *)notification {
    NSObject *window = notification.object;
    ((NSWindow *)window).level =NSNormalWindowLevel;
}

#pragma mark - 替换 NSSearchPathForDirectoriesInDomains & NSHomeDirectory
static NSArray<NSString *> *(*original_NSSearchPathForDirectoriesInDomains)(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde);

NSArray<NSString *> *swizzled_NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde) {
    NSMutableArray<NSString *> *paths = [original_NSSearchPathForDirectoriesInDomains(directory, domainMask, expandTilde) mutableCopy];
    NSString *sandBoxPath = [NSString stringWithFormat:@"%@/Library/Containers/com.tencent.xinWeChat/Data",original_NSHomeDirectory()];
    
    [paths enumerateObjectsUsingBlock:^(NSString *filePath, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = [filePath rangeOfString:original_NSHomeDirectory()];
        if (range.length > 0) {
            NSMutableString *newFilePath = [filePath mutableCopy];
            [newFilePath replaceCharactersInRange:range withString:sandBoxPath];
            paths[idx] = newFilePath;
        }
    }];
    
    return paths;
}

static NSString *(*original_NSHomeDirectory)(void);

NSString *swizzled_NSHomeDirectory(void) {
    return [NSString stringWithFormat:@"%@/Library/Containers/com.tencent.xinWeChat/Data",original_NSHomeDirectory()];
}

@end
