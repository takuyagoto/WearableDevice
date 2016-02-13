//
//  AppDelegate.m
//  WearableDevice
//
//  Created by Takuya on 2015/07/05.
//  Copyright (c) 2015年 Takuya. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // HealthStore使用の確認
    // Health Kitが使用できるか
    // Health KitはiOS 8.0 以上のみ
    if (NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable]) {
        
        HKHealthStore *healthStore = [[HKHealthStore alloc] init];
        
        // 歩数と歩行距離データへのread/write権限のを要求する
        NSSet *shareObjectTypes = [NSSet setWithObjects:
                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning],
                                   nil];
        
        [healthStore requestAuthorizationToShareTypes:shareObjectTypes
                                            readTypes:nil
                                           completion:^(BOOL success, NSError *error) {
                                               // 選択終了時のハンドリング
                                           }];
    }
    
    // プッシュ通知使用の確認
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    
    // 通値取得時
    UILocalNotification *localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        [application cancelAllLocalNotifications];
        if ([[localNotification.userInfo objectForKey:NOTIFICATION_INFO_TYPE] isEqualToString:START_NOTIFICATION_INFO]) {
            [StepCounterViewController clearData];
        }
        if ([[localNotification.userInfo objectForKey:NOTIFICATION_INFO_TYPE] isEqualToString:END_NOTIFICATION_INFO]) {
            
        }
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    _stepCounterViewController = [[StepCounterViewController alloc] init];
    self.window.rootViewController = _stepCounterViewController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {

    if (notification) {
        if ([[notification.userInfo objectForKey:NOTIFICATION_INFO_TYPE] isEqualToString:START_NOTIFICATION_INFO]) {
            [StepCounterViewController clearData];
        }
        if ([[notification.userInfo objectForKey:NOTIFICATION_INFO_TYPE] isEqualToString:END_NOTIFICATION_INFO]) {
            
        }
    }
}

@end
