//
//  InsertItemViewController.m
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "InsertItemViewController.h"
#import "EditorViewController.h"
#import "PhotoDrawable.h"
#import "CanvasEditor.h"
#import "TextDrawable.h"
#import "ShapeDrawable.h"
#import "SubcanvasDrawable.h"
#import "SKColorFill.h"
#import "computer-Swift.h"
#import "StarDrawable.h"
#import "ParticleDrawable.h"
#import "UIColor+RandomColors.h"
#import "EditorViewController+InsertMedia.h"
#import "CGPointExtras.h"
#import "CMShapeDrawable.h"
#import "CMStarDrawable.h"
#import "CMTextDrawable.h"
#import "CMParticleDrawable.h"
#import "CMPhotoDrawable.h"
@import MobileCoreServices;

@interface InsertItemViewController ()

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSArray *models;

@end

@implementation InsertItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak InsertItemViewController *weakSelf = self;
    
    CMTransactionStack *transactionStack = weakSelf.editorVC.canvas.transactionStack;
    
    QuickCollectionItem *camera = [QuickCollectionItem new];
    camera.icon = [UIImage imageNamed:@"Camera"];
    camera.action = ^{
        [weakSelf.editorVC insertMediaWithSource:UIImagePickerControllerSourceTypeCamera mediaTypes:@[(id)kUTTypeImage, (id)kUTTypeMovie]];
    };
    QuickCollectionItem *photos = [QuickCollectionItem new];
    photos.icon = [UIImage imageNamed:@"Pictures"];
    photos.action = ^{
        [weakSelf.editorVC insertMediaWithSource:UIImagePickerControllerSourceTypePhotoLibrary mediaTypes:@[(id)kUTTypeImage, (id)kUTTypeMovie]];;
    };
    QuickCollectionItem *imageSearch = [QuickCollectionItem new];
    imageSearch.icon = [UIImage imageNamed:@"Search"];
    imageSearch.action = ^{
        CMPhotoDrawable *p = [CMPhotoDrawable new];
        [p setImage:[UIImage imageNamed:@"PlaceholderImage"] withTransactionStack:transactionStack];
        [weakSelf.editorVC.canvas insertDrawableAtCurrentTime:p];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [p promptToPickPhotoFromImageSearchWithTransactionStack:transactionStack];
        });
    };
    QuickCollectionItem *text = [QuickCollectionItem new];
    text.icon = [UIImage imageNamed:@"Text"];
    text.action = ^{
        CMTextDrawable *d = [CMTextDrawable new];
        d.aspectRatio = 1.6;
        NSMutableParagraphStyle *para = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
        para.alignment = NSTextAlignmentCenter;
        NSDictionary *attrs = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:14], NSParagraphStyleAttributeName: para};
        d.text = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Double-tap to edit", @"") attributes:attrs];
        [weakSelf.editorVC.canvas insertDrawableAtCurrentTime:d];
        // [weakSelf.editorVC.canvas insertDrawable:d];
    };
    QuickCollectionItem *particle = [QuickCollectionItem new];
    particle.icon = [UIImage imageNamed:@"Fire"];
    particle.action = ^{
        [weakSelf insertParticle];
    };
    QuickCollectionItem *pen = [QuickCollectionItem new];
    pen.icon = [UIImage imageNamed:@"Pen"];
    pen.action = ^{
        [weakSelf.editorVC startFreehandDrawing];
    };
    QuickCollectionItem *circle = [QuickCollectionItem new];
    circle.icon = [UIImage imageNamed:@"Circle"];
    circle.action = ^{
        CMShapeDrawable *shape = [CMShapeDrawable new];
        CGRect r = CGRectMake(0, 0, 100, 100);
        [shape setPath:[UIBezierPath bezierPathWithOvalInRect:r] usingTransactionStack:weakSelf.editorVC.canvas.transactionStack updateAspectRatio:YES];
        shape.pattern = [Pattern solidColor:[UIColor randomHue]];
        shape.strokePattern = [Pattern solidColor:[UIColor blackColor]];
        shape.strokeWidth = 2;
        shape.boundsDiagonal = CGRectDiagonal(r);
        [weakSelf.editorVC.canvas insertDrawableAtCurrentTime:shape];
    };
    
    QuickCollectionItem *square = [QuickCollectionItem new];
    square.icon = [UIImage imageNamed:@"Square"];
    square.action = ^{
        CMShapeDrawable *shape = [CMShapeDrawable new];
        CGRect r = CGRectMake(0, 0, 100, 100);
        [shape setPath:[UIBezierPath bezierPathWithRect:r] usingTransactionStack:weakSelf.editorVC.canvas.transactionStack updateAspectRatio:YES];
        shape.pattern = [Pattern solidColor:[UIColor randomHue]];
        shape.strokePattern = [Pattern solidColor:[UIColor blackColor]];
        shape.strokeWidth = 2;
        shape.boundsDiagonal = CGRectDiagonal(r);
        [weakSelf.editorVC.canvas insertDrawableAtCurrentTime:shape];
    };
    
    QuickCollectionItem *star = [QuickCollectionItem new];
    star.icon = [UIImage imageNamed:@"Star"];
    star.action = ^{
        CMStarDrawable *d = [CMStarDrawable new];
        d.pattern = [Pattern solidColor:[UIColor randomHue]];
        d.strokePattern = [Pattern solidColor:[UIColor blackColor]];
        d.strokeWidth = 2;
        [weakSelf.editorVC.canvas insertDrawableAtCurrentTime:d];
    };
    
    self.items = @[camera, photos, imageSearch, text, pen, circle, square, star, particle];
}

- (void)insertParticle {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Particle Effect", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Fire", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CMParticleDrawable *d = [CMParticleDrawable new];
        d.particlePreset = ParticlePresetFire;
        [self.editorVC.canvas insertDrawableAtCurrentTime:d];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sparkle", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CMParticleDrawable *d = [CMParticleDrawable new];
        d.particlePreset = ParticlePresetSparkle;
        [self.editorVC.canvas insertDrawableAtCurrentTime:d];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Snow", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CMParticleDrawable *d = [CMParticleDrawable new];
        d.particlePreset = ParticlePresetSnow;
        [self.editorVC.canvas insertDrawableAtCurrentTime:d];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Smoke", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CMParticleDrawable *d = [CMParticleDrawable new];
        d.particlePreset = ParticlePresetSmoke;
        [self.editorVC.canvas insertDrawableAtCurrentTime:d];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Colorful orbs", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CMParticleDrawable *d = [CMParticleDrawable new];
        d.particlePreset = ParticlePresetOrbs;
        [self.editorVC.canvas insertDrawableAtCurrentTime:d];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Macaroni", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CMParticleDrawable *d = [CMParticleDrawable new];
        d.particlePreset = ParticlePresetMacaroni;
        [self.editorVC.canvas insertDrawableAtCurrentTime:d];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Never mind", @"") style:UIAlertActionStyleCancel handler:nil]];
    [[NPSoftModalPresentationController getViewControllerForPresentationInWindow:[UIApplication sharedApplication].windows.firstObject] presentViewController:alert animated:YES completion:nil];
}

@end
