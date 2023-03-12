//
//  MMChatsTableCellView+hook.m
//  WeChatPlugin
//
//  Created by TK on 2017/9/15.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "MMChatsTableCellView+hook.h"
#import "WeChatPlugin.h"
#import "TKIgnoreSessonModel.h"
#import "TKMessageManager.h"
#import "TKEmoticonManager.h"

@implementation NSObject (MMChatsTableCellViewHook)

+ (void)hookMMChatsTableCellView {
    tk_hookMethod(objc_getClass("MMChatsTableCellView"), @selector(menuWillOpen:), [self class], @selector(hook_menuWillOpen:));
    tk_hookMethod(objc_getClass("MMChatsTableCellView"), @selector(setSessionInfo:), [self class], @selector(hook_setSessionInfo:));
    tk_hookMethod(objc_getClass("MMChatsTableCellView"), @selector(contextMenuSticky:), [self class], @selector(hook_contextMenuSticky:));
    tk_hookMethod(objc_getClass("MMChatsTableCellView"), @selector(contextMenuDelete:), [self class], @selector(hook_contextMenuDelete:));
    tk_hookMethod(objc_getClass("MMChatsViewController"), @selector(tableView:rowGotMouseDown:), [self class], @selector(hook_tableView:rowGotMouseDown:));
}

- (void)hook_tableView:(NSTableView *)arg1 rowGotMouseDown:(long long)arg2 {
    [self hook_tableView:arg1 rowGotMouseDown:arg2];
    
    if ([[TKWeChatPluginConfig sharedConfig] multipleSelectionEnable]) {
        NSMutableArray *selectSessions = [[TKWeChatPluginConfig sharedConfig] selectSessions];
        MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
        MMSessionInfo *sessionInfo = [sessionMgr getSessionAtIndex:arg2];
        if ([selectSessions containsObject:sessionInfo]) {
            [selectSessions removeObject:sessionInfo];
        } else {
            [selectSessions addObject:sessionInfo];
        }
        [arg1 reloadData];
    }
}

- (void)hook_setSessionInfo:(MMSessionInfo *)sessionInfo {
    [self hook_setSessionInfo:sessionInfo];
    
    MMChatsTableCellView *cellView = (MMChatsTableCellView *)self;
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    __block BOOL isIgnore = false;
    NSMutableArray *ignoreSessions = [[TKWeChatPluginConfig sharedConfig] ignoreSessionModels];
    [ignoreSessions enumerateObjectsUsingBlock:^(TKIgnoreSessonModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.userName isEqualToString:sessionInfo.m_nsUserName] && [model.selfContact isEqualToString:currentUserName]) {
            isIgnore = true;
            *stop = YES;
        }
    }];
    
    NSMutableArray *selectSessions = [[TKWeChatPluginConfig sharedConfig] selectSessions];
    if (isIgnore) {
        cellView.layer.backgroundColor = kBG3.CGColor;
    } else if ([selectSessions containsObject:sessionInfo]){
        cellView.layer.backgroundColor = kBG4.CGColor;
    } else {
        cellView.layer.backgroundColor = [NSColor clearColor].CGColor;
    }
    [cellView.layer setNeedsDisplay];
}

- (void)hook_menuWillOpen:(NSMenu *)arg1 {
    MMSessionInfo *sessionInfo = [(MMChatsTableCellView *)self sessionInfo];
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    
    __block BOOL isIgnore = false;
    NSMutableArray *ignoreSessions = [[TKWeChatPluginConfig sharedConfig] ignoreSessionModels];
    [ignoreSessions enumerateObjectsUsingBlock:^(TKIgnoreSessonModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.userName isEqualToString:sessionInfo.m_nsUserName] && [model.selfContact isEqualToString:currentUserName]) {
            isIgnore = true;
            *stop = YES;
        }
    }];

    NSMenuItem *clearUnReadItem = [[NSMenuItem alloc] initWithTitle:TKLocalizedString(@"assistant.chat.readAll") action:@selector(contextMenuClearUnRead) keyEquivalent:@""];
    
    NSMenuItem *clearEmptySessionItem = [[NSMenuItem alloc] initWithTitle:TKLocalizedString(@"assistant.chat.clearEmpty") action:@selector(contextMenuClearEmptySession) keyEquivalent:@""];

    [arg1 addItems:@[[NSMenuItem separatorItem],
                     clearUnReadItem,
                     clearEmptySessionItem
                     ]];
    [self hook_menuWillOpen:arg1];
}

