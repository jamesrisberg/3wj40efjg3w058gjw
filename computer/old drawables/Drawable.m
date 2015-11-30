//
//  Drawable.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"
#import "QuickCollectionModal.h"
#import "CanvasEditor.h"
#import "computer-Swift.h"
#import "OptionsView.h"
#import "SliderOptionsCell.h"
#import "StaticAnimationPicker.h"

NSString * const DrawableArrayPasteboardType = @"com.nateparrott.computer.DrawableArrayPasteboardType";

@interface Drawable ()

@property (nonatomic) KeyframeStore *keyframeStore;
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) CGFloat alphaSettingKeyframes;

@end



@implementation Drawable

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self setup];
    return self;
}

- (void)primaryEditAction {
    
}

- (void)setup {
    _rotation = 0;
    _scale = 1;
    _itemOpacity = 1;
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    BOOL shouldHaveDisplayLink = !!newWindow;
    BOOL hasDisplayLink = !!self.displayLink;
    if (hasDisplayLink != shouldHaveDisplayLink) {
        if (shouldHaveDisplayLink) {
            self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateAppearance)];
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        } else {
            [self.displayLink invalidate];
            self.displayLink = nil;
        }
    }
}

- (void)dealloc {
    if (self.displayLink) [self.displayLink invalidate];
}

#pragma mark Appearances

- (void)setRotation:(CGFloat)rotation {
    _rotation = rotation;
    [self updateAppearance];
}

- (void)setScale:(CGFloat)scale {
    _scale = scale;
    [self updateAppearance];
}

- (void)setItemOpacity:(CGFloat)itemOpacity {
    _itemOpacity = itemOpacity;
    [self updateAppearance];
}

- (void)updateAppearance {
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformMakeScale(_scale, _scale), _rotation);
    NSTimeInterval time = self.useTimeForStaticAnimations ? self.time.time : [NSDate timeIntervalSinceReferenceDate]; // TODO: don't use the real date
    transform = [self.staticAnimation adjustTransform:transform time:time];
    CGFloat alpha = _itemOpacity;
    alpha = [self.staticAnimation adjustAlpha:alpha time:time];
    if (_dimmed) alpha *= 0.4;
    
    self.alpha = alpha;
    self.transform = transform;
}

#pragma mark Util

- (UIViewController *)vcForPresentingModals {
    return [NPSoftModalPresentationController getViewControllerForPresentationInWindow:self.window];
}

- (CanvasEditor *)canvas {
    return nil;
}

#pragma mark Options

- (NSArray <__kindof QuickCollectionItem*> *)optionsItems {
    NSMutableArray *items = [NSMutableArray new];
    __weak Drawable *weakSelf = self;
    QuickCollectionItem *delete = [QuickCollectionItem new];
    delete.label = NSLocalizedString(@"Delete", @"");
    delete.action = ^{
        [weakSelf delete:nil];
    };
    [items addObject:delete];
    QuickCollectionItem *duplicate = [QuickCollectionItem new];
    duplicate.label = NSLocalizedString(@"Duplicate", @"");
    duplicate.action = ^{
        [weakSelf duplicate:nil];
    };
    [items addObject:duplicate];
    QuickCollectionItem *animations = [QuickCollectionItem new];
    animations.label = NSLocalizedString(@"Animations…", @"");
    animations.action = ^{
        [weakSelf showStaticAnimationPicker];
    };
    [items addObject:animations];
    
    BOOL isAtZeroTime = self.canvas.time.time == 0;
    BOOL hasOtherKeyframes = self.keyframeStore.maxTime.time > 0;
    if ([self hasKeyframeAtCurrentTime] && (!isAtZeroTime || hasOtherKeyframes)) {
        QuickCollectionItem *removeKeyframe = [QuickCollectionItem new];
        removeKeyframe.label = NSLocalizedString(@"Delete keyframe", @"");
        removeKeyframe.action = ^{
            [weakSelf resetKeyframe];
        };
        [items addObject:removeKeyframe];
    }
    return items;
}

