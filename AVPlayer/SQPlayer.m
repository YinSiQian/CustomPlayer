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

@property (nonatomic, strong) UIButton *closeBtn;

@property (nonatomic, assign) BOOL isFullScreen;

@property (nonatomic, assign) BOOL isFirstHidden;

@property (nonatomic, assign) BOOL isDraging;

@property (nonatomic, assign) BOOL isFinished;

@property (nonatomic, strong) UILabel *titleLable;

@property (nonatomic, strong) NSTimer *timer;
@end

@implementation SQPlayer


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.originalFrame = frame;
        [self initSubviews];
        self.isFirstHidden = YES;
    }
    return self;
}

#pragma mark ---初始化操作

- (void)addObserver {
    NSNotificationCenter *notification = [NSNotificationCenter defaultCenter];
    [notification addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
    [notification addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];

    [self.contentView addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:nil];
    
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
    self.placeHolderView = [UIImageView new];
    [self addSubview:self.placeHolderView];
    
    self.contentView = [UIView new];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.contentView];
    
    self.closeBtn = [UIButton new];
    [self.closeBtn setBackgroundImage:[UIImage imageNamed:@"fullplayer_icon_back"] forState:UIControlStateNormal];
    [self.closeBtn addTarget:self action:@selector(exitVideoPlay) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.closeBtn];
    
    self.titleLable = [UILabel new];
    self.titleLable.textColor = [UIColor whiteColor];
    self.titleLable.font = [UIFont boldSystemFontOfSize:14];
    self.titleLable.textAlignment = NSTextAlignmentLeft;
    [self.contentView addSubview:self.titleLable];
    
    _playBtn = [[UIButton alloc]init];
    [_playBtn setBackgroundImage:[UIImage imageNamed:@"fullplayer_icon_player"] forState:UIControlStateNormal];
    [_playBtn setBackgroundImage:[UIImage imageNamed:@"fullplayer_icon_pause"] forState:UIControlStateSelected];
    _playBtn.showsTouchWhenHighlighted = YES;
    _playBtn.selected = YES;
    [self.contentView addSubview:_playBtn];
    [_playBtn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    _fullScreenBtn = [[UIButton alloc]init];
    [_fullScreenBtn setBackgroundImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    [self.contentView addSubview:_fullScreenBtn];
    [_fullScreenBtn addTarget:self action:@selector(fullScreen:) forControlEvents:UIControlEventTouchUpInside];
    
    self.time = [[UILabel alloc]init];
    self.time.text = @"0/0";
    self.time.font = [UIFont systemFontOfSize:10];
    self.time.textColor = [UIColor whiteColor];
    [self.contentView addSubview:self.time];
    
    self.videoProgress = [[UISlider alloc]init];
    self.videoProgress.minimumValue = 0;
    self.videoProgress.maximumValue = 1;
    [self.videoProgress setThumbImage:[UIImage imageNamed:@"icon_slider_s"] forState:UIControlStateNormal];
    self.videoProgress.minimumTrackTintColor = [UIColor greenColor];
    self.videoProgress.maximumTrackTintColor = [UIColor clearColor];
    self.videoProgress.value = 0;
    [self.videoProgress addTarget:self action:@selector(dragSlider:) forControlEvents:UIControlEventValueChanged];
    [self.videoProgress addTarget:self action:@selector(updateVideoProgress:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.videoProgress];
    
    self.bufferProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.bufferProgress.progressTintColor = [UIColor clearColor];
    self.bufferProgress.trackTintColor    = [UIColor lightGrayColor];
    [self.contentView addSubview:self.bufferProgress];
    self.bufferProgress.progress = 0.0f;
    [self.contentView addSubview:self.bufferProgress];
    
    [self.contentView sendSubviewToBack:self.bufferProgress];
    
    self.contentView.hidden = YES;
    
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self addSubview:self.loadingView];
    
    [self.loadingView startAnimating];
    
    [self makeConstraints];
    
    [self addGestureRecognizer];
}

- (void)addGestureRecognizer {
    UITapGestureRecognizer *sliderTag = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickSlider:)];
    sliderTag.numberOfTapsRequired = 1;
    [self.videoProgress addGestureRecognizer:sliderTag];
    
    UITapGestureRecognizer *showContentTag = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showOpreationColumn)];
    showContentTag.numberOfTapsRequired = 1;
    [self addGestureRecognizer:showContentTag];
}

- (void)makeConstraints {
    [self.placeHolderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(5);
        make.top.equalTo(self.contentView).offset(30);
    }];
    
    [self.titleLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.closeBtn.mas_right).offset(5);
        make.right.mas_lessThanOrEqualTo(self.contentView.mas_right).offset(-10);
        make.centerY.equalTo(self.closeBtn.mas_centerY);
    }];
    
    [_playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left).offset(10);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-10);
    }];
    
    [_fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView.mas_right).offset(-5);
        make.centerY.equalTo(_playBtn.mas_centerY);
    }];
    
    [self.videoProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_time.mas_right).offset(5);
        make.right.equalTo(_fullScreenBtn.mas_left).offset(-10);
        make.centerY.equalTo(_time.mas_centerY);
    }];
    
    [self.time mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.playBtn.mas_right).offset(5);
        make.centerY.equalTo(self.playBtn.mas_centerY);
    }];
    
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
    [self showOpreationColumn];
    [self.player pause];
    self.playBtn.selected = NO;
    self.isFinished = YES;
    //初始化播放进度
    [self.player seekToTime:CMTimeMakeWithSeconds(0, self.playerItem.currentTime.timescale)];
    self.videoProgress.value = 0;
    if ([self.delegate respondsToSelector:@selector(sq_PlayerFinished:)]) {
        [self.delegate sq_PlayerFinished:self];
    }
}


