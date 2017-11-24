//
//  ViewController.m
//  FQFaceRecognizeSample
//
//  Created by fanqi on 2017/9/13.
//  Copyright © 2017年 fanqi. All rights reserved.
//

#import "ViewController.h"
#import "FQImageRecognizeViewController.h"
#import "FQVideoRecognizeViewController.h"

NSString * const ReuseID = @"TableViewCell";

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate & UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseID];
    
    cell.textLabel.text = self.dataArray[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        FQImageRecognizeViewController *ctr = [[FQImageRecognizeViewController alloc] init];
        [self.navigationController pushViewController:ctr animated:YES];
    } else if (indexPath.row == 1) {
        FQVideoRecognizeViewController *ctr = [[FQVideoRecognizeViewController alloc] init];
        [self.navigationController pushViewController:ctr animated:YES];
    }
}

#pragma mark - Getter

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        tableView.rowHeight = 50;
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ReuseID];
        [self.view addSubview:tableView];
        _tableView = tableView;
    }
    return _tableView;
}

- (NSArray *)dataArray {
    if (!_dataArray) {
        _dataArray = @[@"图片", @"视频"];
    }
    return _dataArray;
}

@end
