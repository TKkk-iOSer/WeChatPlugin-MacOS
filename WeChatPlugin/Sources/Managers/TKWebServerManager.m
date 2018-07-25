//
//  TKWebServerManager.m
//  WeChatPlugin
//
//  Created by TK on 2018/3/18.
//  Copyright © 2018年 tk. All rights reserved.
//

#import "TKWebServerManager.h"
#import "WeChatPlugin.h"
#import <GCDWebServer.h>
#import <GCDWebServerDataResponse.h>
#import <GCDWebServerURLEncodedFormRequest.h>
#import "TKMessageManager.h"

@interface TKWebServerManager ()

@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, strong) MMContactSearchLogic *searchLogic;

@end

@implementation TKWebServerManager

+ (instancetype)shareManager {
    static TKWebServerManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TKWebServerManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.searchLogic = [[objc_getClass("MMContactSearchLogic") alloc] init];
    }
    return self;
}

- (void)startServer {
    if (self.webServer) {
        return;
    }
    NSDictionary *options = @{GCDWebServerOption_Port: @52700,
                              GCDWebServerOption_BindToLocalhost: @YES,
                              GCDWebServerOption_ConnectedStateCoalescingInterval: @2,
                              };
    
    self.webServer = [[GCDWebServer alloc] init];
    [self addHandleForSearchUser];
    [self addHandleForOpenSession];
    [self addHandleForSendMsg];
    [self addHandleForSearchUserChatLog];
    [self.webServer startWithOptions:options error:nil];
}

- (void)endServer {
    if( [self.webServer isRunning] ) {
        [self.webServer stop];
        [self.webServer removeAllHandlers];
        self.webServer = nil;
    }
}

- (void)addHandleForSearchUser {
    __weak typeof(self) weakSelf = self;
    
    [self.webServer addHandlerForMethod:@"GET" path:@"/wechat-plugin/user" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        
        NSString *keyword = request.query ? request.query[@"keyword"] ? request.query[@"keyword"] : @"" : @"";
        __block NSMutableArray *sessionList = [NSMutableArray array];
        
//        返回最近聊天
        if ([keyword isEqualToString:@""]) {
            MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
            NSMutableArray <MMSessionInfo *> *arrSession = sessionMgr.m_arrSession;
            [arrSession enumerateObjectsUsingBlock:^(MMSessionInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.m_packedInfo.m_contact.m_nsUsrName isEqualToString:@"brandsessionholder"]) {
                    return ;
                }
                [sessionList addObject:[weakSelf dictFromSessionInfo:obj]];
            }];
            return [GCDWebServerDataResponse responseWithJSONObject:sessionList];
        }
        
//        返回搜索结果
        MMContactSearchLogic *logic = weakSelf.searchLogic;
        __block BOOL hasResult = NO;
        
        [logic doSearchWithKeyword:keyword searchScene:31 resultIsShownBlock:nil completion:^ {
            if ([logic respondsToSelector:@selector(reloadSearchResultDataWithKeyword:completionBlock:)]) {
                [logic reloadSearchResultDataWithKeyword:keyword completionBlock:^ {
                    hasResult = YES;
                }];
            } else if ([logic respondsToSelector:@selector(reloadSearchResultDataWithCompletionBlock:)]) {
                [logic reloadSearchResultDataWithCompletionBlock:^ {
                    hasResult = YES;
                }];
            }
        }];
        
        while (!(hasResult)) {};

        [logic.contactResults enumerateObjectsUsingBlock:^(MMSearchResultItem * _Nonnull contact, NSUInteger idx, BOOL * _Nonnull stop) {
            [sessionList addObject:[weakSelf dictFromContactSearchResult:(MMComplexContactSearchResult *)contact.result]];
        }];
        [logic.groupResults enumerateObjectsUsingBlock:^(MMSearchResultItem * _Nonnull group, NSUInteger idx, BOOL * _Nonnull stop) {
            [sessionList addObject:[weakSelf dictFromGroupSearchResult:(MMComplexGroupContactSearchResult *)group.result]];
        }];
        [logic.oaResults enumerateObjectsUsingBlock:^(MMSearchResultItem * _Nonnull contact, NSUInteger idx, BOOL * _Nonnull stop) {
            [sessionList addObject:[weakSelf dictFromContactSearchResult:(MMComplexContactSearchResult *)contact.result]];
        }];
        
        [logic clearAllResults];
        
        return [GCDWebServerDataResponse responseWithJSONObject:sessionList];
    }];
}

