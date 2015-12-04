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
    return @[@"boundsDiagonal", @"keyframeStore", @"key"];
}

- (Class)keyframeClass {
    return [CMDrawableKeyframe class];
}

- (CMDrawableView *)renderToView:(CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx {
    FrameTime *time = ctx.time;
    
    CMDrawableView *v = [existingOrNil isKindOfClass:[CMDrawableView class]] ? existingOrNil : [CMDrawableView new];
    CMDrawableKeyframe *keyframe = [self.keyframeStore interpolatedKeyframeAtTime:time];
    v.center = keyframe.center;
    CGSize size = CMSizeWithDiagonalAndAspectRatio(self.boundsDiagonal, self.aspectRatio);
    v.bounds = CGRectMake(0, 0, size.width, size.height); // TODO: is math
    v.alpha = keyframe.alpha;
    v.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(keyframe.rotation), keyframe.scale, keyframe.scale);
    
    NSTimeInterval staticAnimationTime = ctx.useFrameTimeForStaticAnimations ? ctx.time.time : (NSTimeInterval)CFAbsoluteTimeGetCurrent();
    v.alpha = [keyframe.staticAnimation adjustAlpha:v.alpha time:staticAnimationTime];
    v.transform = [keyframe.staticAnimation adjustTransform:v.transform time:staticAnimationTime];
    
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
    
    return @[unique, animatable, staticAnimation];
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

- (id)copy {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
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

@end
