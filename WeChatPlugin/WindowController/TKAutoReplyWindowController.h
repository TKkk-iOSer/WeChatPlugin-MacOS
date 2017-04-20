//
//  TKAutoReplyWindowController.h
//  WeChatPlugin
//
//  Created by TK on 2017/4/19.
//  Copyright © 2017年 tk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TKAutoReplyWindowController : NSWindowController

@property (nonatomic, copy) void (^startAutoReply)();

@end
