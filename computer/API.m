//
//  API.m
//  computer
//
//  Created by Nate Parrott on 11/23/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "API.h"
#import "ProgressBarWindow.h"

@implementation API

+ (instancetype)shared {
    static API *api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        api = [API new];
    });
    return api;
}

- (NSURLComponents *)URLComponents {
    NSURLComponents *comps = [NSURLComponents componentsWithString:@"https://content-1138.appspot.com"];
    return comps;
}

- (NSString *)getShareableURL {
    uuid_t uuid;
    [[NSUUID UUID] getUUIDBytes:(void*)&uuid];
    NSData *b64Name = [[NSData dataWithBytes:uuid length:sizeof(uuid)] base64EncodedDataWithOptions:0];
    NSString *name = [[NSString alloc] initWithData:b64Name encoding:NSUTF8StringEncoding];
    NSURLComponents *comps = [self URLComponents];
    comps.path = [@"/" stringByAppendingString:name];
    return comps.URL.absoluteString;
}

- (void)uploadParseFile:(PFFile *)file atShareableURL:(NSString *)url callback:(void (^)(BOOL success, NSError *error))callback {
    ProgressBarWindowItem *progressItem = [ProgressBarWindowItem new];
    progressItem.minDisplayTime = 0.1;
    progressItem.title = NSLocalizedString(@"Uploading GIF…", @"");
    progressItem.progress = 0;
    
    NSURLComponents *shareableURLComps = [NSURLComponents componentsWithString:url];
    NSString *name = [shareableURLComps.path substringFromIndex:1];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSURLComponents *comps = [self URLComponents];
            comps.path = @"/register";
            comps.queryItems = @[
                                 [NSURLQueryItem queryItemWithName:@"name" value:name],
                                 [NSURLQueryItem queryItemWithName:@"fileUrl" value:file.url]
                                 ];
            NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:comps.URL];
            req.HTTPMethod = @"POST";
            [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (response) {
                    NSError *err = nil;
                    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
                    if (result) {
                        BOOL success = [[result objectForKey:@"success"] boolValue];
                        if (success) {
                            ProgressBarWindowItem *success = [ProgressBarWindowItem new];
                            success.progress = 1;
                            success.minDisplayTime = 1;
                            success.title = NSLocalizedString(@"Finished uploading GIF", @"");
                            [[ProgressBarWindow shared] performSelectorOnMainThread:@selector(addItems:) withObject:@[success] waitUntilDone:NO];
                        }
                        callback(success, nil);
                    } else {
                        callback(NO, err);
                    }
                } else {
                    callback(NO, error);
                }
            }] resume];
        } else {
            callback(NO, error);
        }
    } progressBlock:^(int percentDone) {
        progressItem.progress = percentDone / 100.0;
    }];
    
    [[ProgressBarWindow shared] addItems:@[progressItem]];
}

@end
