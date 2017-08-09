//
//  TKRemoteControlModel.h
//  WeChatPlugin
//
//  Created by TK on 2017/8/8.
//  Copyright © 2017年 tk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TKRemoteControlModel : NSObject

@property (nonatomic, assign) BOOL enable;
@property (nonatomic, copy) NSString *keyword;
@property (nonatomic, copy) NSString *function;
@property (nonatomic, copy) NSString *executeCommand;

- (instancetype)initWithDict:(NSDictionary *)dict;
- (NSDictionary *)dictionary;

@end
