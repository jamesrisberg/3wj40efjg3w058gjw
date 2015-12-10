//
//  CMDrawable.m
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDrawable.h"
#import "computer-Swift.h"
#import "SliderOptionsCell.h"
#import "PropertyViewTableCell.h"
#import "StaticAnimation.h"
#import "CGPointExtras.h"
#import "NSMutableArray+Utility.h"
#import "CMRepeatingWrapper.h"

@implementation CMRenderContext

@end



@interface CMDrawable ()

@property (nonatomic) KeyframeStore *keyframeStore;
@property (nonatomic) NSString *key;

@end

@implementation CMDrawable

- (instancetype)init {
    self = [super init];
    self.keyframeStore = [KeyframeStore new];
    self.keyframeStore.keyframeClass = [self keyframeClass];
    self.boundsDiagonal = 200;
    self.xRepeat = 1;
    self.xRepeatGap = 1;
    self.yRepeat = 1;
    self.yRepeatGap = 1;
    self.key = [NSUUID UUID].UUIDString;
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    for (NSString *key in [self keysForCoding]) {
        [self setValue:[aDecoder decodeObjectForKey:key] forKey:key];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    for (NSString *key in [self keysForCoding]) {
        [aCoder encodeObject:[self valueForKey:key] forKey:key];
    }
}

- (NSArray<NSString*>*)keysForCoding {
    return @[@"boundsDiagonal", @"keyframeStore", @"key", @"xRepeat", @"xRepeatGap", @"yRepeat", @"yRepeatGap"];
}

- (Class)keyframeClass {
    return [CMDrawableKeyframe class];
}

- (__kindof CMDrawableView *)renderToView:(CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx {
    CMDrawableView *v = [existingOrNil isKindOfClass:[CMDrawableView class]] ? existingOrNil : [CMDrawableView new];
    
    CGSize size = CMSizeWithDiagonalAndAspectRatio(self.boundsDiagonal, self.aspectRatio);
    v.bounds = CGRectMake(0, 0, size.width, size.height); // TODO: is math
    
    return v;
}

- (FrameTime *)maxTime {
    return self.keyframeStore.maxTime;
}

- (CGFloat)aspectRatio {
    return 1;
}

#pragma mark New Options UI

- (NSArray<PropertyGroupModel*>*)propertyGroupsWithEditor:(CanvasEditor *)editor {
    PropertyGroupModel *animatable = [PropertyGroupModel new];
    animatable.title = NSLocalizedString(@"Properties", @"");
    animatable.properties = [self animatablePropertiesWithEditor:editor];
    
    PropertyGroupModel *unique = [PropertyGroupModel new];
    unique.title = [self drawableTypeDisplayName];
    unique.properties = [self uniqueObjectPropertiesWithEditor:editor];
    
    PropertyGroupModel *staticAnimation = [PropertyGroupModel new];
    staticAnimation.title = NSLocalizedString(@"Animation", @"");
    staticAnimation.singleView = YES;
    PropertyModel *staticAnimationProp = [PropertyModel new];
    staticAnimationProp.isKeyframeProperty = YES;
    staticAnimationProp.type = PropertyModelTypeStaticAnimation;
    staticAnimationProp.key = @"staticAnimation";
    staticAnimation.properties = @[staticAnimationProp];
    
    PropertyGroupModel *repeating = [self repeatingPropertiesGroupModel];
    
    return @[unique, animatable, staticAnimation, repeating];
}

- (NSString *)drawableTypeDisplayName {
    return NSLocalizedString(@"Object", @"");
}

- (NSArray<PropertyModel*>*)animatablePropertiesWithEditor:(CanvasEditor *)editor {
    PropertyModel *opacity = [PropertyModel new];
    opacity.title = NSLocalizedString(@"Opacity", @"");
    opacity.type = PropertyModelTypeSlider;
    opacity.valueMin = 0;
    opacity.valueMax = 1;
    opacity.isKeyframeProperty = YES;
    opacity.key = @"alpha";
    
    PropertyModel *keyframeActions = [PropertyModel new];
    keyframeActions.title = NSLocalizedString(@"Current keyframe actions", @"");
    keyframeActions.type = PropertyModelTypeButtons;
    keyframeActions.buttonTitles = @[NSLocalizedString(@"Delete", @"")];
    keyframeActions.buttonSelectorNames = @[@"deleteCurrentKeyframe:"];
    keyframeActions.availabilitySelectors = @[@"canDeleteCurrentKeyframe:"];
    
    return @[opacity, keyframeActions];
}

- (NSArray<PropertyModel*>*)uniqueObjectPropertiesWithEditor:(CanvasEditor *)editor {
    return @[];
}

- (PropertyGroupModel *)repeatingPropertiesGroupModel {
    PropertyModel *xRepeat = [PropertyModel new];
    xRepeat.title = NSLocalizedString(@"Horizontal repeat", @"");
    xRepeat.type = PropertyModelTypeSlider;
    xRepeat.valueMin = 1;
    xRepeat.valueMax = 7;
    xRepeat.key = @"xRepeat";
    
    PropertyModel *xGap = [PropertyModel new];
    xGap.title = NSLocalizedString(@"Horizontal spacing", @"");
    xGap.type = PropertyModelTypeSlider;
    xGap.valueMax = 3;
    xGap.key = @"xRepeatGap";
    
    PropertyModel *yRepeat = [PropertyModel new];
    yRepeat.title = NSLocalizedString(@"Vertical repeat", @"");
    yRepeat.type = PropertyModelTypeSlider;
    yRepeat.valueMin = 1;
    yRepeat.valueMax = 7;
    yRepeat.key = @"yRepeat";
    
    PropertyModel *yGap = [PropertyModel new];
    yGap.title = NSLocalizedString(@"Vertical spacing", @"");
    yGap.type = PropertyModelTypeSlider;
    yGap.valueMax = 3;
    yGap.key = @"yRepeatGap";
    
    PropertyGroupModel *group = [PropertyGroupModel new];
    group.title = NSLocalizedString(@"Repeat", @"");
    group.properties = @[xRepeat, xGap, yRepeat, yGap];
    
    return group;
}

- (id)copy {
    CMDrawable *d = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
    d.key = [NSUUID UUID].UUIDString;
    return d;
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

#pragma mark Wrappers

- (__kindof CMDrawableView *)renderFullyWrappedWithView:(__kindof CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx {
    NSMutableArray *stackOfOldViews = [NSMutableArray new];
    CMDrawableView *v = existingOrNil;
    while (v) {
        [stackOfOldViews addObject:v];
        v = v.wrapsView;
    }
    
    CMDrawableView *result = [self renderToView:stackOfOldViews.pop context:ctx];
    for (CMDrawableWrapperFunction fn in [self wrappers]) {
        result = fn(result, stackOfOldViews.pop);
    }
    
    CMDrawableKeyframe *keyframe = [self.keyframeStore interpolatedKeyframeAtTime:ctx.time];
    CGPoint center = keyframe.center;
    
    CGFloat canvasScale = 1;
    if (ctx.coordinateSpace) canvasScale = [ctx.coordinateSpace convertRect:CGRectMake(center.x, center.y, canvasScale, canvasScale) toCoordinateSpace:ctx.canvasView].size.width;
    
    CGFloat alpha = keyframe.alpha;
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformMakeRotation(keyframe.rotation), keyframe.scale * canvasScale, keyframe.scale * canvasScale);
    
    NSTimeInterval staticAnimationTime = ctx.useFrameTimeForStaticAnimations ? ctx.time.time : (NSTimeInterval)CFAbsoluteTimeGetCurrent();
    alpha = [keyframe.staticAnimation adjustAlpha:alpha time:staticAnimationTime];
    transform = [keyframe.staticAnimation adjustTransform:transform time:staticAnimationTime];
    
    result.alpha = alpha;
    result.transform = transform;
    
    if (ctx.coordinateSpace) {
        result.center = [ctx.coordinateSpace convertPoint:center toCoordinateSpace:ctx.canvasView];
    } else {
        // CanvasViewerLite doesn't have a coordinate space...
        result.center = center;
    }
    
    return result;
}

- (NSArray<CMDrawableWrapperFunction>*)wrappers {
    NSMutableArray *wrappers = [NSMutableArray new];
    
    if (self.xRepeat > 1) {
        NSInteger repeat = self.xRepeat;
        CGFloat gap = self.xRepeatGap;
        CMDrawableWrapperFunction fn = ^CMDrawableView*(CMDrawableView *child, CMDrawableView *old) {
            CMRepeatingWrapper *v = [old isKindOfClass:[CMRepeatingWrapper class]] ? (id)old : [CMRepeatingWrapper new];
            v.count = repeat;
            v.gap = gap;
            v.vertical = NO;
            v.child = child;
            return v;
        };
        [wrappers addObject:fn];
    }
    
    if (self.yRepeat > 1) {
        NSInteger repeat = self.yRepeat;
        CGFloat gap = self.yRepeatGap;
        CMDrawableWrapperFunction fn = ^CMDrawableView*(CMDrawableView *child, CMDrawableView *old) {
            CMRepeatingWrapper *v = [old isKindOfClass:[CMRepeatingWrapper class]] ? (id)old : [CMRepeatingWrapper new];
            v.count = repeat;
            v.gap = gap;
            v.vertical = YES;
            v.child = child;
            return v;
        };
        [wrappers addObject:fn];
    }
    
    return wrappers;
}

#pragma mark Keyframe actions

- (NSNumber *)canDeleteCurrentKeyframe:(PropertyViewTableCell *)cell {
    return @(self.keyframeStore.allKeyframes.count > 1 && [self.keyframeStore keyframeAtTime:cell.time] != nil);
}

- (void)deleteCurrentKeyframe:(PropertyViewTableCell *)cell {
    if ([self canDeleteCurrentKeyframe:cell].boolValue) {
        CMDrawableKeyframe *oldKeyframe = [self.keyframeStore keyframeAtTime:cell.time];
        FrameTime *time = cell.time;
        [cell.transactionStack doTransaction:[[CMTransaction alloc] initWithTarget:self action:^(id target) {
            [self.keyframeStore removeKeyframeAtTime:time];
        } undo:^(id target) {
            [self.keyframeStore storeKeyframe:oldKeyframe];
        }]];
    }
}

@end

@implementation CMDrawableKeyframe

- (instancetype)init {
    self = [super init];
    self.center = CGPointMake(100, 100);
    self.alpha = 1;
    self.scale = 1;
    self.rotation = 0;
    self.staticAnimation = [StaticAnimation new];
    return self;
}

- (NSArray<NSString*>*)keys {
    return @[@"center", @"scale", @"rotation", @"alpha", @"frameTime", @"staticAnimation"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    for (NSString *key in [self keys]) {
        [self setValue:[aDecoder decodeObjectForKey:key] forKey:key];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    for (NSString *key in [self keys]) {
        [aCoder encodeObject:[self valueForKey:key] forKey:key];
    }
}

- (NSComparisonResult)compare:(id)other {
    return [self.frameTime compare:[other frameTime]];
}

- (instancetype)interpolatedWith:(id)other progress:(CGFloat)progress {
    CMDrawableKeyframe *i = [[self class] new];
    for (NSString *key in [self keys]) {
        [i setValue:[[self valueForKey:key] interpolatedWith:[other valueForKey:key] progress:progress] forKey:key];
    }
    return i;
}

- (id)copy {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

@end

@implementation CMDrawableView

- (CGRect)unrotatedBoundingBox {
    return self.frame; // TODO: math
}

@end
