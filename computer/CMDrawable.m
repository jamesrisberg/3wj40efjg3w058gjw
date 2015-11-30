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

@interface CMDrawable ()

@property (nonatomic) KeyframeStore *keyframeStore;
@property (nonatomic) NSString *key;

@end

@implementation CMDrawable

- (instancetype)init {
    self = [super init];
    self.keyframeStore = [KeyframeStore new];
    self.keyframeStore.keyframeClass = [self keyframeClass];
    self.boundsDiagonal = 100;
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

- (CMDrawableView *)renderToView:(CMDrawableView *)existingOrNil atTime:(FrameTime *)time {
    CMDrawableView *v = [existingOrNil isKindOfClass:[CMDrawableView class]] ? existingOrNil : [CMDrawableView new];
    CMDrawableKeyframe *keyframe = [self.keyframeStore interpolatedKeyframeAtTime:time];
    v.center = keyframe.center;
    v.bounds = CGRectMake(0, 0, self.boundsDiagonal / sqrt(2), self.boundsDiagonal / sqrt(2)); // TODO: is math
    v.alpha = keyframe.alpha;
    v.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(keyframe.rotation), keyframe.scale, keyframe.scale);
    return v;
}

- (FrameTime *)maxTime {
    return self.keyframeStore.maxTime;
}

#pragma mark Options UI


- (NSArray <__kindof QuickCollectionItem*> *)optionsItemsWithEditor:(CanvasEditor *)editor {
    NSMutableArray *items = [NSMutableArray new];
    __weak CMDrawable *weakSelf = self;
    __weak CanvasEditor *weakEditor = editor;
    QuickCollectionItem *delete = [QuickCollectionItem new];
    delete.label = NSLocalizedString(@"Delete", @"");
    delete.action = ^{
        [weakEditor deleteDrawable:weakSelf];
    };
    [items addObject:delete];
    QuickCollectionItem *duplicate = [QuickCollectionItem new];
    duplicate.label = NSLocalizedString(@"Duplicate", @"");
    duplicate.action = ^{
        [weakEditor duplicateDrawable:weakSelf];
    };
    [items addObject:duplicate];
    QuickCollectionItem *animations = [QuickCollectionItem new];
    animations.label = NSLocalizedString(@"Animations…", @"");
    animations.action = ^{
        // [weakSelf showStaticAnimationPicker];
    };
    [items addObject:animations];
    
    BOOL isAtZeroTime = editor.time.time == 0;
    BOOL hasOtherKeyframes = self.keyframeStore.maxTime.time > 0;
    BOOL hasKeyframeAtCurrentTime = !![self.keyframeStore keyframeAtTime:editor.time];
    if (hasKeyframeAtCurrentTime && (!isAtZeroTime || hasOtherKeyframes)) {
        QuickCollectionItem *removeKeyframe = [QuickCollectionItem new];
        removeKeyframe.label = NSLocalizedString(@"Delete keyframe", @"");
        removeKeyframe.action = ^{
            [weakEditor deleteCurrentKeyframeForDrawable:weakSelf];
        };
        [items addObject:removeKeyframe];
    }
    return items;
}

- (QuickCollectionItem *)mainActionWithEditor:(CanvasEditor *)editor {
    return nil;
}

- (UIView *)propertiesModalTopActionViewWithEditor:(CanvasEditor *)editor {
    return nil;
}

- (UIViewController *)createInlineViewControllerForEditingWithEditor:(CanvasEditor *)editor {
    return nil;
}

- (NSArray<__kindof OptionsViewCellModel*>*)optionsViewCellModelsWithEditor:(CanvasEditor *)editor {
    OptionsViewCellModel *alpha = [self sliderForKeyOnKeyframeObject:@"alpha" title:NSLocalizedString(@"Opacity", @"") editor:editor];
    return @[alpha];
}

- (OptionsViewCellModel *)sliderForKeyOnKeyframeObject:(NSString *)key title:(NSString *)title editor:(CanvasEditor *)editor {
    __weak CMDrawable *weakSelf = self;
    FrameTime *time = editor.time;
    __weak CanvasEditor *weakEditor = editor;
    
    __block CMTransaction *transaction = nil;
    OptionsViewCellModel *model = [OptionsViewCellModel new];
    model.title = title;
    model.cellClass = [SliderOptionsCell class];
    model.onCreate = ^(OptionsCell *cell){
        SliderOptionsCell *sliderCell = (SliderOptionsCell *)cell;
        sliderCell.value = [[[weakSelf.keyframeStore interpolatedKeyframeAtTime:time] valueForKey:key] floatValue];
        __weak SliderOptionsCell *weakSliderCell = sliderCell;
        sliderCell.onValueChange = ^(CGFloat val) {
            if (!transaction) {
                CMDrawableKeyframe *oldKeyframe = [[weakSelf.keyframeStore keyframeAtTime:time] copy];
                transaction = [[CMTransaction alloc] initNonFinalizedWithTarget:editor action:^(id target) {
                    [[weakSelf.keyframeStore createKeyframeAtTimeIfNeeded:time] setValue:@(val) forKey:key];
                    weakSliderCell.value = val;
                } undo:^(id target) {
                    [weakSelf.keyframeStore removeKeyframeAtTime:time];
                    if (oldKeyframe) {
                        [weakSelf.keyframeStore storeKeyframe:oldKeyframe];
                    }
                    weakSliderCell.value = val;
                }];
                [[weakEditor transactionStack] doTransaction:transaction];
            } else {
                // update the transaction:
                transaction.action = ^(id target) {
                    [[weakSelf.keyframeStore createKeyframeAtTimeIfNeeded:time] setValue:@(val) forKey:key];
                    weakSliderCell.value = val;
                };
            }
        };
        sliderCell.onTouchUp = ^{
            transaction.finalized = YES;
            transaction = nil;
        };
    };
    return model;
}


- (id)copy {
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

@end

@implementation CMDrawableKeyframe

- (instancetype)init {
    self = [super init];
    self.center = CGPointMake(100, 100);
    self.alpha = 1;
    self.scale = 1;
    self.rotation = 0;
    return self;
}

- (NSArray<NSString*>*)keys {
    return @[@"center", @"scale", @"rotation", @"alpha", @"frameTime"];
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
    CMDrawableKeyframe *i = [CMDrawableKeyframe new];
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
