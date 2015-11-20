//
//  TextDrawable.h
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"

@interface TextDrawable : Drawable

@property (nonatomic) CGFloat textStart, textEnd;
@property (nonatomic) NSAttributedString *attributedString;

+ (NSAttributedString *)defaultAttributedStringWithText:(NSString *)text;

@end
