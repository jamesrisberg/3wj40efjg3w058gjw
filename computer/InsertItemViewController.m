//
//  InsertItemViewController.m
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "InsertItemViewController.h"
#import "EditorViewController.h"
#import "CanvasEditor.h"
#import "SKColorFill.h"
#import "computer-Swift.h"
#import "UIColor+RandomColors.h"
#import "EditorViewController+InsertMedia.h"
#import "CGPointExtras.h"
#import "CMShapeDrawable.h"
#import "CMStarDrawable.h"
#import "CMTextDrawable.h"
#import "CMParticleDrawable.h"
#import "CMPhotoDrawable.h"
#import "UIBarButtonItem+BorderedButton.h"
#import "CMCameraDrawable.h"
#import "ConvenienceCategories.h"
@import MobileCoreServices;

@interface InsertItemViewController ()

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSArray *models;
@property (nonatomic) UIToolbar *topToolbar;
@property (nonatomic) UIBarButtonItem *pasteButton;

@end

@implementation InsertItemViewController

+ (CGFloat)defaultItemSize {
    return 200; // also defined in [CMDrawable init] for some cases, but ugh
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // setup top bar:
    
    self.topToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    self.topBar = self.topToolbar;
    [self.topToolbar setBackgroundImage:[UIImage new]
                  forToolbarPosition:UIToolbarPositionAny
                          barMetrics:UIBarMetricsDefault];
    [self.topToolbar setBackgroundColor:[UIColor clearColor]];
    self.pasteButton = [[UIBarButtonItem alloc] initUnborderedWithTitle:NSLocalizedString(@"Paste", @"") target:self action:@selector(paste)];
    self.topToolbar.items = @[
                              self.pasteButton,
                              [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                              [[UIBarButtonItem alloc] initUnborderedWithTitle:NSLocalizedString(@"Create Group", @"") target:self action:@selector(createGroup)]
                              ];
    self.topToolbar.tintColor = [UIColor colorWithWhite:1 alpha:0.6];
    
    // setup main items:
    
    __weak InsertItemViewController *weakSelf = self;
    
    CMTransactionStack *transactionStack = weakSelf.editorVC.canvas.transactionStack;
    
    QuickCollectionItem *camera = [QuickCollectionItem new];
    camera.icon = [UIImage imageNamed:@"Camera"];
    camera.label = NSLocalizedString(@"Camera", @"");
    camera.action = ^{
        [weakSelf.editorVC insertMediaWithSource:UIImagePickerControllerSourceTypeCamera mediaTypes:@[(id)kUTTypeImage, (id)kUTTypeMovie]];
    };
    QuickCollectionItem *photos = [QuickCollectionItem new];
    photos.icon = [UIImage imageNamed:@"Pictures"];
    photos.label = NSLocalizedString(@"Photos", @"");
    photos.action = ^{
        [weakSelf.editorVC insertMediaWithSource:UIImagePickerControllerSourceTypePhotoLibrary mediaTypes:@[(id)kUTTypeImage, (id)kUTTypeMovie]];;
    };
    QuickCollectionItem *imageSearch = [QuickCollectionItem new];
    imageSearch.icon = [UIImage imageNamed:@"Search"];
    imageSearch.label = NSLocalizedString(@"Image Search", @"");
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
    text.label = NSLocalizedString(@"Text", @"");
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
    particle.label = NSLocalizedString(@"Effects", @"");
    particle.action = ^{
        [weakSelf insertParticle];
    };
    QuickCollectionItem *pen = [QuickCollectionItem new];
    pen.icon = [UIImage imageNamed:@"Pen"];
    pen.label = NSLocalizedString(@"Drawing", @"");
    pen.action = ^{
        [weakSelf.editorVC startFreehandDrawing];
    };
    QuickCollectionItem *circle = [QuickCollectionItem new];
    circle.icon = [UIImage imageNamed:@"Circle"];
    circle.label = NSLocalizedString(@"Circle", @"");
    circle.action = ^{
        CMShapeDrawable *shape = [CMShapeDrawable new];
        CGSize size = CMSizeWithDiagonalAndAspectRatio([[self class] defaultItemSize], 1);
        CGRect r = (CGRect){CGPointZero, size};
        [shape setPath:[UIBezierPath bezierPathWithOvalInRect:r] usingTransactionStack:weakSelf.editorVC.canvas.transactionStack updateAspectRatio:YES];
        shape.pattern = [Pattern solidColor:[UIColor randomHue]];
        shape.strokePattern = [Pattern solidColor:[UIColor blackColor]];
        // shape.strokeWidth = 2;
        shape.boundsDiagonal = CGRectDiagonal(r);
        [weakSelf.editorVC.canvas insertDrawableAtCurrentTime:shape];
    };
    
    QuickCollectionItem *square = [QuickCollectionItem new];
    square.icon = [UIImage imageNamed:@"Square"];
    square.label = NSLocalizedString(@"Square", @"");
    square.action = ^{
        CMShapeDrawable *shape = [CMShapeDrawable new];
        CGSize size = CMSizeWithDiagonalAndAspectRatio([[self class] defaultItemSize], 1);
        CGRect r = (CGRect){CGPointZero, size};
        [shape setPath:[UIBezierPath bezierPathWithRect:r] usingTransactionStack:weakSelf.editorVC.canvas.transactionStack updateAspectRatio:YES];
        shape.pattern = [Pattern solidColor:[UIColor randomHue]];
        shape.strokePattern = [Pattern solidColor:[UIColor blackColor]];
        // shape.strokeWidth = 2;
        shape.boundsDiagonal = CGRectDiagonal(r);
        [weakSelf.editorVC.canvas insertDrawableAtCurrentTime:shape];
    };
    
    QuickCollectionItem *star = [QuickCollectionItem new];
    star.icon = [UIImage imageNamed:@"Star"];
    star.label = NSLocalizedString(@"Polygon", @"");
    star.action = ^{
        CMStarDrawable *d = [CMStarDrawable new];
        d.pattern = [Pattern solidColor:[UIColor randomHue]];
        d.strokePattern = [Pattern solidColor:[UIColor blackColor]];
        // d.strokeWidth = 2;
        [weakSelf.editorVC.canvas insertDrawableAtCurrentTime:d];
    };
    
    QuickCollectionItem *exportCamera = [QuickCollectionItem new];
    exportCamera.icon = [UIImage imageNamed:@"Viewport"];
    exportCamera.label = NSLocalizedString(@"Viewport", @"");
    exportCamera.action = ^{
        CMCameraDrawable *cam = [CMCameraDrawable new];
        [weakSelf.editorVC.canvas insertDrawableAtCurrentTime:cam];
    };
    
    self.items = @[camera, photos, imageSearch, text, pen, circle, square, star, particle, exportCamera];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    BOOL canPaste = [[UIPasteboard generalPasteboard] containsPasteboardTypes:@[CMDrawableArrayPasteboardType]];
    self.pasteButton.tintColor = canPaste ? nil : [UIColor colorWithWhite:0 alpha:0];
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
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Custom", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        CMParticleDrawable *d = [CMParticleDrawable new];
        d.boundsDiagonal *= 2;
        d.particlePreset = ParticlePresetCustom;
        d.customParticleImages = [@[@"ridge-confetti", @"oval-confetti", @"triangle-confetti"] map:^id(id obj) {
            return [UIImage imageNamed:obj];
        }];
        [self.editorVC.canvas insertDrawableAtCurrentTime:d];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Never mind", @"") style:UIAlertActionStyleCancel handler:nil]];
    [[NPSoftModalPresentationController getViewControllerForPresentationInWindow:[UIApplication sharedApplication].windows.firstObject] presentViewController:alert animated:YES completion:nil];
}

- (void)createGroup {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.editorVC beginCreatingGroup];
}

- (void)paste {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.editorVC.canvas paste:nil];
}

@end
