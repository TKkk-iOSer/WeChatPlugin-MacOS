//
//  WeChat+hook.m
//  WeChatPlugin
//
//  Created by TK on 2017/4/19.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "WeChat+hook.h"
#import "WeChatPlugin.h"
#import "fishhook.h"
#import "TKIgnoreSessonModel.h"
#import "TKWebServerManager.h"
#import "TKMessageManager.h"
#import "TKAssistantMenuManager.h"
#import "TKAutoReplyModel.h"
#import "TKVersionManager.h"
#import "TKRemoteControlManager.h"
#import "TKDownloadWindowController.h"
#import "TKConstants.h"

@implementation NSObject (WeChatHook)

+ (void)hookWeChat {
    //      微信撤回消息
    tk_hookMethod(objc_getClass("FFProcessReqsvrZZ"), @selector(FFToNameFavChatZZ:sessionMsgList:), [self class], @selector(hook_FFToNameFavChatZZ:sessionMsgList:));
    //      微信消息同步
    SEL syncBatchAddMsgsMethod = LargerOrEqualVersion(@"2.3.22") ? @selector(FFImgToOnFavInfoInfoVCZZ:isFirstSync:) : @selector(OnSyncBatchAddMsgs:isFirstSync:);
    tk_hookMethod(objc_getClass("FFProcessReqsvrZZ"), syncBatchAddMsgsMethod, [self class], @selector(hook_OnSyncBatchAddMsgs:isFirstSync:));
    //      微信多开
    SEL hasWechatInstanceMethod = LargerOrEqualVersion(@"2.3.22") ? @selector(FFSvrChatInfoMsgWithImgZZ) : @selector(HasWechatInstance);
    tk_hookClassMethod(objc_getClass("CUtility"), hasWechatInstanceMethod, [self class], @selector(hook_HasWechatInstance));
    //      窗口置顶
    tk_hookMethod(objc_getClass("NSWindow"), @selector(makeKeyAndOrderFront:), [self class], @selector(hook_makeKeyAndOrderFront:));
    //      登录逻辑
    tk_hookMethod(objc_getClass("AccountService"), @selector(onAuthOKOfUser:withSessionKey:withServerId:autoAuthKey:isAutoAuth:), [self class], @selector(hook_onAuthOKOfUser:withSessionKey:withServerId:autoAuthKey:isAutoAuth:));

    //      自带浏览器打开链接
    tk_hookMethod(objc_getClass("MMURLHandler"), @selector(preHandleUrlStr:withMessage:), [self class], @selector(hook_preHandleUrlStr:withMessage:));

    tk_hookMethod(objc_getClass("MMURLHandler"), @selector(startGetA8KeyWithURL:), [self class], @selector(hook_startGetA8KeyWithURL:));
    tk_hookMethod(objc_getClass("WeChat"), @selector(applicationDidFinishLaunching:), [self class], @selector(hook_applicationDidFinishLaunching:));
    
    tk_hookMethod(objc_getClass("UserDefaultsService"), @selector(stringForKey:), [self class], @selector(hook_stringForKey:));
    
    //    设置标记未读
    tk_hookMethod(objc_getClass("MMChatMessageViewController"), @selector(onClickSession), [self class], @selector(hook_onClickSession));
    tk_hookMethod(objc_getClass("MMSessionMgr"), @selector(onUnReadCountChange:), [self class], @selector(hook_onUnReadCountChange:));

    //    远程语音控制
    tk_hookMethod(objc_getClass("MMVoiceTranslateMgr"), @selector(updateTranscribeVoiceMessage:voiceText:voiceToTextStatus:), [self class], @selector(hook_updateTranscribeVoiceMessage:voiceText:voiceToTextStatus:));

    //    不支持的消息提示（小程序、转账等
    tk_hookClassMethod(objc_getClass("MMAppBrandMessageCellView"), @selector(makeAppBrandTableItemWithItem:), [self class], @selector(hook_makeAppBrandTableItemWithItem:));
    tk_hookClassMethod(objc_getClass("MMUnsupportedCellView"), @selector(makeUnsupportedTableItemWithItem:), [self class], @selector(hook_makeUnsupportedTableItemWithItem:));
    tk_hookClassMethod(objc_getClass("MMPayTransferCellView"), @selector(makePayTransferTableItemWithItem:), [self class], @selector(hook_makePayTransferTableItemWithItem:));
    
    //  退群提示
    tk_hookMethod(objc_getClass("GroupStorage"), @selector(notifyModifyGroupContactsOnMainThread:), [self class], @selector(hook_notifyModifyGroupContactsOnMainThread:));
    tk_hookMethod(objc_getClass("MMSystemMessageCellView"), @selector(textView:clickedOnLink:atIndex:), [self class], @selector(hook_textView:clickedOnLink:atIndex:));
    tk_hookMethod(objc_getClass("MMSystemMessageCellView"), @selector(populateWithMessage:), [self class], @selector(hook_populateWithMessage:));
    //      替换沙盒路径
    rebind_symbols((struct rebinding[2]) {
        { "NSSearchPathForDirectoriesInDomains", swizzled_NSSearchPathForDirectoriesInDomains, (void *)&original_NSSearchPathForDirectoriesInDomains },
        { "NSHomeDirectory", swizzled_NSHomeDirectory, (void *)&original_NSHomeDirectory }
    }, 2);
    
    [self setup];
}

