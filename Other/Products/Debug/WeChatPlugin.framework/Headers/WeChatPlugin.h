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

#pragma mark - 微信原始的部分类与方法

@interface MMLoginOneClickViewController : NSViewController
@property(nonatomic) NSTextField *descriptionLabel;
- (void)onLoginButtonClicked:(id)arg1;
@property(nonatomic) NSButton *loginButton;
@end

@interface AccountService : NSObject
- (id)GetLastLoginUserName;
- (id)GetLastLoginAutoAuthKey;
- (BOOL)canAutoAuth;
- (void)AutoAuth;
- (void)ManualLogin:(id)arg1 withPassword:(id)arg2;
- (void)ManualLogout;
- (void)QRCodeLoginWithUserName:(id)arg1 password:(id)arg2;
@end

@interface MMLoginViewController : NSObject
@property(retain, nonatomic) MMLoginOneClickViewController *oneClickViewController;
@end

@interface MMMainWindowController : NSWindowController
@property(retain, nonatomic) MMLoginViewController *loginViewController;
- (void)onAuthOK;
- (void)onLogOut;
@end

@interface MessageService : NSObject
- (void)onRevokeMsg:(id)arg1;
- (void)OnSyncBatchAddMsgs:(NSArray *)arg1 isFirstSync:(BOOL)arg2;
- (id)SendTextMessage:(id)arg1 toUsrName:(id)arg2 msgText:(id)arg3 atUserList:(id)arg4;
- (id)GetMsgData:(id)arg1 svrId:(long)arg2;
- (void)AddLocalMsg:(id)arg1 msgData:(id)arg2;
- (void)TranscribeVoiceMessage:(id)arg1 completion:(void (^)(void))arg2;
- (BOOL)ClearUnRead:(id)arg1 FromID:(unsigned int)arg2 ToID:(unsigned int)arg3;
- (BOOL)hasMsgInChat:(id)arg1;
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
@property (nonatomic, assign) unsigned int createTime;
@property(nonatomic, setter=SetNewMsgId:) long long newMsgId;
@end

@interface MMChatsViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
@property(nonatomic) __weak NSTableView *tableView;
@end

@interface WeChat : NSObject
+ (id)sharedInstance;
@property(nonatomic) MMChatsViewController *chatsViewController;
@property(retain, nonatomic) MMMainWindowController *mainWindowController;
@property(nonatomic) BOOL isAppTerminating;
- (void)startANewChatWithContact:(id)arg1;
- (void)_clearAllUnreadMessages:(id)arg1;
- (void)onAuthOK:(BOOL)arg1;
@property(nonatomic) BOOL hasAuthOK;
@end

@interface ContactStorage : NSObject
- (id)GetSelfContact;
- (id)GetContact:(id)arg1;
- (id)GetAllBrandContacts;
- (id)GetAllFavContacts;
- (id)GetAllFriendContacts;
@end

@interface GroupStorage : NSObject
{
    NSMutableDictionary *m_dictGroupContacts;
}
- (id)GetAllGroups;
@end

@interface WCContactData : NSObject
@property(retain, nonatomic) NSString *m_nsUsrName; // @synthesize m_nsUsrName;
@property(nonatomic) unsigned int m_uiFriendScene;  // @synthesize m_uiFriendScene;
@property(retain, nonatomic) NSString *m_nsNickName;    // 用户昵称
@property(retain, nonatomic) NSString *m_nsRemark;      // 备注
@property(retain, nonatomic) NSString *m_nsHeadImgUrl;  // 头像
@property(nonatomic) BOOL m_isShowRedDot; 
- (BOOL)isBrandContact;
- (BOOL)isSelf;
- (id)getGroupDisplayName;

@end

@interface MessageData : NSObject
- (id)initWithMsgType:(long long)arg1;
@property(retain, nonatomic) NSString *fromUsrName;
@property(retain, nonatomic) NSString *toUsrName;
@property(retain, nonatomic) NSString *msgContent;
@property(retain, nonatomic) NSString *msgPushContent;
@property(nonatomic) int messageType;
@property(nonatomic) int msgStatus;
@property(nonatomic) int msgCreateTime;
@property(nonatomic) int mesLocalID;
@property(nonatomic) long long mesSvrID;
@property(retain, nonatomic) NSString *msgVoiceText;
@property(copy, nonatomic) NSString *m_nsEmoticonMD5;
- (BOOL)isChatRoomMessage;
- (id)groupChatSenderDisplayName;
- (id)getRealMessageContent;
- (BOOL)isSendFromSelf;
- (BOOL)isCustomEmojiMsg;
- (BOOL)isImgMsg;
- (BOOL)isVideoMsg;
- (BOOL)isVoiceMsg;
- (BOOL)canForward;
@end

@interface CUtility : NSObject
+ (BOOL)HasWechatInstance;
+ (unsigned long long)getFreeDiskSpace;
+ (void)ReloadSessionForMsgSync;
+ (id)GetCurrentUserName;
@end
@interface MMSessionInfoPackedInfo: NSObject
@property(retain, nonatomic) WCContactData *m_contact;
@end

@interface MMSessionInfo : NSObject
@property(nonatomic) BOOL m_bIsTop; // @synthesize m_bIsTop;
@property(nonatomic) BOOL m_bShowUnReadAsRedDot;
@property(nonatomic) BOOL m_isMentionedUnread; // @synthesize
@property(retain, nonatomic) NSString *m_nsUserName; // @synthesize m_nsUserName;
@property(retain, nonatomic) MMSessionInfoPackedInfo *m_packedInfo;
@end

