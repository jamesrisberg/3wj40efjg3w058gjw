//
//  CMPhotoDrawable.m
//  computer
//
//  Created by Nate Parrott on 12/1/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMPhotoDrawable.h"
#import "CMTransaction.h"
#import "FilterPickerViewController.h"
#import "computer-Swift.h"
#import "PropertyViewTableCell.h"

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


@interface CMPhotoDrawable ()

@property (nonatomic) NSData *photoData;

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

- (NSArray<NSString*>*)keysForCoding {
    return [[super keysForCoding] arrayByAddingObjectsFromArray:@[@"photoData", @"aspectRatio"]];
}

- (NSArray<PropertyModel*>*)uniqueObjectPropertiesWithEditor:(CanvasEditor *)editor {
    PropertyModel *actions = [PropertyModel new];
    actions.type = PropertyModelTypeButtons;
    actions.title = NSLocalizedString(@"Actions", @"");
    actions.buttonTitles = @[NSLocalizedString(@"Filter", @""), NSLocalizedString(@"Cut out", @"")];
    actions.buttonSelectorNames = @[@"filter:", @"cutOut:"];
    
    return [[super uniqueObjectPropertiesWithEditor:editor] arrayByAddingObjectsFromArray:@[actions]];
}

- (void)filter:(PropertyViewTableCell *)sender {
    [[NPSoftModalPresentationController getViewControllerForPresentationInWindow:[UIApplication sharedApplication].windows.firstObject] presentViewController:[FilterPickerViewController filterPickerWithImage:self.image callback:^(UIImage *filtered) {
        if (filtered) {
            [self setImage:filtered withTransactionStack:sender.transactionStack];
        }
    }] animated:YES completion:nil];
}

- (void)cutOut:(PropertyViewTableCell *)sender {
    StickerExtractViewController *extractVC = (id)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"StickerExtractVC"];
    extractVC.onExtractedSticker = ^(UIImage *sticker) {
        if (sticker) {
            [self setImage:sticker withTransactionStack:sender.transactionStack];
        }
    };
    extractVC.imageToExtractFrom = self.image;
    [[NPSoftModalPresentationController getViewControllerForPresentationInWindow:[UIApplication sharedApplication].windows.firstObject] presentViewController:extractVC animated:YES completion:nil];
}

- (NSString *)drawableTypeDisplayName {
    return NSLocalizedString(@"Image", @"");
}

- (NSData *)photoData {
    return self.image ? UIImagePNGRepresentation(self.image) : nil;
}

- (void)setPhotoData:(NSData *)photoData {
    self.image = [UIImage imageWithData:photoData];
}

@end
