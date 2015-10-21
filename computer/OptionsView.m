//
//  OptionsView.m
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "OptionsView.h"
#import "Drawable.h"

@implementation OptionsViewCellModel

- (instancetype)init {
    self = [super init];
    self.cellClass = [OptionsTableViewCell class];
    return self;
}

@end

@interface OptionsView () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation OptionsView

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)setUnderlyingBlurEffect:(UIBlurEffect *)underlyingBlurEffect {
    _underlyingBlurEffect = underlyingBlurEffect;
    self.tableView.separatorEffect = [UIVibrancyEffect effectForBlurEffect:underlyingBlurEffect];
}

- (void)setModels:(NSArray *)models {
    _models = models;
    [self.tableView reloadData];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        [self addSubview:self.tableView];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.showsVerticalScrollIndicator = NO;
        self.tableView.decelerationRate = UIScrollViewDecelerationRateFast;
    }
    return _tableView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tableView.frame = self.bounds;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, round([UIScreen mainScreen].bounds.size.height * 0.3));
}

#pragma mark TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OptionsViewCellModel *model = self.models[indexPath.row];
    NSString *reuseId = NSStringFromClass(model.cellClass);
    OptionsTableViewCell *cell = nil; // [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!cell) {
        Class cls = model.cellClass;
        cell = [[cls alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
        cell.underlyingBlurEffect = self.underlyingBlurEffect;
    }
    if (model.onCreate) model.onCreate(cell);
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.models[indexPath.row] onSelect] != nil;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OptionsViewCellModel *model = self.models[indexPath.row];
    // for some reason, dispatch_after is needed when presenting modals or something...
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (model.onSelect) model.onSelect((id)[tableView cellForRowAtIndexPath:indexPath]);
    });
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
