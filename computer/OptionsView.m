//
//  OptionsView.m
//  computer
//
//  Created by Nate Parrott on 9/3/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "OptionsView.h"

@implementation OptionsViewCellModel

@end

@interface OptionsView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSArray *models;

@end

@implementation OptionsView

- (instancetype)init {
    self = [super init];
    
    return self;
}

- (void)setDrawable:(Drawable *)drawable {
    self.models = [drawable optionsCellModels];
}

- (void)setModels:(NSArray *)models {
    _models = models;
    [self.tableView reloadData];
}

- (UITableView *)tableView {
    if (!_tableView) {
        self.tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        [self addSubview:self.tableView];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.backgroundColor = [UIColor clearColor];
    }
    return _tableView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tableView.frame = self.bounds;
}

#pragma mark TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OptionsViewCellModel *model = self.models[indexPath.row];
    NSString *reuseId = NSStringFromClass(model.cellClass);
    OptionsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (!reuseId) {
        cell = [[OptionsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    if (model.onCreate) model.onCreate(cell);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end
