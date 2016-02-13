//
//  ConfigViewController.h
//  WearableDevice
//
//  Created by Takuya on 2015/07/08.
//  Copyright (c) 2015年 Takuya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Const.h"


@protocol ConfigViewControllerDelegate <NSObject>

- (void)checkStatus;

@end

@interface ConfigViewController : UIViewController

@property (weak, nonatomic) id<ConfigViewControllerDelegate> delegate;

- (id)init;
- (void)closeView;

@end
