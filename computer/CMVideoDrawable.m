//
//  CMVideoDrawable.m
//  computer
//
//  Created by Nate Parrott on 12/4/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMVideoDrawable.h"
#import <ReactiveCocoa.h>
#import "CMMediaStore.h"
@import AVFoundation;
#import "PropertyViewTableCell.h"
#import "computer-Swift.h"
#import "FilterPickerViewController.h"
#import "EditorViewController.h"
#import "CanvasEditor.h"
#import "ConvenienceCategories.h"
#import "CGPointExtras.h"

@interface _CMVideoDrawableView : CMDrawableView

@property (nonatomic) CMMediaID *media;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) AVPlayerItemStatus playerItemStatus;
@property (nonatomic) FrameTime *videoDuration;

@property (nonatomic) AVAssetImageGenerator *snapshotGenerator;
@property (nonatomic) UIImageView *snapshotView;

@property (nonatomic) BOOL useTimeForStaticAnimations;
@property (nonatomic) FrameTime *time;
@property (nonatomic) BOOL preparedForStaticScreenshot;

@end

@implementation _CMVideoDrawableView

- (instancetype)init {
    self = [super init];
    RAC(self, playerItemStatus) = [[[RACObserve(self, playerItem) map:^id(AVPlayerItem *value) {
        return RACObserve(value, status);
    }] switchToLatest] deliverOnMainThread];
    return self;
}


- (void)setMedia:(CMMediaID *)media {
    if (media == _media) return;
    _media = media;
    
    self.playerItem = [AVPlayerItem playerItemWithURL:media.url];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.player.muted = YES;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.snapshotGenerator = nil;
}

- (void)setPlayer:(AVPlayer *)player {
    [self.player pause];
    [self.player cancelPendingPrerolls];
    _player = player;
}

- (void)setPlayerLayer:(AVPlayerLayer *)playerLayer {
    [self.playerLayer removeFromSuperlayer];
    _playerLayer = playerLayer;
    [self.layer addSublayer:self.playerLayer];
    self.playerLayer.frame = self.bounds;
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    self.playerLayer.frame = self.bounds;
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    }
    _playerItem = playerItem;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
}

- (void)playbackDidFinish:(AVPlayerItem *)playerItem {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.player seekToTime:kCMTimeZero];
        if (!self.useTimeForStaticAnimations) {
            [self.player play];
        }
    });
}

- (void)setUseTimeForStaticAnimations:(BOOL)useTimeForStaticAnimations {
    _useTimeForStaticAnimations = useTimeForStaticAnimations;
    if (!useTimeForStaticAnimations) {
        [self.player play];
    } else {
        [self.player pause];
    }
}

- (void)setTime:(FrameTime *)time {
    _time = time;
    if (self.useTimeForStaticAnimations && [self.playerItem status] == AVPlayerItemStatusReadyToPlay) {
        [self seekToTime:time];
        if (self.preparedForStaticScreenshot) {
            [self updateSnapshot];
        }
    }
}

