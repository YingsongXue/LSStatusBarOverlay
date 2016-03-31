//
//  LSStatusBarOverlay.m
//  LSStatusBarOverLay
//
//  Created by 薛 迎松 on 16/3/16.
//  Copyright © 2016年 薛 迎松. All rights reserved.
//

#import "LSStatusBarOverlay.h"
#include <objc/runtime.h>

@interface LSStatusBarOverlay ()
@property (nonatomic, weak) UIWindow *overlayWindow;//only when plist file contain
@property (nonatomic, strong) NSTimer *dismissTimer;
@property (nonatomic, assign) BOOL isDisplaying;

@property (nonatomic, weak) NSLayoutConstraint *statusBarOverlayHeightCons;
@end

#pragma mark Window interface
@interface UIApplication(LSMainWindow)
- (UIWindow *)mainApplicationWindow;
- (UIWindow *)mainApplicationWindowIgnoringWindow:(UIWindow *)ignoringWindow;
@end
#pragma mark LSWindow interface
@interface LSWindow : UIWindow
@end

@implementation LSStatusBarOverlay

- (instancetype)init
{
    if (self = [super init])
    {
        [self loadThisView];
        self.backgroundColor = [UIColor blackColor];
        
        [self bringSubviewToFront:self.backgroundView];
        [self bringSubviewToFront:self.messageLabel];
        [self bringSubviewToFront:self.activityIndicatorView];
    }
    return self;
}

- (void)postMessage:(NSString *)message
{
    [self postMessage:message dismissAfter:0];
}

- (void)postMessage:(NSString *)message dismissAfter:(NSTimeInterval)timeInterval
{
    self.isDisplaying = YES;
    self.messageLabel.text = message;
    if (timeInterval > 0)
    {
        [self setDismissTimerWithInterval:timeInterval];
    }
    else
    {
        [self invalidateDismissTimer];
    }
}

#pragma mark Dismiss
- (void)invalidateDismissTimer
{
    [self.dismissTimer invalidate];
    self.dismissTimer = nil;
}

- (void)setDismissTimerWithInterval:(NSTimeInterval)interval;
{
    [self invalidateDismissTimer];
    self.dismissTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]
                                                 interval:0 target:self selector:@selector(dismiss:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.dismissTimer forMode:NSRunLoopCommonModes];
}

- (void)dismiss:(NSTimer*)timer;
{
    [self dismissAnimated:YES];
}

- (void)dismissAnimated:(BOOL)animated;
{
    [self invalidateDismissTimer];
    
    if (animated)
    {
        [UIView animateWithDuration:0.4 animations:^{
            self.isDisplaying = NO;
        } completion:^(BOOL finished) {
            self.isDisplaying = NO;
        }];
    }
    else
    {
        self.isDisplaying = NO;
    }
    
//    if (self.delegate && [self.delegate respondsToSelector:@selector(statusBarDidHide)])
//    {
//        [self.delegate statusBarDidHide];
//    }
}

- (void)hideDisplay;
{
    self.isDisplaying = NO;
}

- (BOOL)isVisible
{
    return self.isDisplaying;
}

#pragma mark Setter or Getter
- (void)setIsDisplaying:(BOOL)isDisplaying
{
    _isDisplaying = isDisplaying;
    
    BOOL isVCBasedStatusBar = [self isViewControllerBasedStatusBarAppearance];
    UIWindow *window = [[UIApplication sharedApplication] mainApplicationWindow];
    if (isVCBasedStatusBar)
    {
        if (isDisplaying)
        {
            [window bringSubviewToFront:self.overlayWindow];
        }
        
        self.overlayWindow.hidden = !isDisplaying;
    }
    else
    {
        if (isDisplaying)
        {
            [window bringSubviewToFront:self];
        }
        
        [self setBarHidden:isDisplaying animation:NO];
        
        [UIView animateWithDuration:0.4 animations:^{
            self.hidden = !isDisplaying;
            
        } completion:^(BOOL finished) {
            self.hidden = !isDisplaying;
        }];
    }
}