+ (void)setup {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //        窗口置顶初始化
        [self setupWindowSticky];
    });
    [self checkPluginVersion];
    //    监听 NSWindow 最小化通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowsWillMiniaturize:) name:NSWindowWillMiniaturizeNotification object:nil];
}

+ (void)setupWindowSticky {
    BOOL onTop = [[TKWeChatPluginConfig sharedConfig] onTop];
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    wechat.mainWindowController.window.level = onTop == NSControlStateValueOn ? NSNormalWindowLevel+2 : NSNormalWindowLevel;
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
                    [[TKDownloadWindowController downloadWindowController] show];
                } else if (respose == NSAlertSecondButtonReturn) {
                    [[TKWeChatPluginConfig sharedConfig] setForbidCheckVersion:YES];
                }
            });
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
- (void)hook_FFToNameFavChatZZ:(id)msgData sessionMsgList:(id)arg2 {
    if (![[TKWeChatPluginConfig sharedConfig] preventRevokeEnable]) {
        [self hook_FFToNameFavChatZZ:msgData sessionMsgList:arg2];
        return;
    }
    id msg = msgData;
    if ([msgData isKindOfClass:objc_getClass("MessageData")]) {
        msg = [msgData valueForKey:@"msgContent"];
    }
    if ([msg rangeOfString:@"<sysmsg"].length <= 0) return;
    
    //      转换群聊的 msg
    NSString *msgContent = [msg substringFromIndex:[msg rangeOfString:@"<sysmsg"].location];
    
    //      xml 转 dict
    XMLDictionaryParser *xmlParser = [objc_getClass("XMLDictionaryParser") sharedInstance];
    NSDictionary *msgDict = [xmlParser dictionaryWithString:msgContent];
    
    if (msgDict && msgDict[@"revokemsg"]) {
        NSString *newmsgid = msgDict[@"revokemsg"][@"newmsgid"];
        NSString *session =  msgDict[@"revokemsg"][@"session"];
        msgDict = nil;
        
        NSMutableSet *revokeMsgSet = [[TKWeChatPluginConfig sharedConfig] revokeMsgSet];
        //      该消息已进行过防撤回处理
        if ([revokeMsgSet containsObject:newmsgid] || !newmsgid) {
            return;
        }
        [revokeMsgSet addObject:newmsgid];
        
        //      获取原始的撤回提示消息
        FFProcessReqsvrZZ *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("FFProcessReqsvrZZ")];
        MessageData *revokeMsgData = [msgService GetMsgData:session svrId:[newmsgid integerValue]];
        if ([revokeMsgData isSendFromSelf] && ![[TKWeChatPluginConfig sharedConfig] preventSelfRevokeEnable]) {
            [self hook_FFToNameFavChatZZ:msgData sessionMsgList:arg2];
            return;
        }
        NSString *msgContent = [[TKMessageManager shareManager] getMessageContentWithData:revokeMsgData];
        NSString *newMsgContent = [NSString stringWithFormat:@"%@ \n%@%@%d",TKLocalizedString(@"assistant.revoke.otherMessage.tip"), msgContent, kTKRevokeLocationKey, revokeMsgData.mesLocalID];
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
//- (id)hook_getNotificationContentWithMsgData:(MessageData *)arg1 {
//    [[TKWeChatPluginConfig sharedConfig] setCurrentUserName:arg1.toUsrName];
//    return [self hook_getNotificationContentWithMsgData:arg1];;
//}
//
//- (void)hook_deliverNotification:(NSUserNotification *)notification {
//    NSMutableDictionary *dict = [notification.userInfo mutableCopy];
//    dict[@"currnetName"] = [[TKWeChatPluginConfig sharedConfig] currentUserName];
//    notification.userInfo = dict;
//    notification.hasReplyButton = YES;
//    [self hook_deliverNotification:notification];
//}
//
//- (void)hook_userNotificationCenter:(id)notificationCenter didActivateNotification:(NSUserNotification *)notification {
//    NSString *chatName = notification.userInfo[@"ChatName"];
//    if (chatName && notification.response.string) {
//        NSString *instanceUserName = [objc_getClass("CUtility") GetCurrentUserName];
//        NSString *currentUserName = notification.userInfo[@"currnetName"];
//        if ([instanceUserName isEqualToString:currentUserName]) {
//            MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
//            [service SendTextMessage:currentUserName toUsrName:chatName msgText:notification.response.string atUserList:nil];
//            [[TKMessageManager shareManager] clearUnRead:chatName];
//        }
//    } else {
//        [self hook_userNotificationCenter:notificationCenter didActivateNotification:notification];
//    }
//}

- (void)hook_onAuthOKOfUser:(id)arg1 withSessionKey:(id)arg2 withServerId:(id)arg3 autoAuthKey:(id)arg4 isAutoAuth:(BOOL)arg5 {
    [self hook_onAuthOKOfUser:arg1 withSessionKey:arg2 withServerId:arg3 autoAuthKey:arg4 isAutoAuth:arg5];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[TKWeChatPluginConfig sharedConfig] alfredEnable]) {
            [[TKWebServerManager shareManager] startServer];
        }
        NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
        NSMenuItem *pluginMenu = mainMenu.itemArray.lastObject;
        pluginMenu.enabled = YES;
        NSMenuItem *preventMenu = pluginMenu.submenu.itemArray.firstObject;
        preventMenu.enabled = YES;
    });
}