- (void)seekToTime:(FrameTime *)time {
    CMTime cmTime = [self CMTimeForTime:time];
    if (CMTimeCompare(cmTime, kCMTimeInvalid) != 0) {
        [self.player seekToTime:cmTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

- (CMTime)CMTimeForTime:(FrameTime *)time {
    NSTimeInterval seconds = time.time;
    NSTimeInterval maxSeconds = CMTimeGetSeconds(self.playerItem.duration);
    seconds = MAX(0, seconds);
    seconds = fmod(seconds, maxSeconds);
    CMTime cmTime = CMTimeMakeWithSeconds(seconds, (int32_t)time.fps ? : 1);
    return cmTime;
}

- (void)setPlayerItemStatus:(AVPlayerItemStatus)playerItemStatus {
    if (playerItemStatus == AVPlayerItemStatusReadyToPlay) {
        if (self.useTimeForStaticAnimations) {
            [self seekToTime:self.time];
        } else {
            [self.player play];
        }
        self.playerLayer.frame = self.bounds;
        self.videoDuration = [[FrameTime alloc] initWithFrame:self.playerItem.duration.value atFPS:self.playerItem.duration.timescale];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.snapshotView.frame = self.bounds;
}

#pragma mark Snapshotting
- (void)setPreparedForStaticScreenshot:(BOOL)preparedForStaticScreenshot {
    _preparedForStaticScreenshot = preparedForStaticScreenshot;
    if (preparedForStaticScreenshot) {
        if (!self.snapshotView) {
            self.snapshotView = [[UIImageView alloc] initWithFrame:self.bounds];
            [self addSubview:self.snapshotView];
        }
        [self updateSnapshot];
    } else {
        [self.snapshotView removeFromSuperview];
        self.snapshotView = nil;
        self.snapshotGenerator = nil;
    }
    self.playerLayer.hidden = preparedForStaticScreenshot;
}

- (void)updateSnapshot {
    if (!self.snapshotGenerator) {
        self.snapshotGenerator = [[AVAssetImageGenerator alloc] initWithAsset:[AVAsset assetWithURL:self.media.url]];
        self.snapshotGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        self.snapshotGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        self.snapshotGenerator.appliesPreferredTrackTransform = YES;
    }
    CMTime time = [self CMTimeForTime:self.time];
    if (CMTimeCompare(time, kCMTimeInvalid) != 0) {
        self.snapshotView.image = [UIImage imageWithCGImage:[self.snapshotGenerator copyCGImageAtTime:time actualTime:nil error:nil]];
    }
}

@end


@interface CMVideoDrawable () {
    BOOL _currentlyGeneratingObjectTrackingData;
}

@property (nonatomic) CMVideoObjectTrackingData *trackingData;
@property (nonatomic) NSMutableDictionary *objectTrackingDict; // maps [face/object ID: drawable ID]

@end

@implementation CMVideoDrawable

- (instancetype)init {
    self = [super init];
    self.objectTrackingDict = [NSMutableDictionary new];
    return self;
}

- (NSArray<NSString*>*)keysForCoding {
    return [[super keysForCoding] arrayByAddingObjectsFromArray:@[@"videoDuration", @"videoSize", @"media", @"trackingData", @"objectTrackingDict"]];
}

- (NSDictionary<NSString*,NSString*> *)objectToDrawableTrackingMap {
    return self.objectTrackingDict.copy;
}

- (__kindof CMDrawableView *)renderToView:(__kindof CMDrawableView *)existingOrNil context:(CMRenderContext *)ctx {
    _CMVideoDrawableView *v = [existingOrNil isKindOfClass:[_CMVideoDrawableView class]] ? (id)existingOrNil : [_CMVideoDrawableView new];
    [super renderToView:v context:ctx];
    v.media = self.media;
    v.preparedForStaticScreenshot = ctx.forStaticScreenshot;
    v.useTimeForStaticAnimations = ctx.useFrameTimeForStaticAnimations;
    v.time = ctx.time;
    return v;
}

- (void)setMedia:(CMMediaID *)media {
    _media = media;
    AVAsset *asset = [AVAsset assetWithURL:media.url];
    AVAssetTrack *video = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    
    NSTimeInterval t = (NSTimeInterval)CMTimeGetSeconds([AVAsset assetWithURL:media.url].duration);
    _videoDuration = [[FrameTime alloc] initWithFrame:t * 10000 atFPS:10000];
    
    _videoSize = CGRectApplyAffineTransform((CGRect){CGPointZero, video.naturalSize}, video.preferredTransform).size;
}

- (CGFloat)aspectRatio {
    return _videoSize.width * _videoSize.height ? _videoSize.width / _videoSize.height : 1;
}

- (NSArray<PropertyModel*>*)uniqueObjectPropertiesWithEditor:(CanvasEditor *)editor {
    PropertyModel *actions = [PropertyModel new];
    actions.type = PropertyModelTypeButtons;
    actions.title = NSLocalizedString(@"Actions", @"");
    actions.buttonTitles = @[NSLocalizedString(@"Filter", @"")];
    actions.buttonSelectorNames = @[@"filter:"];
    
    return [[super uniqueObjectPropertiesWithEditor:editor] arrayByAddingObjectsFromArray:@[actions]];
}

- (NSArray<PropertyGroupModel*>*)propertyGroupsWithEditor:(CanvasEditor *)editor {
    return [[super propertyGroupsWithEditor:editor] arrayByAddingObject:[self objectTrackingPropertyGroup]];
}

- (void)filter:(PropertyViewTableCell *)sender {
    FilterPickerViewController *picker = [FilterPickerViewController filterPickerWithMediaID:self.media callback:^(CMMediaID *newMediaID) {
        [sender.transactionStack doTransaction:[[CMTransaction alloc] initWithTarget:self action:^(id target) {
            self.media = newMediaID;
        } undo:^(id target) {
            NSLog(@"Video filtering operations can't be undone yet");
        }]];
    }];
    picker.snapshotsForImagePicker = [sender.editor.canvas snapshotsOfAllDrawables];
        
    [[NPSoftModalPresentationController getViewControllerForPresentationInWindow:[UIApplication sharedApplication].windows.firstObject] presentViewController:picker animated:YES completion:nil];
}

- (NSString *)drawableTypeDisplayName {
    return NSLocalizedString(@"Video", @"");
}

- (FrameTime *)maxTime {
    return self.videoDuration;
}

#pragma mark Object tracking

- (void)createTrackingData:(PropertyViewTableCell *)cell {
    EditorViewController *editor = cell.editor;
    if (!_currentlyGeneratingObjectTrackingData) {
        _currentlyGeneratingObjectTrackingData = YES;
        [editor updatePropertyEditors];
        [CMVideoObjectTrackingData trackObjectsInVideo:self.media.url callback:^(CMVideoObjectTrackingData *result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _currentlyGeneratingObjectTrackingData = NO;
                self.trackingData = result;
                [editor updatePropertyEditors];
            });
        }];
    }
}

- (PropertyGroupModel *)objectTrackingPropertyGroup {
    PropertyGroupModel *g = [PropertyGroupModel new];
    g.title = NSLocalizedString(@"Face Tracking", @"");
    
    if (self.trackingData) {
        if (self.trackingData.objects.count > 0) {
            PropertyModel *label = [PropertyModel new];
            label.type = PropertyModelTypeLabel;
            label.labelText = NSLocalizedString(@"Select objects to move with each face", @"");
            NSArray *objectModels = [self.trackingData.objects.allValues map:^id(id obj) {
                PropertyModel *model = [PropertyModel new];
                model.type = PropertyModelTypeAnotherDrawable;
                model.title = [obj name];
                model.key = [@"objectTrackingDict." stringByAppendingString:[obj uuid]];
                return model;
            }];
            g.properties = [objectModels arrayByAddingObject:label];
        } else {
            PropertyModel *label = [PropertyModel new];
            label.type = PropertyModelTypeLabel;
            label.labelText = NSLocalizedString(@"Couldn't find any faces", @"");
            g.properties = @[label];
        }
    } else if (_currentlyGeneratingObjectTrackingData) {
        PropertyModel *label = [PropertyModel new];
        label.type = PropertyModelTypeLabel;
        label.labelText = NSLocalizedString(@"Scanning video…", @"");
        g.properties = @[label];
    } else {
        PropertyModel *button = [PropertyModel new];
        button.type = PropertyModelTypeButtons;
        button.buttonSelectorNames = @[@"createTrackingData:"];
        button.buttonTitles = @[NSLocalizedString(@"Scan Video for Faces", @"")];
        g.properties = @[button];
    }
    return g;
}

- (NSDictionary<NSString*,CMLayoutBase*>*)layoutBasesForViewsWithKeysInRenderContext:(CMRenderContext *)ctx {
    if (self.objectTrackingDict.count) {
        NSMutableDictionary *bases = [NSMutableDictionary new];
        for (NSString *objectId in self.objectTrackingDict) {
            NSString *drawableKey = self.objectTrackingDict[objectId];
            CMDrawableKeyframe *keyframe = [self.keyframeStore interpolatedKeyframeAtTime:ctx.time];
            CGSize size = CMSizeWithDiagonalAndAspectRatio(self.boundsDiagonal, self.aspectRatio);
            CMLayoutBase *base = [self.trackingData.objects[objectId] layoutBaseAtTime:ctx.time];
            // transform base for self:
            CGFloat xScale = size.width * cos(keyframe.rotation) + size.height *  sin(keyframe.rotation);
            CGFloat yScale = size.width * sin(keyframe.rotation) + size.height * cos(keyframe.rotation);
            base.center = CGPointMake(base.center.x * xScale + keyframe.center.x, base.center.y * yScale + keyframe.center.y);
            base.scale *= keyframe.scale;
            base.rotation += keyframe.rotation;
            bases[drawableKey] = base;
        }
        return bases;
    }
    return nil;
}

@end
