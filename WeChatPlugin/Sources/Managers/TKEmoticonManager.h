//
//  TKEmoticonManager.h
//  WeChatPlugin
//
//  Created by TK on 2019/3/13.
//  Copyright © 2019 tk. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKEmoticonManager : NSObject

+ (instancetype)shareManager;

- (void)copyEmoticonWithMd5:(NSString *)md5Str;
- (void)exportEmoticonWithMd5:(NSString *)md5Str window:(NSWindow *)window;
@end

NS_ASSUME_NONNULL_END