- (void)hook_startGetA8KeyWithURL:(id)arg1 {
    MMURLHandler *urlHandler = (MMURLHandler *)self;
    [urlHandler openURLWithDefault:arg1];
}

- (void)hook_applicationDidFinishLaunching:(id)arg1 {
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    if ([NSObject hook_HasWechatInstance]) {
        wechat.hasAuthOK = YES;
    }
    if ([wechat respondsToSelector:@selector(checkForUpdatesInBackground)]) {
        //      去除刚启动微信更新弹窗提醒
        tk_hookMethod(objc_getClass("WeChat"), @selector(checkForUpdatesInBackground), [self class], @selector(hook_checkForUpdatesInBackground));
    }
    
    [[TKAssistantMenuManager shareManager] initAssistantMenuItems];
    [self hook_applicationDidFinishLaunching:arg1];
}

//  强制用户退出时保存聊天记录
- (id)hook_stringForKey:(NSString *)key {
    if ([key isEqualToString:@"kMMUserDefaultsKey_SaveChatHistory"]) {
        return @"1";
    }
    return [self hook_stringForKey:key];
}

//  微信检测更新
- (void)hook_checkForUpdatesInBackground {
    if ([[TKWeChatPluginConfig sharedConfig] checkUpdateWechatEnable]) {
        [self hook_checkForUpdatesInBackground];
    }
}

