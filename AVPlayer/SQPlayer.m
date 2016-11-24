//
//  SQPlayer.m
//  AVPlayer
//
//  Created by 尹思迁 on 2016/11/23.
//  Copyright © 2016年 尹思迁. All rights reserved.
//

#import "SQPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"

#define screen_width  [UIScreen mainScreen].bounds.size.width
#define screen_height  [UIScreen mainScreen].bounds.size.height

@interface SQPlayer ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, assign) BOOL isInitPlayer;

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UILabel *time;
@property (nonatomic, strong) UILabel *rightTime;
@property (nonatomic, strong) UISlider *videoProgress;
@property (nonatomic, strong) UIButton *fullScreenBtn;

@property (nonatomic, assign) CGRect originalFrame;

@property (nonatomic, assign) CGFloat totalTime;

@property (nonatomic, strong) UIActivityIndicatorView *loadingView;

@property (nonatomic, strong) UIProgressView *bufferProgress;

@property (nonatomic, strong) id timeObserver;

@property (nonatomic, strong) NSDateFormatter *formatter;

@property (nonatomic, strong) UIView *originalSuperView;

@end

@implementation SQPlayer


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.originalFrame = frame;
        [self initSubviews];
    }
    return self;
}

#pragma mark ---初始化操作

- (void)addObserver {
    NSNotificationCenter *notification = [NSNotificationCenter defaultCenter];
    [notification addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
    [notification addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];

    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监控网络加载情况属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监听播放的区域缓存是否为空
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    //缓存可以播放的时候调用
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)initPlayer {
    self.playerItem = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:self.urlString]];
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    self.player.usesExternalPlaybackWhileExternalScreenIsActive = YES;
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.bounds;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.layer insertSublayer:_playerLayer atIndex:0];
    [self addObserver];
}

- (void)initSubviews {
    
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self addSubview:self.loadingView];
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    [self.loadingView startAnimating];
    
    self.bottomView = [[UIView alloc]init];
    self.bottomView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.bottomView];
    
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    _playBtn = [[UIButton alloc]init];
    [_playBtn setBackgroundImage:[UIImage imageNamed:@"icon_play_middle"] forState:UIControlStateNormal];
    [_playBtn setBackgroundImage:[UIImage imageNamed:@"fullplayer_icon_pause"] forState:UIControlStateSelected];
    _playBtn.showsTouchWhenHighlighted = YES;
    _playBtn.selected = YES;
    [self.bottomView addSubview:_playBtn];
    [_playBtn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [_playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView.mas_left).offset(10);
        make.bottom.equalTo(self.bottomView.mas_bottom).offset(-10);
    }];
    
    _fullScreenBtn = [[UIButton alloc]init];
    [_fullScreenBtn setBackgroundImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    [_fullScreenBtn setBackgroundImage:[UIImage imageNamed:@"nonfullscreen"] forState:UIControlStateSelected];
    _fullScreenBtn.showsTouchWhenHighlighted = YES;
    [self.bottomView addSubview:_fullScreenBtn];
    [_fullScreenBtn addTarget:self action:@selector(fullScreen:) forControlEvents:UIControlEventTouchUpInside];
    
    [_fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView.mas_right).offset(-5);
        make.centerY.equalTo(_playBtn.mas_centerY);
    }];
    
    self.time = [[UILabel alloc]init];
    self.time.text = @"0/0";
    self.time.font = [UIFont systemFontOfSize:10];
    self.time.textColor = [UIColor whiteColor];
    [self.bottomView addSubview:self.time];
    
    [self.time mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.playBtn.mas_right).offset(5);
        make.centerY.equalTo(self.playBtn.mas_centerY);
    }];

    self.videoProgress = [[UISlider alloc]init];
    self.videoProgress.minimumValue = 0;
    self.videoProgress.maximumValue = 1;
    [self.videoProgress setThumbImage:[UIImage imageNamed:@"icon_slider_s"] forState:UIControlStateNormal];
    self.videoProgress.minimumTrackTintColor = [UIColor greenColor];
    self.videoProgress.maximumTrackTintColor = [UIColor clearColor];
    self.videoProgress.value = 0;
    [self.videoProgress addTarget:self action:@selector(dragSlider:) forControlEvents:UIControlEventValueChanged];
    
    UITapGestureRecognizer *sliderTag = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickSlider:)];
    sliderTag.numberOfTapsRequired = 1;
    [self.videoProgress addGestureRecognizer:sliderTag];
    [self.bottomView addSubview:self.videoProgress];
    
    [self.videoProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_time.mas_right).offset(5);
        make.right.equalTo(_fullScreenBtn.mas_left).offset(-10);
        make.centerY.equalTo(_time.mas_centerY);
    }];
    
    self.bufferProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.bufferProgress.progressTintColor = [UIColor clearColor];
    self.bufferProgress.trackTintColor    = [UIColor lightGrayColor];
    [self.bottomView addSubview:self.bufferProgress];
    self.bufferProgress.progress = 0.0f;
    [self.bottomView addSubview:self.bufferProgress];
    
    [self.bottomView sendSubviewToBack:self.bufferProgress];
    
    self.bottomView.hidden = YES;
    
    [self.bufferProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.videoProgress);
        make.right.equalTo(self.videoProgress);
        make.center.equalTo(self.videoProgress);
        make.height.equalTo(@1);
    }];
    
}

#pragma mark --监听回调方法

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.player.rate == 0) {
        [self.player play];
        self.playBtn.selected = YES;
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (self.player.rate == 1){
        [self.player pause];
        self.playBtn.selected = NO;
    }
}

