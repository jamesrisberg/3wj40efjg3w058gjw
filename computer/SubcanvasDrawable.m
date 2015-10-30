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
#import "SliderTableViewCell.h"
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
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.subcanvas forKey:@"canvas"];
    [aCoder encodeInteger:self.xRepeat forKey:@"xRepeat"];
    [aCoder encodeInteger:self.yRepeat forKey:@"yRepeat"];
}

- (void)setup {
    [super setup];
    
    self.xReplicator = [ReplicatorView new];
    [self addSubview:self.xReplicator];
    self.yReplicator = [ReplicatorView new];
    [self.xReplicator addSubview:self.yReplicator];
    _xRepeat = 1;
    _yRepeat = 1;
    
    if (!self.subcanvas) {
        self.subcanvas = [Canvas new];
    }
}

- (void)setSubcanvas:(Canvas *)canvas {
    CGFloat oldAspectRatio = [self preferredAspectRatio];
    [_subcanvas removeFromSuperview];
    _subcanvas = canvas;
    [canvas resizeBoundsToFitContent];
    [self.yReplicator addSubview:_subcanvas];
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        self.bounds = CGRectMake(0, 0, 200, 200);
    }
    [self adjustAspectRatioWithOld:oldAspectRatio new:[self preferredAspectRatio]];
}

#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    // subcanvas.bounds is set by -[Canvas resizeBoundsToFitContent] inside -setSubcanvas:
    self.subcanvas.transform = CGAffineTransformMakeScale(self.bounds.size.width / self.xRepeat / self.subcanvas.bounds.size.width, self.bounds.size.height / self.yRepeat / self.subcanvas.bounds.size.height);
    self.subcanvas.layer.anchorPoint = CGPointMake(0, 0);
    self.subcanvas.center = CGPointMake(0, 0);
    self.xReplicator.frame = self.bounds;
    self.yReplicator.frame = self.bounds;
    self.xReplicator.replicatorLayer.instanceTransform = CATransform3DMakeTranslation(self.bounds.size.width / self.xRepeat, 0, 0);
    self.yReplicator.replicatorLayer.instanceTransform = CATransform3DMakeTranslation(0, self.bounds.size.height / self.yRepeat, 0);
    self.xReplicator.replicatorLayer.instanceCount = self.xRepeat;
    self.yReplicator.replicatorLayer.instanceCount = self.yRepeat;
}

- (CGSize)preferredInnerSize {
    return CGSizeMake(self.subcanvas.bounds.size.width * self.xRepeat, self.subcanvas.bounds.size.height * self.yRepeat);
}

- (CGFloat)preferredAspectRatio {
    CGSize s = [self preferredInnerSize];
    return s.width * s.height ? s.width / s.height : 1;
}

#pragma mark Editing

- (void)primaryEditAction {
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
    return [[super optionsItems] arrayByAddingObject:tiling];
}

#pragma mark Tiling

- (NSInteger)mapSliderToTileCount:(CGFloat)slider {
    return 1 + round(pow(slider * 5, 2)); // max 26
}

- (CGFloat)mapTileCountToSlider:(NSInteger)count {
    return sqrt((count - 1) / 5.0);
}

- (void)showTilingOptions {
    OptionsView *v = [OptionsView new];
    __weak SubcanvasDrawable *weakSelf = self;
    
    OptionsViewCellModel *xTiles = [OptionsViewCellModel new];
    xTiles.title = NSLocalizedString(@"Horizontal tiles", @"");
    xTiles.cellClass = [SliderTableViewCell class];
    xTiles.onCreate = ^(OptionsTableViewCell *cell){
        SliderTableViewCell *sliderCell = (SliderTableViewCell *)cell;
        sliderCell.value = [weakSelf mapTileCountToSlider:weakSelf.xRepeat];
        sliderCell.onValueChange = ^(CGFloat val) {
            weakSelf.xRepeat = [weakSelf mapSliderToTileCount:val];
            [weakSelf updatedKeyframeProperties];
        };
    };
    OptionsViewCellModel *yTiles = [OptionsViewCellModel new];
    yTiles.title = NSLocalizedString(@"Vertical tiles", @"");
    yTiles.cellClass = [SliderTableViewCell class];
    yTiles.onCreate = ^(OptionsTableViewCell *cell){
        SliderTableViewCell *sliderCell = (SliderTableViewCell *)cell;
        sliderCell.value = [weakSelf mapTileCountToSlider:weakSelf.yRepeat];
        sliderCell.onValueChange = ^(CGFloat val) {
            weakSelf.yRepeat = [weakSelf mapSliderToTileCount:val];
            [weakSelf updatedKeyframeProperties];
        };
    };
    
    v.models = @[xTiles, yTiles];
    
    [self.canvas.delegate canvas:self.canvas shouldShowEditingPanel:v];
}

- (void)setXRepeat:(NSInteger)xRepeat {
    if (_xRepeat == xRepeat) return;
    
    CGFloat oldAspect = [self preferredAspectRatio];
    
    _xRepeat = xRepeat;
    [self setNeedsLayout];
    [self adjustAspectRatioWithOld:oldAspect new:[self preferredAspectRatio]];
}

- (void)setYRepeat:(NSInteger)yRepeat {
    if (_yRepeat == yRepeat) return;
    
    CGFloat oldAspect = [self preferredAspectRatio];
    
    _yRepeat = yRepeat;
    [self setNeedsLayout];
    [self adjustAspectRatioWithOld:oldAspect new:[self preferredAspectRatio]];
}

@end
