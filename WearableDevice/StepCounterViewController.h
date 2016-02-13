//
//  StepCounterViewController.h
//  WearableDevice
//
//  Created by Takuya on 2015/07/06.
//  Copyright (c) 2015年 Takuya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <HealthKit/HealthKit.h>
#import "Const.h"
#import "ConfigViewController.h"

@interface StepCounterViewController : UIViewController <CLLocationManagerDelegate, ConfigViewControllerDelegate>

+ (void)clearData;

@end