//播放完成
- (void)playbackFinished:(NSNotification *)noti {
    [self.player pause];
    self.playBtn.selected = NO;
    //初始化播放进度
    [self.player seekToTime:CMTimeMakeWithSeconds(0, self.playerItem.currentTime.timescale)];
    self.videoProgress.value = 0;
    NSLog(@"%s",__func__);
}


- (void)dragSlider:(UISlider *)slider {
    NSLog(@"%s",__func__);

}

- (void)clickSlider:(UITapGestureRecognizer *)tag {
    NSLog(@"%s",__func__);
    CGPoint location = [tag locationInView:self.videoProgress];
    CGFloat value = location.x / self.videoProgress.frame.size.width;
    CGFloat nowTime = self.totalTime * value;
    [self.player seekToTime:CMTimeMakeWithSeconds(nowTime, self.playerItem.currentTime.timescale)];
}

- (void)fullScreen:(UIButton *)btn {
    btn.selected = !btn.selected;
    [self handleRotateScreen:btn.selected];
    if (self.delegate && [self.delegate respondsToSelector:@selector(sq_PlayerRotateScreen:fullScreen:)]) {
        [self.delegate sq_PlayerRotateScreen:self fullScreen:btn.selected];
    }
}

- (void)clickBtn:(UIButton *)btn {
    btn.selected = ! btn.selected;
    if (btn.selected) {
        [self.player play];
    } else {
        [self.player pause];
    }
}

- (void)onDeviceOrientationChange {

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        if(status == AVPlayerStatusReadyToPlay){
            NSLog(@"observeValueForKeyPath");
            self.totalTime = CMTimeGetSeconds(self.playerItem.duration);
            [self.loadingView stopAnimating];
            [self updateTime];
            self.bottomView.hidden = NO;
        } else if (status == AVPlayerStatusUnknown) {
            [self.loadingView startAnimating];
        } else if (status == AVPlayerStatusFailed) {
            NSLog(@"%@",@"AVPlayerStatusFailed");
            [self play];
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        CGFloat totalTime = CMTimeGetSeconds(_playerItem.duration);
        CGFloat totalBuffer = [self countBufferRange];
        self.bufferProgress.progressTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
        [self.bufferProgress setProgress:totalBuffer / totalTime animated:YES];
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        NSLog(@"playbackBufferEmpty");
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        NSLog(@"playbackLikelyToKeepUp");
    }
}

#pragma mark --private func

- (void)updateTime {
    CMTime duration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(duration)) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CGFloat now = CMTimeGetSeconds(time);
        CGFloat total = CMTimeGetSeconds([weakSelf.playerItem duration]);
        if (now) {
            [weakSelf setTime:now totalTime:total];
        }
    }];
}

- (CGFloat)countBufferRange {
    NSArray *array = self.playerItem.loadedTimeRanges;
    CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    CGFloat totalBuffer = startSeconds + durationSeconds;
    return totalBuffer;
}

- (void)handleRotateScreen:(BOOL)isfullScreen {
    [UIView animateWithDuration:.5 animations:^{
        if (isfullScreen) {
            self.originalSuperView = self.superview;
            [self removeFromSuperview];
            self.transform = CGAffineTransformIdentity;
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.frame = CGRectMake(0, 0, screen_width, screen_height);
            self.playerLayer.frame = CGRectMake(0, 0, screen_height, screen_width);
            [[UIApplication sharedApplication].keyWindow addSubview:self];
        } else {
            [self removeFromSuperview];
            self.transform = CGAffineTransformIdentity;
            self.frame = self.originalFrame;
            self.playerLayer.frame = self.bounds;
            [self.originalSuperView addSubview:self];
        }
        [self handleRotateScreemConstraints:isfullScreen];
    }];
}

- (void)handleRotateScreemConstraints:(BOOL)isfullScreen {
    [self.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).offset(0);
        make.left.equalTo(self).offset(0);
        if (isfullScreen) {
            make.width.equalTo(@(screen_height));
            make.height.equalTo(@(screen_width));
        } else {
            make.width.equalTo(@(self.bounds.size.width));
            make.height.equalTo(@(self.bounds.size.height));
        }
    }];
}

//获取当前的旋转状态
- (CGAffineTransform)getCurrentDeviceOrientation{
    //状态条的方向已经设置过,所以这个就是你想要旋转的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    //根据要进行旋转的方向来计算旋转的角度
    if (orientation ==UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    }else if (orientation ==UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    }else if(orientation ==UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}


- (void)setTime:(CGFloat)now totalTime:(CGFloat)total {
    self.videoProgress.value = now / total;
    self.time.text = [NSString stringWithFormat:@"%@/%@",[self countTime:now],[self countTime:total]];
}

- (CMTime)playerItemDuration {
    AVPlayerItem *playerItem = _playerItem;
    if (_playerItem.status == AVPlayerItemStatusReadyToPlay) {
        return [playerItem duration];
    }
    return kCMTimeInvalid;
}

- (NSString *)countTime:(CGFloat)time {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    if (time / 3600 >= 1) {
        self.formatter.dateFormat = @"HH:mm:ss";
    } else {
        self.formatter.dateFormat = @"mm:ss";
    }
    return [self.formatter stringFromDate:date];
}

- (NSDateFormatter *)formatter {
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc]init];
    }
    return _formatter;
}

#pragma mark --public func
- (void)play {
    if (!self.isInitPlayer) {
        self.isInitPlayer = YES;
        [self initPlayer];
        [self.player play];
    } else {
        [self.player play];
    }
}

- (void)pause {
    [self.player pause];
}

- (void)setUrlString:(NSString *)urlString {
    _urlString = urlString;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

@end
