//
//  TKRemoteControlWindowController.m
//  WeChatPlugin
//
//  Created by TK on 2017/8/8.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "TKRemoteControlWindowController.h"
#import "TKRemoteControlModel.h"
#import "TKWeChatPluginConfig.h"
#import "TKRemoteControlCell.h"

@interface TKRemoteControlWindowController () <NSWindowDelegate, NSTabViewDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSTabView *tabView;
@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) NSArray *remoteControlModels;

@end

@implementation TKRemoteControlWindowController

- (void)windowDidLoad {
    [super windowDidLoad];

    [self setup];
    [self initSubviews];
}

- (void)initSubviews {

    CGFloat tabViewWidth = self.tabView.frame.size.width;
    CGFloat tabViewHeight = self.tabView.frame.size.height;

    self.tableView = ({
        NSTableView *tableView = [[NSTableView alloc] init];
        tableView.frame = NSMakeRect(50, 50, tabViewWidth, tabViewHeight);
        tableView.delegate = self;
        tableView.dataSource = self;
        NSTableColumn *column = [[NSTableColumn alloc] init];
        column.width = tabViewWidth - 100;
        [tableView addTableColumn:column];
        tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
        tableView.backgroundColor = [NSColor clearColor];

        tableView;
    });

    [self.tabView addSubview:self.tableView];
}

- (void)setup {
    self.window.contentView.layer.backgroundColor = [NSColor whiteColor].CGColor;
    [self.window.contentView.layer setNeedsDisplay];
    self.remoteControlModels = [[TKWeChatPluginConfig sharedConfig] remoteControlModels][0];
}

/**
 关闭窗口时间

 */
- (BOOL)windowShouldClose:(id)sender {
    [[TKWeChatPluginConfig sharedConfig] saveRemoteControlModels];
    return YES;
}

#pragma mark - NSTableViewDataSource && NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.remoteControlModels.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    TKRemoteControlCell *cell = [[TKRemoteControlCell alloc] init];
    cell.frame = NSMakeRect(0, 0, self.tabView.frame.size.width, 40);
    [cell setupWithData:self.remoteControlModels[row]];

    return cell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row{
    return 50;
}

#pragma mark - NSTabViewDelegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    NSInteger selectTabIndex = [tabViewItem.identifier integerValue];
    self.remoteControlModels = [[TKWeChatPluginConfig sharedConfig] remoteControlModels][selectTabIndex];
    [self.tableView reloadData];
}

@end
