//
//  ViewController.m
//  LSStatusBarOverLay
//
//  Created by 薛 迎松 on 16/3/16.
//  Copyright © 2016年 薛 迎松. All rights reserved.
//

#import "ViewController.h"
#import "LSStatusBarOverlay.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor purpleColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)postMessage
{
//    NSString *message = [NSString stringWithFormat:@"%u",arc4random()];
    [[LSStatusBarOverlay sharedInstance] postMessage:self.textField.text dismissAfter:3];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