- (void)addHandleForSearchUserChatLog {
    __weak typeof(self) weakSelf = self;
    [self.webServer addHandlerForMethod:@"GET" path:@"/wechat-plugin/chatlog" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        NSString *userId = request.query ? request.query[@"userId"] ? request.query[@"userId"] : nil : nil;
        
        if (userId) {
            NSMutableArray *charLogList = [NSMutableArray array];
            
            NSArray *msgDataList = [[TKMessageManager shareManager] getMsgListWithChatName:userId minMesLocalId:0 limitCnt:30];
            [msgDataList enumerateObjectsUsingBlock:^(MessageData * _Nonnull msgData, NSUInteger idx, BOOL * _Nonnull stop) {
                [charLogList addObject:[weakSelf dictFromMessageData:msgData]];
            }];
            
            MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
            WCContactData *contact = [sessionMgr getContact:userId];
            NSString *title = [weakSelf getUserNameWithContactData:contact];
            NSString *imgPath = [weakSelf cacheAvatarPathFromHeadImgUrl:contact.m_nsHeadImgUrl];
            
            NSDictionary *dict = @{@"title": [NSString stringWithFormat:@"To: %@", title],
                                   @"subTitle": TKLocalizedString(@"assistant.search.chatlog"),
                                   @"icon": imgPath,
                                   @"userId": userId
                                   };
            [charLogList insertObject:dict atIndex:0];
            
            return [GCDWebServerDataResponse responseWithJSONObject:charLogList];
        }
        
        return [GCDWebServerResponse responseWithStatusCode:404];
    }];
}

- (void)addHandleForOpenSession {
    [self.webServer addHandlerForMethod:@"POST" path:@"/wechat-plugin/open-session" requestClass:[GCDWebServerURLEncodedFormRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerURLEncodedFormRequest * _Nonnull request) {
        NSDictionary *requestBody = [request arguments];
        
        if (requestBody && requestBody[@"userId"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
                WCContactData *selectContact = [sessionMgr getContact:requestBody[@"userId"]];
                
                WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
                if ([selectContact isBrandContact]) {
                    WCContactData *brandsessionholder  = [sessionMgr getContact:@"brandsessionholder"];
                    if (brandsessionholder) {
                        [wechat startANewChatWithContact:brandsessionholder];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            MMBrandChatsViewController *brandChats = wechat.chatsViewController.brandChatsViewController;
                            [brandChats startChatWithContact:selectContact];
                        });
                    }
                } else {
                    [wechat startANewChatWithContact:selectContact];
                }
                [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
            });
            return [GCDWebServerResponse responseWithStatusCode:200];
        }
        
        return [GCDWebServerResponse responseWithStatusCode:404];
    }];
}

- (void)addHandleForSendMsg {
    [self.webServer addHandlerForMethod:@"POST" path:@"/wechat-plugin/send-message" requestClass:[GCDWebServerURLEncodedFormRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerURLEncodedFormRequest * _Nonnull request) {
        NSDictionary *requestBody = [request arguments];
        if (requestBody && requestBody[@"userId"] && requestBody[@"content"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                MessageService *messageService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
                NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
                [messageService SendTextMessage:currentUserName
                                      toUsrName:requestBody[@"userId"]
                                        msgText:requestBody[@"content"]
                                     atUserList:nil];
            });
            return [GCDWebServerResponse responseWithStatusCode:200];
        }
        
        return [GCDWebServerResponse responseWithStatusCode:404];
    }];
}

- (NSDictionary *)dictFromGroupSearchResult:(MMComplexGroupContactSearchResult *)result {
    WCContactData *groupContact = result.groupContact;
    
    __block NSString *subTitle = @"";
    if (result.searchType == 2) {
        [result.groupMembersResult.membersSearchReults enumerateObjectsUsingBlock:^(MMComplexContactSearchResult * _Nonnull contact, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *matchStr =[self matchWithContactResult:contact];
            subTitle = [NSString stringWithFormat:@"%@%@(%@)", TKLocalizedString(@"assistant.search.member"), contact.contact.m_nsNickName, matchStr];
        }];
    }
    
    NSString *imgPath = [self cacheAvatarPathFromHeadImgUrl:groupContact.m_nsHeadImgUrl];
    
    return @{@"title": [NSString stringWithFormat:@"%@%@", TKLocalizedString(@"assistant.search.group"), groupContact.getGroupDisplayName],
             @"subTitle": subTitle,
             @"icon": imgPath,
             @"userId": groupContact.m_nsUsrName
             };
}

