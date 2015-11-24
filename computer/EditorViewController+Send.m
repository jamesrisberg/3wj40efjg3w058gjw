//
//  EditorViewController+Send.m
//  computer
//
//  Created by Nate Parrott on 11/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EditorViewController+Send.h"
#import <Parse.h>
#import "API.h"
#import "computer-Swift.h"

@implementation EditorViewController (Send)


- (void)presentMailComposer:(MFMailComposeViewController *)composer {
    composer.mailComposeDelegate = self;
    [self presentViewController:composer animated:YES completion:nil];
}

- (void)presentMessageComposer:(MFMessageComposeViewController *)composer {
    composer.messageComposeDelegate = self;
    [self presentViewController:composer animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)shareGIFWithFileURL:(NSURL *)url callback:(void(^)(NSString *shareableURL))callback {
    NSString *shareableURL = [[API shared] getShareableURL];
    callback(shareableURL);
    
    PFFile *file = [PFFile fileWithName:@"Content.gif" contentsAtPath:url.path];
    [[API shared] uploadParseFile:file atShareableURL:shareableURL callback:^(BOOL success, NSError *error) {
        if (!success) {
            UIAlertController *err = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Couldn't Upload GIF", @"") message:NSLocalizedString(@"The URL we gave you won't work.", @"") preferredStyle:UIAlertControllerStyleActionSheet];
            [err addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Okay", @"") style:UIAlertActionStyleCancel handler:nil]];
            [[NPSoftModalPresentationController getViewControllerForPresentationInWindow:[[UIApplication sharedApplication] windows].firstObject] presentViewController:err animated:YES completion:nil];
        }
    }];
}

@end
