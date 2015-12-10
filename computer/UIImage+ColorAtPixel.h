//
//  UIImage+ColorAtPixel.h
//  computer
//
//  Created by Nate Parrott on 12/10/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ColorAtPixel)

- (UIColor *)colorAtPixel:(CGPoint)p;

@end
