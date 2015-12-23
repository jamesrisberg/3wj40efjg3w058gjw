//
//  CMVideoObjectTrackingData.h
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

@import UIKit;
@class FrameTime;
@class CMVideoTrackedObject;

@interface CMVideoObjectTrackingData : NSObject <NSCoding>

+ (void)trackObjectsInVideo:(NSURL *)video callback:(void(^)(CMVideoObjectTrackingData *result))callback;
@property (nonatomic,readonly) NSDictionary<NSString*, CMVideoTrackedObject*> *objects;

@end
