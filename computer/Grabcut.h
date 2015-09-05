//
//  Grabcut.h
//  Backgrounder
//
//  Created by Nate Parrott on 6/15/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Grabcut : NSObject

- (id)initWithImage:(UIImage*)image;
- (void)maskToRect:(CGRect)boundingRect;
- (void)addMask:(UIImage*)mask foregroundColor:(UIColor*)foreground backgroundColor:(UIColor*)background;
- (UIImage*)extractImage;

@end
