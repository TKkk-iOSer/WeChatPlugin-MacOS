//
//  TKWeChatPluginConfig.h
//  WeChatPlugin
//
//  Created by TK on 2017/4/19.
//  Copyright © 2017年 tk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKWeChatPluginConfig : NSObject

+ (instancetype)sharedConfig;

@property (nonatomic, assign) BOOL preventRevokeEnable;         /**<    是否开启防撤回    */
@property (nonatomic, assign) BOOL autoReplyEnable;             /**<    是否开启自动回复  */
@property (nonatomic, copy) NSString *autoReplyKeyword;         /**<    自动回复关键字    */
@property (nonatomic, copy) NSString *autoReplyText;            /**<    自动回复的内容    */

@end
