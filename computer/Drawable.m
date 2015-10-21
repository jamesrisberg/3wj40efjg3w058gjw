//
//  Drawable.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"
#import "QuickCollectionModal.h"
#import "Canvas.h"
#import "computer-Swift.h"
#import "OptionsView.h"

@interface Drawable ()

@property (nonatomic) KeyframeStore *keyframeStore;

@end



@implementation Drawable

- (instancetype)init {
    self = [super init];
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
    self.transform = CGAffineTransformRotate(CGAffineTransformMakeScale(_scale, _scale), _rotation);
    self.alpha = _itemOpacity * (_dimmed ? 0.4 : 1);
}

#pragma mark Util

- (UIViewController *)vcForPresentingModals {
    return [NPSoftModalPresentationController getViewControllerForPresentationInWindow:self.window];
}

- (Canvas *)canvas {
    return (Canvas *)self.superview;
}

#pragma mark Options

- (NSArray <__kindof QuickCollectionItem*> *)optionsItems {
    __weak Drawable *weakSelf = self;
    QuickCollectionItem *delete = [QuickCollectionItem new];
    delete.label = NSLocalizedString(@"Delete", @"");
    delete.action = ^{
        [weakSelf delete:nil];
    };
    QuickCollectionItem *duplicate = [QuickCollectionItem new];
    duplicate.label = NSLocalizedString(@"Duplicate", @"");
    duplicate.action = ^{
        [weakSelf duplicate:nil];
    };
    QuickCollectionItem *options = [QuickCollectionItem new];
    options.label = NSLocalizedString(@"Options…", @"");
    options.action = ^{
        [weakSelf showOptions];
    };
    return @[delete, duplicate, options];
}

#pragma mark Actions
- (void)delete:(id)sender {
    if (self.canvas.selection == self) self.canvas.selection = nil;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.scale /= 100;
        self.alpha = 0;
    } completion:^(BOOL finished) {
        if (self.canvas.selection == self) self.canvas.selection = nil;
        [self removeFromSuperview];
    }];
}

- (void)duplicate:(id)sender {
    Drawable *dupe = [self copy];
    [self.canvas insertSubview:dupe aboveSubview:self];
    dupe.center = CGPointMake(dupe.center.x + 20, dupe.center.y + 20);
}

- (void)showOptions {
    OptionsView *v = [OptionsView new];
    [self.canvas.delegate canvas:self.canvas shouldShowEditingPanel:v];
}

#pragma mark Resize

- (void)setInternalSize:(CGSize)size {
    self.bounds = CGRectMake(0, 0, size.width, size.height);
}

#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    // deliberately DON'T call super
    [aCoder encodeObject:[self currentKeyframeProperties] forKey:@"currentKeyframeProperties"];
    [aCoder encodeObject:self.keyframeStore forKey:@"keyframeStore"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init]; // deliberately DON'T call super
    [self setCurrentKeyframeProperties:[aDecoder decodeObjectForKey:@"currentKeyframeProperties"]];
    self.keyframeStore = [aDecoder decodeObjectForKey:@"keyframeStore"];
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
             @"itemOpacity": @(self.itemOpacity)
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
}

- (void)keyframePropertiesChangedAtTime:(FrameTime *)time {
    Keyframe *keyframe = [Keyframe new];
    keyframe.frameTime = time;
    [keyframe.properties addEntriesFromDictionary:[self currentKeyframeProperties]];
    [self.keyframeStore storeKeyframe:keyframe];
}

- (void)updatedKeyframeProperties {
    if (self.onKeyframePropertiesUpdated) self.onKeyframePropertiesUpdated();
}

- (void)setDimmed:(BOOL)dimmed {
    _dimmed = dimmed;
    [self updateAppearance];
}

@end
