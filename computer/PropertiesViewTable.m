//
//  PropertiesViewTable.m
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "PropertiesViewTable.h"
#import "PropertyModel.h"
#import "PropertyViewTableCell.h"

@interface PropertiesViewTable () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) FrameTime *time;
@property (nonatomic) NSArray<CMDrawable*> *drawables;
@property (nonatomic) NSArray<PropertyModel*> *properties;

@end


@implementation PropertiesViewTable

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    self.delegate = self;
    self.dataSource = self;
    self.canCancelContentTouches = YES;
    return self;
}

- (void)setProperties:(NSArray<PropertyModel*>*)properties onDrawables:(NSArray<CMDrawable*>*)drawables time:(FrameTime *)time {
    self.properties = properties;
    self.drawables = drawables;
    self.time = time;
    [self reloadData];
}

- (void)reloadValues {
    for (PropertyViewTableCell *cell in [self visibleCells]) {
        [cell reloadValue];
    }
}

- (void)setSingleView:(BOOL)singleView {
    _singleView = singleView;
    self.scrollEnabled = !singleView;
    if (self.numberOfSections > 0 && [self numberOfRowsInSection:0] > 0) {
        [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.properties.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.properties[section] title];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PropertyModel *prop = self.properties[indexPath.section];
    NSString *identifier = NSStringFromClass(prop.cellClass);
    PropertyViewTableCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[prop.cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.editor = self.editor;
        [cell setupIfNeeded];
    }
    cell.model = prop;
    cell.time = self.time;
    cell.drawables = self.drawables;
    [cell reloadValue];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.singleView) {
        return self.bounds.size.height;
    } else {
        PropertyModel *model = self.properties[indexPath.section];
        return [[model cellClass] heightForModel:model];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    UIView *bgView = [UIView new];
    bgView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.8];
    header.backgroundView = bgView;
    header.textLabel.textColor = [UIColor whiteColor];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

@end
