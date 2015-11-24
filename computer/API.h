//
//  API.h
//  computer
//
//  Created by Nate Parrott on 11/23/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse.h>

@interface API : NSObject

+ (instancetype)shared;

- (NSString *)getShareableURL;
- (void)uploadParseFile:(PFFile *)file atShareableURL:(NSString *)url callback:(void (^)(BOOL success, NSError *error))callback;

@end
