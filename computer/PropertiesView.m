//
//  PropertiesView.m
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "PropertiesView.h"
#import "PropertyModel.h"
#import "PropertiesViewTabControl.h"
#import "PropertiesViewTable.h"
#import <ReactiveCocoa.h>
#import "CMDrawable.h"
#import "ConvenienceCategories.h"

@interface PropertiesView () {
    PropertiesViewTabControl *_tabControl;
    
    RACScopedDisposable *_disposable;
    __weak CMTransactionStack *_transactionStack;
}

@property (nonatomic) NSArray<CMDrawable *> *drawables;
@property (nonatomic) NSArray<PropertyGroupModel*> *groups;
@property (nonatomic) NSInteger selectedGroupIndex;
@property (nonatomic) FrameTime *time;

@property (nonatomic) PropertiesViewTable *table;

@end

@implementation PropertiesView

- (void)setDrawables:(NSArray<CMDrawable *> *)drawables withEditor:(CanvasEditor *)editor time:(FrameTime *)time transactionStack:(CMTransactionStack *)transactionStack {
    _transactionStack = transactionStack;
    _table.transactionStack = transactionStack;
    self.time = time;
    self.drawables = drawables;
    self.groups = drawables.count == 1 ? [drawables.firstObject propertyGroupsWithEditor:editor] : @[];
}

- (void)reloadValues {
    [_table reloadValues];
}

#pragma mark Data

- (void)setGroups:(NSArray<PropertyGroupModel *> *)groups {
    _groups = groups;
    if (!_table) {
        [self setup];
    }
}

#pragma mark Lifecycle

- (void)setup {
    __weak PropertiesView *weakSelf = self;
    _tabControl = [[PropertiesViewTabControl alloc] initWithFrame:CGRectZero];
    [self addSubview:_tabControl];
    _tabControl.onTabSelected = ^(NSInteger index) {
        weakSelf.selectedGroupIndex = index;
    };
    RAC(_tabControl, tabTitles) = [RACObserve(self, groups) map:^id(NSArray *groups) {
        return [groups map:^id(id obj) {
            return [obj title];
        }];
    }];
    RAC(_tabControl, highlightedTabIndex) = RACObserve(self, selectedGroupIndex);
    
    _table = [[PropertiesViewTable alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _table.transactionStack = _transactionStack;
    [self addSubview:_table];
    
    _disposable = [[[[RACSignal combineLatest:@[RACObserve(self, selectedGroupIndex), RACObserve(self, groups), RACObserve(self, drawables), RACObserve(self, time)]] throttle:0.01] subscribeNext:^(RACTuple *x) {
        NSInteger groupIndex = [[x first] integerValue];
        NSArray<PropertyGroupModel*> *groups = [x second];
        NSArray *properties = @[];
        if (groupIndex < groups.count) {
            properties = [groups[groupIndex] properties];
        }
        NSArray *selection = [x third];
        FrameTime *time = [x fourth];
        [weakSelf.table setProperties:properties onDrawables:selection time:time];
    }] asScopedDisposable];
    
    _tabControl.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.9];
    _table.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.6];
    self.backgroundColor = [UIColor clearColor];
}

#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    _tabControl.frame = CGRectMake(0, self.bounds.size.height-44, self.bounds.size.width, 44);
    _table.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height-44);
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, 240);
}

@end
