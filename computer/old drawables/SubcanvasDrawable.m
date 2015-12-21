//
//  SubcanvasDrawable.m
//  computer
//
//  Created by Nate Parrott on 10/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "SubcanvasDrawable.h"
#import "CanvasEditor.h"
#import "EditorViewController.h"
#import "OptionsView.h"
#import "SliderOptionsCell.h"
#import "ReplicatorView.h"

@interface SubcanvasDrawable ()

@property (nonatomic) ReplicatorView *xReplicator, *yReplicator;

@end

@implementation SubcanvasDrawable

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.subcanvas = [aDecoder decodeObjectForKey:@"canvas"];
    self.xRepeat = [aDecoder decodeIntegerForKey:@"xRepeat"] ? : 1;
    self.yRepeat = [aDecoder decodeIntegerForKey:@"yRepeat"] ? : 1;
    self.xGap = [aDecoder decodeFloatForKey:@"xGap"] ? : 1;
    self.yGap = [aDecoder decodeFloatForKey:@"yGap"] ? : 1;
    self.rotatedCopies = [aDecoder decodeIntegerForKey:@"rotatedCopies"] ? : 1;
    self.rotationOffset = [aDecoder decodeFloatForKey:@"rotationOffset"] ? : 2;
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.subcanvas forKey:@"canvas"];
    [aCoder encodeInteger:self.xRepeat forKey:@"xRepeat"];
    [aCoder encodeInteger:self.yRepeat forKey:@"yRepeat"];
    [aCoder encodeFloat:self.xGap forKey:@"xGap"];
    [aCoder encodeFloat:self.yGap forKey:@"yGap"];
    [aCoder encodeInteger:self.rotatedCopies forKey:@"rotatedCopies"];
    [aCoder encodeFloat:self.rotationOffset forKey:@"rotationOffset"];
}

- (void)setup {
    [super setup];
    
    self.xReplicator = [ReplicatorView new];
    [self addSubview:self.xReplicator];
    self.yReplicator = [ReplicatorView new];
    [self.xReplicator addSubview:self.yReplicator];
    _xRepeat = 1;
    _yRepeat = 1;
    _xGap = 1;
    _yGap = 1;
    _rotatedCopies = 1;
    _rotationOffset = 2;
    
    if (!self.subcanvas) {
        self.subcanvas = [CanvasEditor new];
    }
}

- (void)setSubcanvas:(CanvasEditor *)canvas {
    [_subcanvas removeFromSuperview];
    _subcanvas = canvas;
    canvas.suppressTimingVisualizations = YES;
    [self.yReplicator addSubview:_subcanvas];
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        self.bounds = CGRectMake(0, 0, 200, 200);
    }
    [self updateAspectRatio:[self preferredAspectRatio]];
    [self setNeedsLayout];
}

#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    // subcanvas.bounds is set by -[Canvas resizeBoundsToFitContent] inside -setSubcanvas:
    
    self.subcanvas.layer.anchorPoint = CGPointMake(0, 0);
    self.subcanvas.center = CGPointMake(0, 0);
    
    if (self.rotatedCopies > 1) {
        CGFloat scale = MIN(self.bounds.size.width / self.rotationOffset / self.subcanvas.bounds.size.width, self.bounds.size.height / self.rotationOffset / self.subcanvas.bounds.size.height);
        self.subcanvas.transform = CGAffineTransformMakeScale(scale, scale);
        self.xReplicator.frame = self.bounds;
        self.yReplicator.frame = self.bounds;
        self.xReplicator.replicatorLayer.instanceCount = 1;
        self.yReplicator.replicatorLayer.instanceCount = self.rotatedCopies;
        self.yReplicator.replicatorLayer.instanceTransform = CATransform3DMakeRotation(2 * M_PI / self.rotatedCopies, 0, 0, 1);
    } else {
        CGSize innerSize = [self preferredInnerSize];
        CGFloat contentXScale = self.bounds.size.width / innerSize.width;
        CGFloat contentYScale = self.bounds.size.height / innerSize.height;
        self.subcanvas.transform = CGAffineTransformMakeScale(contentXScale, contentYScale);
        self.xReplicator.frame = self.bounds;
        self.yReplicator.frame = self.bounds;
        self.xReplicator.replicatorLayer.instanceTransform = CATransform3DMakeTranslation(self.subcanvas.bounds.size.width * contentXScale * self.xGap, 0, 0);
        self.yReplicator.replicatorLayer.instanceTransform = CATransform3DMakeTranslation(0, self.subcanvas.bounds.size.height * contentYScale * self.yGap, 0);
        self.xReplicator.replicatorLayer.instanceCount = self.xRepeat;
        self.yReplicator.replicatorLayer.instanceCount = self.yRepeat;
    }
}

