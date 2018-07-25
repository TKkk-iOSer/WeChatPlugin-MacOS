//
//  TKMessageManager.m
//  WeChatPlugin
//
//  Created by TK on 2018/4/23.
//  Copyright © 2018年 tk. All rights reserved.
//

#import "TKMessageManager.h"

@implementation TKMessageManager

+ (instancetype)shareManager {
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)sendTextMessageToSelf:(id)msgContent {
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    [self sendTextMessage:msgContent toUsrName:currentUserName delay:0];
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

- (void)clearUnRead:(id)arg1 {
    MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
    if ([service respondsToSelector:@selector(ClearUnRead:FromCreateTime:ToCreateTime:)]) {
        [service ClearUnRead:arg1 FromCreateTime:0 ToCreateTime:0];
    } else if ([service respondsToSelector:@selector(ClearUnRead:FromID:ToID:)]) {
        [service ClearUnRead:arg1 FromID:0 ToID:0];
    }
}

- (NSString *)getMessageContentWithData:(MessageData *)msgData {
    NSString *msgContent;
    if (msgData.messageType == 1) {
        msgContent = [msgData getRealMessageContent];
    } else if ([msgData isCustomEmojiMsg]) {
        msgContent = TKLocalizedString(@"assistant.revokeType.emoji");
    } else if ([msgData isImgMsg]) {
        msgContent = TKLocalizedString(@"assistant.revokeType.image");
    } else if ([msgData isVideoMsg]) {
        msgContent = TKLocalizedString(@"assistant.revokeType.video");
    } else if ([msgData isVoiceMsg]) {
        msgContent = TKLocalizedString(@"assistant.revokeType.voice");
    } else if (msgData.m_nsTitle){
        msgContent = msgData.m_nsTitle;
    } else {
        msgContent = TKLocalizedString(@"assistant.revokeType.other");
    }

    if (msgData.isChatRoomMessage) {
        if (msgData.groupChatSenderDisplayName.length > 0) {
            msgContent = [NSString stringWithFormat:@"%@：%@",msgData.groupChatSenderDisplayName, msgContent];
        }
    }
    
    return msgContent;
}

- (NSArray <MessageData *> *)getMsgListWithChatName:(id)arg1 minMesLocalId:(unsigned int)arg2 limitCnt:(unsigned int)arg3 {
    MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
    char hasMore = '1';
    NSArray *array = @[];
    if ([service respondsToSelector:@selector(GetMsgListWithChatName:fromLocalId:limitCnt:hasMore:sortAscend:)]) {
        array = [service GetMsgListWithChatName:arg1 fromLocalId:arg2 limitCnt:arg3 hasMore:&hasMore sortAscend:YES];
    } else if ([service respondsToSelector:@selector(GetMsgListWithChatName:fromCreateTime:limitCnt:hasMore:sortAscend:)]) {
         array = [service GetMsgListWithChatName:arg1 fromCreateTime:arg2 limitCnt:arg3 hasMore:&hasMore sortAscend:YES];
    }
    
    return [[array reverseObjectEnumerator] allObjects];
}

@end