- (void)dragSlider:(UISlider *)slider {
    [self showOpreationColumn];
    _isDraging = YES;
    CGFloat nowTime = self.totalTime * slider.value;
    [self.player seekToTime:CMTimeMakeWithSeconds(nowTime, self.playerItem.currentTime.timescale)];
}

//slider拖拽完成后回调
- (void)updateVideoProgress:(UISlider *)slider {
    _isDraging = NO;
    [self hiddenOperationColumn];
}

- (void)showOpreationColumn {
    if (self.contentView.alpha == 0) {
        [UIView animateWithDuration:0.2 animations:^{
            self.contentView.alpha = 1.0;
        }];
    }
}

- (void)clickSlider:(UITapGestureRecognizer *)tag {
    CGPoint location = [tag locationInView:self.videoProgress];
    CGFloat value = location.x / self.videoProgress.frame.size.width;
    CGFloat nowTime = self.totalTime * value;
    [self.player seekToTime:CMTimeMakeWithSeconds(nowTime, self.playerItem.currentTime.timescale)];
}

- (void)fullScreen:(UIButton *)btn {
    self.isFullScreen = YES;
    self.fullScreenBtn.hidden = YES;
    [self handleRotateScreen:self.isFullScreen];
    if (self.delegate && [self.delegate respondsToSelector:@selector(sq_PlayerRotateScreen:fullScreen:)]) {
        [self.delegate sq_PlayerRotateScreen:self fullScreen:self.isFullScreen];
    }
}

- (void)exitVideoPlay {
    if (self.isFullScreen) {
        self.isFullScreen = NO;
        self.fullScreenBtn.hidden = NO;
        if ([self.delegate respondsToSelector:@selector(sq_PlayerRotateScreen:fullScreen:)]) {
            [self.delegate sq_PlayerRotateScreen:self fullScreen:_isFullScreen];
        }
        [self handleRotateScreen:self.isFullScreen];
        [self remakeConstraints];
    } else {
        if ([self.delegate respondsToSelector:@selector(sq_PlayerExitVideoPlay:)]) {
            [self.delegate sq_PlayerExitVideoPlay:self];
        }
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
        if(status == AVPlayerStatusReadyToPlay){
            self.totalTime = CMTimeGetSeconds(self.playerItem.duration);
            [self.loadingView stopAnimating];
            [self updateTime];
            self.contentView.hidden = NO;
            [self firstHiddenOperationColumn];
        } else if (status == AVPlayerStatusUnknown) {
            [self.loadingView startAnimating];
        } else if (status == AVPlayerStatusFailed) {
            if ([self.delegate respondsToSelector:@selector(sq_PlayerStatusFailed:error:)]) {
                [self.delegate sq_PlayerStatusFailed:self error:self.playerItem.error];
            }
            [self play];
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        CMTime ctime = self.player.currentTime;
        NSLog(@"%lld     %d",ctime.value,ctime.timescale);
        CGFloat totalTime = CMTimeGetSeconds(_playerItem.duration);
        CGFloat totalBuffer = [self countBufferRange];
        self.bufferProgress.progressTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
        [self.bufferProgress setProgress:totalBuffer / totalTime animated:YES];
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        NSLog(@"playbackBufferEmpty: %@ ",self.playerItem.loadedTimeRanges);
        [self.loadingView startAnimating];
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        //缓存可以播放的时候会回调
        [self.loadingView stopAnimating];
        [self.player play];
        NSLog(@"playbackLikelyToKeepUp");
    } else if ([keyPath isEqualToString:@"alpha"]) {
        CGFloat alpha = [change[@"new"] floatValue];
        if (alpha == 1.0 && !_isFinished && !_isDraging) {
            [self hiddenOperationColumn];
        }
    }
}

#pragma mark --private func

- (void)firstHiddenOperationColumn {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hiddenOperationColumn];
    });
}

- (void)hiddenOperationColumn {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.2 animations:^{
            self.contentView.alpha = 0.0;
        }];
    });
}

- (void)remakeConstraints {
    [self.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(5);
        make.top.equalTo(self.contentView).offset(30);
    }];
    
    [self.titleLable mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.closeBtn.mas_right).offset(5);
        make.right.mas_lessThanOrEqualTo(self.contentView.mas_right).offset(-10);
        make.centerY.equalTo(self.closeBtn.mas_centerY);
    }];
}

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
    [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
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

#pragma mark -- setter方法

- (void)setUrlString:(NSString *)urlString {
    _urlString = urlString;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLable.text = _title;
}

#pragma mark --custom UI func

- (void)setPlayBtnName:(NSString *)playBtnName {
    [self.playBtn setBackgroundImage:[UIImage imageNamed:playBtnName] forState:UIControlStateNormal];
}

- (void)setPauseBtnName:(NSString *)pauseBtnName {
    [self.playBtn setBackgroundImage:[UIImage imageNamed:pauseBtnName] forState:UIControlStateSelected];
}

- (void)setSliderDotName:(NSString *)sliderDotName {
    [self.videoProgress setThumbImage:[UIImage imageNamed:sliderDotName] forState:UIControlStateNormal];
}

- (void)setCloseBtnName:(NSString *)closeBtnName {
    [self.closeBtn setBackgroundImage:[UIImage imageNamed:closeBtnName] forState:UIControlStateNormal];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self.contentView removeObserver:self forKeyPath:@"alpha"];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

@end
