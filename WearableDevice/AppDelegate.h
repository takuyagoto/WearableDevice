//
//  AppDelegate.h
//  WearableDevice
//
//  Created by Takuya on 2015/07/05.
//  Copyright (c) 2015年 Takuya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>
#import "StepCounterViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong,nonatomic) StepCounterViewController *stepCounterViewController;

@end

