//
//  TKAutoReplyModel.h
//  WeChatPlugin
//
//  Created by TK on 2017/8/18.
//  Copyright © 2017年 tk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKAutoReplyModel : NSObject

@property (nonatomic, assign) BOOL enable;                  /**<    是否开启自动回复  */
@property (nonatomic, copy) NSString *keyword;              /**<    自动回复关键字    */
@property (nonatomic, copy) NSString *replyContent;         /**<    自动回复的内容    */
@property (nonatomic, assign) BOOL enableGroupReply;        /**<    是否开启群聊自动回复  */

- (instancetype)initWithDict:(NSDictionary *)dict;
- (NSDictionary *)dictionary;
- (BOOL)hasEmptyKeywordOrReplyContent;

@end
