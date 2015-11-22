//
//  GifOptimizer.m
//  computer
//
//  Created by Nate Parrott on 11/7/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "GifOptimizer.h"

int gifsicle_main(int argc, char *argv[]);

@implementation GifOptimizer

+ (void)optimizeGifAtPath:(NSString *)path doneBlock:(void(^)())doneBlock {
    static NSLock *lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [NSLock new];
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [lock lock];
        int argc = 9;
        const char *argv[] = {"", path.UTF8String, "--colors", "256", "--threads=2", "--lossy=120", "-O3", "-o", path.UTF8String};
        gifsicle_main(argc, (char**)argv);
        [lock unlock];
        dispatch_async(dispatch_get_main_queue(), ^{
            doneBlock();
        });
    });
}

@end
