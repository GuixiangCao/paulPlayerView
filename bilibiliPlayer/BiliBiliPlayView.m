//
//  BiliBiliPlayView.m
//  bilibiliPlayer
//
//  Created by 曹桂祥 on 17/3/9.
//  Copyright © 2017年 曹桂祥. All rights reserved.
//

#import "BiliBiliPlayView.h"
#import "NSString+time.h"
#import "Masonry.h"

@implementation RotationScreen

//
+ (void)forceOrientation:(UIInterfaceOrientation)orientation {
    // setOrientation: 私有方法强制横屏
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

//
+ (BOOL)isOrientationLandscape {
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return YES;
    } else {
        return NO;
    }
}

@end

@interface BiliBiliPlayView()

{
    //状态相关
    BOOL _isSliding;
    BOOL _isIntobackground;
    id _playTimeObserver; // 观察者
    BOOL _isShowToolbar; // 是否显示工具条
    
    //播放器相关
    AVPlayerLayer *_playerLayer;
    AVPlayerItem  *_playerItem;
    NSTimer *_timer;
}


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingAlert;

@property (weak, nonatomic) IBOutlet UIButton *playerBottomBtn;

@property (weak, nonatomic) IBOutlet UILabel *beginLabel;

@property (weak, nonatomic) IBOutlet UILabel *endLabel;

@property (weak, nonatomic) IBOutlet UIButton *rotation;

@property (weak, nonatomic) IBOutlet UIProgressView *loadProgress;

@property (weak, nonatomic) IBOutlet UISlider *playProgress;

@property (weak, nonatomic) IBOutlet UIView *bottomView;

@property (weak, nonatomic) IBOutlet UIView *topView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UIButton *moreBtn;

@property (weak, nonatomic) IBOutlet UIView *playerView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewTop;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewBottom;


@end

@implementation BiliBiliPlayView

-(void)awakeFromNib{
    
    [super awakeFromNib];
    
    self.loadProgress.progress = 0;
    
    self.playProgress.value    = 0;

    [self.playProgress setThumbImage:[UIImage imageNamed:@"icmpv_thumb_light"] forState:UIControlStateNormal];
    
}

-(instancetype)init{
    
    if (self = [super init]) {
        
        self = [[[NSBundle mainBundle]loadNibNamed:@"BiliBiliPlayView" owner:nil options:nil] lastObject];
        
        self.player  = [[AVPlayer alloc]init];
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        _playerLayer.videoGravity = AVLayerVideoGravityResize;
        [self.playerView.layer addSublayer:_playerLayer];
        
        [self.playerView bringSubviewToFront:_topView];
        [self.playerView bringSubviewToFront:_bottomView];
        [self.playerView bringSubviewToFront:_playerBottomBtn];
        [self.playerView bringSubviewToFront:_playProgress];
        
        [self.playerView bringSubviewToFront:self.loadingAlert];
        
        //setPortraintLayout
        [self setPortarintLayout];
        
        self.loadingAlert.hidden = false;
        
        [self.loadingAlert startAnimating];
    }
    return self;
}

#pragma mark 横竖屏约束
-(void)setPortarintLayout{
    
    _isLandscape = false;
    
    // 不隐藏工具条
    [self portraitShow];
    
    [self layoutIfNeeded];
}

//显示工具条
-(void)portraitShow{
    _isShowToolbar = true;
    
    //约束动画
    self.topViewTop.constant       = 0;
    self.bottomViewBottom.constant = 0;
    
    [UIView animateWithDuration:0.1 animations:^{
        [self layoutIfNeeded];
        self.topView.alpha         = self.bottomView.alpha = 1;
        self.playerBottomBtn.alpha = 1.0;
    }];
    
    // 显示状态条
    [[UIApplication sharedApplication] setStatusBarHidden:false animated:true];
    [[UIApplication sharedApplication] setStatusBarStyle:(UIStatusBarStyleLightContent)];
}

- (void)portraitHide {
    _isShowToolbar = NO; // 显示工具条置为 no
    
    // 约束动画
    self.topViewTop.constant = -(self.topView.frame.size.height);
    self.bottomViewBottom.constant = -(self.bottomView.frame.size.height);
    [UIView animateWithDuration:0.1 animations:^{
        [self layoutIfNeeded];
        self.topView.alpha = self.bottomView.alpha = 0;
        self.playerBottomBtn.alpha = 0;
    } completion:^(BOOL finished) {
    }];
    
    // 隐藏状态条
    [[UIApplication sharedApplication] setStatusBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:(UIStatusBarStyleLightContent)];
    
}

#pragma - mark : touch事件

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _touchMode = TouchPlayerViewModeNone;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (_touchMode == TouchPlayerViewModeNone) {
        if (_isLandscape) { // 如果当前是横屏
            if (_isShowToolbar) {
                //                [self landscapeHide];
            } else {
                //                [self landscapeShow];
            }
        } else { // 如果是竖屏
            if (_isShowToolbar) {
                [self portraitHide];
            } else {
                [self portraitShow];
            }
        }
    }
}


-(void)layoutSubviews{
    
    [super layoutSubviews];
    
    _playerLayer.frame = self.bounds;
//    NSLog(@"height--%f=====width----%f",_playerLayer.frame.size.height,_playerLayer.frame.size.width);
    
}



-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    return self;
}

//创建avitem
-(void)updatePlayerWithURl:(NSURL *)url{
    
    _playerItem = [[AVPlayerItem alloc]initWithURL:url];
    
    [_player replaceCurrentItemWithPlayerItem:_playerItem];
    
    //监听播放
    [self monitoringPlayback:_playerItem];
    
    [self addObserverAndNotification];
    
}

