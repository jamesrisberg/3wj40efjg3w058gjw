#import <UIKit/UIKit.h>

@interface ShowcaseFilterListController : UITableViewController

@property (nonatomic) UIImage *image;
@property (nonatomic,copy) void(^callback)(UIImage *);

@end
