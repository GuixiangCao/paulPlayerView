//
//  BiliBiliPlayView.h
//  bilibiliPlayer
//
//  Created by 曹桂祥 on 17/3/9.
//  Copyright © 2017年 曹桂祥. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>

#define RGBColor(r, g, b) [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:1.0]

typedef NS_ENUM(NSInteger ,TouchPlayerViewMode) {
    
    TouchPlayerViewModeNone, // 轻触
    TouchPlayerViewModeHorizontal, // 水平滑动
    TouchPlayerViewModeUnknow, // 未知
    
};

@interface BiliBiliPlayView : UIView

{
    TouchPlayerViewMode _touchMode;
}

@property (nonatomic,strong) AVPlayer *player;

@property (nonatomic,assign) BOOL isPlaying;

// 是否横屏
@property (nonatomic, assign) BOOL isLandscape;

@property (nonatomic,assign) CGSize verticalVideoSize;

-(void)updatePlayerWithURl:(NSURL *)url;


@end

@interface RotationScreen : NSObject

/**
 *  切换横竖屏
 *
 *  @param orientation UIInterfaceOrientation
 */
+ (void)forceOrientation:(UIInterfaceOrientation)orientation;

/**
 *  是否是横屏
 *
 *  @return 是 返回yes
 */
+ (BOOL)isOrientationLandscape;

@end
