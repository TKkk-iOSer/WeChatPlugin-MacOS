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
#import "TKRemoteControlController.h"
#import "TKAutoReplyWindowController.h"
#import "TKRemoteControlWindowController.h"
#import "TKIgnoreSessonModel.h"

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
    //      置底
    tk_hookMethod(objc_getClass("MMSessionMgr"), @selector(sortSessions), [self class], @selector(hook_sortSessions));
    
    [self setup];
    [self replaceAboutFilePathMethod];
}

+ (void)setup {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addAssistantMenuItem];
        
        BOOL onTop = [[TKWeChatPluginConfig sharedConfig] onTop];
        WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
        wechat.mainWindowController.window.level = onTop == NSControlStateValueOn ? NSStatusWindowLevel : NSNormalWindowLevel;
    });
}

/**
 菜单栏添加 menuItem
 */
+ (void)addAssistantMenuItem {
    //        消息防撤回
    NSMenuItem *preventRevokeItem = [[NSMenuItem alloc] initWithTitle:@"开启消息防撤回" action:@selector(onPreventRevoke:) keyEquivalent:@"t"];
    preventRevokeItem.state = [[TKWeChatPluginConfig sharedConfig] preventRevokeEnable];
    //        自动回复
    NSMenuItem *autoReplyItem = [[NSMenuItem alloc] initWithTitle:@"自动回复设置" action:@selector(onAutoReply:) keyEquivalent:@"k"];
    //        登录新微信
    NSMenuItem *newWeChatItem = [[NSMenuItem alloc] initWithTitle:@"登录新微信" action:@selector(onNewWechatInstance:) keyEquivalent:@"N"];
    //        远程控制
    NSMenuItem *commandItem = [[NSMenuItem alloc] initWithTitle:@"远程控制Mac OS" action:@selector(onRemoteControl:) keyEquivalent:@"C"];
    //        微信窗口置顶
    NSMenuItem *onTopItem = [[NSMenuItem alloc] initWithTitle:@"微信窗口置顶" action:@selector(onWechatOnTopControl:) keyEquivalent:@"d"];
    onTopItem.state = [[TKWeChatPluginConfig sharedConfig] onTop];
    //        免认证登录
    NSMenuItem *autoAuthItem = [[NSMenuItem alloc] initWithTitle:@"免认证登录" action:@selector(onAutoAuthControl:) keyEquivalent:@"M"];
    autoAuthItem.state = [[TKWeChatPluginConfig sharedConfig] autoAuthEnable];
    
    NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"微信小助手"];
    [subMenu addItem:preventRevokeItem];
    [subMenu addItem:autoReplyItem];
    [subMenu addItem:commandItem];
    [subMenu addItem:newWeChatItem];
    [subMenu addItem:onTopItem];
    [subMenu addItem:autoAuthItem];
    
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    [menuItem setTitle:@"微信小助手"];
    [menuItem setSubmenu:subMenu];
    
    [[[NSApplication sharedApplication] mainMenu] addItem:menuItem];
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
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    wechat.mainWindowController.window.level = item.state == NSControlStateValueOn ? NSStatusWindowLevel : NSNormalWindowLevel;
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
        
        //      获取原始的撤回提示消息
        MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
        MessageData *revokeMsgData = [msgService GetMsgData:session svrId:[newmsgid integerValue]];
        
        //      获取自己的联系人信息
        NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
        
        NSString *newMsgContent = @"TK拦截到一条非文本撤回消息";
        //      判断是否是自己发起撤回
        if ([currentUserName isEqualToString:revokeMsgData.fromUsrName]) {
            if (revokeMsgData.messageType == 1) {       // 判断是否为文本消息
                newMsgContent = [NSString stringWithFormat:@"TK拦截到你撤回了一条消息：\n %@",revokeMsgData.msgContent];
            }
        } else {
            if (![revokeMsgData.msgPushContent isEqualToString:@""]) {
                newMsgContent = [NSString stringWithFormat:@"TK拦截到一条撤回消息：\n %@",revokeMsgData.msgPushContent];
            } else if (revokeMsgData.messageType == 1) {
                NSRange range = [revokeMsgData.msgContent rangeOfString:@":\n"];
                if (range.length > 0) {
                    NSString *content = [revokeMsgData.msgContent substringFromIndex:range.location + range.length];
                    newMsgContent = [NSString stringWithFormat:@"TK拦截到一条撤回消息：\n %@",content];
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
            //                [msg setMesLocalID:[revokeMsgData mesLocalID]];
            
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

- (void)hook_onLoginButtonClicked:(NSButton *)btn {
    AccountService *accountService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("AccountService")];
    BOOL autoAuthEnable = [[TKWeChatPluginConfig sharedConfig] autoAuthEnable];
    if (autoAuthEnable && [accountService canAutoAuth]) {
        [accountService AutoAuth];
        
        WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
        MMLoginOneClickViewController *loginVC = wechat.mainWindowController.loginViewController.oneClickViewController;
        loginVC.loginButton.hidden = YES;
        [wechat.mainWindowController onAuthOK];
        loginVC.descriptionLabel.stringValue = @"TK正在为你免认证登录~";
        loginVC.descriptionLabel.textColor = TK_RGB(0x88, 0x88, 0x88);
        loginVC.descriptionLabel.hidden = NO;
    } else {
        [self hook_onLoginButtonClicked:btn];
    }
}

- (void)hook_sendLogoutCGIWithCompletion:(id)arg1 {
    BOOL autoAuthEnable = [[TKWeChatPluginConfig sharedConfig] autoAuthEnable];
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    if (autoAuthEnable && wechat.isAppTerminating) return;
    
    return [self hook_sendLogoutCGIWithCompletion:arg1];
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

#pragma mark - Other
/**
 自动回复
 
 @param addMsg 接收的消息
 */
- (void)autoReplyWithMsg:(AddMsg *)addMsg {
    if (addMsg.msgType != 1 && addMsg.msgType != 3) return;
    
    ContactStorage *contactStorage = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("ContactStorage")];
    WCContactData *msgContact = [contactStorage GetContact:addMsg.fromUserName.string];
    if (msgContact.m_uiFriendScene == 0 && ![addMsg.fromUserName.string containsString:@"@chatroom"]) {
        //        该消息为公众号
        return;
    }
    MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
    
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    
    NSArray *autoReplyModels = [[TKWeChatPluginConfig sharedConfig] autoReplyModels];
    [autoReplyModels enumerateObjectsUsingBlock:^(TKAutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!model.enable) return;
        if (!model.replyContent || model.replyContent.length == 0) return;
        if ([addMsg.fromUserName.string containsString:@"@chatroom"] && !model.enableGroupReply) return;
        if (![addMsg.fromUserName.string containsString:@"@chatroom"] && !model.enableSingleReply) return;
        
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
        
        if (model.enableRegex) {
            NSString *regex = model.keyword;
            NSError *error;
            NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
            if (error) return;
            NSInteger count = [regular numberOfMatchesInString:msgContent options:NSMatchingReportCompletion range:NSMakeRange(0, msgContent.length)];
            if (count > 0) {
                [service SendTextMessage:currentUserName toUsrName:addMsg.fromUserName.string msgText:randomReplyContent atUserList:nil];
            }
        } else {
            NSArray * keyWordArray = [model.keyword componentsSeparatedByString:@"|"];
            [keyWordArray enumerateObjectsUsingBlock:^(NSString *keyword, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([keyword isEqualToString:@"*"] || [msgContent isEqualToString:keyword]) {
                    [service SendTextMessage:currentUserName toUsrName:addMsg.fromUserName.string msgText:randomReplyContent atUserList:nil];
                }
            }];
        }
    }];
}

/**
 远程控制
 
 @param addMsg 接收的消息
 */
- (void)remoteControlWithMsg:(AddMsg *)addMsg {
    if (addMsg.msgType == 1 || addMsg.msgType == 3) {
        [TKRemoteControlController executeRemoteControlCommandWithMsg:addMsg.content.string];
    }
}

- (void)replySelfWithMsg:(AddMsg *)addMsg {
    if (addMsg.msgType != 1 && addMsg.msgType != 3) return;
    
    if ([addMsg.content.string isEqualToString:@"获取指令"]) {
        NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
        NSString *callBack = [TKRemoteControlController remoteControlCommandsString];
        MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
        [service SendTextMessage:currentUserName toUsrName:currentUserName msgText:callBack atUserList:nil];
    }
}

#pragma mark -- 替换部分调用了 NSSearchPathForDirectoriesInDomains 的方法
+ (void)replaceAboutFilePathMethod {
    tk_hookMethod(objc_getClass("JTStatisticManager"), @selector(statFilePath), [self class], @selector(hook_statFilePath));
    tk_hookClassMethod(objc_getClass("CUtility"), @selector(getFreeDiskSpace), [self class], @selector(hook_getFreeDiskSpace));
    tk_hookClassMethod(objc_getClass("MemoryMappedKV"), @selector(mappedKVPathWithID:), [self class], @selector(hook_mappedKVPathWithID:));
    tk_hookClassMethod(objc_getClass("PathUtility"), @selector(getSysDocumentPath), [self class], @selector(hook_getSysDocumentPath));
    tk_hookClassMethod(objc_getClass("PathUtility"), @selector(getSysLibraryPath), [self class], @selector(hook_getSysLibraryPath));
    tk_hookClassMethod(objc_getClass("PathUtility"), @selector(getSysCachePath), [self class], @selector(hook_getSysCachePath));
}

- (id)hook_statFilePath {
    NSString *filePath = [self hook_statFilePath];
    NSString *newCachePath = [NSObject realFilePathWithOriginFilePath:filePath originKeyword:@"/Documents"];
    if (newCachePath) {
        return newCachePath;
    } else {
        return filePath;
    }
}

+ (unsigned long long)hook_getFreeDiskSpace {
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(0x9, 0x1, 0x1) firstObject];
    if (documentPath.length == 0) {
        return [self hook_getFreeDiskSpace];
    }
    
    NSString *newDocumentPath = [self realFilePathWithOriginFilePath:documentPath originKeyword:@"/Documents"];
    if (newDocumentPath.length > 0) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *dict = [fileManager attributesOfFileSystemForPath:newDocumentPath error:nil];
        if (dict) {
            NSNumber *freeSize = [dict objectForKey:NSFileSystemFreeSize];
            unsigned long long freeSieValue = [freeSize unsignedLongLongValue];
            return freeSieValue;
        }
    }
    return [self hook_getFreeDiskSpace];
}