//  是否使用微信浏览器
- (BOOL)hook_preHandleUrlStr:(id)arg1 withMessage:(id)arg2 {
   if ([[TKWeChatPluginConfig sharedConfig] systemBrowserEnable]) {
        MMURLHandler *urlHander = [objc_getClass("MMURLHandler") defaultHandler];
       if ([urlHander respondsToSelector:@selector(openURLWithDefault:)]) { // 2.3.22
           [urlHander openURLWithDefault:arg1];
           return YES;
       } else if ([urlHander respondsToSelector:@selector(openURLWithDefault:useA8Key:)]) { // 2.3.30
           [urlHander openURLWithDefault:arg1 useA8Key:YES];
           return YES;
       }
    }
    return [self hook_preHandleUrlStr:arg1 withMessage:arg2];
}

//  设置标记未读
- (void)hook_onClickSession {
    [self hook_onClickSession];
    MMChatMessageViewController *chatMessageVC = (MMChatMessageViewController *)self;
    NSMutableSet *unreadSessionSet = [[TKWeChatPluginConfig sharedConfig] unreadSessionSet];
    if ([unreadSessionSet containsObject:chatMessageVC.chatContact.m_nsUsrName]) {
        [unreadSessionSet removeObject:chatMessageVC.chatContact.m_nsUsrName];
        [[TKMessageManager shareManager] clearUnRead:chatMessageVC.chatContact.m_nsUsrName];
    }
}

- (void)hook_onUnReadCountChange:(id)arg1 {
    NSMutableSet *unreadSessionSet = [[TKWeChatPluginConfig sharedConfig] unreadSessionSet];
    if ([unreadSessionSet containsObject:arg1]) {
        MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
        MMSessionInfo *sessionInfo = [sessionMgr sessionInfoByUserName:arg1];
        sessionInfo.m_uUnReadCount++;
    }
    [self hook_onUnReadCountChange:arg1];
}

//  拦截微信语音转换，用于语音远程控制
- (void)hook_updateTranscribeVoiceMessage:(MessageData *)arg1 voiceText:(id)arg2 voiceToTextStatus:(unsigned int)arg3 {
    [self hook_updateTranscribeVoiceMessage:arg1 voiceText:arg2 voiceToTextStatus:arg3];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([arg1 isSendFromSelf]) {
             NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
            if ([arg1.toUsrName isEqualToString:currentUserName]) {
                [TKRemoteControlManager executeRemoteControlCommandWithVoiceMsg:arg2];
            }
        }
    });
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
    //    addMsg.msgType != 49
    if (![[TKWeChatPluginConfig sharedConfig] autoReplyEnable]) return;
    if (addMsg.msgType != 1 && addMsg.msgType != 3) return;
    
    NSString *userName = addMsg.fromUserName.string;
    
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    WCContactData *msgContact = [sessionMgr getSessionContact:userName];
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
        msgContent = [msgContent substringFromString:@":\n"];
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
            [[TKMessageManager shareManager] sendTextMessage:randomReplyContent toUsrName:addMsg.fromUserName.string delay:delayTime];
        }
    } else {
        NSArray * keyWordArray = [model.keyword componentsSeparatedByString:@"|"];
        [keyWordArray enumerateObjectsUsingBlock:^(NSString *keyword, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([keyword isEqualToString:@"*"] || [msgContent isEqualToString:keyword]) {
                [[TKMessageManager shareManager] sendTextMessage:randomReplyContent toUsrName:addMsg.fromUserName.string delay:delayTime];
                *stop = YES;
            }
        }];
    }
}

/**
 远程控制
 
 @param addMsg 接收的消息
 */
- (void)remoteControlWithMsg:(AddMsg *)addMsg {
    NSDate *now = [NSDate date];
    NSTimeInterval nowSecond = now.timeIntervalSince1970;
    if (nowSecond - addMsg.createTime > 10) {      // 若是10秒前的消息，则不进行远程控制。
        return;
    }
    if (addMsg.msgType == 1 || addMsg.msgType == 3) {
        [TKRemoteControlManager executeRemoteControlCommandWithMsg:addMsg.content.string];
    } else if (addMsg.msgType == 34) {
        //      此为语音消息
        FFProcessReqsvrZZ *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("FFProcessReqsvrZZ")];
        MessageData *msgData = [msgService GetMsgData:addMsg.fromUserName.string svrId:addMsg.newMsgId];
         dispatch_async(dispatch_get_main_queue(), ^{
             MMVoiceTranslateMgr *voiceMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMVoiceTranslateMgr")];
             [voiceMgr doTranslate:msgData isAuto:YES];
         });
    }
}

