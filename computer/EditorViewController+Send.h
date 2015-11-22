//
//  EditorViewController+Send.h
//  computer
//
//  Created by Nate Parrott on 11/22/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "EditorViewController.h"
@import MessageUI;

@interface EditorViewController (Send) <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

- (void)presentMailComposer:(MFMailComposeViewController *)composer;
- (void)presentMessageComposer:(MFMessageComposeViewController *)composer;
- (void)shareGIFWithFileURL:(NSURL *)url callback:(void(^)(NSString *shareableURL))callback;

@end