@protocol MMChatsTableCellViewDelegate <NSObject>
@optional
- (void)cellViewReloadData:(MMSessionInfo *)arg1;
@end

@interface MMChatsTableCellView : NSTableCellView
@property(nonatomic) __weak id <MMChatsTableCellViewDelegate> delegate;
@property(retain, nonatomic) MMSessionInfo *sessionInfo;
- (void)menuWillOpen:(id)arg1;
- (void)contextMenuSticky:(id)arg1;
- (void)contextMenuDelete:(id)arg1;
- (void)tableView:(NSTableView *)arg1 rowGotMouseDown:(long long)arg2;
@end

@interface MMSessionMgr : NSObject
@property(retain, nonatomic) NSMutableArray *m_arrSession;
- (id)GetSessionAtIndex:(unsigned long long)arg1;
- (void)MuteSessionByUserName:(id)arg1;
//- (void)TopSessionByUserName:(id)arg1;
- (void)UnmuteSessionByUserName:(id)arg1;
- (void)UntopSessionByUserName:(id)arg1;
- (void)deleteSessionWithoutSyncToServerWithUserName:(id)arg1;
- (void)sortSessions;
- (id)getContact:(id)arg1;
@end

@interface LogoutCGI : NSTableCellView
- (void)sendLogoutCGIWithCompletion:(id)arg1;
@end

@interface MMNotificationService : NSObject
- (id)getNotificationContentWithMsgData:(id)arg1;
- (void)userNotificationCenter:(id)arg1 didActivateNotification:(id)arg2;
@end

@interface MMChatMessageViewController : NSViewController
@end

@interface MMMessageTableItem : NSObject
@property(retain, nonatomic) MessageData *message;
@end

@interface MMStickerMessageCellView : NSObject
@property(retain, nonatomic) MMMessageTableItem *messageTableItem;
@property(nonatomic) MMChatMessageViewController *delegate;
- (BOOL)allowCopy;
- (void)contextMenuCopy;
- (id)contextMenu;
@end

@interface EmoticonMgr : NSObject
@property(retain, nonatomic) MessageData *message;
- (id)getEmotionDataWithMD5:(id)arg1;
@end

@interface MMComplexContactSearchTaskMgr : NSObject
+ (id)sharedInstance;
- (void)doComplexContactSearch:(id)arg1 searchScene:(unsigned long long)arg2 complete:(void (^)(NSArray *, NSArray *, NSArray *))arg3 cancelable:(BOOL)arg4;
@end

@interface MMComplexContactSearchResult : NSObject
@property(retain, nonatomic) NSString *fieldValue;
@property(retain, nonatomic) WCContactData *contact;
@property(nonatomic) unsigned long long fieldType;  // 1：备注 3：昵称 4：微信号  8：省份  7：市  9：国家
@end

@interface MMComplexGroupContactMembersSearchResult : NSObject
@property(retain, nonatomic) NSMutableArray<MMComplexContactSearchResult *> *membersSearchReults;
@end

@interface MMComplexGroupContactSearchResult : NSObject
@property(nonatomic) unsigned long long searchType;     // 1 名称 2 群成员名称
@property(retain) WCContactData *groupContact;
@property(retain, nonatomic) MMComplexGroupContactMembersSearchResult *groupMembersResult;
@end

@interface MMAvatarService : NSObject
- (NSString *)avatarCachePath;
@end

@interface NSString (MD5)
- (id)md5String;
@end

@interface MMSessionPickerLogic : NSObject
@property(nonatomic) NSArray *selectedUserNames;
@end


@interface MMSessionListView : NSObject
{
    MMSessionPickerLogic *m_logic;
}
@end

@interface MMSessionPickerWindow : NSWindowController
+ (id)shareInstance;
- (void)beginSheetForWindow:(id)arg1 completionHandler:(void(^)(id a1))arg2;
@property(retain, nonatomic) id choosenViewController; // @synthesize
@property(retain, nonatomic) id listViewController; // @synthesize
- (void)setShowsGroupChats:(BOOL)arg1;
- (void)setShowsOfficialAccounts:(BOOL)arg1;
- (void)setShowsOtherNonhumanChats:(BOOL)arg1;
- (void)setType:(unsigned long long)arg1;

@end

@interface AFHTTPResponseSerializer : NSObject
@end

@interface AFURLSessionManager : NSObject
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request
                                             progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                                          destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
                                    completionHandler:(void (^)(NSURLResponse *response, NSURL * filePath, NSError * error))completionHandler;
- (id)initWithSessionConfiguration:(id)arg1;
@end

@interface AFHTTPRequestSerializer : NSObject
+ (id)serializer;
@property(nonatomic) unsigned long long cachePolicy;
@end

@interface AFHTTPSessionManager : NSObject
+ (AFHTTPSessionManager *)manager;
@property(retain, nonatomic) AFHTTPRequestSerializer *requestSerializer;
@property(retain, nonatomic) AFHTTPResponseSerializer *responseSerializer;
@end

@interface MMURLHandler : NSObject
- (void)startGetA8KeyWithURL:(id)arg1;
- (BOOL)openURLWithDefault:(id)arg1;
@end

@interface UserDefaultsService : NSObject
- (void)setString:(id)arg1 forKey:(id)arg2;
- (id)stringForKey:(id)arg1;
@end
