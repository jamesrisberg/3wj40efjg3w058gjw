//
//  ShapeStackList.m
//  computer
//
//  Created by Nate Parrott on 9/4/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "ShapeStackList.h"
#import "Drawable.h"

#define SnapshotViewTag 37985
#define CellHeight 50
#define SnapshotHeight (CellHeight - 10)
#define SnapshotWidth (SnapshotHeight * 2)
#define TableFadeHeight 30

@interface ShapeStackList () <UITableViewDataSource, UITableViewDelegate> {
    CAGradientLayer *_tableMask;
}

@property (nonatomic) UITableView *tableView;
@property (nonatomic) CGFloat tableHeight;

@end

@implementation ShapeStackList

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
    
    UIButton *dismiss = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:dismiss];
    dismiss.frame = self.bounds;
    dismiss.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [dismiss addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchDown];
    
    return self;
}

- (void)setDrawables:(NSArray *)drawables {
    _drawables = drawables;
    if (!self.tableView) {
        self.tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        [self addSubview:self.tableView];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.editing = YES;
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.contentInset = UIEdgeInsetsMake(TableFadeHeight, 0, TableFadeHeight, 0);
        self.tableView.contentOffset = CGPointMake(0, -TableFadeHeight);
        
        // TODO: get this to work
        // (research UIScrollView masking?)
        _tableMask = [CAGradientLayer layer];
        _tableMask.frame = self.tableView.bounds;
        _tableMask.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor blackColor].CGColor, (id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor];
        [self.tableView.layer setMask:_tableMask];
    }
    [self.tableView reloadData];
    self.tableHeight = drawables.count * CellHeight + TableFadeHeight*2;
}

- (void)setTableHeight:(CGFloat)tableHeight {
    _tableHeight = tableHeight;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width * 0.7;
    CGFloat height = MIN(self.bounds.size.height * 0.7, self.tableHeight);
    self.tableView.bounds = CGRectMake(0, 0, width, height);
    self.tableView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    self.tableView.frame = CGRectIntegral(self.tableView.frame);
    _tableMask.frame = self.tableView.bounds;
    _tableMask.locations = @[@0, @(TableFadeHeight / self.tableView.bounds.size.height), @(1 - TableFadeHeight / self.tableView.bounds.size.height), @1];
}

- (void)show {
    CGFloat fadeDuration = 0.2;
    CGFloat flyDuration = 0.3;
    
    [self.tableView layoutIfNeeded];
    [self layoutIfNeeded];
    
    UIView *animationRootView = [UIView new];
    [self.superview addSubview:animationRootView];
    animationRootView.frame = animationRootView.superview.bounds;
    animationRootView.alpha = 0;
    
    for (UITableViewCell *cell in self.tableView.visibleCells.reverseObjectEnumerator) {
        UIView *snapshotInCell = [cell viewWithTag:SnapshotViewTag];
        Drawable *drawable = self.drawables[[self.tableView indexPathForCell:cell].row];
        UIView *snapshotInRoot = [drawable snapshotViewAfterScreenUpdates:NO];
        [animationRootView addSubview:snapshotInRoot];
        snapshotInRoot.center = [animationRootView convertPoint:drawable.center fromView:drawable.superview];
        snapshotInRoot.transform = drawable.transform;
        
        snapshotInCell.hidden = YES;
        [UIView animateWithDuration:flyDuration delay:fadeDuration options:0 animations:^{
            snapshotInRoot.transform = CGAffineTransformIdentity;
            snapshotInRoot.bounds = snapshotInCell.bounds;
            snapshotInRoot.center = [animationRootView convertPoint:snapshotInCell.center fromView:snapshotInCell.superview];
        } completion:^(BOOL finished) {
            snapshotInCell.hidden = NO;
        }];
    }
    [UIView animateWithDuration:fadeDuration animations:^{
        animationRootView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:fadeDuration delay:flyDuration options:0 animations:^{
            animationRootView.alpha = 0;
        } completion:^(BOOL finished) {
            [animationRootView removeFromSuperview];
        }];
    }];
    
    self.hidden = NO;
    self.alpha = 0;
    [UIView animateWithDuration:flyDuration delay:fadeDuration options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.alpha = 0;
        self.tableView.transform = CGAffineTransformMakeTranslation(0, 60);
    } completion:^(BOOL finished) {
        self.alpha = 1;
        self.hidden = YES;
        self.tableView.transform = CGAffineTransformIdentity;
    }];
}

#pragma mark Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.drawables.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CellHeight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedCell:)];
        [cell addGestureRecognizer:tap];
    }
    
    UIView *oldSnapshot = [cell viewWithTag:SnapshotViewTag];
    [oldSnapshot removeFromSuperview];
    
    Drawable *drawable = self.drawables[indexPath.row];
    UIView *snapshot = [drawable snapshotViewAfterScreenUpdates:NO];
    [cell addSubview:snapshot];
    
    cell.showsReorderControl = YES;
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    CGFloat scale = MIN(SnapshotWidth / snapshot.bounds.size.width, SnapshotHeight / snapshot.bounds.size.height);
    snapshot.bounds = CGRectMake(0, 0, snapshot.bounds.size.width * scale, snapshot.bounds.size.height * scale);
    snapshot.center = CGPointMake(cell.bounds.size.width/2, cell.bounds.size.height/2);
    snapshot.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    snapshot.tag = SnapshotViewTag;
    
    return cell;
}

- (void)tappedCell:(UITapGestureRecognizer *)gestureRec {
    UITableViewCell *cell = (id)gestureRec.view;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self hide];
    self.onDrawableSelected(self.drawables[indexPath.row]);
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSMutableArray *drawables = self.drawables.mutableCopy;
    Drawable *d = drawables[sourceIndexPath.row];
    [drawables removeObject:d];
    [drawables insertObject:d atIndex:destinationIndexPath.row];
    _drawables = drawables;
    
    NSArray *drawablesInViewOrder = drawables.reverseObjectEnumerator.allObjects;
    NSInteger destinationIndex = drawablesInViewOrder.count - 1 - destinationIndexPath.row;
    if (destinationIndex == 0 && drawablesInViewOrder.count > 1) {
        Drawable *drawableAboveThisOne = drawablesInViewOrder[1];
        [d removeFromSuperview];
        [drawableAboveThisOne.superview insertSubview:d belowSubview:drawableAboveThisOne];
    } else if (destinationIndex > 0) {
        Drawable *drawableBelowThisOne = drawablesInViewOrder[destinationIndex-1];
        [d removeFromSuperview];
        [drawableBelowThisOne.superview insertSubview:d aboveSubview:drawableBelowThisOne];
    }
}

@end
