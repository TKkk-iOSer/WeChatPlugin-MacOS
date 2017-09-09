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
    
    [self setup];
    [self replaceAboutFilePathMethod];
}

+ (void)setup {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addAssistantMenuItem];
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
    NSMenuItem *autoReplyItem = [[NSMenuItem alloc] initWithTitle:@"自动回复设置w" action:@selector(onAutoReply:) keyEquivalent:@"k"];
    //        登录新微信
    NSMenuItem *newWeChatItem = [[NSMenuItem alloc] initWithTitle:@"登录新微信" action:@selector(onNewWechatInstance:) keyEquivalent:@"N"];
    //        远程控制
    NSMenuItem *commandItem = [[NSMenuItem alloc] initWithTitle:@"远程控制Mac OS" action:@selector(onRemoteControl:) keyEquivalent:@"C"];
    
    NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@"微信小助手"];
    [subMenu addItem:preventRevokeItem];
    [subMenu addItem:autoReplyItem];
    [subMenu addItem:commandItem];
    [subMenu addItem:newWeChatItem];
    
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
    if (msg && [[TKWeChatPluginConfig sharedConfig] preventRevokeEnable]) {
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
            ContactStorage *contactStorage = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("ContactStorage")];
            WCContactData *selfContact = [contactStorage GetSelfContact];
            
            NSString *newMsgContent = @"TK拦截到一条非文本撤回消息";
            //      判断是否是自己发起撤回
            if ([selfContact.m_nsUsrName isEqualToString:revokeMsgData.fromUsrName]) {
                if (revokeMsgData.messageType == 1) {       // 判断是否为文本消息
                    newMsgContent = [NSString stringWithFormat:@"TK拦截到你撤回了一条消息：\n %@",revokeMsgData.msgContent];
                }
            } else {
                if (![revokeMsgData.msgPushContent isEqualToString:@""]) {
                    newMsgContent = [NSString stringWithFormat:@"TK拦截到一条撤回消息：\n %@",revokeMsgData.msgPushContent];
                } else if (revokeMsgData.messageType == 1) {
                    NSRange range = [revokeMsgData.msgContent rangeOfString:@":\n"];
                    NSString *content = [revokeMsgData.msgContent substringFromIndex:range.location + range.length];
                    if (range.length > 0) {
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
                [msg setMesLocalID:[revokeMsgData mesLocalID]];
                
                msg;
            });
            
            [msgService AddLocalMsg:session msgData:newMsgData];
            return;
        }
    }
    
    [self hook_onRevokeMsg:msg];
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
        
        ContactStorage *contactStorage = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("ContactStorage")];
        WCContactData *selfContact = [contactStorage GetSelfContact];
        if ([addMsg.fromUserName.string isEqualToString:selfContact.m_nsUsrName] &&
            [addMsg.toUserName.string isEqualToString:selfContact.m_nsUsrName]) {
            [self remoteControlWithMsg:addMsg];
        }
    }];
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
    WCContactData *selfContact = [contactStorage GetSelfContact];
    
    NSArray *autoReplyModels = [[TKWeChatPluginConfig sharedConfig] autoReplyModels];
    [autoReplyModels enumerateObjectsUsingBlock:^(TKAutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!model.enable) return ;
        if ([addMsg.fromUserName.string containsString:@"@chatroom"] && !model.enableGroupReply) return;
        
        NSString *msgContent = addMsg.content.string;
        if ([addMsg.fromUserName.string containsString:@"@chatroom"]) {
            NSRange range = [msgContent rangeOfString:@":\n"];
            if (range.length != 0) {
                msgContent = [msgContent substringFromIndex:range.location + range.length];
            }
        }
        NSArray * keyWordArray = [model.keyword componentsSeparatedByString:@"||"];
        [keyWordArray enumerateObjectsUsingBlock:^(NSString *keyword, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([keyword isEqualToString:@"*"] || [msgContent isEqualToString:keyword]) {
                [service SendTextMessage:selfContact.m_nsUsrName toUsrName:addMsg.fromUserName.string msgText:model.replyContent atUserList:nil];
            }
        }];
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