+ (id)hook_mappedKVPathWithID:(id)arg1 {
    NSString *mappedKVPath = [self hook_mappedKVPathWithID:arg1];
    NSString *newMappedKVPath = [self realFilePathWithOriginFilePath:mappedKVPath originKeyword:@"/Documents/MMappedKV"];
    if (newMappedKVPath) {
        return newMappedKVPath;
    } else {
        return mappedKVPath;
    }
}

+ (id)hook_getSysDocumentPath {
    NSString *sysDocumentPath = [self hook_getSysDocumentPath];
    NSString *newSysDocumentPath = [self realFilePathWithOriginFilePath:sysDocumentPath originKeyword:@"/Library/Application Support"];
    if (newSysDocumentPath) {
        return newSysDocumentPath;
    } else {
        return sysDocumentPath;
    }
}

+ (id)hook_getSysLibraryPath {
    NSString *libraryPath = [self hook_getSysLibraryPath];
    NSString *newLibraryPath = [self realFilePathWithOriginFilePath:libraryPath originKeyword:@"/Library"];
    if (newLibraryPath) {
        return newLibraryPath;
    } else {
        return libraryPath;
    }
}

+ (id)hook_getSysCachePath {
    NSString *cachePath = [self hook_getSysCachePath];
    NSString *newCachePath = [self realFilePathWithOriginFilePath:cachePath originKeyword:@"/Library/Caches"];
    if (newCachePath) {
        return newCachePath;
    } else {
        return cachePath;
    }
}

+ (id)realFilePathWithOriginFilePath:(NSString *)filePath originKeyword:(NSString *)keyword {
    NSRange range = [filePath rangeOfString:keyword];
    if (range.length > 0) {
        NSMutableString *newFilePath = [filePath mutableCopy];
        NSString *subString = [NSString stringWithFormat:@"/Library/Containers/com.tencent.xinWeChat/Data%@",keyword];
        [newFilePath replaceCharactersInRange:range withString:subString];
        return newFilePath;
    } else {
        return nil;
    }
}

@end
