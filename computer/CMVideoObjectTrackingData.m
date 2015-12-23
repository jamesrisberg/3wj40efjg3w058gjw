//
//  CMVideoObjectTrackingData.m
//  computer
//
//  Created by Nate Parrott on 12/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "CMVideoObjectTrackingData.h"
#import "CMLayoutBase.h"
#import "Keyframe.h"

@interface CMVideoTrackedObject ()

@property (nonatomic) NSString *name, *uuid;

@end

@implementation CMVideoTrackedObject

- (instancetype)init {
    self = [super init];
    self.uuid = [NSUUID UUID].UUIDString;
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    self.name = [aDecoder decodeObjectForKey:@"name"];
    self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
}

- (CMLayoutBase *)layoutBaseAtTime:(FrameTime *)time {
    CMLayoutBase *b = [CMLayoutBase new];
    b.visible = YES;
    b.center = CGPointMake(0, sin(time.time * 2 * M_PI));
    b.rotation = cos(time.time * 5 * M_PI) * 0.3;
    b.scale = 1;
    return b;
}

@end




@interface CMVideoObjectTrackingData ()

@property (nonatomic) NSDictionary<NSString*, CMVideoTrackedObject*> *objects;

@end

@implementation CMVideoObjectTrackingData

+ (void)trackObjectsInVideo:(NSURL *)video callback:(void(^)(CMVideoObjectTrackingData *result))callback {
    CMVideoObjectTrackingData *data = [CMVideoObjectTrackingData new];
    
    CMVideoTrackedObject *obj = [CMVideoTrackedObject new];
    obj.name = @"Face #1";
    data.objects = @{obj.uuid: obj};
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        callback(data);
    });
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    self.objects = [aDecoder decodeObjectForKey:@"objects"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.objects forKey:@"objects"];
}

@end
