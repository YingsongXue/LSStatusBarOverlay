//
//  LSStatusBarOverlay.h
//  LSStatusBarOverLay
//
//  Created by 薛 迎松 on 16/3/16.
//  Copyright © 2016年 薛 迎松. All rights reserved.
//
/*
 Do remember 
 Please set [View controller-based status bar appearance] = NO in info.plist
 */
#import <UIKit/UIKit.h>

@interface LSStatusBarOverlay : UIView

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong, readonly) UIProgressView *progressView;

+ (instancetype)sharedOverlay;
+ (instancetype)sharedInstance;

- (void)postMessage:(NSString *)message;
- (void)postMessage:(NSString *)message dismissAfter:(NSTimeInterval)timeInterval;
- (void)hideDisplay;

- (BOOL)isVisible;

@end


#pragma mark StatusBarDelegate
@protocol JDStatusBarNotificationDelegate <NSObject>

@optional
- (void)statusBarDidRecognizeGesture:(UIGestureRecognizer *)gestureRecognizer;

- (void)statusBarDidHide;

@end