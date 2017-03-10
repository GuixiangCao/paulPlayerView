//
//  ViewController.m
//  bilibiliPlayer
//
//  Created by 曹桂祥 on 17/3/9.
//  Copyright © 2017年 曹桂祥. All rights reserved.
//

#import "ViewController.h"
#import "BiliBiliPlayView.h"

@interface ViewController ()

@property (nonatomic,strong) BiliBiliPlayView *playView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    NSLog(@"%.2f",width);
    
    BiliBiliPlayView *playView = [[BiliBiliPlayView alloc]init];
    
    NSURL *url = [NSURL URLWithString:@"http://hc.yinyuetai.com/uploads/videos/common/B65B013CF61E82DC9766E8BDEEC8B602.flv?sc=8cafc5714c8a6265"];
    
    playView.frame = CGRectMake(0, 0,width , width * 0.6);
    
    [playView updatePlayerWithURl:url];
    
    [self.view addSubview:playView];
    
}


// 1. 设置样式
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent; // 白色的
}
// 2. 横屏时显示 statusBar
- (BOOL)prefersStatusBarHidden {
    return NO; // 显示
}

// 3. 设置隐藏动画
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}


@end
