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
    
    tk_hookMethod(objc_getClass("MMChatsTableCellView"), @selector(menuWillOpen:), [self class], @selector(hook_menuNeedsUpdate:));
    
    tk_hookMethod(objc_getClass("MMChatsTableCellView"), @selector(setSessionInfo:), [self class], @selector(hook_setSessionInfo:));
    
    tk_hookMethod(objc_getClass("MMChatsTableCellView"), @selector(contextMenuSticky), [self class], @selector(hook_contextMenuSticky));
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
    
    if (isIgnore) {
        cellView.layer.backgroundColor = kBG3.CGColor;
    } else {
        cellView.layer.backgroundColor = [NSColor clearColor].CGColor;
    }
    [cellView.layer setNeedsDisplay];
}

- (void)hook_menuNeedsUpdate:(NSMenu *)arg1 {
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
    [arg1 insertItem:preventRevokeItem atIndex:1];
    [self hook_menuNeedsUpdate:arg1];
}

-(void)contextMenuStickyBottom {
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

@end
