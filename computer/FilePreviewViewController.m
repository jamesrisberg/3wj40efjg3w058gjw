//
//  FilePreviewViewController.m
//  computer
//
//  Created by Nate Parrott on 10/28/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FilePreviewViewController.h"

@interface FilePreviewViewController ()

@property (nonatomic) UIImageView *imageView;

@end

@implementation FilePreviewViewController

- (void)setDocumentURL:(NSURL *)documentURL {
    _documentURL = documentURL;
    if (!self.imageView) {
        self.imageView = [UIImageView new];
        [self.view addSubview:self.imageView];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.backgroundColor = [UIColor whiteColor];
        [CMDocument loadSnapshotForDocumentAtURL:_documentURL callback:^(UIImage *snapshot) {
            self.imageView.image = snapshot;
        }];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.imageView.frame = self.view.bounds;
}

@end