- (CGSize)preferredInnerSize {
    return CGSizeMake(self.subcanvas.bounds.size.width * (1 + self.xGap*(self.xRepeat-1)), self.subcanvas.bounds.size.height * (1 + self.yGap*(self.yRepeat-1)));
}

- (CGFloat)preferredAspectRatio {
    // [self.subcanvas resizeBoundsToFitContent]; // TODO: cache this; this is expensive AF!
    if (self.rotatedCopies > 1) {
        return 1;
    } else {
        CGSize s = [self preferredInnerSize];
        return s.width * s.height ? s.width / s.height : 1;
    }
}

#pragma mark Editing

- (void)primaryEditAction {
    [self editSubcanvas];
}

- (QuickCollectionItem *)mainAction {
    __weak SubcanvasDrawable *weakSelf = self;
    QuickCollectionItem *edit = [QuickCollectionItem new];
    edit.label = NSLocalizedString(@"Edit Group Contents", @"");
    edit.action = ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf editSubcanvas];
        });
    };
    return edit;
}

- (void)editSubcanvas {
    __weak SubcanvasDrawable *weakSelf = self;
    EditorViewController *editorVC = [EditorViewController modalEditorForCanvas:self.subcanvas callback:^(CMCanvas *edited) {
        // weakSelf.subcanvas = edited;
    }];
    [[self vcForPresentingModals] presentViewController:editorVC animated:YES completion:nil];
}

- (NSArray <__kindof QuickCollectionItem*> *)optionsItems {
    __weak SubcanvasDrawable *weakSelf = self;
    QuickCollectionItem *tiling = [QuickCollectionItem new];
    tiling.label = NSLocalizedString(@"Tiling…", @"");
    tiling.action = ^{
        [weakSelf showTilingOptions];
    };
    QuickCollectionItem *rotations = [QuickCollectionItem new];
    rotations.label = NSLocalizedString(@"Rotated copies…", @"");
    rotations.action = ^{
        [weakSelf showRotationOptions];
    };
    return [[super optionsItems] arrayByAddingObjectsFromArray:@[tiling, rotations]];
}

#pragma mark Tiling

- (void)showTilingOptions {
    OptionsView *v = [OptionsView new];
    __weak SubcanvasDrawable *weakSelf = self;
    
    OptionsViewCellModel *xTiles = [OptionsViewCellModel new];
    xTiles.title = NSLocalizedString(@"Horizontal tiles", @"");
    xTiles.cellClass = [SliderOptionsCell class];
    xTiles.onCreate = ^(OptionsCell *cell){
        __weak SliderOptionsCell *sliderCell = (SliderOptionsCell *)cell;
        [sliderCell setRampedValue:weakSelf.xRepeat withMin:1 max:6];
        sliderCell.onValueChange = ^(CGFloat val) {
            weakSelf.xRepeat = round([sliderCell getRampedValueWithMin:1 max:6]);
            [weakSelf updatedKeyframeProperties];
        };
    };
    OptionsViewCellModel *yTiles = [OptionsViewCellModel new];
    yTiles.title = NSLocalizedString(@"Vertical tiles", @"");
    yTiles.cellClass = [SliderOptionsCell class];
    yTiles.onCreate = ^(OptionsCell *cell){
        __weak SliderOptionsCell *sliderCell = (SliderOptionsCell *)cell;
        [sliderCell setRampedValue:weakSelf.yRepeat withMin:1 max:6];
        sliderCell.onValueChange = ^(CGFloat val) {
            weakSelf.yRepeat = round([sliderCell getRampedValueWithMin:1 max:6]);
            [weakSelf updatedKeyframeProperties];
        };
    };
    
    OptionsViewCellModel *xGap = [OptionsViewCellModel new];
    xGap.title = NSLocalizedString(@"Horizontal spacing", @"");
    xGap.cellClass = [SliderOptionsCell class];
    xGap.onCreate = ^(OptionsCell *cell){
        __weak SliderOptionsCell *sliderCell = (SliderOptionsCell *)cell;
        [sliderCell setRampedValue:weakSelf.xGap withMin:0.1 max:2];
        sliderCell.onValueChange = ^(CGFloat val) {
            weakSelf.xGap = [sliderCell getRampedValueWithMin:0.1 max:2];
            [weakSelf updatedKeyframeProperties];
        };
    };
    
    OptionsViewCellModel *yGap = [OptionsViewCellModel new];
    yGap.title = NSLocalizedString(@"Vertical spacing", @"");
    yGap.cellClass = [SliderOptionsCell class];
    yGap.onCreate = ^(OptionsCell *cell){
        __weak SliderOptionsCell *sliderCell = (SliderOptionsCell *)cell;
        [sliderCell setRampedValue:weakSelf.yGap withMin:0.1 max:2];
        sliderCell.onValueChange = ^(CGFloat val) {
            weakSelf.yGap = [sliderCell getRampedValueWithMin:0.1 max:2];
            [weakSelf updatedKeyframeProperties];
        };
    };
    
    v.models = @[xTiles, yTiles, xGap, yGap];
    
    [self.canvas.delegate canvas:self.canvas shouldShowEditingPanel:v];
}

