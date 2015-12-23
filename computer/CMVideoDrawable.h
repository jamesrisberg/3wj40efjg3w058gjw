//
//  CMVideoDrawable.h
//  computer
//
//  Created by Nate Parrott on 12/4/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMDrawable.h"
@class CMMediaID;
#import "CMVideoObjectTrackingData.h"

@interface CMVideoDrawable : CMDrawable

@property (nonatomic) CMMediaID *media;
@property (nonatomic,readonly) FrameTime *videoDuration;
@property (nonatomic,readonly) CGSize videoSize;
@property (nonatomic,readonly) CMVideoObjectTrackingData *trackingData;

- (NSDictionary<NSString*,NSString*> *)objectToDrawableTrackingMap;

@end
