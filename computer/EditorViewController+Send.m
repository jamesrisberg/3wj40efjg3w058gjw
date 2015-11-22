//
//  EditorViewController+Send.m
//  computer
//
//  Created by Nate Parrott on 11/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EditorViewController+Send.h"

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

@end
