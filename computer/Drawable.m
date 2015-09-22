//
//  Drawable.m
//  computer
//
//  Created by Nate Parrott on 9/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "Drawable.h"
#import "MultiButtonOptionsTableViewCell.h"
#import "Canvas.h"

@implementation Drawable

- (instancetype)init {
    self = [super init];
    [self setup];
    return self;
}

- (void)primaryEditAction {
    
}

- (void)setup {
    _rotation = 0;
    _scale = 1;
}

#pragma mark Transforms

- (void)setRotation:(CGFloat)rotation {
    _rotation = rotation;
    [self updateTransform];
}

- (void)setScale:(CGFloat)scale {
    _scale = scale;
    [self updateTransform];
}

- (void)updateTransform {
    self.transform = CGAffineTransformRotate(CGAffineTransformMakeScale(self.scale, self.scale), self.rotation);
}

#pragma mark Util

- (UIViewController *)vcForPresentingModals {
    return self.window.rootViewController;
}

- (Canvas *)canvas {
    return (Canvas *)self.superview;
}

#pragma mark Options

- (NSArray *)optionsCellModels {
    __weak Drawable *weakSelf = self;
    OptionsViewCellModel *actions = [OptionsViewCellModel new];
    actions.cellClass = [MultiButtonOptionsTableViewCell class];
    actions.onCreate = ^(OptionsTableViewCell *cell){
        MultiButtonOptionsTableViewCell *multiButtonCell = (id)cell;
        multiButtonCell.buttonTitles = @[NSLocalizedString(@"Delete", @""), NSLocalizedString(@"Duplicate", @"")];
        multiButtonCell.buttonActions = @[
                                          ^{ // delete
                                              [weakSelf delete:nil];
                                          },
                                           ^{ // duplicate
                                               [weakSelf duplicate:nil];
                                           }
                                          ];
    };
    
    return @[actions];
}

#pragma mark Actions
- (void)delete:(id)sender {
    if (self.canvas.selection == self) self.canvas.selection = nil;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.scale /= 100;
        self.alpha = 0;
    } completion:^(BOOL finished) {
        if (self.canvas.selection == self) self.canvas.selection = nil;
        [self removeFromSuperview];
    }];
}

- (void)duplicate:(id)sender {
    Drawable *dupe = [self copy];
    [self.canvas insertSubview:dupe aboveSubview:self];
    dupe.center = CGPointMake(dupe.center.x + 20, dupe.center.y + 20);
}

#pragma mark Resize

- (void)setInternalSize:(CGSize)size {
    self.bounds = CGRectMake(0, 0, size.width, size.height);
}

#pragma mark Coding
- (void)encodeWithCoder:(NSCoder *)aCoder {
    // deliberately DON'T call super
    [aCoder encodeObject:[NSValue valueWithCGRect:self.bounds] forKey:@"bounds"];
    [aCoder encodeObject:[NSValue valueWithCGPoint:self.center] forKey:@"center"];
    [aCoder encodeDouble:self.scale forKey:@"scale"];
    [aCoder encodeDouble:self.rotation forKey:@"rotation"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init]; // deliberately DON'T call super
    self.bounds = [[aDecoder decodeObjectForKey:@"bounds"] CGRectValue];
    self.center = [[aDecoder decodeObjectForKey:@"center"] CGPointValue];
    self.scale = [aDecoder decodeDoubleForKey:@"scale"];
    self.rotation = [aDecoder decodeDoubleForKey:@"rotation"];
    return self;
}

#pragma mark Copying

- (id)copy {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (id)copyWithZone:(NSZone *)zone {
    return [self copy];
}

@end