- (void)showRotationOptions {
    OptionsView *v = [OptionsView new];
    __weak SubcanvasDrawable *weakSelf = self;
    
    OptionsViewCellModel *rotations = [OptionsViewCellModel new];
    rotations.title = NSLocalizedString(@"Rotated copies", @"");
    rotations.cellClass = [SliderOptionsCell class];
    rotations.onCreate = ^(OptionsCell *cell){
        __weak SliderOptionsCell *sliderCell = (SliderOptionsCell *)cell;
        sliderCell.value = (weakSelf.rotatedCopies - 1) / 12;
        sliderCell.onValueChange = ^(CGFloat val) {
            weakSelf.rotatedCopies = round(val * 12) + 1;
            [weakSelf updatedKeyframeProperties];
        };
    };
    
    OptionsViewCellModel *offset = [OptionsViewCellModel new];
    offset.title = NSLocalizedString(@"Rotation offset", @"");
    offset.cellClass = [SliderOptionsCell class];
    offset.onCreate = ^(OptionsCell *cell){
        __weak SliderOptionsCell *sliderCell = (SliderOptionsCell *)cell;
        sliderCell.value = (weakSelf.rotationOffset - 1) / 5;
        sliderCell.onValueChange = ^(CGFloat val) {
            weakSelf.rotationOffset = val * 5 + 1;
            [weakSelf updatedKeyframeProperties];
        };
    };
    
    v.models = @[rotations, offset];
    
    [self.canvas.delegate canvas:self.canvas shouldShowEditingPanel:v];
}

- (void)setXRepeat:(NSInteger)xRepeat {
    if (_xRepeat == xRepeat) return;
        
    _xRepeat = xRepeat;
    if (xRepeat > 1) {
        self.rotatedCopies = 1;
    }
    [self setNeedsLayout];
    [self updateAspectRatio:[self preferredAspectRatio]];
}

- (void)setYRepeat:(NSInteger)yRepeat {
    if (_yRepeat == yRepeat) return;
    
    _yRepeat = yRepeat;
    if (yRepeat > 1) {
        self.rotatedCopies = 1;
    }
    [self setNeedsLayout];
    [self updateAspectRatio:[self preferredAspectRatio]];
}

- (void)setXGap:(CGFloat)xGap {
    if (_xGap == xGap) return;
    _xGap = xGap;
    [self setNeedsLayout];
    [self updateAspectRatio:[self preferredAspectRatio]];
}


- (void)setYGap:(CGFloat)yGap {
    if (_yGap == yGap) return;
    _yGap = yGap;
    [self setNeedsLayout];
    [self updateAspectRatio:[self preferredAspectRatio]];
}

- (void)setRotatedCopies:(NSInteger)rotatedCopies {
    if (_rotatedCopies == rotatedCopies) return;
    _rotatedCopies = rotatedCopies;
    if (rotatedCopies > 1) {
        self.xRepeat = 1;
        self.yRepeat = 1;
    }
    [self setNeedsLayout];
    [self updateAspectRatio:[self preferredAspectRatio]];
}

- (void)setRotationOffset:(CGFloat)rotationOffset {
    if (_rotationOffset == rotationOffset) return;
    _rotationOffset = rotationOffset;
    [self setNeedsLayout];
    [self updateAspectRatio:[self preferredAspectRatio]];
}
#pragma mark Time
- (void)setTime:(FrameTime *)time {
    [super setTime:time];
    self.subcanvas.time = time;
}

- (void)setUseTimeForStaticAnimations:(BOOL)useTimeForStaticAnimations {
    [super setUseTimeForStaticAnimations:useTimeForStaticAnimations];
    self.subcanvas.useTimeForStaticAnimations = useTimeForStaticAnimations;
}
#pragma mark Capture
- (void)setPreparedForStaticScreenshot:(BOOL)preparedForStaticScreenshot {
    [super setPreparedForStaticScreenshot:preparedForStaticScreenshot];
    self.subcanvas.preparedForStaticScreenshot = preparedForStaticScreenshot;
}

@end
