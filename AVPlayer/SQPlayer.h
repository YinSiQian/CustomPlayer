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

@optional

- (void)sq_PlayerExitVideoPlay:(SQPlayer *)player;

/**
 播放完成的回调方法

 @param player 当前播放器实例
 */
- (void)sq_PlayerFinished:(SQPlayer *)player;

/**
 播放失败的回调方法

 @param player 当前播放器实例
 @param error 播放失败的信息
 */
- (void)sq_PlayerStatusFailed:(SQPlayer *)player error:(NSError *)error;

/**
 全屏播放

 @param player 当前播放器实例
 @param isFullScreen 是否全屏
 */
- (void)sq_PlayerRotateScreen:(SQPlayer *)player fullScreen:(BOOL)isFullScreen;

@end


@interface SQPlayer : UIView

@property (nonatomic, strong) NSString *urlString;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIImageView *placeHolderView;

@property (nonatomic, weak) id <SQPlayerDelegate>delegate;

@property (nonatomic, copy) NSString *title;

/***************自定义控件图片*********************/

/**
 自定义播放条的滑动圆点的自定义图片名称
 */
@property (nonatomic, copy) NSString *sliderDotName;

@property (nonatomic, copy) NSString *playBtnName;

@property (nonatomic, copy) NSString *pauseBtnName;

@property (nonatomic, copy) NSString *closeBtnName;

- (void)handleRotateScreen:(BOOL)isfullScreen;

- (void)play;

- (void)pause;


@end
