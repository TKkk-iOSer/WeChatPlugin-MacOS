//
//  TKAutoReplyWindowController.m
//  WeChatPlugin
//
//  Created by TK on 2017/4/19.
//  Copyright © 2017年 tk. All rights reserved.
//

#import "TKAutoReplyWindowController.h"
#import "TKAutoReplyContentView.h"
#import "WeChatPlugin.h"
#import "TKAutoReplyCell.h"

@interface TKAutoReplyWindowController () <NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) TKAutoReplyContentView *contentView;
@property (nonatomic, strong) NSButton *addButton;
@property (nonatomic, strong) NSButton *reduceButton;
@property (nonatomic, strong) NSAlert *alert;

@property (nonatomic, strong) NSMutableArray *autoReplyModels;
@property (nonatomic, assign) NSInteger lastSelectIndex;

@end

@implementation TKAutoReplyWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self initSubviews];
    [self setup];
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    [self.tableView reloadData];
    [self.contentView setHidden:YES];
    if (self.autoReplyModels && self.autoReplyModels.count == 0) {
        [self addModel];
    }
    if (self.autoReplyModels.count > 0 && self.tableView) {
         [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.autoReplyModels.count - 1] byExtendingSelection:YES];
    }
}

- (void)initSubviews {
    NSScrollView *scrollView = ({
        NSScrollView *scrollView = [[NSScrollView alloc] init];
        scrollView.hasVerticalScroller = YES;
        scrollView.frame = NSMakeRect(30, 50, 200, 375);
        scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        scrollView;
    });
    
    self.tableView = ({
        NSTableView *tableView = [[NSTableView alloc] init];
        tableView.frame = scrollView.bounds;
        tableView.allowsTypeSelect = YES;
        tableView.delegate = self;
        tableView.dataSource = self;
        NSTableColumn *column = [[NSTableColumn alloc] init];
        column.title = @"自动回复列表";
        column.width = 200;
        [tableView addTableColumn:column];
        
        tableView;
    });
    
    self.contentView = ({
        TKAutoReplyContentView *contentView = [[TKAutoReplyContentView alloc] init];
        contentView.frame = NSMakeRect(250, 50, 400, 375);
        contentView.hidden = YES;
        
        contentView;
    });
    
    self.addButton = ({
        NSButton *btn = [NSButton tk_buttonWithTitle:@"＋" target:self action:@selector(addModel)];
        btn.frame = NSMakeRect(30, 10, 40, 40);
        btn.bezelStyle = NSBezelStyleTexturedRounded;
        
        btn;
    });
    
    self.reduceButton = ({
        NSButton *btn = [NSButton tk_buttonWithTitle:@"－" target:self action:@selector(reduceModel)];
        btn.frame = NSMakeRect(80, 10, 40, 40);
        btn.bezelStyle = NSBezelStyleTexturedRounded;
        btn.enabled = NO;
        
        btn;
    });
    
    self.alert = ({
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"确定"];
        [alert setMessageText:@"您还有一条自动回复设置未完成"];
        [alert setInformativeText:@"请完善未完成的自动回复设置"];
        
        alert;
    });
    
    scrollView.contentView.documentView = self.tableView;
    
    [self.window.contentView addSubviews:@[scrollView,
                                           self.contentView,
                                           self.addButton,
                                           self.reduceButton]];
}

- (void)setup {
    self.window.title = @"自动回复设置";
    self.window.contentView.layer.backgroundColor = [kBG1 CGColor];
    [self.window.contentView.layer setNeedsDisplay];
    
    self.lastSelectIndex = -1;
    self.autoReplyModels = [[TKWeChatPluginConfig sharedConfig] autoReplyModels];
    [self.tableView reloadData];
    
    __weak typeof(self) weakSelf = self;
    self.contentView.endEdit = ^(void) {
        [weakSelf.tableView reloadData];
        if (weakSelf.lastSelectIndex != -1) {
            [weakSelf.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:weakSelf.lastSelectIndex] byExtendingSelection:YES];
        }
    };
}

/**
 关闭窗口事件
 
 */
- (BOOL)windowShouldClose:(id)sender {
    [[TKWeChatPluginConfig sharedConfig] saveAutoReplyModels];
    return YES;
}

#pragma mark - addButton & reduceButton ClickAction
- (void)addModel {
    if (self.contentView.hidden) {
        self.contentView.hidden = NO;
    }
    __block NSInteger emptyModelIndex = -1;
    [self.autoReplyModels enumerateObjectsUsingBlock:^(TKAutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (model.hasEmptyKeywordOrReplyContent) {
            emptyModelIndex = idx;
            *stop = YES;
        }
    }];
    
    if (self.autoReplyModels.count > 0 && emptyModelIndex != -1) {
        [self.alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            if(returnCode == NSAlertFirstButtonReturn){
                if (self.tableView.selectedRow != -1) {
                    [self.tableView deselectRow:self.tableView.selectedRow];
                }
                [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:emptyModelIndex] byExtendingSelection:YES];
            }
        }];
        return;
    };
    
    TKAutoReplyModel *model = [[TKAutoReplyModel alloc] init];
    [self.autoReplyModels addObject:model];
    [self.tableView reloadData];
    self.contentView.model = model;
    
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.autoReplyModels.count - 1] byExtendingSelection:YES];
}

- (void)reduceModel {
    NSInteger index = self.tableView.selectedRow;
    if (index > -1) {
        [self.autoReplyModels removeObjectAtIndex:index];
        [self.tableView reloadData];
        if (self.autoReplyModels.count == 0) {
            self.contentView.hidden = YES;
            self.reduceButton.enabled = NO;
        } else {
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.autoReplyModels.count - 1] byExtendingSelection:YES];
        }
    }
}

#pragma mark - NSTableViewDataSource && NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.autoReplyModels.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    TKAutoReplyCell *cell = [[TKAutoReplyCell alloc] init];
    cell.frame = NSMakeRect(0, 0, self.tableView.frame.size.width, 40);
    cell.model = self.autoReplyModels[row];
     __weak typeof(self) weakSelf = self;
    cell.updateModel = ^{
        weakSelf.contentView.model = weakSelf.autoReplyModels[row];
    };
    return cell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 50;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = notification.object;
    self.contentView.hidden = tableView.selectedRow == -1;
    self.reduceButton.enabled = tableView.selectedRow != -1;
    
    if (tableView.selectedRow != -1) {
        TKAutoReplyModel *model = self.autoReplyModels[tableView.selectedRow];
        self.contentView.model = model;
        self.lastSelectIndex = tableView.selectedRow;
        __block NSInteger emptyModelIndex = -1;
        [self.autoReplyModels enumerateObjectsUsingBlock:^(TKAutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            if (model.hasEmptyKeywordOrReplyContent) {
                emptyModelIndex = idx;
                *stop = YES;
            }
        }];
        
        if (emptyModelIndex != -1 && tableView.selectedRow != emptyModelIndex) {
            [self.alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                if(returnCode == NSAlertFirstButtonReturn){
                    if (self.tableView.selectedRow != -1) {
                        [self.tableView deselectRow:self.tableView.selectedRow];
                    }
                    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:emptyModelIndex] byExtendingSelection:YES];
                }
            }];
        }
    }
}

@end
