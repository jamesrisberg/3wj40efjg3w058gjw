//
//  NSAttributedString+ResizeToFit.m
//  computer
//
//  Created by Nate Parrott on 9/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "NSAttributedString+ResizeToFit.h"

@implementation NSAttributedString (ResizeToFit)

- (NSAttributedString *)resizeToFitInside:(CGSize)size {
    // TODO: binary search
    NSMutableAttributedString *scaled = self.mutableCopy;
    
    CGFloat base = 1.1;
    NSInteger step = 0;
    
    [[self class] _scaleAttributedString:self byScaleFactor:pow(base, step) output:scaled];
    while (1) {
        // grow:
        CGFloat height = [scaled boundingRectWithSize:CGSizeMake(size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.height;
        // NSLog(@"height: %f; size.height: %f", height, size.height);
        if (height > size.height) {
            break;
        } else {
            step++;
            [[self class] _scaleAttributedString:self byScaleFactor:pow(base, step) output:scaled];
        }
    }
    while (1) {
        // shrink to fit:
        CGFloat height = [scaled boundingRectWithSize:CGSizeMake(size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size.height;
        if (height <= size.height) {
            break;
        } else {
            step--;
            [[self class] _scaleAttributedString:self byScaleFactor:pow(base, step) output:scaled];
        }
    }
    return scaled;
}

+ (void)_scaleAttributedString:(NSAttributedString *)str byScaleFactor:(CGFloat)scale output:(NSMutableAttributedString *)output {
    [str enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, str.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        UIFont *oldFont = value;
        UIFont *scaledFont = [oldFont fontWithSize:oldFont.pointSize * scale];
        [output removeAttribute:NSFontAttributeName range:range];
        [output addAttribute:NSFontAttributeName value:scaledFont range:range];
    }];
}

@end
