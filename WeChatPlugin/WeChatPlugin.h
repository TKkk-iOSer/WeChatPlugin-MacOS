//
//  WeChatPlugin.h
//  WeChatPlugin
//
//  Created by TK on 2017/4/19.
//  Copyright © 2017年 tk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TKWeChatPluginConfig.h"
#import "TKHelper.h"

FOUNDATION_EXPORT double WeChatPluginVersionNumber;
FOUNDATION_EXPORT const unsigned char WeChatPluginVersionString[];

#define SCREEN_WIDTH ([NSScreen mainScreen].frame.size.width)
#define SCREEN_HEIGHT ([NSScreen mainScreen].frame.size.height)


#pragma mark - 微信原始的部分类与方法

@interface MMMainWindowController : NSObject
- (void)onAuthOK;
- (void)onLogOut;
@end

@interface MessageService : NSObject
- (void)onRevokeMsg:(id)arg1;
- (void)OnSyncBatchAddMsgs:(NSArray *)arg1 isFirstSync:(BOOL)arg2;
- (id)SendTextMessage:(id)arg1 toUsrName:(id)arg2 msgText:(id)arg3 atUserList:(id)arg4;
- (id)GetMsgData:(id)arg1 svrId:(long)arg2;
- (void)AddLocalMsg:(id)arg1 msgData:(id)arg2;
@end

@interface MMServiceCenter : NSObject
+ (id)defaultCenter;
- (id)getService:(Class)arg1;
@end

@interface SKBuiltinString_t : NSObject
@property(retain, nonatomic, setter=SetString:) NSString *string; // @synthesize string;
@end

@interface AddMsg : NSObject
@property(retain, nonatomic, setter=SetContent:) SKBuiltinString_t *content; // @synthesize content;
@property(retain, nonatomic, setter=SetFromUserName:) SKBuiltinString_t *fromUserName; // @synthesize fromUserName;
@property(nonatomic, setter=SetMsgType:) int msgType; // @synthesize msgType;
@property(retain, nonatomic, setter=SetToUserName:) SKBuiltinString_t *toUserName; // @synthesize toUserName;
@end

@interface WeChat : NSObject
+ (id)sharedInstance;
@end

@interface ContactStorage : NSObject
- (id)GetSelfContact;
@end

@interface WCContactData : NSObject
@property(retain, nonatomic) NSString *m_nsUsrName; // @synthesize m_nsUsrName;
@end

@interface MessageData : NSObject
- (id)initWithMsgType:(long long)arg1;
@property(retain, nonatomic) NSString *fromUsrName;
@property(retain, nonatomic) NSString *toUsrName; 
@property(retain, nonatomic) NSString *msgContent;
@property(retain, nonatomic) NSString *msgPushContent;
@property(nonatomic) int msgStatus;
@property(nonatomic) int msgCreateTime;
@property(nonatomic) int mesLocalID;
@end
