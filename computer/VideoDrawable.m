//
//  VideoDrawable.m
//  computer
//
//  Created by Nate Parrott on 11/24/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "VideoDrawable.h"
@import AVFoundation;
#import <ReactiveCocoa.h>
#import "FilterPickerViewController.h"

@interface VideoDrawable ()

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
@property (nonatomic) AVPlayerLayer *playerLayer;
@property (nonatomic) AVPlayerItemStatus playerItemStatus;
@property (nonatomic) FrameTime *videoDuration;
@property (nonatomic) CGSize sizeCache;

@property (nonatomic) AVAssetImageGenerator *snapshotGenerator;
@property (nonatomic) UIImageView *snapshotView;

@end

@implementation VideoDrawable

#pragma mark Media

- (void)setup {
    [super setup];
    RAC(self, playerItemStatus) = [[[RACObserve(self, playerItem) map:^id(AVPlayerItem *value) {
        return RACObserve(value, status);
    }] switchToLatest] deliverOnMainThread];
}

- (void)setMedia:(CMMediaID *)media {
    _media = media;
    
    self.sizeCache = CGSizeZero;
    
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
    [super setUseTimeForStaticAnimations:useTimeForStaticAnimations];
    if (!useTimeForStaticAnimations) {
        [self.player play];
    } else {
        [self.player pause];
    }
}

- (void)setTime:(FrameTime *)time {
    [super setTime:time];
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
        self.sizeCache = self.playerItem.presentationSize;
        [self updateAspectRatio:self.playerItem.presentationSize.width / self.playerItem.presentationSize.height];
        self.playerLayer.frame = self.bounds;
        self.videoDuration = [[FrameTime alloc] initWithFrame:self.playerItem.duration.value atFPS:self.playerItem.duration.timescale];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.snapshotView.frame = self.bounds;
}

#pragma mark Options

- (NSArray <__kindof QuickCollectionItem*> *)optionsItems {
    __weak VideoDrawable *weakSelf = self;
    QuickCollectionItem *filter = [QuickCollectionItem new];
    filter.label = NSLocalizedString(@"Filter…", @"");
    filter.action = ^{
        [weakSelf addFilter];
    };
    return [[super optionsItems] arrayByAddingObject:filter];
}

- (void)addFilter {
    __weak VideoDrawable *weakSelf = self;
    FilterPickerViewController *picker = [FilterPickerViewController filterPickerWithMediaID:self.media callback:^(CMMediaID *newMediaID) {
        weakSelf.media = newMediaID;
    }];
    [self.vcForPresentingModals presentViewController:picker animated:YES completion:nil];
}

#pragma mark Lifecyle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Coding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.videoDuration = [aDecoder decodeObjectForKey:@"videoDuration"];
    self.media = [aDecoder decodeObjectForKey:@"media"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.media forKey:@"media"];
    [aCoder encodeObject:self.videoDuration forKey:@"videoDuration"];
}

#pragma mark Snapshotting
- (void)setPreparedForStaticScreenshot:(BOOL)preparedForStaticScreenshot {
    [super setPreparedForStaticScreenshot:preparedForStaticScreenshot];
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
