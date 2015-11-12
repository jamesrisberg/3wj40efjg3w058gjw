//
//  SubcanvasDrawable.m
//  computer
//
//  Created by Nate Parrott on 10/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "SubcanvasDrawable.h"
#import "Canvas.h"
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
    
    if (!self.subcanvas) {
        self.subcanvas = [Canvas new];
    }
}

- (void)setSubcanvas:(Canvas *)canvas {
    [_subcanvas removeFromSuperview];
    _subcanvas = canvas;
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
    CGSize innerSize = [self preferredInnerSize];
    CGFloat contentXScale = self.bounds.size.width / innerSize.width;
    CGFloat contentYScale = self.bounds.size.height / innerSize.height;
    self.subcanvas.transform = CGAffineTransformMakeScale(contentXScale, contentYScale);
    self.subcanvas.layer.anchorPoint = CGPointMake(0, 0);
    self.subcanvas.center = CGPointMake(0, 0);
    self.xReplicator.frame = self.bounds;
    self.yReplicator.frame = self.bounds;
    self.xReplicator.replicatorLayer.instanceTransform = CATransform3DMakeTranslation(self.subcanvas.bounds.size.width * contentXScale * self.xGap, 0, 0);
    self.yReplicator.replicatorLayer.instanceTransform = CATransform3DMakeTranslation(0, self.subcanvas.bounds.size.height * contentYScale * self.yGap, 0);
    self.xReplicator.replicatorLayer.instanceCount = self.xRepeat;
    self.yReplicator.replicatorLayer.instanceCount = self.yRepeat;
}

- (CGSize)preferredInnerSize {
    return CGSizeMake(self.subcanvas.bounds.size.width * (1 + self.xGap*(self.xRepeat-1)), self.subcanvas.bounds.size.height * (1 + self.yGap*(self.yRepeat-1)));
}

- (CGFloat)preferredAspectRatio {
    if (self.rotatedCopies > 1) {
        return 1;
    } else {
        [self.subcanvas resizeBoundsToFitContent];
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
    EditorViewController *editorVC = [EditorViewController modalEditorForCanvas:self.subcanvas callback:^(Canvas *edited) {
        weakSelf.subcanvas = edited;
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
    return [[super optionsItems] arrayByAddingObjectsFromArray:@[tiling]];
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

@end
