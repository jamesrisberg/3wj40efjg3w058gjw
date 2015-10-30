//
//  TimelineView.m
//  computer
//
//  Created by Nate Parrott on 10/19/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "TimelineView.h"
#import "VideoConstants.h"

@interface TimelineViewSnapshotCell : UICollectionViewCell

@property (nonatomic) UILabel *label;
@property (nonatomic) UIView *hasKeyframesIndicator;

@end

@implementation TimelineViewSnapshotCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.label = [UILabel new];
    [self addSubview:self.label];
    self.backgroundColor = [UIColor clearColor];
    self.label.textColor = [UIColor whiteColor];
    self.label.font = [UIFont boldSystemFontOfSize:12];
    self.label.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.5];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.layer.cornerRadius = 8;
    self.label.clipsToBounds = YES;
    self.hasKeyframesIndicator = [UIView new];
    self.hasKeyframesIndicator.backgroundColor = [UIColor whiteColor];
    self.hasKeyframesIndicator.bounds = CGRectMake(0, 0, 6, 6);
    self.hasKeyframesIndicator.layer.cornerRadius = 3;
    [self addSubview:self.hasKeyframesIndicator];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.label.frame = CGRectInset(self.bounds, 5, 5);
    self.hasKeyframesIndicator.center = CGPointMake(self.bounds.size.width/2, 5 + 3 + 10);
}

@end





@interface TimelineView () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSInteger snapshotsPerSecond;
@property (nonatomic) NSTimeInterval time;
@property (nonatomic) UIView *centerLine;

@end

@implementation TimelineView

- (instancetype)init {
    self = [super init];
    [self setup];
    return self;
}

- (void)setup {
    self.snapshotsPerSecond = VC_TIMELINE_CELLS_PER_SECOND;
    
    UICollectionViewFlowLayout *flow = [UICollectionViewFlowLayout new];
    flow.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flow.minimumInteritemSpacing = 0;
    flow.minimumLineSpacing = 0;
    flow.itemSize = CGSizeMake([[self class] height], [[self class] height]);
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flow];
    [self addSubview:self.collectionView];
    [self.collectionView registerClass:[TimelineViewSnapshotCell class] forCellWithReuseIdentifier:@"Cell"];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    self.centerLine = [UIView new];
    [self addSubview:self.centerLine];
    self.centerLine.userInteractionEnabled = NO;
    self.centerLine.backgroundColor = [UIColor grayColor];
}

- (FrameTime *)currentFrameTime {
    NSTimeInterval time = self.time;
    NSTimeInterval roundedOff = round(time * self.snapshotsPerSecond)  / self.snapshotsPerSecond;
    if (time == roundedOff) {
        return [[FrameTime alloc] initWithFrame:roundedOff * self.snapshotsPerSecond atFPS:self.snapshotsPerSecond];
    } else {
        return [[FrameTime alloc] initWithFrame:time * 10000 atFPS:10000];
    }
}

- (void)setDelegate:(id<TimelineViewDelegate>)delegate {
    _delegate = delegate;
    [self keyframeAvailabilityUpdatedForTime:nil];
}

#pragma mark Layout

+ (CGFloat)height {
    return 60;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, [[self class] height]);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.collectionView.frame = self.bounds;
    
    UICollectionViewFlowLayout *flow = (id)self.collectionView.collectionViewLayout;
    CGFloat xInset = self.bounds.size.width/2 - flow.itemSize.width/2;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, xInset, 0, xInset);
    
    self.centerLine.frame = CGRectMake(self.bounds.size.width/2 - 1, self.bounds.size.height * 0.6, 2, self.bounds.size.height * 0.3);
    self.centerLine.alpha = 0.7;
    
    [self scrollToTime:self.time animated:NO];
}

- (NSTimeInterval)convertScrollOffsetToTime:(CGFloat)offset {
    UICollectionViewFlowLayout *flow = (id)self.collectionView.collectionViewLayout;
    CGFloat centerOffset = offset + self.collectionView.contentInset.left;
    CGFloat snapshotOffset = centerOffset / flow.itemSize.width;
    NSTimeInterval timeOffset = snapshotOffset / self.snapshotsPerSecond;
    return timeOffset;
}

- (CGFloat)convertTimeToScrollOffset:(NSTimeInterval)time {
    UICollectionViewFlowLayout *flow = (id)self.collectionView.collectionViewLayout;
    CGFloat snapshotOffset = time * self.snapshotsPerSecond;
    CGFloat centerOffset = snapshotOffset * flow.itemSize.width;
    return centerOffset - self.collectionView.contentInset.left;
}

#pragma mark CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 1000 * 1000;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TimelineViewSnapshotCell *cell = (id)[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    if (indexPath.item % self.snapshotsPerSecond == 0) {
        NSInteger seconds = indexPath.item / self.snapshotsPerSecond;
        cell.label.text = [NSString stringWithFormat:@"%@s", @(seconds)];
    } else {
        cell.label.text = nil;
    }
    FrameTime *frameTime = [[FrameTime alloc] initWithFrame:indexPath.item atFPS:self.snapshotsPerSecond];
    cell.hasKeyframesIndicator.hidden = ![self.delegate timelineView:self shouldIndicateKeyframesExistAtTime:frameTime];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSTimeInterval time = indexPath.row * 1.0 / self.snapshotsPerSecond;
    [self scrollToTime:time animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.time = [self convertScrollOffsetToTime:scrollView.contentOffset.x];
    [self.delegate timelineViewDidScroll:self];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    NSTimeInterval targetTime = [self convertScrollOffsetToTime:targetContentOffset->x];
    targetTime = round(targetTime * self.snapshotsPerSecond) / self.snapshotsPerSecond;
    targetContentOffset->x = [self convertTimeToScrollOffset:targetTime];
}

- (void)keyframeAvailabilityUpdatedForTime:(FrameTime *)time {
    for (TimelineViewSnapshotCell *cell in (NSArray *)[self.collectionView visibleCells]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        FrameTime *frameTime = [[FrameTime alloc] initWithFrame:indexPath.item atFPS:self.snapshotsPerSecond];
        cell.hasKeyframesIndicator.hidden = ![self.delegate timelineView:self shouldIndicateKeyframesExistAtTime:frameTime];
    }
}

#pragma mark Selections

- (void)scrollToTime:(NSTimeInterval)time animated:(BOOL)animated {
    [self.collectionView setContentOffset:CGPointMake([self convertTimeToScrollOffset:time], 0) animated:animated];
}

@end