//观察播放进度
-(void)monitoringPlayback:(AVPlayerItem *)item
{
    __weak typeof (self) WeakSelf = self;
    _playTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        if (_touchMode != TouchPlayerViewModeHorizontal) {
            float currentPlayTime = (double)item.currentTime.value / item.currentTime.timescale;
            
            if (_isSliding == false) {
                [WeakSelf updateVideoSlider:currentPlayTime];

            }
        }
    }];
}

// 更新滑动条
- (void)updateVideoSlider:(float)currentTime {
    
    self.playProgress.value = currentTime;
    self.beginLabel.text    = [NSString convertTime:currentTime];
}

-(void)addObserverAndNotification{
    
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    
    [_playerItem addObserver:self forKeyPath:@"playbackBufferFull" options:NSKeyValueObservingOptionNew context:nil];
    

    
    
#pragma - mark : to do
    
//    [self addObserverAndNotification];
}

- (void)addNotification {
    // 播放完成通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
//    // 前台通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
//    // 后台通知
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
}


#pragma mark KVO - status
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    AVPlayerItem *item = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"status"]) {
        
        if (_isIntobackground) {
            return;
        }else{
            AVPlayerStatus status = [[change objectForKey:@"new"] intValue]; // 获取更改后的状态
            if (status == AVPlayerStatusReadyToPlay) {
                
                NSLog(@"准备播放");
                [self.loadingAlert stopAnimating];
                
                self.loadingAlert.hidden = true;
                
                CMTime duration   = item.duration; // 获取视频长度
                NSLog(@"%.2f", CMTimeGetSeconds(duration));
                // 设置视频时间
                [self setMaxDuration:CMTimeGetSeconds(duration)];
                // 播放
                [self play];
                
            } else if (status == AVPlayerStatusFailed) {
                NSLog(@"AVPlayerStatusFailed");
            } else {
                NSLog(@"AVPlayerStatusUnknown");
                self.loadingAlert.hidden = false;
                [self.loadingAlert startAnimating];
            }
        }
        
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        
        NSTimeInterval timeInterval = [self availableDurationRanges];
        CGFloat totalDuration       = CMTimeGetSeconds(_playerItem.duration);
        [self.loadProgress setProgress:timeInterval / totalDuration animated:true];
        
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){ //当视频播放因为各种状态播放停止的时候, 这个属性会发生变化
            if (self.isPlaying) {
                [self.player play];
                [self.loadingAlert stopAnimating];
                self.loadingAlert.hidden = YES;
            }
        NSLog(@"playbackLikelyToKeepUp change : %@", change);
    }else if([keyPath isEqualToString:@"playbackBufferEmpty"]){  //当没有任何缓冲部分可以播放的时候
        self.loadingAlert.hidden = false;
        [self.loadingAlert startAnimating];
        NSLog(@"playbackBufferEmpty");
    }else if ([keyPath isEqualToString:@"playbackBufferFull"]){
        NSLog(@"playbackBufferFull: change : %@", change);
    }
}

-(void)play{
    _isPlaying = YES;
    
    [_player play]; // 调用avplayer 的play方法
    
    [self.playerBottomBtn setImage:[UIImage imageNamed:@"Stop"] forState:(UIControlStateNormal)];

}

-(void)pause{
    _isPlaying = false;
    
    [self.loadingAlert stopAnimating];
    
    self.loadingAlert.hidden = true;
    
    [_player pause];
    
    [self.playerBottomBtn setImage:[UIImage imageNamed:@"Play"] forState:(UIControlStateNormal)];
}

-(void)setMaxDuration:(CGFloat)duration{
    
    self.playProgress.maximumValue = duration;
    
    self.endLabel.text             = [NSString convertTime:duration];
}

// 已缓冲进度
- (NSTimeInterval)availableDurationRanges {

    NSArray *loadTimeRanges = [_playerItem loadedTimeRanges];
    
    CMTimeRange timeRange   = [loadTimeRanges.firstObject CMTimeRangeValue];
    float startSecond       = CMTimeGetSeconds(timeRange.start);
    float duratuon          = CMTimeGetSeconds(timeRange.duration);
    
    NSTimeInterval result   = startSecond + duratuon;
    
    return result;
}

-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    CGRect bounds      = [UIScreen mainScreen].bounds;
    
    
    
    NSLog(@"playH:%f",_playerLayer.frame.size.height);

    // 横竖屏判断
    if (self.traitCollection.verticalSizeClass != UIUserInterfaceSizeClassCompact) { // 竖屏
        self.frame  = CGRectMake(0, 0, bounds.size.width,bounds.size.width * 0.6);
        self.bottomView.backgroundColor = self.topView.backgroundColor = [UIColor clearColor];
        [self.rotation setImage:[UIImage imageNamed:@"player_fullScreen_iphone"] forState:(UIControlStateNormal)];
    } else { // 横屏
        NSLog(@"playH:%f",bounds.size.height);
        self.frame  = CGRectMake(0, 0, bounds.size.width,bounds.size.height);
        self.bottomView.backgroundColor = self.topView.backgroundColor = RGBColor(89, 87, 90);
        [self.rotation setImage:[UIImage imageNamed:@"player_window_iphone"] forState:(UIControlStateNormal)];
        
    }
}


#pragma - mark :actions 

- (IBAction)palyOrPauseAction:(id)sender {
    if (_isPlaying) {
        [self pause];
    } else {
        [self play];
    }
}


- (IBAction)rotationAction:(id)sender {
    
    if ([RotationScreen isOrientationLandscape]) { // 如果是横屏，
        [RotationScreen forceOrientation:(UIInterfaceOrientationPortrait)]; // 切换为竖屏
    } else {
        [RotationScreen forceOrientation:(UIInterfaceOrientationLandscapeRight)]; // 否则，切换为横屏
    }
    
}






@end


