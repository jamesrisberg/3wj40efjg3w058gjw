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
#import "Canvas.h"
#import "TextDrawable.h"
#import "ShapeDrawable.h"
#import "SubcanvasDrawable.h"
#import "SKColorFill.h"
#import "computer-Swift.h"
#import "StarDrawable.h"
#import "ParticleDrawable.h"

@interface InsertItemViewController ()

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) NSArray *models;

@end

@implementation InsertItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak InsertItemViewController *weakSelf = self;
    PhotoDrawable* (^addPhoto)() = ^{
        PhotoDrawable *d = [PhotoDrawable new];
        d.bounds = CGRectMake(0, 0, 250, 250);
        [weakSelf.editorVC.canvas insertDrawable:d];
        return d;
    };
    
    QuickCollectionItem *camera = [QuickCollectionItem new];
    camera.icon = [UIImage imageNamed:@"Camera"];
    camera.action = ^{
        PhotoDrawable *d = addPhoto();
        [d promptToPickPhotoWithSource:UIImagePickerControllerSourceTypeCamera];
    };
    QuickCollectionItem *photos = [QuickCollectionItem new];
    photos.icon = [UIImage imageNamed:@"Pictures"];
    photos.action = ^{
        PhotoDrawable *d = addPhoto();
        [d promptToPickPhotoWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
    };
    QuickCollectionItem *imageSearch = [QuickCollectionItem new];
    imageSearch.icon = [UIImage imageNamed:@"Search"];
    imageSearch.action = ^{
        PhotoDrawable *d = addPhoto();
        [d promptToPickPhotoFromImageSearch];
    };
    QuickCollectionItem *video = [QuickCollectionItem new];
    video.icon = [UIImage imageNamed:@"Video"];
    QuickCollectionItem *text = [QuickCollectionItem new];
    text.icon = [UIImage imageNamed:@"Text"];
    text.action = ^{
        TextDrawable *d = [TextDrawable new];
        d.bounds = CGRectMake(0, 0, 300, 200);
        [weakSelf.editorVC.canvas insertDrawable:d];
    };
    QuickCollectionItem *particle = [QuickCollectionItem new];
    particle.icon = [UIImage imageNamed:@"Fire"];
    particle.action = ^{
        InsertItemViewController *strongSelf = weakSelf;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Particle Effect", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Fire", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ParticleDrawable *d = [ParticleDrawable new];
            d.particlePreset = ParticlePresetFire;
            [strongSelf.editorVC.canvas insertDrawable:d];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sparkle", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ParticleDrawable *d = [ParticleDrawable new];
            d.particlePreset = ParticlePresetSparkle;
            [strongSelf.editorVC.canvas insertDrawable:d];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Snow", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ParticleDrawable *d = [ParticleDrawable new];
            d.particlePreset = ParticlePresetSnow;
            [strongSelf.editorVC.canvas insertDrawable:d];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Macaroni", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ParticleDrawable *d = [ParticleDrawable new];
            d.particlePreset = ParticlePresetMacaroni;
            [strongSelf.editorVC.canvas insertDrawable:d];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Never mind", @"") style:UIAlertActionStyleCancel handler:nil]];
        [[NPSoftModalPresentationController getViewControllerForPresentationInWindow:[UIApplication sharedApplication].windows.firstObject] presentViewController:alert animated:YES completion:nil];
    };
    QuickCollectionItem *pen = [QuickCollectionItem new];
    pen.icon = [UIImage imageNamed:@"Pen"];
    pen.action = ^{
        ShapeDrawable *d = [ShapeDrawable new];
        d.pattern = nil;
        d.path = nil;
        d.strokeColor = [UIColor redColor];
        d.strokeWidth = 2;
        [weakSelf.editorVC.canvas insertDrawable:d];
        [weakSelf.editorVC startFreehandDrawingToShape:d];
    };
    QuickCollectionItem *circle = [QuickCollectionItem new];
    circle.icon = [UIImage imageNamed:@"Circle"];
    circle.action = ^{
        ShapeDrawable *d = [ShapeDrawable new];
        d.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 200, 200)];
        d.pattern = [Pattern solidColor:[UIColor greenColor]];
        [weakSelf.editorVC.canvas insertDrawable:d];
    };
    
    QuickCollectionItem *square = [QuickCollectionItem new];
    square.icon = [UIImage imageNamed:@"Square"];
    square.action = ^{
        ShapeDrawable *d = [ShapeDrawable new];
        d.pattern = [Pattern solidColor:[UIColor orangeColor]];
        [weakSelf.editorVC.canvas insertDrawable:d];
    };
    
    QuickCollectionItem *star = [QuickCollectionItem new];
    star.icon = [UIImage imageNamed:@"Star"];
    star.action = ^{
        StarDrawable *d = [StarDrawable new];
        d.pattern = [Pattern solidColor:[UIColor purpleColor]];
        [weakSelf.editorVC.canvas insertDrawable:d];
    };
    
    QuickCollectionItem *group = [QuickCollectionItem new];
    group.icon = [UIImage imageNamed:@"Group"];
    group.action = ^{
        Canvas *canvas = [[Canvas alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        
        ShapeDrawable *square = [ShapeDrawable new];
        square.pattern = nil;// [[SKColorFill alloc] initWithColor:[UIColor blueColor]];
        square.strokeWidth = 4;
        square.strokeColor = [UIColor purpleColor];
        [canvas insertDrawable:square];
        
        /*ShapeDrawable *circle = [ShapeDrawable new];
        circle.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 120, 120)];
        circle.fill = [[SKColorFill alloc] initWithColor:[UIColor orangeColor]];
        [canvas insertDrawable:circle];*/
        
        SubcanvasDrawable *d = [SubcanvasDrawable new];
        d.subcanvas = canvas;
        [weakSelf.editorVC.canvas insertDrawable:d];
    };
    
    self.items = @[camera, photos, imageSearch, video, text, pen, circle, square, star, group, particle];
}

@end
