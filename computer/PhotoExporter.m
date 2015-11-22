//
//  PhotoExporter.m
//  computer
//
//  Created by Nate Parrott on 10/24/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "PhotoExporter.h"
#import "EditorViewController.h"

@implementation PhotoExporter

- (void)start {
    UIGraphicsBeginImageContextWithOptions(self.cropRect.size, NO, 0);
    [self _askDelegateToRenderFrame:self.defaultTime];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    [self.parentViewController presentViewController:activityVC animated:YES completion:nil];
    [self.delegate exporterDidFinish:self];
}

@end
