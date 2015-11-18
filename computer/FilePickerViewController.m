//
//  FilePickerViewController.m
//  computer
//
//  Created by Nate Parrott on 9/29/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "FilePickerViewController.h"
#import "CMDocument.h"
#import "ConvenienceCategories.h"
#import "ExpandingButton.h"
#import "EditorViewController.h"
#import "FilePreviewViewController.h"
#import "SwipeMenuView.h"

const CGFloat _FilePickerPreviewViewAspectRatio = 1.61803398875; // golden ratio b/c why tf not
const CGFloat _FilePickerPreviewLineSpacing = 7;

@interface _FilePickerPreviewView : SwipeMenuView <UIViewControllerPreviewingDelegate>

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) NSURL *fileURL;
@property (nonatomic,copy) void (^onTapped)();
@property (nonatomic,copy) void (^onDelete)();
@property (nonatomic,weak) id<UIViewControllerPreviewing> previewingContext;

@end

@implementation _FilePickerPreviewView

- (instancetype)init {
    self = [super init];
    
    self.imageView = [UIImageView new];
    self.imageView.backgroundColor = [UIColor whiteColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.view = self.imageView;
    
    UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    self.imageView.userInteractionEnabled = YES;
    [self.imageView addGestureRecognizer:tapRec];
    
    self.clipsToBounds = YES;
    
    __weak _FilePickerPreviewView *weakSelf = self;
    SwipeMenuViewAction *delete = [SwipeMenuViewAction new];
    delete.icon = [UIImage imageNamed:@"Delete"];
    delete.title = NSLocalizedString(@"Delete", @"");
    delete.action = ^{
        weakSelf.onDelete();
    };
    self.actions = @[delete];
    
    return self;
}

- (void)tapped:(UITapGestureRecognizer *)tapRec {
    self.onTapped();
}

- (void)setFileURL:(NSURL *)fileURL {
    _fileURL = fileURL;
    self.imageView.image = nil;
    self.contentOffset = CGPointZero;
    [CMDocument loadSnapshotForDocumentAtURL:fileURL callback:^(UIImage *snapshot) {
        if ([self.fileURL isEqual:fileURL]) {
            self.imageView.image = snapshot;
        }
    }];
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    FilePreviewViewController *preview = [FilePreviewViewController new];
    preview.documentURL = self.fileURL;
    return preview;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self tapped:nil];
}

@end

@interface FilePickerViewController () <UIScrollViewDelegate>

@property (nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) NSMutableDictionary<__kindof NSURL *, __kindof _FilePickerPreviewView *> *viewsForURLs;

@property (nonatomic) NSArray<__kindof NSURL *> *fileURLs;

@end

@implementation FilePickerViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.viewsForURLs = [NSMutableDictionary new];
    
    ExpandingButton *newDocButton = [[ExpandingButton alloc] initWithBackground:[UIImage imageNamed:@"NewDocBG"] glpyh:[UIImage imageNamed:@"NewDocGlyph"]];
    [self.view addSubview:newDocButton];
    newDocButton.frame = CGRectMake(self.view.bounds.size.width - newDocButton.frame.size.width, self.view.bounds.size.height - newDocButton.frame.size.height, newDocButton.frame.size.width, newDocButton.frame.size.height);
    [newDocButton addTarget:self action:@selector(addDocument:) forControlEvents:UIControlEventTouchUpInside];
    
    [self reload];
}

#pragma mark Data

- (void)reload {
    for (UIView *view in self.viewsForURLs.allValues) {
        [view removeFromSuperview];
    }
    [_viewsForURLs removeAllObjects];
    NSURL *dirURL = [CMDocument documentsURL];
    
    NSArray *fileURLs = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[dirURL path] error:nil] map:^id(id obj) {
        if ([[obj pathExtension] isEqualToString:@"computerdoc"]) {
            return [dirURL URLByAppendingPathComponent:obj];
        } else {
            return nil;
        }
    }];
    NSDictionary *lastModDates = [fileURLs mapToDict:^id(__autoreleasing id *key) {
        return [[NSFileManager defaultManager] attributesOfItemAtPath:[(NSURL *)*key path] error:nil][NSFileModificationDate] ? : [NSDate date];
    }];
    fileURLs = [fileURLs sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSDate *date1 = lastModDates[obj1];
        NSDate *date2 = lastModDates[obj2];
        return [date2 compare:date1];
    }];
    self.fileURLs = fileURLs;
    // NSLog(@"%@", dirURL);
}

- (void)setFileURLs:(NSArray<__kindof NSURL *> *)fileURLs {
    _fileURLs = fileURLs;
    [self updateRowsWithAnimationCompletion:nil];
}

- (void)setFileURLs:(NSArray<__kindof NSURL *> *)fileURLs withAnimationCompletion:(void(^)())completion {
    _fileURLs = fileURLs;
    [self updateRowsWithAnimationCompletion:completion];
}

#pragma mark Layout

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.frame = self.view.bounds;
    [self updateRowsWithAnimationCompletion:nil];
}

- (CGFloat)rowHeight {
    return round(self.scrollView.frame.size.width / _FilePickerPreviewViewAspectRatio);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateRowsWithAnimationCompletion:nil];
}

