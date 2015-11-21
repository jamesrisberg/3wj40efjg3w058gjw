//
//  SimplePickerViewController.m
//  computer
//
//  Created by Nate Parrott on 11/20/15.
//  Copyright © 2015 Nate Parrott. All rights reserved.
//

#import "SimplePickerViewController.h"
#import "computer-Swift.h"

@implementation SimplePickerModel

@end



@interface SimplePickerViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) IBOutlet UILabel *promptLabel;
@property (nonatomic,copy) void(^callback)(SimplePickerModel *modelOrNil);

@end

@implementation SimplePickerViewController

+ (SimplePickerViewController *)picker {
    return [[SimplePickerViewController alloc] initWithNibName:@"SimplePickerViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)setPrompt:(NSString *)prompt {
    _prompt = prompt;
    [self loadView];
    self.promptLabel.text = prompt;
}

- (void)setModels:(NSArray<__kindof SimplePickerModel *> *)models {
    _models = models;
    [self.tableView reloadData];
}

- (void)setSelectedModel:(SimplePickerModel *)selectedModel {
    _selectedModel = selectedModel;
    
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if (selectedModel) {
        NSInteger index = [self.models indexOfObject:selectedModel];
        NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.selectedModel) {
        NSInteger index = [self.models indexOfObject:self.selectedModel];
        NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.textLabel.text = [self.models[indexPath.row] title];
    cell.accessoryType = [self.models[indexPath.row] isEqual:self.selectedModel] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedModel = self.models[indexPath.row];
    [self dismissViewControllerAnimated:YES completion:nil];
    self.callback(self.selectedModel);
}

- (void)presentWithCallback:(void(^)(SimplePickerModel *modelOrNil))callback {
    [NPSoftModalPresentationController presentViewController:self];
    self.callback = callback;
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
