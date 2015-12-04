//
//  CMPhotoDrawable.m
//  computer
//
//  Created by Nate Parrott on 12/1/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMPhotoDrawable.h"
#import "CMTransaction.h"

@interface CMPhotoDrawableView : CMDrawableView {
    UIImageView *_imageView;
}

@property (nonatomic) UIImage *image;

@end

@implementation CMPhotoDrawableView

- (void)setImage:(UIImage *)image {
    if (!_imageView) {
        _imageView = [UIImageView new];
        [self addSubview:_imageView];
    }
    _imageView.image = image;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.bounds;
}

- (UIImage *)image {
    return _imageView.image;
}

@end



@implementation CMPhotoDrawable

- (instancetype)init {
    self = [super init];
    self.image = nil;
    self.aspectRatio = 1;
    return self;
}

- (CGFloat)aspectRatio {
    return _aspectRatio;
}

- (CMDrawableView *)renderToView:(CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx {
    CMPhotoDrawableView *v = [existingOrNil isKindOfClass:[CMPhotoDrawableView class]] ? (id)existingOrNil : [CMPhotoDrawableView new];
    [super renderToView:v context:ctx];
    v.image = self.image;
    return v;
}

- (void)setImage:(UIImage *)image withTransactionStack:(CMTransactionStack *)stack {
    CGFloat oldAspectRatio = self.aspectRatio;
    UIImage *oldImage = self.image;
    [stack doTransaction:[[CMTransaction alloc] initWithTarget:self action:^(id target) {
        [target setImage:image];
        [target setAspectRatio:image ? image.size.width / image.size.height : 1];
    } undo:^(id target) {
        [target setImage:oldImage];
        [target setAspectRatio:oldAspectRatio];
    }]];
}

- (NSArray<PropertyModel*>*)uniqueObjectPropertiesWithEditor:(CanvasEditor *)editor {
    PropertyModel *actions = [PropertyModel new];
    actions.type = PropertyModelTypeButtons;
    actions.title = NSLocalizedString(@"Actions", @"");
    actions.buttonTitles = @[NSLocalizedString(@"Filter", @""), NSLocalizedString(@"Cut out", @"")];
    actions.buttonSelectorNames = @[@"filter:", @"cutOut:"];
    
    return [[super uniqueObjectPropertiesWithEditor:editor] arrayByAddingObjectsFromArray:@[actions]];
}

- (void)filter:(id)sender {
    // TODO
}

- (void)cutOut:(id)sender {
    // TODO
}

- (NSString *)drawableTypeDisplayName {
    return NSLocalizedString(@"Image", @"");
}

@end