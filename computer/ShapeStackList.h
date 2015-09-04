//
//  ShapeStackList.h
//  computer
//
//  Created by Nate Parrott on 9/4/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Drawable;

@interface ShapeStackList : UIView

@property (nonatomic) NSArray *drawables;
@property (nonatomic,copy) void (^onDrawableSelected)(Drawable *drawable);
- (void)show;
- (void)hide;

@end
