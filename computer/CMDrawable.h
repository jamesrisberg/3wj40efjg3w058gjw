//
//  CMDrawable.h
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

@import UIKit;
#import "Keyframe.h"
#import "EVInterpolation.h"
@class CMDrawableKeyframe;
@class OptionsViewCellModel;
@class StaticAnimation;
#import "CanvasEditor.h"
#import "QuickCollectionModal.h"
#import "PropertyModel.h"
#import "CMRenderContext.h"
#import "CMLayoutBase.h"
@class EditorViewController;

extern NSString * const CMDrawableArrayPasteboardType;

@interface CMDrawableView : UIView

- (CGRect)unrotatedBoundingBox;
@property (nonatomic,weak) CMDrawableView *wrapsView;

@end

typedef CMDrawableView* (^CMDrawableWrapperFunction)(CMDrawableView *toWrap, CMDrawableView *oldResult);

@interface CMDrawable : NSObject <NSCoding, NSCopying>

- (instancetype)init;
- (NSArray<NSString*>*)keysForCoding;
@property (nonatomic) CGFloat boundsDiagonal;
@property (nonatomic,readonly) KeyframeStore *keyframeStore;
- (Class)keyframeClass;
@property (nonatomic,readonly) NSString *key;

- (__kindof CMDrawableView *)renderToView:(__kindof CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx;

- (__kindof CMDrawableView *)renderFullyWrappedWithView:(__kindof CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx;

- (FrameTime *)maxTime;

- (CGFloat)aspectRatio;

- (NSArray<PropertyGroupModel*>*)propertyGroupsWithEditor:(CanvasEditor *)editor;
- (NSArray<PropertyModel*>*)animatablePropertiesWithEditor:(CanvasEditor *)editor;
- (NSArray<PropertyModel*>*)uniqueObjectPropertiesWithEditor:(CanvasEditor *)editor;
- (NSString *)drawableTypeDisplayName;
- (NSString *)displayName;

- (NSArray<CMDrawableWrapperFunction>*)wrappers;

// repeating:
@property (nonatomic) NSInteger xRepeat;
@property (nonatomic) CGFloat xRepeatGap;
@property (nonatomic) NSInteger yRepeat;
@property (nonatomic) CGFloat yRepeatGap;

- (CGRect)boundingBoxForAllTime;

- (NSDictionary<NSString*,CMLayoutBase*>*)layoutBasesForViewsWithKeysInRenderContext:(CMRenderContext *)cx;

- (BOOL)performDefaultEditActionWithEditor:(EditorViewController *)editor;

@end


@interface CMDrawableKeyframe : NSObject <NSCoding, EVInterpolation, NSCopying>

@property (nonatomic) FrameTime *frameTime;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGFloat scale, rotation, alpha;
@property (nonatomic) StaticAnimation *staticAnimation;
- (NSArray<NSString*>*)keys;
- (CGRect)outerBoundingBoxWithBounds:(CGSize)bounds;

@end
