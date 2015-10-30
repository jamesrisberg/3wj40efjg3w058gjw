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

@interface SubcanvasDrawable ()

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
    if (!self.subcanvas) {
        self.subcanvas = [Canvas new];
    }
}

- (void)setSubcanvas:(Canvas *)canvas {
    CGFloat oldAspectRatio = _subcanvas ? _subcanvas.bounds.size.width / _subcanvas.bounds.size.height : 1;
    [_subcanvas removeFromSuperview];
    _subcanvas = canvas;
    [canvas resizeBoundsToFitContent];
    CGFloat newAspectRatio = canvas ? canvas.bounds.size.width / canvas.bounds.size.height : 1;
    [self addSubview:_subcanvas];
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        self.bounds = CGRectMake(0, 0, 200, 200);
    }
    [self adjustAspectRatioWithOld:oldAspectRatio new:newAspectRatio];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // subcanvas.bounds is set by -[Canvas resizeBoundsToFitContent] inside -setSubcanvas:
    self.subcanvas.transform = CGAffineTransformMakeScale(self.bounds.size.width / self.subcanvas.bounds.size.width, self.bounds.size.height / self.subcanvas.bounds.size.height);
    self.subcanvas.layer.anchorPoint = CGPointMake(0, 0);
    self.subcanvas.center = CGPointMake(0, 0);
}

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

- (NSInteger)mapSliderToTileCount:(CGFloat)slider {
    return 1 + round(pow(slider * 5, 2)); // max 26
}

- (CGFloat)mapTileCountToSlider:(NSInteger)count {
    return sqrt((count - 1) / 5);
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

@end
