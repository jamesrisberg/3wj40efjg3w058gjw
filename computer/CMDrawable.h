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
#import "OptionsView.h"
#import "PropertyModel.h"

@interface CMDrawableView : UIView

- (CGRect)unrotatedBoundingBox;

@end

@interface CMRenderContext : NSObject

@property (nonatomic) FrameTime *time;
@property (nonatomic) BOOL useFrameTimeForStaticAnimations;
@property (nonatomic) BOOL renderMetaInfo;
@property (nonatomic) BOOL forStaticScreenshot;
@property (nonatomic) id<UICoordinateSpace> coordinateSpace;
@property (nonatomic) UIView *canvasView;
@property (nonatomic) CGSize canvasSize;

@end

@interface CMDrawable : NSObject <NSCoding, NSCopying>

- (instancetype)init;
- (NSArray<NSString*>*)keysForCoding;
@property (nonatomic) CGFloat boundsDiagonal;
@property (nonatomic,readonly) KeyframeStore *keyframeStore;
- (Class)keyframeClass;
@property (nonatomic,readonly) NSString *key;

- (__kindof CMDrawableView *)renderToView:(__kindof CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx;

- (FrameTime *)maxTime;

- (CGFloat)aspectRatio;

- (NSArray<PropertyGroupModel*>*)propertyGroupsWithEditor:(CanvasEditor *)editor;
- (NSArray<PropertyModel*>*)animatablePropertiesWithEditor:(CanvasEditor *)editor;
- (NSArray<PropertyModel*>*)uniqueObjectPropertiesWithEditor:(CanvasEditor *)editor;
- (NSString *)drawableTypeDisplayName;

@end


@interface CMDrawableKeyframe : NSObject <NSCoding, EVInterpolation, NSCopying>

@property (nonatomic) FrameTime *frameTime;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGFloat scale, rotation, alpha;
@property (nonatomic) StaticAnimation *staticAnimation;
- (NSArray<NSString*>*)keys;

@end
