//
//  WeChat+hook.m
//  WeChatPlugin
//
//  Created by TK on 2017/4/19.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "WeChat+hook.h"
#import "WeChatPlugin.h"
#import "TKAutoReplyWindowController.h"
#import "XMLReader.h"
#import "TKRemoteControlController.h"
#import "TKRemoteControlWindowController.h"

static char tkAutoReplyWindowControllerKey;         //  自动回复窗口的关联 key
static char tkRemoteControlWindowControllerKey;     //  自动回复窗口的关联 key

@implementation NSObject (WeChatHook)

+ (void)hookWeChat {
    //      微信撤回消息
    tk_hookMethod(objc_getClass("MessageService"), @selector(onRevokeMsg:), [self class], @selector(hook_onRevokeMsg:));
    //      微信消息同步
    tk_hookMethod(objc_getClass("MessageService"), @selector(OnSyncBatchAddMsgs:isFirstSync:), [self class], @selector(hook_OnSyncBatchAddMsgs:isFirstSync:));
    //      微信多开
    tk_hookClassMethod(objc_getClass("CUtility"), @selector(HasWechatInstance), [self class], @selector(hook_HasWechatInstance));

    [self setup];
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
    NSMenuItem *autoReplyItem = [[NSMenuItem alloc] initWithTitle:@"开启自动回复" action:@selector(onAutoReply:) keyEquivalent:@"k"];
    autoReplyItem.state = [[TKWeChatPluginConfig sharedConfig] autoReplyEnable];
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
    [autoReplyWC setStartAutoReply:^{
        item.state = YES;
    }];

    if (item.state) {
        item.state = NO;
        [[TKWeChatPluginConfig sharedConfig] setAutoReplyEnable:NO];
        if (autoReplyWC) {
            [autoReplyWC close];
        }
        return;
    }

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
 菜单栏-帮助-远程控制MAC OS 设置

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

            NSString *newMsgContent;
            //      判断是否是自己发起撤回
            if ([selfContact.m_nsUsrName isEqualToString:revokeMsgData.fromUsrName]) {
                newMsgContent = [NSString stringWithFormat:@"TK拦截到你撤回了一条消息：\n %@",revokeMsgData.msgContent];
            } else {
                newMsgContent = [NSString stringWithFormat:@"TK拦截到一条撤回消息：\n %@",revokeMsgData.msgPushContent];
                //      消息免打扰的群，撤回时 msgPushContent 为空
                if ([revokeMsgData.msgPushContent isEqualToString:@""]) {
                    NSRange range = [revokeMsgData.msgContent rangeOfString:@":\n"];
                    NSString *content = [revokeMsgData.msgContent substringFromIndex:range.location + range.length];
                    newMsgContent = [NSString stringWithFormat:@"TK拦截到一条撤回消息：\n %@",content];
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
        
        if ([addMsg.fromUserName.string containsString:@"@chatroom"]) {     // 过滤群聊消息
            return ;
        }

        ContactStorage *contactStorage = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("ContactStorage")];
        WCContactData *selfContact = [contactStorage GetSelfContact];
        
        if ([addMsg.fromUserName.string isEqualToString:selfContact.m_nsUsrName]) {
            if ([addMsg.toUserName.string isEqualToString:selfContact.m_nsUsrName]) {
                 [self remoteControlWithMsg:addMsg];
            }
        } else {
            [self autoReplyWithMsg:addMsg];
        }
    }];
}

#pragma mark - Other
/**
 自动回复

 @param msg 接收的消息
 */
- (void)autoReplyWithMsg:(AddMsg *)msg {
    if( ![[TKWeChatPluginConfig sharedConfig] autoReplyEnable]) return;

    if (msg.msgType == 1 || msg.msgType == 3) {
        MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
        //                NSString *content = addMsg.content.string;
        //                if ([addMsg.fromUserName.string containsString:@"@chatroom"]) {
        //                    NSRange range = [addMsg.content.string rangeOfString:@":\n"];
        //                    if (range.length != 0) {
        //                        content = [addMsg.content.string substringFromIndex:range.location + range.length];
        //                    }
        //                }
        ContactStorage *contactStorage = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("ContactStorage")];
        WCContactData *selfContact = [contactStorage GetSelfContact];

        NSString *keyword = [[TKWeChatPluginConfig sharedConfig] autoReplyKeyword];
        if ([keyword isEqualToString:@""] || [msg.content.string isEqualToString:keyword]) {
            [service SendTextMessage:selfContact.m_nsUsrName toUsrName:msg.fromUserName.string msgText:[[TKWeChatPluginConfig sharedConfig] autoReplyText] atUserList:nil];
        }
    }
}

/**
 远程控制

 @param msg 接收的消息
 */
- (void)remoteControlWithMsg:(AddMsg *)msg {
    
    if (msg.msgType == 1 || msg.msgType == 3) {
        [TKRemoteControlController executeRemoteControlCommandWithMsg:msg.content.string];
    }
}

@end