- (void)replySelfWithMsg:(AddMsg *)addMsg {
    if (addMsg.msgType != 1 && addMsg.msgType != 3) return;
    
    if ([addMsg.content.string isEqualToString:TKLocalizedString(@"assistant.remoteControl.getList")]) {
        NSString *callBack = [TKRemoteControlManager remoteControlCommandsString];
        [[TKMessageManager shareManager] sendTextMessageToSelf:callBack];
    }
}

- (void)windowsWillMiniaturize:(NSNotification *)notification {
    NSObject *window = notification.object;
    ((NSWindow *)window).level =NSNormalWindowLevel;
}

#pragma mark - 不支持的消息展示
+ (id)hook_makePayTransferTableItemWithItem:(MMMessageTableItem *)arg1 {
    MMMessageTableItem *tableItem = [self hook_makePayTransferTableItemWithItem:arg1];
    
    NSString *feeDesc = tableItem.message.m_oWCPayInfoItem.m_nsFeeDesc;
    if (feeDesc.length > 0) {
        tableItem.message.msgContent = [NSString stringWithFormat:@"%@\n金额：%@元",tableItem.message.msgContent,feeDesc];
    }
    return tableItem;
    
}
+ (id)hook_makeAppBrandTableItemWithItem:(MMMessageTableItem *)arg1 {
    MMMessageTableItem *tableItem = [self hook_makeAppBrandTableItemWithItem:arg1];
    tableItem.message = [self resetMsgContent:tableItem.message];
    return tableItem;
}

+ (id)hook_makeUnsupportedTableItemWithItem:(MMMessageTableItem *)arg1 {
    MMMessageTableItem *tableItem = [self hook_makeUnsupportedTableItemWithItem:arg1];
    tableItem.message = [self resetMsgContent:tableItem.message];
    return tableItem;
}

+ (MessageData *)resetMsgContent:(MessageData *)msgData {
    if (msgData.m_nsTitle.length > 0) {
        NSString *from = @"内容";
        if (msgData.m_nsSourceDisplayname.length > 0) {
            from = msgData.m_nsSourceDisplayname;
        } else if (msgData.m_nsAppName.length > 0) {
            from = msgData.m_nsAppName;
        }
        msgData.msgContent = [msgData.msgContent stringByAppendingFormat:@"\n%@：%@", from, msgData.m_nsTitle];
    }

    return msgData;
}

#pragma mark - 退群处理
- (void)hook_notifyModifyGroupContactsOnMainThread:(NSArray <WCContactData *> *)arg1 {
    [self hook_notifyModifyGroupContactsOnMainThread:arg1];
    if (![TKWeChatPluginConfig sharedConfig].memberExitMonitoringEnable) {
        return;
    }
    GroupStorage *contactStorage = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("GroupStorage")];
    [arg1 enumerateObjectsUsingBlock:^(WCContactData * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *m_dicData = [obj.m_chatRoomData valueForKey:@"m_dicData"];
        [m_dicData.allKeys enumerateObjectsUsingBlock:^(NSString *userName, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![obj containsMember:userName]) {
                NSString *localKey = [NSString stringWithFormat:@"%@-%@",obj.m_nsUsrName, userName];
                NSMutableDictionary *quitChatRoomMemberDict = [TKWeChatPluginConfig sharedConfig].quitChatRoomMemberDict;
                NSString *saveDateKey = quitChatRoomMemberDict[localKey];
                BOOL canShowQuitTip = NO;
                if (saveDateKey) {
                    NSDate *currentDate = [NSDate date];
                    NSDate *lastSaveDate = [[TKUtility getDateFormater] dateFromString:saveDateKey];
                    NSTimeInterval days = [currentDate timeIntervalSinceDate:lastSaveDate] / (3600.0 * 24);
                    canShowQuitTip = days > kTKMemberQuitDayInterval;
                } else {
                    canShowQuitTip = YES;
                }
                if (canShowQuitTip) {
                    [TKWeChatPluginConfig sharedConfig].quitChatRoomMemberDict[localKey] = [TKUtility getOnlyDateString];
                    [[TKWeChatPluginConfig sharedConfig] saveQuitChatRoomMemberDict];
                    WCContactData *quitChatroomUser = [contactStorage GetGroupMemberContact:userName];
                    NSString *msgContent = [NSString stringWithFormat:@"%@ %@ \n %@%@",quitChatroomUser.m_nsNickName, WXLocalizedString(@"ChatInspector.LeaveChat"),WXLocalizedString(@"Contacts.UserNameKeyLabel"),userName];
                    FFProcessReqsvrZZ *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("FFProcessReqsvrZZ")];
                    MessageData *newMsgData = ({
                        MessageData *msg = [[objc_getClass("MessageData") alloc] initWithMsgType:0x2710];
                        [msg setFromUsrName:userName];
                        [msg setToUsrName:obj.m_nsUsrName];
                        [msg setM_nsAppName:userName];
                        [msg setMsgStatus:4];
                        [msg setMsgContent:msgContent];
                        [msg setMsgCreateTime:[[NSDate date] timeIntervalSince1970]];

                        msg;
                    });
                    [msgService AddLocalMsg:obj.m_nsUsrName msgData:newMsgData];
                }
            }
        }];
    }];
}

