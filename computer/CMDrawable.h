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

@interface CMDrawableView : UIView

- (CGRect)unrotatedBoundingBox;
@property (nonatomic,weak) CMDrawableView *wrapsView;

@end

@interface CMRenderContext : NSObject <NSCopying>

@property (nonatomic) FrameTime *time;
@property (nonatomic) BOOL useFrameTimeForStaticAnimations;
@property (nonatomic) BOOL renderMetaInfo;
@property (nonatomic) BOOL forStaticScreenshot;
@property (nonatomic) id<UICoordinateSpace> coordinateSpace;
@property (nonatomic) CGPoint scale;
@property (nonatomic) _CMCanvasView *canvasView;
@property (nonatomic) CGSize canvasSize;
@property (nonatomic) BOOL atRoot; // the view that's been passed this context is the root

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

- (NSArray<CMDrawableWrapperFunction>*)wrappers;

// repeating:
@property (nonatomic) NSInteger xRepeat;
@property (nonatomic) CGFloat xRepeatGap;
@property (nonatomic) NSInteger yRepeat;
@property (nonatomic) CGFloat yRepeatGap;

- (CGRect)boundingBoxForAllTime;

@end


@interface CMDrawableKeyframe : NSObject <NSCoding, EVInterpolation, NSCopying>

@property (nonatomic) FrameTime *frameTime;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGFloat scale, rotation, alpha;
@property (nonatomic) StaticAnimation *staticAnimation;
- (NSArray<NSString*>*)keys;
- (CGRect)outerBoundingBoxWithBounds:(CGSize)bounds;

@end
