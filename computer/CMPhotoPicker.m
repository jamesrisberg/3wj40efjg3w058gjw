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

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIImage *snapshot;

@end

@implementation _CMPhotoPickerSnapshotCell

- (void)setSnapshot:(UIImage *)snapshot {
    _snapshot = snapshot;
    if (!self.imageView) {
        self.imageView = [UIImageView new];
        [self.contentView addSubview:self.imageView];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    self.imageView.image = snapshot;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    
}

@end




@interface CMPhotoPicker () <UIImagePickerControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic,weak) IBOutlet UICollectionView *collectionView;

@end

@implementation CMPhotoPicker

+ (instancetype)photoPicker {
    return [[UIStoryboard storyboardWithName:@"CMPhotoPicker" bundle:nil] instantiateInitialViewController];
}

- (void)setViewSnapshots:(NSArray<UIImage *> *)viewSnapshots {
    _viewSnapshots = viewSnapshots;
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
    return self.viewSnapshots.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _CMPhotoPickerSnapshotCell *cell = (id)[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.snapshot = self.viewSnapshots[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIImage *snapshot = self.viewSnapshots[indexPath.row];
    [self gotImage:snapshot];
}

@end
