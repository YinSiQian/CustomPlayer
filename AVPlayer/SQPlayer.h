//
//  SQPlayer.h
//  AVPlayer
//
//  Created by 尹思迁 on 2016/11/23.
//  Copyright © 2016年 尹思迁. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SQPlayer;
@protocol SQPlayerDelegate <NSObject>

- (void)sq_PlayerStatusFailed:(SQPlayer *)player;

- (void)sq_PlayerRotateScreen:(SQPlayer *)player fullScreen:(BOOL)isFullScreen;

@end


@interface SQPlayer : UIView

@property (nonatomic, strong) NSString *urlString;

@property (nonatomic, weak) id <SQPlayerDelegate>delegate;

- (void)handleRotateScreen:(BOOL)isfullScreen;
- (void)play;

- (void)pause;


@end
