//
//  FilterPickerViewController.m
//  computer
//
//  Created by Nate Parrott on 11/25/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FilterPickerViewController.h"
#import <GPUImage.h>
#import "FilterThumbnailCollectionViewCell.h"
#import "FilterPickerFilterInfo.h"
#import "computer-Swift.h"

@interface FilterPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) CMMediaID *originalMediaID, *filteredMediaID, *currentSourceMediaID;

@property (nonatomic) GPUImageMovie *source;
@property (nonatomic) GPUImageFilter *filter;
@property (nonatomic) GPUImageView *outputView;
@property (nonatomic) IBOutlet UIView *outputViewContainer;

@property (nonatomic) FilterPickerFilterInfo *currentFilterInfo;
@property (nonatomic) NSArray<__kindof FilterPickerFilterInfo*> *allFilters;

@property (nonatomic) UIImage *thumbnail;

@property (nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) NSInteger UIBlockCount;
@property (nonatomic) IBOutlet UIView *blockView;

@property (nonatomic) CGSize outputSize;
@property (nonatomic) GPUImageRotationMode inputRotation;

@end

@implementation FilterPickerViewController

+ (FilterPickerViewController *)filterPickerWithMediaID:(CMMediaID *)mediaID {
    FilterPickerViewController *vc = [[FilterPickerViewController alloc] initWithNibName:@"FilterPickerViewController" bundle:nil];
    vc.originalMediaID = mediaID;
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[FilterThumbnailCollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    
    self.allFilters = [FilterPickerFilterInfo allFilters];
    
    self.outputView = [GPUImageView new];
    [self.outputViewContainer addSubview:self.outputView];
    self.currentFilterInfo = self.allFilters.firstObject;
    
    self.currentSourceMediaID = self.originalMediaID;
    
    self.thumbnail = [[UIImage imageNamed:@"bliss.jpg"] resizedWithMaxDimension:150];
    
    [self.source startProcessing];
}

- (void)setThumbnail:(UIImage *)thumbnail {
    _thumbnail = thumbnail;
    for (FilterThumbnailCollectionViewCell *cell in self.collectionView.visibleCells) {
        cell.input = thumbnail;
    }
}

- (void)setCurrentFilterInfo:(FilterPickerFilterInfo *)currentFilterInfo {
    _currentFilterInfo = currentFilterInfo;
    self.filter = [currentFilterInfo createFilter];
    for (NSIndexPath *selection in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:selection animated:NO];
    }
    if (currentFilterInfo) {
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:[self.allFilters indexOfObject:currentFilterInfo] inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (void)setSource:(GPUImageMovie *)source {
    [_source removeAllTargets];
    [_source cancelProcessing];
    _source = source;
    [self rebuildFilterChain];
}

- (void)setFilter:(GPUImageFilter *)filter {
    [_source removeAllTargets];
    [_filter removeAllTargets];
    
    _filter = filter;
    [_filter setInputRotation:self.inputRotation atIndex:0];
    [self rebuildFilterChain];
}

- (void)setInputRotation:(GPUImageRotationMode)inputRotation {
    _inputRotation = inputRotation;
    [self.filter setInputRotation:inputRotation atIndex:0];
}

- (void)rebuildFilterChain {
    if (_source && _filter && _outputView) {
        [_source removeAllTargets];
        [_filter removeAllTargets];
        
        [_source addTarget:_filter];
        [_filter addTarget:_outputView];
    }
}

- (void)dealloc {
    self.source = nil;
}

#pragma mark Media management

- (void)setFilteredMediaID:(CMMediaID *)filteredMediaID {
    self.currentSourceMediaID = nil;
    [_filteredMediaID dispose];
    _filteredMediaID = filteredMediaID;
}

- (void)setCurrentSourceMediaID:(CMMediaID *)currentSourceMediaID {
    _currentSourceMediaID = currentSourceMediaID;
    
    AVAsset *asset = [AVAsset assetWithURL:self.originalMediaID.url];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    self.outputSize = size;
    self.inputRotation = [self rotationForTrack:videoTrack];
    
    self.source = currentSourceMediaID ? [self movieWithMedia:currentSourceMediaID] : nil;
}

- (GPUImageMovie *)movieWithMedia:(CMMediaID *)mediaID {
    GPUImageMovie *movie = [[GPUImageMovie alloc] initWithURL:mediaID.url];
    movie.shouldSmoothlyScaleOutput = YES;
    movie.playAtActualSpeed = YES;
    movie.shouldRepeat = YES;
    [movie forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(1000, 1000)];
    return movie;
}

#pragma mark UI

- (void)setUIBlockCount:(NSInteger)UIBlockCount {
    _UIBlockCount = UIBlockCount;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.blockView.alpha = (UIBlockCount == 0) ? 0 : 1;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark Collection View

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.allFilters.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FilterThumbnailCollectionViewCell *thumbnail = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    thumbnail.input = self.thumbnail;
    thumbnail.filter = [self.allFilters[indexPath.item] createFilter];
    return thumbnail;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.currentFilterInfo = self.allFilters[indexPath.item];
}

#pragma mark Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.outputView.frame = self.outputView.superview.bounds;
    UICollectionViewFlowLayout *flow = (id)self.collectionView.collectionViewLayout;
    flow.itemSize = CGSizeMake(self.collectionView.bounds.size.height, self.collectionView.bounds.size.height);
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark Actions

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.filteredMediaID dispose];
}

