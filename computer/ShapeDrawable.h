//
//  ShapeDrawable.h
//  computer
//
//  Created by Nate Parrott on 9/7/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"
#import "SKFill.h"

@interface ShapeDrawable : Drawable

@property (nonatomic) UIBezierPath *path;
- (void)fitContent;
@property (nonatomic) SKFill *fill;
@property (nonatomic) UIColor *strokeColor; // TODO: implement stroke
@property (nonatomic) CGFloat strokeWidth;
- (void)_setPathWithoutFittingContent:(UIBezierPath *)path;
- (void)setPathPreservingSize:(UIBezierPath *)path;

@property (nonatomic) CGFloat strokeStart, strokeEnd;

@end