- (void)setBarHidden:(BOOL)isHidden animation:(BOOL)animation
{
    BOOL isVCBasedStatusBar = [self isViewControllerBasedStatusBarAppearance];
    
    if (isVCBasedStatusBar)
    {
        NSLog(@"Please set [View controller-based status bar appearance] = NO in info.plist");
        
        UIWindow *window = [[UIApplication sharedApplication] mainApplicationWindow];
        UIViewController *topViewController = window.rootViewController;
        if ([window.rootViewController isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navi = (UINavigationController *)window.rootViewController;
            
            topViewController = navi.topViewController;
            while ([topViewController presentedViewController]) {
                topViewController = [topViewController presentedViewController];
            }
        }
//        topViewController
//        class_addMethod([UIViewController class], @selector(prefersStatusBarHidden), (IMP)prefersStatusBarHidden, "v@:");
        
        [topViewController setNeedsStatusBarAppearanceUpdate];
    }
    else
    {
        if (animation) {
            [[UIApplication sharedApplication] setStatusBarHidden:isHidden withAnimation:UIStatusBarAnimationFade];
        }
        else
        {
            [[UIApplication sharedApplication] setStatusBarHidden:isHidden];
        }
    }
}

- (BOOL)isViewControllerBasedStatusBarAppearance
{
    NSNumber *viewControllerBasedStatusBarAppearance = [[NSBundle mainBundle]objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
    BOOL isVCBasedStatusBar = YES;
    
    //If not set
    if (viewControllerBasedStatusBarAppearance)
    {
        isVCBasedStatusBar = [viewControllerBasedStatusBarAppearance boolValue];
    }
    return isVCBasedStatusBar;
}

//- (BOOL)prefersStatusBarHidden
//{
//    return self.isDisplaying;
//}

#pragma mark Actions
- (void)tapOnMessage:(UITapGestureRecognizer *)tapGes
{
    [self hideDisplay];
}

#pragma mark Views
- (void)loadThisView
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnMessage:)];
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
    
    BOOL isVCBasedStatusBar = [self isViewControllerBasedStatusBarAppearance];
    UIWindow *window = [[UIApplication sharedApplication] mainApplicationWindow];
    
    if (isVCBasedStatusBar)
    {
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor clearColor];
        LSWindow *overlayWindow = [[LSWindow alloc] init];
        overlayWindow.rootViewController = viewController;
        overlayWindow.autoresizingMask = UIViewAutoresizingNone;
        overlayWindow.windowLevel = UIWindowLevelStatusBar + 1;
        overlayWindow.translatesAutoresizingMaskIntoConstraints = NO;
        overlayWindow.hidden = NO;
        [window addSubview:overlayWindow];
        self.overlayWindow = overlayWindow;
        
        NSDictionary *viewDict = NSDictionaryOfVariableBindings(overlayWindow);
        [window addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[overlayWindow]-0-|" options:0 metrics:nil views:viewDict]];
        [window addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[overlayWindow]" options:0 metrics:nil views:viewDict]];
        NSLayoutConstraint *statusBarOverlayHeightCons = [NSLayoutConstraint constraintWithItem:overlayWindow attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
        statusBarOverlayHeightCons.constant = [UIApplication sharedApplication].statusBarFrame.size.height;
        self.statusBarOverlayHeightCons = statusBarOverlayHeightCons;
        [window addConstraint:statusBarOverlayHeightCons];
        //set self;
        [overlayWindow addSubview:self];
        UIView *view = self;
        NSDictionary *myViewDict = NSDictionaryOfVariableBindings(view);
        [overlayWindow addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|" options:0 metrics:nil views:myViewDict]];
        [overlayWindow addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:0 metrics:nil views:myViewDict]];
        [window setNeedsLayout];
        [window updateConstraintsIfNeeded];
    }
    else
    {
        [window addSubview:self];
        
        self.layer.zPosition = FLT_MAX-1; //even unable to touch, make it top of every other view
        
        UIView *view = self;
        NSDictionary *viewDict = NSDictionaryOfVariableBindings(view);
        [window addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|" options:0 metrics:nil views:viewDict]];
        [window addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]" options:0 metrics:nil views:viewDict]];
        NSLayoutConstraint *statusBarOverlayHeightCons = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
        statusBarOverlayHeightCons.constant = [UIApplication sharedApplication].statusBarFrame.size.height;
        self.statusBarOverlayHeightCons = statusBarOverlayHeightCons;
        [window addConstraint:statusBarOverlayHeightCons];
    }
}

- (UIView *)backgroundView
{
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:_backgroundView];
        
        NSDictionary *viewDict = NSDictionaryOfVariableBindings(_backgroundView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_backgroundView]-0-|" options:0 metrics:nil views:viewDict]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_backgroundView]-0-|" options:0 metrics:nil views:viewDict]];
    }
    return _backgroundView;
}

- (UILabel *)messageLabel
{
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _messageLabel.text = @"";
        _messageLabel.textColor = [UIColor whiteColor];
        _messageLabel.font = [UIFont systemFontOfSize:12];
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.adjustsFontSizeToFitWidth = NO;
        _messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _messageLabel.clipsToBounds = YES;
        
        [self addSubview:_messageLabel];
        
        NSDictionary *viewDict = NSDictionaryOfVariableBindings(_messageLabel);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_messageLabel]-0-|" options:0 metrics:nil views:viewDict]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_messageLabel]-0-|" options:0 metrics:nil views:viewDict]];
    }
    return _messageLabel;
}

- (UIActivityIndicatorView *)activityIndicatorView;
{
    if (!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.transform = CGAffineTransformMakeScale(0.7, 0.7);
//        [_activityIndicatorView startAnimating];
        _activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_activityIndicatorView];
        
        NSDictionary *viewDict = NSDictionaryOfVariableBindings(_activityIndicatorView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_activityIndicatorView]" options:0 metrics:nil views:viewDict]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_activityIndicatorView]-0-|" options:0 metrics:nil views:viewDict]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicatorView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_activityIndicatorView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
    }
    return _activityIndicatorView;
}

#pragma mark Singleton
+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    __strong static id sharedOverlay = nil;
    
    dispatch_once(&pred, ^{
        sharedOverlay = [[[self class] alloc] init];
    });
    
    return sharedOverlay;
}

+ (instancetype)sharedOverlay
{
    return [self sharedInstance];
}

@end


#pragma mark Window Implement
@implementation UIApplication (LSMainWindow)

- (UIWindow *)mainApplicationWindow
{
    return [self mainApplicationWindowIgnoringWindow:nil];
}

- (UIWindow*)mainApplicationWindowIgnoringWindow:(UIWindow *)ignoringWindow
{
    for (UIWindow *window in [self windows]) {
        if (!window.hidden && window != ignoringWindow) {
            return window;
        }
    }
    return nil;
}
@end

#pragma mark LSWindow
@implementation LSWindow


//- (void)setFrame:(CGRect)frame
//{
//    CGFloat height = CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]);
//    [super setFrame:CGRectMake(0, 0, CGRectGetWidth(frame), height)];
////    [super setFrame:frame];
////    NSLog(@"%@",[self constraints]);
//}
//
- (void)layoutSubviews{
    [super layoutSubviews];
}

@end