- (BOOL)hook_textView:(NSTextView *)arg1 clickedOnLink:(NSString *)arg2 atIndex:(unsigned long long)arg3 {
    if ([arg2 containsString:kTKScrollToMessageKey]) {
        MMSystemMessageCellView *currentCellView = (MMSystemMessageCellView *)self;
        NSString *localIDStr = [arg2 substringFromString:kTKScrollToMessageKey];
        NSUInteger localId = [localIDStr integerValue];
        if (localId > 0) {
            if ([currentCellView.delegate isKindOfClass:objc_getClass("MMChatMessageViewController")]) {
                MMChatMessageViewController *vc = currentCellView.delegate;
                if ([vc respondsToSelector:@selector(showLocatedMessage:)]) {
                    [vc showLocatedMessage:localId];
                } else if ([vc respondsToSelector:@selector(showLocatedMessage:needHighLighted:)]) {
                    [vc showLocatedMessage:localId needHighLighted:YES];
                }
            }
        }
        return YES;
    } else if ([arg2 containsString:kTKShowMembeContactProfileKey]) {
        NSString *usrName = [arg2 substringFromString:kTKShowMembeContactProfileKey];
        if (usrName.length) {
            MMSystemMessageCellView *currentCellView = (MMSystemMessageCellView *)self;
            MMMessageTableItem *item = currentCellView.messageTableItem;
            MessageData *msgData = item.message;
            GroupStorage *contactStorage = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("GroupStorage")];
            WCContactData *contactData = [objc_getClass("CUtility") GetContactByUsrName:usrName];
            if (!contactData) {
                contactData = [contactStorage GetGroupMemberContact:usrName];
            }
            if (contactData) {
                MMContactProfileController *vc = [[objc_getClass("MMContactProfileController") alloc] initWithNibName:@"MMContactProfileController" bundle:0];
                vc.groupName = msgData.fromUsrName;
                vc.relativeToRect = CGRectMake(150, 11, 200, 50);
                vc.preferredEdge = 2;
                vc.contactData = contactData;
                [vc showInView:self];
                return YES;
            }
        }
    }
    
    return [self hook_textView:arg1 clickedOnLink:arg2 atIndex:arg3];
}

