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

@interface PropertyViewTableCell () {
    CMTransaction *_transaction;
}

@end

@implementation PropertyViewTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    [self setup];
    return self;
}

+ (CGFloat)heightWithModel:(PropertyModel *)model {
    return 44;
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
        self.value = [d valueForKey:self.model.key];
    }
}

- (void)saveValue:(id)value {
    if (!self.model.key) return;
    
    __weak PropertyViewTableCell *weakSelf = self;
    CMDrawable *drawable = self.drawables.firstObject; // TODO: multiple selection
    FrameTime *time = self.time;
    
    if (!_transaction || _transaction.finalized) {
        
        CMDrawableKeyframe *oldKeyframe = nil;
        id oldValue = nil;
        if (self.model.isKeyframeProperty) {
            oldKeyframe = [[drawable.keyframeStore keyframeAtTime:self.time] copy];
        } else {
            oldValue = [drawable valueForKey:weakSelf.model.key];
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
            [drawable setValue:value forKey:weakSelf.model.key];
        }
    };
}

@end
