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
@property (nonatomic) UIColor *strokeColor;
@property (nonatomic) CGFloat strokeWidth;

@end

@interface CMShapeDrawableKeyframe : CMDrawableKeyframe

@property (nonatomic) CGFloat strokeScale, strokeStart, strokeEnd;

@end
