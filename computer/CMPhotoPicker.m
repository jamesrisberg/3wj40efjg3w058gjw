//
//  CMPhotoPicker.m
//  computer
//
//  Created by Nate Parrott on 12/10/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMPhotoPicker.h"
#import "computer-Swift.h"

@interface _CMPhotoPickerSnapshotCell : UICollectionViewCell

@property (nonatomic) UIView *snapshot;

@end

@implementation _CMPhotoPickerSnapshotCell

- (void)setSnapshot:(UIView *)snapshot {
    [_snapshot removeFromSuperview];
    _snapshot = snapshot;
    [self.contentView addSubview:snapshot];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.snapshot.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    CGFloat scale = MIN(self.bounds.size.width/self.snapshot.bounds.size.width, self.bounds.size.height/self.snapshot.bounds.size.height);
    self.snapshot.transform = CGAffineTransformMakeScale(scale, scale);
    
}

@end




@interface CMPhotoPicker () <UIImagePickerControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic,weak) IBOutlet UICollectionView *collectionView;

@end

@implementation CMPhotoPicker

+ (instancetype)photoPicker {
    return [[UIStoryboard storyboardWithName:@"CMPhotoPicker" bundle:nil] instantiateInitialViewController];
}

- (void)setSnapshotViews:(NSArray<UIView *> *)snapshotViews {
    _snapshotViews = snapshotViews;
    [self.collectionView reloadData];
}

- (void)gotImage:(UIImage *)image {
    [self dismissViewControllerAnimated:YES completion:nil];
    self.imageCallback(image);
}

- (void)present {
    [NPSoftModalPresentationController presentViewController:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.cornerRadius = 7;
    self.view.clipsToBounds = YES;
}

#pragma mark Actions

- (IBAction)imageSearch:(id)sender {
    ImageSearchViewController *vc = [ImageSearchViewController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    __weak UINavigationController *weakNav = nav;
    __weak CMPhotoPicker *weakSelf = self;
    vc.onImagePicked = ^(UIImage *image) {
        [weakNav dismissViewControllerAnimated:YES completion:^{
            if (image) {
                [weakSelf gotImage:image];
            }
        }];;
    };
    [[NPSoftModalPresentationController getViewControllerForPresentation] presentViewController:nav animated:YES completion:nil];
}

- (IBAction)takePhoto:(id)sender {
    [self showPickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
}

- (IBAction)pickPhoto:(id)sender {
    [self showPickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)showPickerWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *p = [UIImagePickerController new];
    p.sourceType = sourceType;
    p.delegate = (id)self;
    [self presentViewController:p animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        [self gotImage:info[UIImagePickerControllerOriginalImage]];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.snapshotViews.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _CMPhotoPickerSnapshotCell *cell = (id)[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.snapshot = self.snapshotViews[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIView *snapshot = self.snapshotViews[indexPath.row];
    CGFloat size = 900;
    CGFloat scale = MIN(size / snapshot.bounds.size.width, size / snapshot.bounds.size.height);
    CGSize imageSize = CGSizeMake(snapshot.bounds.size.width * scale, snapshot.bounds.size.height * scale);
    UIGraphicsBeginImageContext(imageSize);
    [snapshot drawViewHierarchyInRect:CGRectMake(0, 0, imageSize.width, imageSize.height) afterScreenUpdates:NO];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self gotImage:image];
}

@end
