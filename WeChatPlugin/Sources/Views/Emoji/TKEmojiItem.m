//
//  TKEmojiItem.m
//  WeChatPlugin
//
//  Created by KenHan on 2018/7/20.
//  Copyright © 2018 tk. All rights reserved.
//

#import "TKEmojiItem.h"

@implementation TKEmojiItem

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    NSRect imageRect = NSMakeRect(5,5,self.frame.size.width -10,self.frame.size.height -10);
    NSBezierPath* imageRoundedRectanglePath = [NSBezierPath bezierPathWithRoundedRect:imageRect xRadius: 4 yRadius: 4];
    NSColor* fillColor = nil;
    NSColor* strokeColor = nil;
    
    //默认是未选中的
    if (_isSelected) {
        
        fillColor = [NSColor colorWithCalibratedRed: 0.851 green: 0.851 blue: 0.851 alpha: 1];
        strokeColor = [NSColor colorWithCalibratedRed: 0.408 green: 0.592 blue: 0.855 alpha: 1];
        
    }else{
        
        fillColor = [NSColor clearColor];
        strokeColor = [NSColor colorWithCalibratedRed: 0.749 green: 0.749 blue: 0.749 alpha: 1];
    }
    
    [fillColor setFill];
    [imageRoundedRectanglePath fill];
    [strokeColor setStroke];
    
    [super drawRect:dirtyRect];
    
}

- (void)setIsSelected:(BOOL)isSelected
{
    _isSelected = isSelected;
    [self setNeedsDisplay:YES];
}


@end
