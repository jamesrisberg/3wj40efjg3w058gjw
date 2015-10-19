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
#import "SKColorFill.h"

@interface InsertItemViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate>

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
    QuickCollectionItem *video = [QuickCollectionItem new];
    video.icon = [UIImage imageNamed:@"Video"];
    QuickCollectionItem *text = [QuickCollectionItem new];
    text.icon = [UIImage imageNamed:@"Text"];
    text.action = ^{
        TextDrawable *d = [TextDrawable new];
        d.bounds = CGRectMake(0, 0, 250, 250);
        [weakSelf.editorVC.canvas insertDrawable:d];
    };
    QuickCollectionItem *pen = [QuickCollectionItem new];
    pen.icon = [UIImage imageNamed:@"Pen"];
    pen.action = ^{
        ShapeDrawable *d = [ShapeDrawable new];
        d.fill = nil;
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
        d.fill = [[SKColorFill alloc] initWithColor:[UIColor greenColor]];
        [weakSelf.editorVC.canvas insertDrawable:d];
    };
    
    QuickCollectionItem *square = [QuickCollectionItem new];
    square.icon = [UIImage imageNamed:@"Square"];
    square.action = ^{
        ShapeDrawable *d = [ShapeDrawable new];
        d.fill = [[SKColorFill alloc] initWithColor:[UIColor redColor]];
        [weakSelf.editorVC.canvas insertDrawable:d];
    };
    
    self.items = @[camera, photos, video, text, pen, circle, square];
}

@end
