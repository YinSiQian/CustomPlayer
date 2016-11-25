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

@interface ViewController ()<SQPlayerDelegate>
@property (nonatomic, strong) NSMutableArray *dataArr;
@property (nonatomic, assign) BOOL isRotateScreen;
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

    
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
    player.delegate = self;
    DataModel *model = self.dataArr.firstObject;
    player.title = model.title;
    player.urlString = model.mp4_url;
    [self.view addSubview:player];
    [player play];
    
}

- (void)onDeviceOrientationChange {
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)sq_PlayerStatusFailed:(SQPlayer *)player {
    
}

- (void)sq_PlayerRotateScreen:(SQPlayer *)player fullScreen:(BOOL)isFullScreen {
    self.isRotateScreen = isFullScreen;
    if (isFullScreen) {
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:NO];
    } else {
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
