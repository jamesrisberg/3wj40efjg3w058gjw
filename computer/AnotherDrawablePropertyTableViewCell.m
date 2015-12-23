//
//  AnotherDrawablePropertyTableViewCell.m
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "AnotherDrawablePropertyTableViewCell.h"
#import "EditorViewController.h"
#import "CMCanvas.h"
#import "CMDrawable.h"
#import "DrawablePickerCollectionViewController.h"
#import "ConvenienceCategories.h"
#import "computer-Swift.h"

@interface AnotherDrawablePropertyTableViewCell ()

@property (nonatomic) UIButton *button;

@end

@implementation AnotherDrawablePropertyTableViewCell

- (void)setModel:(PropertyModel *)model {
    [super setModel:model];
    if (!self.button) {
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.contentView addSubview:self.button];
        self.button.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.button.titleLabel.font = [UIFont boldSystemFontOfSize:self.button.titleLabel.font.pointSize];
        [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.button addTarget:self action:@selector(pick:) forControlEvents:UIControlEventTouchUpInside];
        self.button.frame = self.button.superview.bounds;
        self.button.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
}

-(void)pick:(id)sender {
    NSArray *drawables = [self.editor.canvas.canvas.contents map:^id(id obj) {
        return [self.drawables containsObject:obj] ? nil : obj;
    }];
    // TODO: make this less SLOW (n^2 rn)
    NSArray *snapshots = [drawables map:^id(id obj) {
        return [[self.editor.canvas.canvasView viewForDrawable:obj] snapshotViewAfterScreenUpdates:NO];
    }];
    DrawablePickerCollectionViewController *picker = [[DrawablePickerCollectionViewController alloc] initWithDrawables:drawables snapshotViews:snapshots callback:^(CMDrawable *drawableOrNil) {
        [self saveValue:drawableOrNil.key];
    }];
    [NPSoftModalPresentationController presentViewController:picker];
}

- (void)reloadValue {
    [super reloadValue];
    NSString *title = NSLocalizedString(@"Pick an Object…", @"");
    if (self.value) {
        CMDrawable *drawable = [self drawableForUUID:self.value];
        title = drawable.displayName;
    }
    [self.button setTitle:title forState:UIControlStateNormal];
    self.button.alpha = self.value ? 1 : 0.5;
}

- (CMDrawable *)drawableForUUID:(NSString *)uuid {
    for (CMDrawable *d in self.editor.canvas.canvas.contents) {
        if ([d.key isEqualToString:uuid]) {
            return d;
        }
    }
    return nil;
}

@end
