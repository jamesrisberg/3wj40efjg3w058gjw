//
//  CMShapeDrawable.h
//  computer
//
//  Created by Nate Parrott on 11/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDrawable.h"
@class Pattern;

@interface CMShapeDrawable : CMDrawable

@property (nonatomic) UIBezierPath *path;
@property (nonatomic) Pattern *pattern;
@property (nonatomic) Pattern *strokePattern;
@property (nonatomic) CGFloat strokeWidth;

@property (nonatomic) CGFloat aspectRatio;

- (void)setPath:(UIBezierPath *)path usingTransactionStack:(CMTransactionStack *)stack updateAspectRatio:(BOOL)updateAspect;

@end

@interface CMShapeDrawableKeyframe : CMDrawableKeyframe

@property (nonatomic) CGFloat strokeScale, strokeStart, strokeEnd;

@end
