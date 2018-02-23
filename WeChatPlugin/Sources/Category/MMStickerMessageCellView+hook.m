//
//  MMStickerMessageCellView+hook.m
//  WeChatPlugin
//
//  Created by TK on 2018/2/23.
//  Copyright © 2018年 tk. All rights reserved.
//

#import "MMStickerMessageCellView+hook.h"
#import "WeChatPlugin.h"

@implementation NSObject (MMStickerMessageCellView)

+ (void)hookMMStickerMessageCellView {
    tk_hookMethod(objc_getClass("MMStickerMessageCellView"), @selector(allowCopy), [self class], @selector(hook_allowCopy));
    tk_hookMethod(objc_getClass("MMStickerMessageCellView"), @selector(contextMenuCopy), [self class], @selector(hook_contextMenuCopy));
    tk_hookMethod(objc_getClass("MMStickerMessageCellView"), @selector(contextMenu), [self class], @selector(hook_contextMenu));
}

- (id)hook_contextMenu {
    NSMenu *menu = [self hook_contextMenu];
    if ([self.className isEqualToString:@"MMStickerMessageCellView"]) {
        NSMenuItem *exportItem = [[NSMenuItem alloc] initWithTitle:@"存储…" action:@selector(contextMenuExport) keyEquivalent:@""];
        [menu insertItem:exportItem atIndex:2];
    }
    return menu;
}

- (BOOL)hook_allowCopy {
    if ([self.className isEqualToString:@"MMStickerMessageCellView"]) {
        return YES;
    }
    return [self hook_allowCopy];
}

- (void)contextMenuExport {
    MMStickerMessageCellView *currentCellView = (MMStickerMessageCellView *)self;
    MMMessageTableItem *item = currentCellView.messageTableItem;
    EmoticonMgr *emoticonMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("EmoticonMgr")];
    NSData *imageData = [emoticonMgr getEmotionDataWithMD5:item.message.m_nsEmoticonMD5];
    
    NSSavePanel *savePanel = ({
        NSSavePanel *panel = [NSSavePanel savePanel];
        [panel setDirectoryURL:[NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Pictures"]]];
        [panel setNameFieldStringValue:item.message.m_nsEmoticonMD5];
        [panel setAllowedFileTypes:@[@"jpg",@"png"]];
        [panel setAllowsOtherFileTypes:YES];
        [panel setExtensionHidden:NO];
        [panel setCanCreateDirectories:YES];
        
        panel;
    });
    [savePanel beginSheetModalForWindow:currentCellView.delegate.view.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            [imageData writeToFile:[[savePanel URL] path] atomically:YES];
        }
    }];
}

- (void)hook_contextMenuCopy {
    if ([self.className isEqualToString:@"MMStickerMessageCellView"]) {
        MMMessageTableItem *item = [self valueForKey:@"messageTableItem"];
        EmoticonMgr *emoticonMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("EmoticonMgr")];
        NSData *imageData = [emoticonMgr getEmotionDataWithMD5:item.message.m_nsEmoticonMD5];
        NSString *imageName = [NSString stringWithFormat:@"temp_paste_image_%@.jpg",item.message.m_nsEmoticonMD5];
        NSString *tempImageFilePath = [NSTemporaryDirectory() stringByAppendingString:imageName];
        NSURL *imageUrl = [NSURL fileURLWithPath:tempImageFilePath];
        [imageData writeToURL:imageUrl atomically:YES];
        
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard declareTypes:@[NSFilenamesPboardType] owner:nil];
        [pasteboard writeObjects:@[imageUrl]];
    } else {
        [self hook_contextMenuCopy];
    }
}

@end
