//
//  CMTextDrawable.h
//  computer
//
//  Created by Nate Parrott on 12/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDrawable.h"

@interface CMTextDrawable : CMDrawable

@property (nonatomic) NSAttributedString *text;
@property (nonatomic) CGFloat aspectRatio;

@end

@interface CMTextDrawableKeyframe : CMDrawableKeyframe

@property (nonatomic) CGFloat textStart, textEnd;

@end

@interface _CMTextDrawableView : CMDrawableView

@property (nonatomic) NSAttributedString *attributedString;
@property (nonatomic) UILabel *label;
@property (nonatomic) CGFloat textStart, textEnd;
@property (nonatomic) NSAttributedString *fittedAttributedString;

@end