- (void)hook_populateWithMessage:(id)arg1 {
    [self hook_populateWithMessage:arg1];
    
    MMSystemMessageCellView *currentCellView = (MMSystemMessageCellView *)self;
    MMMessageTableItem *item = currentCellView.messageTableItem;
    MessageData *msgData = item.message;
    NSString *msgContent = msgData.msgContent;
    if ([msgContent containsString:WXLocalizedString(@"ChatInspector.LeaveChat")] &&
        [msgContent containsString:WXLocalizedString(@"Contacts.UserNameKeyLabel")]) {
        NSMutableAttributedString *attStr = [currentCellView.msgTextView.attributedString mutableCopy];
        NSString *displayMsgContent = attStr.string;
        NSString *userName = [displayMsgContent substringToString:WXLocalizedString(@"ChatInspector.LeaveChat")];
        NSString *userId = [displayMsgContent substringFromString:WXLocalizedString(@"Contacts.UserNameKeyLabel")];
        
        if (userName && userId) {
            // 将用户昵称标记超链接
            NSRange userRange = [displayMsgContent rangeOfString:userName];
            if (userRange.length > 0 && userId) {
                NSString *linkValue = [kTKShowMembeContactProfileKey stringByAppendingString:userId];
                [attStr addAttribute:NSLinkAttributeName value:linkValue range:userRange];
            }
            //  删除其他信息，不显示微信号
            NSString *otherMsg = [displayMsgContent substringFromString:WXLocalizedString(@"ChatInspector.LeaveChat")];
            if (otherMsg) {
                NSRange otherMsgRange = [displayMsgContent rangeOfString:otherMsg];
                [attStr deleteCharactersInRange:otherMsgRange];
            }
            currentCellView.msgTextView.textStorage.attributedString = attStr;
        }
    } else if ([msgContent containsString:kTKRevokeLocationKey]) {
        NSMutableAttributedString *attStr = [currentCellView.msgTextView.attributedString mutableCopy];
        NSString *displayMsgContent = attStr.string;
        NSString *originMsg = [displayMsgContent substringFromString:TKLocalizedString(@"assistant.revoke.otherMessage.tip")];
        if (originMsg) {
            // 将撤回内容标记超链接
            NSRange msgRange = [displayMsgContent rangeOfString:originMsg];
            if (msgRange.length > 0) {
                NSString *localID = [displayMsgContent substringFromString:kTKRevokeLocationKey];
                if (localID) {
                    NSString *linkValue = [kTKScrollToMessageKey stringByAppendingString:localID];
                    [attStr addAttribute:NSLinkAttributeName value:linkValue range:msgRange];
                }
            }
        }
        //  删除其他信息，不显示微信号
        NSRange tipRange = [attStr.string rangeOfString:kTKRevokeLocationKey];
        if (tipRange.length > 0) {
            NSString *tipAndLocalId = [attStr.string substringFromIndex:tipRange.location];
            NSRange localIdrange = [attStr.string rangeOfString:tipAndLocalId];
            if (localIdrange.length > 0) {
                if (localIdrange.length + localIdrange.location > attStr.length) {
                    localIdrange.length = attStr.length - localIdrange.location;
                }
                [attStr deleteCharactersInRange:localIdrange];
            }
            currentCellView.msgTextView.textStorage.attributedString = attStr;
        }
    }
    NSMutableArray *names = [TKUtility getMemberNameWithMsgContent:msgContent];
    if (names.count > 0) {
        NSMutableAttributedString *attStr = [currentCellView.msgTextView.attributedString mutableCopy];
         NSString *displayMsgContent = attStr.string;
        GroupStorage *contactStorage = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("GroupStorage")];
        MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
        WCContactData *group = [sessionMgr getSessionContact:msgData.fromUsrName];
        NSArray *memberList = [contactStorage GetGroupMemberListWithGroupContact:group limit:500 filterSelf:YES];

        [memberList enumerateObjectsUsingBlock:^(WCContactData *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            __block NSString *needRemoveName = nil;
            [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL * _Nonnull subStop) {
                if ( [[obj groupChatDisplayNameInGroup:msgData.fromUsrName] isEqualToString:name] ||
                    [obj.m_nsNickName isEqualToString:name] ||
                    [obj.m_nsRemark isEqual:name]) {
                    NSRange nameRange = [displayMsgContent rangeOfString:name];
                    NSString *value = [NSString stringWithFormat:@"%@%@",kTKShowMembeContactProfileKey,obj.m_nsUsrName];
                    [attStr addAttribute:NSLinkAttributeName value:value range:nameRange];
                    needRemoveName = name;
                    *subStop = YES;
                }
            }];
            if (needRemoveName) {
                [names removeObject:needRemoveName];
            }
            if (names.count == 0) {
                *stop = YES;
            }
        }];
        currentCellView.msgTextView.textStorage.attributedString = attStr;
    }
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
