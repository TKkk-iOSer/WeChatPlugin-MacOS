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

@implementation NSObject (MMChatsTableCellViewHook)

+ (void)hookMMChatsTableCellView {
    tk_hookMethod(objc_getClass("MMChatsTableCellView"), @selector(menuWillOpen:), [self class], @selector(hook_menuWillOpen:));
    tk_hookMethod(objc_getClass("MMChatsTableCellView"), @selector(setSessionInfo:), [self class], @selector(hook_setSessionInfo:));
    tk_hookMethod(objc_getClass("MMChatsTableCellView"), @selector(contextMenuSticky), [self class], @selector(hook_contextMenuSticky));
    tk_hookMethod(objc_getClass("MMChatsTableCellView"), @selector(contextMenuDelete), [self class], @selector(hook_contextMenuDelete));
    tk_hookMethod(objc_getClass("MMChatsViewController"), @selector(tableView:rowGotMouseDown:), [self class], @selector(hooktableView:rowGotMouseDown:));
}

- (void)hooktableView:(NSTableView *)arg1 rowGotMouseDown:(long long)arg2 {
    [self hooktableView:arg1 rowGotMouseDown:arg2];
    
    if ([[TKWeChatPluginConfig sharedConfig] multipleSelectionEnable]) {
        NSMutableArray *selectSessions = [[TKWeChatPluginConfig sharedConfig] selectSessions];
        MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
        MMSessionInfo *sessionInfo = [sessionMgr GetSessionAtIndex:arg2];
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
    MMChatsTableCellView *cellView = (MMChatsTableCellView *)self;
    MMSessionInfo *sessionInfo = [cellView sessionInfo];
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    
    __block BOOL isIgnore = false;
    NSMutableArray *ignoreSessions = [[TKWeChatPluginConfig sharedConfig] ignoreSessionModels];
    [ignoreSessions enumerateObjectsUsingBlock:^(TKIgnoreSessonModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.userName isEqualToString:sessionInfo.m_nsUserName] && [model.selfContact isEqualToString:currentUserName]) {
            isIgnore = true;
            *stop = YES;
        }
    }];
    
    NSString *itemString = isIgnore ? @"取消置底" : @"置底";
    NSMenuItem *preventRevokeItem = [[NSMenuItem alloc] initWithTitle:itemString action:@selector(contextMenuStickyBottom) keyEquivalent:@""];
    
    BOOL multipleSelectionEnable = [[TKWeChatPluginConfig sharedConfig] multipleSelectionEnable];
    NSString *multipleSelectionString = multipleSelectionEnable ? @"取消多选" : @"多选";
    NSMenuItem *multipleSelectionItem = [[NSMenuItem alloc] initWithTitle:multipleSelectionString action:@selector(contextMenuMutipleSelection) keyEquivalent:@""];
    
    [arg1 insertItem:preventRevokeItem atIndex:1];
    [arg1 addItem:multipleSelectionItem];
    [self hook_menuWillOpen:arg1];
}

- (void)contextMenuStickyBottom {
    MMChatsTableCellView *cellView = (MMChatsTableCellView *)self;
    MMSessionInfo *sessionInfo = [cellView sessionInfo];
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    
    NSMutableArray *ignoreSessions = [[TKWeChatPluginConfig sharedConfig] ignoreSessionModels];
    __block NSInteger index = -1;
    [ignoreSessions enumerateObjectsUsingBlock:^(TKIgnoreSessonModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.userName isEqualToString:sessionInfo.m_nsUserName] && [model.selfContact isEqualToString:currentUserName]) {
            index = idx;
            *stop = YES;
        }
    }];
    
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    
    if (index == -1) {
        TKIgnoreSessonModel *model = [[TKIgnoreSessonModel alloc] init];
        model.userName = sessionInfo.m_nsUserName;
        model.selfContact = currentUserName;
        model.ignore = true;
        [ignoreSessions addObject:model];
        if (!sessionInfo.m_bShowUnReadAsRedDot) {
            [sessionMgr MuteSessionByUserName:sessionInfo.m_nsUserName];
        }
        if (sessionInfo.m_bIsTop) {
            [sessionMgr UntopSessionByUserName:sessionInfo.m_nsUserName];
        } 
    } else {
        [ignoreSessions removeObjectAtIndex:index];
        if (sessionInfo.m_bShowUnReadAsRedDot) {
            [sessionMgr UnmuteSessionByUserName:sessionInfo.m_nsUserName];
        }
    }
    [sessionMgr sortSessions];
    [[TKWeChatPluginConfig sharedConfig] saveIgnoreSessionModels];
}

- (void)contextMenuMutipleSelection {
    BOOL multipleSelectionEnable = [[TKWeChatPluginConfig sharedConfig] multipleSelectionEnable];
    if (multipleSelectionEnable) {
        [[[TKWeChatPluginConfig sharedConfig] selectSessions] removeAllObjects];
        WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
        [wechat.chatsViewController.tableView reloadData];
    }
    
    [[TKWeChatPluginConfig sharedConfig] setMultipleSelectionEnable:!multipleSelectionEnable];
}

- (void)hook_contextMenuSticky {
    [self hook_contextMenuSticky];
    
    MMChatsTableCellView *cellView = (MMChatsTableCellView *)self;
    MMSessionInfo *sessionInfo = [cellView sessionInfo];
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
        
        if (sessionInfo.m_bShowUnReadAsRedDot) {
            [sessionMgr UnmuteSessionByUserName:sessionInfo.m_nsUserName];
        }
        [sessionMgr sortSessions];
        [[TKWeChatPluginConfig sharedConfig] saveIgnoreSessionModels];
    }
}

- (void)hook_contextMenuDelete {
    BOOL multipleSelection = [[TKWeChatPluginConfig sharedConfig] multipleSelectionEnable];
    
    if (multipleSelection) {
        MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
        NSMutableArray *selectSessions = [[TKWeChatPluginConfig sharedConfig] selectSessions];
        
        [selectSessions  enumerateObjectsUsingBlock:^(MMSessionInfo *sessionInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *sessionUserName = sessionInfo.m_nsUserName;
            if (sessionUserName.length != 0) {
                [sessionMgr deleteSessionWithoutSyncToServerWithUserName:sessionUserName];
            }
        }];
        
        WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
        [wechat.chatsViewController.tableView reloadData];
    } else {
        [self hook_contextMenuDelete];
    }
}

@end
