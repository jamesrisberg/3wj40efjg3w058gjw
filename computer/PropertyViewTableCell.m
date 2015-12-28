//
//  PropertyViewTableCell.m
//  computer
//
//  Created by Nate Parrott on 12/2/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "PropertyViewTableCell.h"
#import "CMDrawable.h"
#import "Keyframe.h"
#import "PropertyModel.h"
#import "computer-Swift.h"
#import "EditorViewController.h"

@interface PropertyViewTableCell () {
    CMTransaction *_transaction;
    BOOL _setupYet;
}

@end

@implementation PropertyViewTableCell

- (void)setupIfNeeded {
    if (!_setupYet) {
        _setupYet = YES;
        [self setup];
    }
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
}

- (void)reloadValue {
    if (!self.model.key) return;
    
    CMDrawable *d = self.drawables.firstObject; // TODO: handle multiple selection
    if (self.model.isKeyframeProperty) {
        self.value = [[[d keyframeStore] interpolatedKeyframeAtTime:self.time] valueForKey:self.model.key];
    } else {
        self.value = [d valueForKeyPath:self.model.key];
    }
}

- (void)saveValue:(id)value {
    if (!self.model.key) return;
    
    if ([value isEqual:self.value]) return;
    
    __weak PropertyViewTableCell *weakSelf = self;
    CMDrawable *drawable = self.drawables.firstObject; // TODO: multiple selection
    FrameTime *time = self.time;
    
    if (!_transaction || _transaction.finalized) {
        
        CMDrawableKeyframe *oldKeyframe = nil;
        id oldValue = nil;
        if (self.model.isKeyframeProperty) {
            oldKeyframe = [[drawable.keyframeStore keyframeAtTime:self.time] copy];
        } else {
            oldValue = [drawable valueForKeyPath:weakSelf.model.key];
        }
        
        _transaction = [[CMTransaction alloc] initImplicitlyFinalizaledWhenTouchesEndWithTarget:self action:^(id target) {
            // do nothing
        } undo:^(id target) {
            if (weakSelf.model.isKeyframeProperty) {
                [drawable.keyframeStore removeKeyframeAtTime:time];
                if (oldKeyframe) {
                    [drawable.keyframeStore storeKeyframe:oldKeyframe];
                }
            } else {
                [drawable setValue:oldValue forKey:weakSelf.model.key];
            }
        }];
        [self.transactionStack doTransaction:_transaction];
    }
    
    _transaction.action = ^(id target) {
        if (weakSelf.model.isKeyframeProperty) {
            CMDrawableKeyframe *keyframe = [[drawable.keyframeStore interpolatedKeyframeAtTime:weakSelf.time] copy];
            [keyframe setValue:value forKey:weakSelf.model.key];
            [drawable.keyframeStore storeKeyframe:keyframe];
        } else {
            [drawable setValue:value forKeyPath:weakSelf.model.key];
        }
    };
}

- (UIViewController *)viewControllerForModals {
    return [NPSoftModalPresentationController getViewControllerForPresentationInWindow:[UIApplication sharedApplication].windows.firstObject];
}

+ (CGFloat)heightForModel:(PropertyModel *)model {
    return 44;
}

+ (CGFloat)standardInlineControlPadding {
    return 8;
}

- (CMTransactionStack *)transactionStack {
    return self.editor.canvas.transactionStack;
}

@end