- (NSString *)matchWithContactResult:(MMComplexContactSearchResult *)result {
    NSString *matchStr = @"";
    NSInteger type = result.fieldType;
    
    switch (type) {     //     1：备注 3：昵称 4：微信号 7：市 8：省份 9：国家
        case 1:
            matchStr = WXLocalizedString(@"Search.Remark");
            break;
        case 3:
            matchStr = WXLocalizedString(@"Search.Nickname");
            break;
        case 4:
            matchStr = WXLocalizedString(@"Search.Username");
            break;
        case 7:
            matchStr = WXLocalizedString(@"Search.City");
            break;
        case 8:
            matchStr = WXLocalizedString(@"Search.Province");
            break;
        case 9:
            matchStr = WXLocalizedString(@"Search.Country");
            break;
        default:
            matchStr = WXLocalizedString(@"Search.Include");
            break;
    }
    matchStr = [matchStr stringByAppendingString:result.fieldValue];
    return matchStr;
}

- (NSDictionary *)dictFromContactSearchResult:(MMComplexContactSearchResult *)result {
    WCContactData *contact = result.contact;
    
    NSString *title = [contact isBrandContact] ? [NSString stringWithFormat:@"%@%@",TKLocalizedString(@"assistant.search.official"), contact.m_nsNickName] : contact.m_nsNickName;
    if(contact.m_nsRemark && ![contact.m_nsRemark isEqualToString:@""]) {
        title = [NSString stringWithFormat:@"%@(%@)",contact.m_nsRemark, contact.m_nsNickName];
    }
    
    NSString *subTitle =[self matchWithContactResult:result];
    NSString *imgPath = [self cacheAvatarPathFromHeadImgUrl:contact.m_nsHeadImgUrl];
    
    return @{@"title": title,
             @"subTitle": subTitle,
             @"icon": imgPath,
             @"userId": contact.m_nsUsrName
             };
}

- (NSDictionary *)dictFromSessionInfo:(MMSessionInfo *)sessionInfo {
    WCContactData *contact = sessionInfo.m_packedInfo.m_contact;
    MessageData *msgData = sessionInfo.m_packedInfo.m_msgData;
    
    NSString *title = [self getUserNameWithContactData:contact];
    NSString *msgContent = [[TKMessageManager shareManager] getMessageContentWithData:msgData];
    NSString *imgPath = [self cacheAvatarPathFromHeadImgUrl:contact.m_nsHeadImgUrl];
    
    return @{@"title": title,
             @"subTitle": msgContent,
             @"icon": imgPath,
             @"userId": contact.m_nsUsrName
             };
}

- (NSDictionary *)dictFromMessageData:(MessageData *)msgData {
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    WCContactData *msgContact = [sessionMgr getContact:msgData.fromUsrName];
    
    NSString *title = [[TKMessageManager shareManager] getMessageContentWithData:msgData];
    NSString *subTitle = [self getUserNameWithContactData:msgContact];
    NSString *imgPath = [self cacheAvatarPathFromHeadImgUrl:msgContact.m_nsHeadImgUrl];
    
    return @{@"title": title,
             @"subTitle": [NSString stringWithFormat:@"from：%@", subTitle],
             @"icon": imgPath,
             @"userId": msgContact.m_nsUsrName
             };
}

//  获取本地图片缓存路径
- (NSString *)cacheAvatarPathFromHeadImgUrl:(NSString *)imgUrl {
    NSString *imgPath = @"";
    if ([imgUrl respondsToSelector:@selector(md5String)]) {
        NSString *imgMd5Str = [imgUrl performSelector:@selector(md5String)];
        MMAvatarService *avatarService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMAvatarService")];
        imgPath = [NSString stringWithFormat:@"%@%@",[avatarService avatarCachePath], imgMd5Str];
    }
    return imgPath;
}

- (NSString *)getUserNameWithContactData:(WCContactData *)contact {
    NSString *userName;
    if (contact.isGroupChat) {
        userName = [NSString stringWithFormat:@"%@%@", TKLocalizedString(@"assistant.search.group"), contact.getGroupDisplayName];
    } else {
        userName = contact.isBrandContact ? [NSString stringWithFormat:@"%@%@",TKLocalizedString(@"assistant.search.official"), contact.m_nsNickName] : contact.m_nsNickName;
        if(contact.m_nsRemark && ![contact.m_nsRemark isEqualToString:@""]) {
            userName = [NSString stringWithFormat:@"%@(%@)",contact.m_nsRemark, contact.m_nsNickName];
        }
    }
    return userName;
}

@end
