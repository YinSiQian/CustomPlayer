//
//  ViewController.m
//  AVPlayer
//
//  Created by 尹思迁 on 2016/11/23.
//  Copyright © 2016年 尹思迁. All rights reserved.
//

#import "ViewController.h"
#import "SQPlayer.h"
#import "NetworkManager.h"
#import "DataModel.h"

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray *dataArr;
@end

@implementation ViewController

- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadData];
    
    
}

- (void)loadData {
    [NetworkManager GET:@"http://c.m.163.com/nc/video/home/0-10.html" success:^(id responseObject) {
        NSLog(@"%@",responseObject);
        NSArray *videoList = responseObject[@"videoList"];
        for (NSDictionary *dict in videoList) {
            DataModel *model = [DataModel modelWithDict:dict];
            [self.dataArr addObject:model];
        }
        [self createPlayer];
    } failure:^(NSError *error) {
        
    }];
}

- (void)createPlayer {
    SQPlayer *player = [[SQPlayer alloc]initWithFrame:CGRectMake(10, 100, 300, 300)];
    [self.view addSubview:player];
    player.urlString = [self.dataArr.firstObject mp4_url];
    [player play];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
