//
//  MMStickerMessageCellView+hook.m
//  WeChatPlugin
//
//  Created by TK on 2018/2/23.
//  Copyright © 2018年 tk. All rights reserved.
//

#import "MMStickerMessageCellView+hook.h"
#import "WeChatPlugin.h"
#import "TKEmoticonManager.h"

@implementation NSObject (MMStickerMessageCellView)

+ (void)hookMMStickerMessageCellView {
    tk_hookMethod(objc_getClass("MMStickerMessageCellView"), @selector(contextMenu), [self class], @selector(hook_contextMenu));
    if (LargerOrEqualVersion(@"2.3.22")) {
         tk_hookMethod(objc_getClass("MMStickerMessageCellView"), @selector(contextMenuExport), [self class], @selector(hook_contextMenuExport));
    }
}

- (id)hook_contextMenu {
    NSMenu *menu = [self hook_contextMenu];
    if ([self.className isEqualToString:@"MMStickerMessageCellView"]) {
        NSMenuItem *copyItem = [[NSMenuItem alloc] initWithTitle:WXLocalizedString(@"Message.Menu.Copy") action:@selector(contextMenuCopyEmoji) keyEquivalent:@""];
        NSMenuItem *exportItem = [[NSMenuItem alloc] initWithTitle:WXLocalizedString(@"Message.Menu.Export") action:@selector(contextMenuExport) keyEquivalent:@""];
        [menu addItem:[NSMenuItem separatorItem]];
        [menu addItem:copyItem];
        [menu addItem:exportItem];
    }
    return menu;
}

- (void)contextMenuExport {
    [self exportEmoji];
}

- (void)hook_contextMenuExport {
    if (![self.className isEqualToString:@"MMStickerMessageCellView"]) {
        [self hook_contextMenu];
        return;
    }
    [self exportEmoji];
}

- (void)exportEmoji {
    MMStickerMessageCellView *currentCellView = (MMStickerMessageCellView *)self;
    MMMessageTableItem *item = currentCellView.messageTableItem;
    if (!item.message || !item.message.m_nsEmoticonMD5) {
        return;
    }
    [[TKEmoticonManager shareManager] exportEmoticonWithMd5:item.message.m_nsEmoticonMD5 window:currentCellView.delegate.view.window];
}

- (void)contextMenuCopyEmoji {
    if ([self.className isEqualToString:@"MMStickerMessageCellView"]) {
        MMMessageTableItem *item = [self valueForKey:@"messageTableItem"];
        if (!item.message || !item.message.m_nsEmoticonMD5) {
            return;
        }
        [[TKEmoticonManager shareManager] copyEmoticonWithMd5:item.message.m_nsEmoticonMD5];
    }
}

@end
