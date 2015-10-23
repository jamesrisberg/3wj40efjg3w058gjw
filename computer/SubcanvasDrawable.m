//
//  SubcanvasDrawable.m
//  computer
//
//  Created by Nate Parrott on 10/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "SubcanvasDrawable.h"
#import "Canvas.h"
#import "EditorViewController.h"

@interface SubcanvasDrawable ()

@end

@implementation SubcanvasDrawable

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.canvas = [aDecoder decodeObjectForKey:@"canvas"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.canvas forKey:@"canvas"];
}

- (void)setup {
    [super setup];
    if (!self.canvas) {
        self.canvas = [Canvas new];
    }
}

- (void)setCanvas:(Canvas *)canvas {
    CGFloat oldAspectRatio = _canvas ? _canvas.bounds.size.width / _canvas.bounds.size.height : 1;
    [_canvas removeFromSuperview];
    _canvas = canvas;
    [canvas resizeBoundsToFitContent];
    CGFloat newAspectRatio = canvas ? canvas.bounds.size.width / canvas.bounds.size.height : 1;
    [self addSubview:_canvas];
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        self.bounds = CGRectMake(0, 0, 200, 200);
    }
    [self adjustAspectRatioWithOld:oldAspectRatio new:newAspectRatio];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // canvas.bounds is set by -[Canvas resizeBoundsToFitContent] inside -setCanvas:
    self.canvas.transform = CGAffineTransformMakeScale(self.bounds.size.width / self.canvas.bounds.size.width, self.bounds.size.height / self.canvas.bounds.size.height);
    self.canvas.layer.anchorPoint = CGPointMake(0, 0);
    self.canvas.center = CGPointMake(0, 0);
}

- (void)primaryEditAction {
    __weak SubcanvasDrawable *weakSelf = self;
    EditorViewController *editorVC = [EditorViewController modalEditorForCanvas:self.canvas callback:^(Canvas *edited) {
        weakSelf.canvas = edited;
    }];
    [[self vcForPresentingModals] presentViewController:editorVC animated:YES completion:nil];
}

@end
