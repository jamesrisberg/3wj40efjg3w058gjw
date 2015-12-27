//
//  CMCameraDrawable.m
//  computer
//
//  Created by Nate Parrott on 12/26/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMCameraDrawable.h"

@interface _CMCameraDrawableView : CMDrawableView

@property (nonatomic) CGRect pathRect;

@end

@implementation _CMCameraDrawableView

+ (Class)layerClass {
    return [CAShapeLayer class];
}

- (instancetype)init {
    self = [super init];
    CAShapeLayer *shape = (CAShapeLayer *)self.layer;
    shape.fillColor = nil;
    shape.lineWidth = 2;
    shape.strokeColor = [UIColor grayColor].CGColor;
    shape.lineDashPattern = @[@4, @2];
    return self;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    self.pathRect = bounds;
}

- (void)setPathRect:(CGRect)pathRect {
    if (!CGRectEqualToRect(pathRect, _pathRect)) {
        _pathRect = pathRect;
        CAShapeLayer *shape = (CAShapeLayer *)self.layer;
        shape.path = [UIBezierPath bezierPathWithRect:pathRect].CGPath;
    }
}

@end



@implementation CMCameraDrawable

- (instancetype)init {
    self = [super init];
    self.aspectRatio = 1;
    return self;
}

- (NSArray<NSString*>*)keysForCoding {
    return [[super keysForCoding] arrayByAddingObject:@"aspectRatio"];
}

- (NSArray<PropertyGroupModel*>*)propertyGroupsWithEditor:(CanvasEditor *)editor {
    return @[]; // don't edit ANYTHING
}

- (NSString *)drawableTypeDisplayName {
    return NSLocalizedString(@"Camera", @"");
}

- (__kindof CMDrawableView *)renderToView:(__kindof CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx {
    _CMCameraDrawableView *v = [existingOrNil isKindOfClass:[_CMCameraDrawableView class]] ? (id)existingOrNil : [_CMCameraDrawableView new];
    v = [super renderToView:v context:ctx];
    v.hidden = !ctx.renderMetaInfo;
    return v;
}

@end