- (IBAction)apply:(id)sender {
    [self applyWithCallback:^{
        
    }];
}

- (void)applyWithCallback:(void(^)())callback {
    self.UIBlockCount++;
    GPUImageFilter *filter = self.filter;
    self.filter = nil; // take the filter out of the chain
    [self transcodeMedia:self.filteredMediaID ? : self.originalMediaID withFilter:filter callback:^(CMMediaID *newMediaID) {
        if (newMediaID) {
            NSLog(@"new media: %@", newMediaID.url);
            self.filteredMediaID = newMediaID;
            self.currentSourceMediaID = newMediaID;
            [self.source startProcessing];
            self.currentFilterInfo = self.allFilters.firstObject;
        } else {
            NSLog(@"FilterPickerViewController transcodeMedia: failed!!!"); // TODO: show something
        }
        self.UIBlockCount--;
        callback();
    }];
}

- (IBAction)applyAndClose:(id)sender {
    [self applyWithCallback:^{
        [self.originalMediaID dispose];
        [self dismissViewControllerAnimated:YES completion:nil];
        self.callback(self.filteredMediaID);
    }];
}

#pragma mark Transcoding

- (void)transcodeMedia:(CMMediaID *)mediaID withFilter:(GPUImageFilter *)filter callback:(void(^)(CMMediaID *newMediaID))callback {
    GPUImageMovie *movie = [[GPUImageMovie alloc] initWithURL:mediaID.url];
    movie.playAtActualSpeed = NO;
    CMMediaID *newMedia = [[CMMediaStore shared] emptyMediaIDWithFileExtension:@"m4v"];
    GPUImageMovieWriter *writer = [[GPUImageMovieWriter alloc] initWithMovieURL:newMedia.url size:self.outputSize];
    
    [movie addTarget:filter];
    [filter addTarget:writer];
    
    writer.shouldPassthroughAudio = YES;
    if ([self videoAtURLHasAudio:mediaID.url]) {
        movie.audioEncodingTarget = writer;
    }
    [movie enableSynchronizedEncodingUsingMovieWriter:writer];
    
    writer.completionBlock = ^{
        [writer finishRecording];
        [filter removeTarget:writer]; // this is okay
        [movie removeTarget:filter];
        [movie cancelProcessing];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(newMedia);
            writer.completionBlock = nil;
        });
        /*[writer finishRecordingWithCompletionHandler:^{
            [filter removeTarget:writer]; // this is okay
            [movie removeTarget:filter];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(newMedia);
                writer.completionBlock = nil;
            });
        }];*/
    };
    writer.failureBlock = ^(NSError *err) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(nil);
        });
    };
    
    [writer startRecording];
    [movie startProcessing];
}

- (BOOL)videoAtURLHasAudio:(NSURL *)url {
    AVAsset *anAsset = [AVAsset assetWithURL:url];
    return [anAsset tracksWithMediaType:AVMediaTypeAudio].count > 0;
}

#pragma mark Orientation crap

// adapted from http://stackoverflow.com/questions/26740964/gpuimagemovie-not-respecting-imageorientation

- (GPUImageRotationMode)rotationForTrack:(AVAssetTrack *)videoTrack {
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];
    
    if (size.width == txf.tx && size.height == txf.ty)
        return kGPUImageRotate180;
    else if (txf.tx == 0 && txf.ty == 0)
        return kGPUImageNoRotation;
    else if (txf.tx == 0 && txf.ty == size.width)
        return kGPUImageRotateLeft;
    else
        return kGPUImageRotateRight;
}

@end
