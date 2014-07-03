//
//  VSAppDelegate.m
//  VSDictSpider
//
//  Created by steven.zhuang on 7/3/14.
//  Copyright (c) 2014 StevenZhuang. All rights reserved.
//

#import "VSAppDelegate.h"
#import "VSMainViewController.h"


@interface VSAppDelegate()

@property (nonatomic, strong) VSMainViewController *mainVC;

@end

@implementation VSAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.mainVC = [[VSMainViewController alloc] initWithNibName: NSStringFromClass([VSMainViewController class]) bundle: nil];
    [self.window.contentView addSubview: self.mainVC.view];
}

@end