- (void)contextMenuClearUnRead {
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    NSMutableArray *arrSession = [sessionMgr getAllSessions];

    [arrSession enumerateObjectsUsingBlock:^(MMSessionInfo *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[TKMessageManager shareManager] clearUnRead:obj.m_nsUserName];
        });
    }];
}

- (void)contextMenuClearEmptySession {
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    FFProcessReqsvrZZ *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("FFProcessReqsvrZZ")];
    
    if (msgService == nil || sessionMgr == nil) {
        return;
        
    }
    
    NSMutableArray *arrSession = [sessionMgr getAllSessions];
    NSMutableArray *emptyArrSession = [NSMutableArray array];
    
    [arrSession enumerateObjectsUsingBlock:^(MMSessionInfo *sessionInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL hasEmplyMsgSession = ![msgService HasMsgInChat:sessionInfo.m_nsUserName];
        WCContactData *contact = sessionInfo.m_packedInfo.m_contact;
        if (![sessionInfo.m_nsUserName isEqualToString:@"brandsessionholder"] && ![contact isSelf] && hasEmplyMsgSession) {
            [emptyArrSession addObject:sessionInfo];
        }
    }];
    
    while (emptyArrSession.count > 0) {
        [emptyArrSession enumerateObjectsUsingBlock:^(MMSessionInfo *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [sessionMgr removeSessionOfUser:obj.m_nsUserName isDelMsg:NO];
            [emptyArrSession removeObject:obj];
        }];
    }
}

- (void)contextMenuUnreadSession {
    MMSessionInfo *sessionInfo = [(MMChatsTableCellView *)self sessionInfo];
    if (sessionInfo.m_uUnReadCount > 0) return;
    
    NSMutableSet *unreadSessionSet = [[TKWeChatPluginConfig sharedConfig] unreadSessionSet];
    if ([unreadSessionSet containsObject:sessionInfo.m_nsUserName]) return;
    
    [unreadSessionSet addObject:sessionInfo.m_nsUserName];
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    [sessionMgr changeSessionUnreadCountWithUserName:sessionInfo.m_nsUserName to:sessionInfo.m_uUnReadCount + 1];
}

- (void)hook_contextMenuSticky:(id)arg1 {
    [self hook_contextMenuSticky:arg1];
    
    MMSessionInfo *sessionInfo = [(MMChatsTableCellView *)self sessionInfo];
    if (!sessionInfo.m_bIsTop) return;
    
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    NSMutableArray *ignoreSessions = [[TKWeChatPluginConfig sharedConfig] ignoreSessionModels];
    __block NSInteger index = -1;
    [ignoreSessions enumerateObjectsUsingBlock:^(TKIgnoreSessonModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.userName isEqualToString:sessionInfo.m_nsUserName] && [model.selfContact isEqual:currentUserName]) {
            index = idx;
            *stop = YES;
        }
    }];
    
    if (index != -1) {
        [ignoreSessions removeObjectAtIndex:index];
        MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
        
        if (sessionInfo.m_bShowUnReadAsRedDot && sessionInfo.m_nsUserName) {
            [sessionMgr unmuteSessionByUserName:sessionInfo.m_nsUserName];
        }
        if ([sessionMgr respondsToSelector:@selector(FFDataSvrMgrSvrFavZZ)]) {
            [sessionMgr FFDataSvrMgrSvrFavZZ];
        } else if ([sessionMgr respondsToSelector:@selector(sortSessions)]){
            [sessionMgr sortSessions];
        }
        [[TKWeChatPluginConfig sharedConfig] saveIgnoreSessionModels];
    }
}

- (void)hook_contextMenuDelete:(id)arg1 {
    BOOL multipleSelection = [[TKWeChatPluginConfig sharedConfig] multipleSelectionEnable];
    
    if (multipleSelection) {
        MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
        NSMutableArray *selectSessions = [[TKWeChatPluginConfig sharedConfig] selectSessions];
        
        [selectSessions  enumerateObjectsUsingBlock:^(MMSessionInfo *sessionInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *sessionUserName = sessionInfo.m_nsUserName;
            if (sessionUserName.length != 0) {
                [sessionMgr removeSessionOfUser:sessionUserName isDelMsg:NO];
            }
        }];
        [[TKWeChatPluginConfig sharedConfig] setMultipleSelectionEnable:NO];
        WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
        [wechat.chatsViewController.tableView reloadData];
    } else {
        [self hook_contextMenuDelete:arg1];
    }
}

@end
