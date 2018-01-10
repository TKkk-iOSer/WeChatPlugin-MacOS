//
//  TKWeChatPluginConfig.h
//  WeChatPlugin
//
//  Created by TK on 2017/4/19.
//  Copyright © 2017年 tk. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface TKWeChatPluginConfig : NSObject

@property (nonatomic, assign) BOOL preventRevokeEnable;                 /**<    是否開啟防撤回    */
@property (nonatomic, assign) BOOL autoAuthEnable;                      /**<    是否免驗證登入    */
@property (nonatomic, assign) BOOL autoLoginEnable;                     /**<    是否自動登入     */
@property (nonatomic, assign) BOOL onTop;                               /**<    是否要置顶微信    */
@property (nonatomic, assign) BOOL multipleSelectionEnable;             /**<    是否要进行多選    */
@property (nonatomic, copy) NSMutableArray *autoReplyModels;            /**<    自動回覆的数组    */
@property (nonatomic, copy) NSMutableArray *remoteControlModels;        /**<    遠端控制的数组    */
@property (nonatomic, copy) NSMutableArray *ignoreSessionModels;        /**<    聊天置底的数组    */
@property (nonatomic, copy) NSMutableArray *selectSessions;             /**<    已经选中的会话    */

- (void)saveAutoReplyModels;
- (void)saveRemoteControlModels;
- (void)saveIgnoreSessionModels;

+ (instancetype)sharedConfig;

@end
