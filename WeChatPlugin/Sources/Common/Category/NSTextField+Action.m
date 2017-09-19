//
//  NSTextField+Action.m
//  WeChatPlugin
//
//  Created by TK on 2017/9/19.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "NSTextField+Action.h"

@implementation NSTextField (Action)

+ (instancetype)tk_labelWithString:(NSString *)stringValue {
//    NSTextField *label = [[NSTextField alloc]init];
//    label.bordered = NO;
//    label.editable = NO;
//    label.selectable = NO;
//    label.stringValue = stringValue;
//    
//    return label;
    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 10, 200, 17)];
    [textField setStringValue:stringValue];
    [textField setBezeled:NO];
    [textField setDrawsBackground:NO];
    [textField setEditable:NO];
    [textField setSelectable:NO];

    return textField;
}

@end
