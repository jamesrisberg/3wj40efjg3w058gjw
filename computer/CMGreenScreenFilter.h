//
//  CMGreenScreenFilter.h
//  computer
//
//  Created by Nate Parrott on 12/13/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <GPUImage.h>

@interface CMGreenScreenFilter : GPUImageTwoInputFilter
{
    GLint colorToReplaceUniform, thresholdSensitivityUniform, smoothingUniform;
}

/** The threshold sensitivity controls how similar pixels need to be colored to be replaced
 
 The default value is 0.3
 */
@property(readwrite, nonatomic) CGFloat thresholdSensitivity;

/** The degree of smoothing controls how gradually similar colors are replaced in the image
 
 The default value is 0.1
 */
@property(readwrite, nonatomic) CGFloat smoothing;

/** The color to be replaced is specified using individual red, green, and blue components (normalized to 1.0).
 
 The default is green: (0.0, 1.0, 0.0).
 
 @param redComponent Red component of color to be replaced
 @param greenComponent Green component of color to be replaced
 @param blueComponent Blue component of color to be replaced
 */
- (void)setColorToReplaceRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent;

@property (nonatomic) CGFloat unifiedSensitivityAndSmoothing;

@property (nonatomic) UIColor *greenScreenColor;

@end