- (QuickCollectionItem *)mainAction {
    return nil;
}

- (UIView *)propertiesModalTopActionView {
    return nil;
}

#pragma mark Actions
- (void)delete:(id)sender {
    NSMutableSet *selection = self.canvas.selectedItems.mutableCopy;
    if ([selection containsObject:self]) {
        [selection removeObject:self];
        self.canvas.selectedItems = selection;
    }
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.scale /= 100;
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)duplicate:(id)sender {
    Drawable *dupe = [self copy];
    [self.canvas _addDrawableToCanvas:dupe aboveDrawable:self];
    dupe.center = CGPointMake(dupe.center.x + 20, dupe.center.y + 20);
    [dupe updatedKeyframeProperties];
}

- (void)showOptions {
    OptionsView *v = [OptionsView new];
    v.models = [self optionsViewCellModels];
    [self.canvas.delegate canvas:self.canvas shouldShowEditingPanel:v];
}

- (NSArray<__kindof OptionsViewCellModel*>*)optionsViewCellModels {
    OptionsViewCellModel *alpha = [self sliderForKey:@"itemOpacity" title:NSLocalizedString(@"Opacity", @"")];
    return @[alpha];
}

- (OptionsViewCellModel *)sliderForKey:(NSString *)key title:(NSString *)title {
    __weak Drawable *weakSelf = self;
    
    OptionsViewCellModel *model = [OptionsViewCellModel new];
    model.title = title;
    model.cellClass = [SliderOptionsCell class];
    model.onCreate = ^(OptionsCell *cell){
        SliderOptionsCell *sliderCell = (SliderOptionsCell *)cell;
        sliderCell.value = [[weakSelf valueForKey:key] floatValue];
        sliderCell.onValueChange = ^(CGFloat val) {
            [weakSelf setValue:@(val) forKey:key];
            [weakSelf updatedKeyframeProperties];
        };
    };
    return model;
}

- (void)showStaticAnimationPicker {
    StaticAnimationPicker *picker = [StaticAnimationPicker new];
    picker.drawable = self;
    [self.canvas.delegate canvas:self.canvas shouldShowEditingPanel:picker];
}

#pragma mark Resize

- (void)setInternalSize:(CGSize)size {
    self.bounds = CGRectMake(0, 0, size.width, size.height);
    [self updatedKeyframeProperties];
}

- (void)updateAspectRatio:(CGFloat)aspect {
    if (self.bounds.size.height > 0 && aspect == self.bounds.size.width / self.bounds.size.height) {
        return;
    }
    CGFloat diag = sqrt(pow(self.bounds.size.width, 2) + pow(self.bounds.size.height, 2)) ? : 200;
    CGFloat width = diag/sqrt(pow(aspect, -2) + 1);
    [self setInternalSize:CGSizeMake(width, width / aspect)];
}

- (CGRect)unrotatedBoundingBox {
    CGFloat w = (self.bounds.size.width * cos(self.rotation) + self.bounds.size.height * sin(self.rotation)) * self.scale;
    CGFloat h = (self.bounds.size.height * cos(self.rotation) + self.bounds.size.width * sin(self.rotation)) * self.scale;
    return CGRectMake(self.center.x - w/2, self.center.y - h/2, w, h);
}

#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    // deliberately DON'T call super
    [aCoder encodeObject:[self currentKeyframeProperties] forKey:@"currentKeyframeProperties"];
    [aCoder encodeObject:self.keyframeStore forKey:@"keyframeStore"];
    [aCoder encodeBool:self.transientEDUView forKey:@"transientEDUView"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init]; // deliberately DON'T call super
    [self setCurrentKeyframeProperties:[aDecoder decodeObjectForKey:@"currentKeyframeProperties"]];
    self.keyframeStore = [aDecoder decodeObjectForKey:@"keyframeStore"];
    self.transientEDUView = [aDecoder decodeBoolForKey:@"transientEDUView"];
    return self;
}

#pragma mark Copying

