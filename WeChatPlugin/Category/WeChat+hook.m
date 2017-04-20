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

static char tkAutoReplyWindowControllerKey;     //  自动回复窗口的关联 key

@implementation NSObject (WeChatHook)

+ (void)hookWeChat {
    
    //      微信用户登录/退出
    tk_hookMethod(objc_getClass("MMMainWindowController"), @selector(onAuthOK), [self class], @selector(hook_onAuthOK));
    tk_hookMethod(objc_getClass("MMMainWindowController"), @selector(onLogOut), [self class], @selector(hook_onLogOut));
    
    //      微信撤回消息
    tk_hookMethod(objc_getClass("MessageService"), @selector(onRevokeMsg:), [self class], @selector(hook_onRevokeMsg:));
    
    //      微信消息同步
    tk_hookMethod(objc_getClass("MessageService"), @selector(OnSyncBatchAddMsgs:isFirstSync:), [self class], @selector(hook_OnSyncBatchAddMsgs:isFirstSync:));
    
}
/**
 hook 用户退出登录
 
 */
- (void)hook_onLogOut {
    NSMenu *helpIMenu = [NSApplication sharedApplication].helpMenu;
    while (helpIMenu.itemArray.count > 1) {
        [helpIMenu removeItemAtIndex:helpIMenu.itemArray.count - 1];
    }
    
    [self hook_onLogOut];
}

/**
 hook 用户登录
 
 */
- (void)hook_onAuthOK {
    NSMenu *helpIMenu = [NSApplication sharedApplication].helpMenu;
    if (helpIMenu.itemArray.count == 1) {
        NSMenuItem *preventRevokeItem = [[NSMenuItem alloc] initWithTitle:@"开启消息防撤回" action:@selector(onPreventRevoke:) keyEquivalent:@"t"];
        preventRevokeItem.state = [[TKWeChatPluginConfig sharedConfig] preventRevokeEnable];
        NSMenuItem *autoReplyItem = [[NSMenuItem alloc] initWithTitle:@"开启自动回复" action:@selector(onAutoReply:) keyEquivalent:@"k"];
        autoReplyItem.state = [[TKWeChatPluginConfig sharedConfig] autoReplyEnable];
        
        [helpIMenu addItem:[NSMenuItem separatorItem]];
        [helpIMenu addItem:preventRevokeItem];
        [helpIMenu addItem:autoReplyItem];
    }
    
    [self hook_onAuthOK];
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
    
    if ([[TKWeChatPluginConfig sharedConfig] autoReplyEnable]) {
        [msgs enumerateObjectsUsingBlock:^(AddMsg *addMsg, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([addMsg.fromUserName.string containsString:@"@chatroom"]) {                 // 过滤群聊消息
                return ;
            }
            
            ContactStorage *contactStorage = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("ContactStorage")];
            WCContactData *selfContact = [contactStorage GetSelfContact];
            
            if ([addMsg.fromUserName.string isEqualToString:selfContact.m_nsUsrName]) {     // 过滤自己发送的消息
                return ;
            }
            
            if (addMsg.msgType == 1 || addMsg.msgType == 3) {
                MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
                //                NSString *content = addMsg.content.string;
                //                if ([addMsg.fromUserName.string containsString:@"@chatroom"]) {
                //                    NSRange range = [addMsg.content.string rangeOfString:@":\n"];
                //                    if (range.length != 0) {
                //                        content = [addMsg.content.string substringFromIndex:range.location + range.length];
                //                    }
                //                }
                NSString *keyword = [[TKWeChatPluginConfig sharedConfig] autoReplyKeyword];
                if ([keyword isEqualToString:@""] || [addMsg.content.string isEqualToString:keyword]) {
                    [service SendTextMessage:selfContact.m_nsUsrName toUsrName:addMsg.fromUserName.string msgText:[[TKWeChatPluginConfig sharedConfig] autoReplyText] atUserList:nil];
                }
            }
        }];
    }
}

/**
 菜单栏-帮助-消息防撤回 设置
 
 @param preventRevokeItem 消息防撤回的item
 */
- (void)onPreventRevoke:(NSMenuItem *)preventRevokeItem {
    if (!preventRevokeItem) return;
    
    preventRevokeItem.state = !preventRevokeItem.state;
    [[TKWeChatPluginConfig sharedConfig] setPreventRevokeEnable:preventRevokeItem.state];
}

/**
 菜单栏-帮助-自动回复 设置
 
 @param autoReplyItem 自动回复设置的item
 */
- (void)onAutoReply:(NSMenuItem *)autoReplyItem {
    if (!autoReplyItem) return;
    
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    TKAutoReplyWindowController *autoReplyWC = objc_getAssociatedObject(wechat, &tkAutoReplyWindowControllerKey);
    [autoReplyWC setStartAutoReply:^{
        autoReplyItem.state = YES;
    }];
    
    if (autoReplyItem.state) {
        autoReplyItem.state = NO;
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

@end
