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
    [self.subcanvas resizeBoundsToFitContent];
    CGSize s = [self preferredInnerSize];
    return s.width * s.height ? s.width / s.height : 1;
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
    
    v.models = @[xTiles, yTiles];
    
    [self.canvas.delegate canvas:self.canvas shouldShowEditingPanel:v];
}

- (void)setXRepeat:(NSInteger)xRepeat {
    if (_xRepeat == xRepeat) return;
        
    _xRepeat = xRepeat;
    [self setNeedsLayout];
    [self updateAspectRatio:[self preferredAspectRatio]];
}

- (void)setYRepeat:(NSInteger)yRepeat {
    if (_yRepeat == yRepeat) return;
    
    _yRepeat = yRepeat;
    [self setNeedsLayout];
    [self updateAspectRatio:[self preferredAspectRatio]];
}

@end