- (id)copy {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

#pragma mark Keyframes

- (KeyframeStore *)keyframeStore {
    if (!_keyframeStore) {
        _keyframeStore = [KeyframeStore new];
    }
    return _keyframeStore;
}

- (NSDictionary<__kindof NSString*, id>*)currentKeyframeProperties {
    return @{
             @"bounds": [NSValue valueWithCGRect:self.bounds],
             @"center": [NSValue valueWithCGPoint:self.center],
             @"scale": @(self.scale),
             @"rotation": @(self.rotation),
             @"itemOpacity": @(self.itemOpacity),
             @"staticAnimation": self.staticAnimation
             };
}

- (void)setCurrentKeyframeProperties:(NSDictionary<__kindof NSString *, id>*)props {
    if (props[@"bounds"]) {
        self.bounds = [props[@"bounds"] CGRectValue];
    }
    if (props[@"center"]) {
        self.center = [props[@"center"] CGPointValue];
    }
    if (props[@"scale"]) {
        self.scale = [props[@"scale"] doubleValue];
    }
    if (props[@"rotation"]) {
        self.rotation = [props[@"rotation"] doubleValue];
    }
    if (props[@"itemOpacity"]) {
        self.itemOpacity = [props[@"itemOpacity"] doubleValue];
    }
    if (props[@"staticAnimation"]) {
        self.staticAnimation = props[@"staticAnimation"];
    }
}

- (void)keyframePropertiesChangedAtTime:(FrameTime *)time {
    /*Keyframe *keyframe = [Keyframe new];
    keyframe.frameTime = time;
    [keyframe.properties addEntriesFromDictionary:[self currentKeyframeProperties]];
    [self.keyframeStore storeKeyframe:keyframe];*/
}

- (void)updatedKeyframeProperties {
    if (self.time) {
        [self keyframePropertiesChangedAtTime:self.time];
    }
    if (self.onKeyframePropertiesUpdated) self.onKeyframePropertiesUpdated();
    if (self.onShapeUpdate) self.onShapeUpdate();
}

- (BOOL)hasKeyframeAtCurrentTime {
    return !![self.keyframeStore keyframeAtTime:self.canvas.time];
}

- (void)resetKeyframe {
    [self.keyframeStore removeKeyframeAtTime:self.canvas.time];
    if (self.onKeyframePropertiesUpdated) self.onKeyframePropertiesUpdated();
    if (self.onShapeUpdate) self.onShapeUpdate();
}

- (void)setDimmed:(BOOL)dimmed {
    _dimmed = dimmed;
    [self updateAppearance];
}

#pragma mark Static Animations
- (StaticAnimation *)staticAnimation {
    if (!_staticAnimation) {
        _staticAnimation = [StaticAnimation new];
    }
    return _staticAnimation;
}

#pragma mark Inline Editing VC
- (UIViewController *)createInlineViewControllerForEditing {
    return nil;
}

#pragma mark Time
- (void)setTime:(FrameTime *)time {
    _time = time;
    
    BOOL hasExactKeyframe = !![self.keyframeStore keyframeAtTime:time];
    if (self.keyframeStore.allKeyframes.count > 0) {
        // [self setCurrentKeyframeProperties:[self.keyframeStore interpolatedPropertiesAtTime:time]];
    }
    self.dimmed = !hasExactKeyframe && !self.suppressTimingVisualizations;;
}

- (void)setSuppressTimingVisualizations:(BOOL)suppressTimingVisualizations {
    _suppressTimingVisualizations = suppressTimingVisualizations;
    self.time = self.time;
}

- (void)setUseTimeForStaticAnimations:(BOOL)useTimeForStaticAnimations {
    _useTimeForStaticAnimations = useTimeForStaticAnimations;
    
}

#pragma mark Special

- (void)setTransientEDUView:(BOOL)transientEDUView {
    _transientEDUView = transientEDUView;
    if (transientEDUView) {
        self.userInteractionEnabled = NO;
        self.itemOpacity = 0.5;
    }
}


@end
