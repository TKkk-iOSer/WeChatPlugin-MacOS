//
//  NSView+Action.m
//  WeChatPlugin
//
//  Created by TK on 2017/8/20.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "NSView+Action.h"

@implementation NSView (Action)

- (void)addSubviews:(NSArray *)subViews {
    for (NSView *v in subViews) {
        NSAssert([v isKindOfClass:[NSView class]], @"the elements must be a view!");
        [self addSubview:v];
    }
}

@end
