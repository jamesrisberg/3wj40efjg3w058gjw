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
        // self.tableView.separatorColor = [UIColor colorWithWhite:0.2 alpha:0.0];
    }
    return _tableView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tableView.frame = self.bounds;
}

- (CGSize)intrinsicContentSize {
    CGFloat height = MIN(self.tableView.contentSize.height, round([UIScreen mainScreen].bounds.size.height * 0.3));
    return CGSizeMake(UIViewNoIntrinsicMetric, height);
}

#pragma mark TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.models.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    OptionsViewCellModel *model = self.models[section];
    return model.title;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    UIView *bgView = [UIView new];
    bgView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.8];
    header.backgroundView = bgView;
    header.textLabel.textColor = [UIColor whiteColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OptionsViewCellModel *model = self.models[indexPath.section];
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
    return [self.models[indexPath.section] onSelect] != nil;
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
    OptionsViewCellModel *model = self.models[indexPath.section];
    // for some reason, dispatch_after is needed when presenting modals or something...
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (model.onSelect) model.onSelect((id)[tableView cellForRowAtIndexPath:indexPath]);
    });
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