- (void)updateRowsWithAnimationCompletion:(void(^)())animationCompletion {
    NSTimeInterval duration = 0.3;
    
    UIScrollView *scrollView = self.scrollView;
    CGFloat rowHeight = [self rowHeight];
    
    CGSize contentSize = CGSizeMake(self.scrollView.frame.size.width, (self.fileURLs.count + 1) * _FilePickerPreviewLineSpacing + self.fileURLs.count * [self rowHeight]);
    if (!CGSizeEqualToSize(contentSize, scrollView.contentSize)) {
        scrollView.contentSize = contentSize;
    }
    
    NSInteger topIndex = floor(scrollView.contentOffset.y - _FilePickerPreviewLineSpacing) / (rowHeight + _FilePickerPreviewLineSpacing);
    topIndex = MAX(0, topIndex);
    NSMutableSet <__kindof NSURL*> *visibleURLs = [NSMutableSet new];
    
    NSInteger filenameCount = _fileURLs.count;
    for (NSInteger i=topIndex; i<filenameCount; i++) {
        CGFloat top = _FilePickerPreviewLineSpacing + i * (rowHeight + _FilePickerPreviewLineSpacing);
        NSURL *url = _fileURLs[i];
        
        _FilePickerPreviewView *view = _viewsForURLs[url];
        BOOL flyingIn = NO;
        if (!view) {
            view = [self viewForIndex:i];
            _viewsForURLs[url] = view;
            [scrollView insertSubview:view atIndex:0];
            view.previewingContext = [self registerForPreviewingWithDelegate:view sourceView:view];
            if (animationCompletion) {
                if (i == 0) {
                    // fly in from top:
                    flyingIn = YES;
                    view.frame = CGRectMake(0, -rowHeight, self.scrollView.bounds.size.width, rowHeight);
                } else {
                    view.alpha = 0;
                }
            }
        }
        [visibleURLs addObject:url];
        CGRect frame = CGRectMake(0, top, self.scrollView.bounds.size.width, rowHeight);
        if (animationCompletion) {
            UIViewAnimationOptions options = flyingIn ? UIViewAnimationOptionCurveEaseOut : 0;
            NSTimeInterval delay = flyingIn ? duration * 0.4 : 0;
            [UIView animateWithDuration:duration-delay delay:delay options:options animations:^{
                view.frame = frame;
                view.alpha = 1;
            } completion:nil];
        } else {
            view.frame = frame;
        }
        
        CGFloat bottom = top + rowHeight;
        if (bottom >= scrollView.contentOffset.y + scrollView.bounds.size.height + rowHeight + 100) {
            break;
        }
    }
    
    NSSet *addedURLs = [NSSet setWithArray:_viewsForURLs.allKeys];
    for (NSURL *url in addedURLs) {
        if (![visibleURLs containsObject:url]) {
            _FilePickerPreviewView *view = _viewsForURLs[url];
            if (animationCompletion) {
                [UIView animateWithDuration:0.3 animations:^{
                    view.alpha = 0;
                } completion:^(BOOL finished) {
                    [view removeFromSuperview];
                }];
            } else {
                [view removeFromSuperview];
            }
            [_viewsForURLs removeObjectForKey:url];
            [self unregisterForPreviewingWithContext:view.previewingContext];
        }
    }
    
    if (animationCompletion) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            animationCompletion(); // TODO: don't rely on this; doesn't work with e.g. slow animations mode
        });
    }
}

- (_FilePickerPreviewView *)viewForIndex:(NSInteger)index {
    _FilePickerPreviewView *view = [_FilePickerPreviewView new];
    NSURL *url = self.fileURLs[index];
    __weak FilePickerViewController *weakSelf = self;
    __weak _FilePickerPreviewView *weakView = view;
    view.onTapped = ^{
        [weakSelf openDocumentAtURL:url];
    };
    view.onDelete = ^{
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        [weakSelf.viewsForURLs removeObjectForKey:url];
        NSMutableArray *urls = weakSelf.fileURLs.mutableCopy;
        [weakView.superview sendSubviewToBack:weakView.superview];
        [UIView animateWithDuration:0.3 animations:^{
            weakView.transform = CGAffineTransformMakeScale(0.8, 0.2);
            weakView.alpha = 0;
        } completion:^(BOOL finished) {
            [weakView removeFromSuperview];
        }];
        [urls removeObject:url];
        [weakSelf setFileURLs:urls withAnimationCompletion:^{
        }];
    };
    view.fileURL = url;
    return view;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reload];
}

#pragma mark Actions

- (IBAction)addDocument:(id)sender {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self addDocument:sender];
        }];
    } else {
        NSMutableArray *fileURLs = self.fileURLs.mutableCopy;
        NSURL *newDocURL = [CMDocument URLForNewDocument];
        [fileURLs insertObject:newDocURL atIndex:0];
        __weak FilePickerViewController *weakSelf = self;
        [self setFileURLs:fileURLs withAnimationCompletion:^{
            [weakSelf openDocumentAtURL:newDocURL];
        }];
    }
}

- (void)openDocumentAtURL:(NSURL *)url {
    EditorViewController *editorVC = [EditorViewController editor];
    editorVC.document = [[CMDocument alloc] initWithFileURL:url];
    _FilePickerPreviewView *previewView = self.viewsForURLs[url];
    [editorVC presentFromSnapshot:previewView.imageView inViewController:self];
}

@end
