//
//  PedoViewController.m
//  WearableDevice
//
//  Created by Takuya on 2015/07/06.
//  Copyright (c) 2015年 Takuya. All rights reserved.
//

#import "PedoViewController.h"

@interface PedoViewController ()
{
    UILabel *stepLabel;
    UILabel *startDateLabel;
    UILabel *endDateLabel;
    UILabel *distanceLabel;
    UILabel *floorAscLabel;
    UILabel *floorDescLabel;
}

@property (strong, nonatomic) CMPedometer *pedometer;

@end

@implementation PedoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    float height = (rect.size.height-100) / 6;
    float matginTop = 50.;
    
    stepLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, matginTop, rect.size.width, height)];
    stepLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    stepLabel.backgroundColor = [UIColor whiteColor];
    [stepLabel.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [stepLabel.layer setBorderWidth: 2.];
    stepLabel.font = [UIFont fontWithName:@"AppleGothic" size:20];
    stepLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:stepLabel];
    
    distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, matginTop + height*1, rect.size.width, height)];
    distanceLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    distanceLabel.backgroundColor = [UIColor whiteColor];
    [distanceLabel.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [distanceLabel.layer setBorderWidth: 2.];
    distanceLabel.font = [UIFont fontWithName:@"AppleGothic" size:20];
    distanceLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:distanceLabel];
    
    startDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, matginTop + height*2, rect.size.width, height)];
    startDateLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    startDateLabel.backgroundColor = [UIColor whiteColor];
    [startDateLabel.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [startDateLabel.layer setBorderWidth: 2.];
    startDateLabel.font = [UIFont fontWithName:@"AppleGothic" size:20];
    startDateLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:startDateLabel];
    
    endDateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, matginTop + height*3, rect.size.width, height)];
    endDateLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    endDateLabel.backgroundColor = [UIColor whiteColor];
    [endDateLabel.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [endDateLabel.layer setBorderWidth: 2.];
    endDateLabel.font = [UIFont fontWithName:@"AppleGothic" size:20];
    endDateLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:endDateLabel];
    
    floorAscLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, matginTop + height*4, rect.size.width, height)];
    floorAscLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    floorAscLabel.backgroundColor = [UIColor whiteColor];
    [floorAscLabel.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [floorAscLabel.layer setBorderWidth: 2.];
    floorAscLabel.font = [UIFont fontWithName:@"AppleGothic" size:20];
    floorAscLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:floorAscLabel];
    
    floorDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, matginTop + height*5, rect.size.width, height)];
    floorDescLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    floorDescLabel.backgroundColor = [UIColor whiteColor];
    [floorDescLabel.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [floorDescLabel.layer setBorderWidth: 2.];
    floorDescLabel.font = [UIFont fontWithName:@"AppleGothic" size:20];
    floorDescLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:floorDescLabel];
    
    NSString *stepText = @"歩数: 0";
    NSString *distanceText = @"距離: 0m";
    NSString *startDateText = @"開始時刻: ";
    NSString *endDateText = @"終了時刻: ";
    NSString *floorAscText = @"上った回数: 0";
    NSString *floorDescText = @"降りた回数: 0";
    
    [self updateLabelsStep:stepText distance:distanceText startDate:startDateText endDate:endDateText floorsAcsended:floorAscText floorsDescended:floorDescText];
    
    _pedometer = [[CMPedometer alloc] init];
    // CMPedometerが利用可能か判断
    if ([CMPedometer isStepCountingAvailable] && [CMPedometer isDistanceAvailable] && [CMPedometer isFloorCountingAvailable]) {
        [self startPedometer];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    // CMPedometerが利用可能か判断
    if (![CMPedometer isStepCountingAvailable] || ![CMPedometer isDistanceAvailable] || ![CMPedometer isFloorCountingAvailable]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"CMPedometer" message:@"ご使用の端末では歩数を取得できません。" preferredStyle:UIAlertControllerStyleAlert];
        
        // addActionした順に左から右にボタンが配置されます
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)startPedometer {
    [_pedometer startPedometerUpdatesFromDate:[NSDate date]
                                  withHandler:^(CMPedometerData *pedometerData, NSError *error) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          // 歩数
                                          NSNumber *step = pedometerData.numberOfSteps;
                                          // 歩いた距離
                                          NSNumber *distance = pedometerData.distance;
                                          
                                          NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                          [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
                                          // 開始日時
                                          NSString *startDate = [dateFormatter stringFromDate:pedometerData.startDate];
                                          // 終了日
                                          NSString *endDate = [dateFormatter stringFromDate:pedometerData.endDate];
                                          
                                          // 階段の昇降
                                          NSNumber *floorsAscended = pedometerData.floorsAscended;
                                          NSNumber *floorsDescemded = pedometerData.floorsDescended;
                                          
                                          NSString *stepText = [[NSString alloc] initWithFormat:@"歩数: %@", step];
                                          NSString *distanceText = [[NSString alloc] initWithFormat:@"距離: %@m", distance];
                                          NSString *startDateText = [[NSString alloc] initWithFormat:@"開始時刻: %@", startDate];
                                          NSString *endDateText = [[NSString alloc] initWithFormat:@"終了時刻: %@", endDate];
                                          NSString *floorAscText = [[NSString alloc] initWithFormat:@"上った回数: %@", floorsAscended];
                                          NSString *floorDescText = [[NSString alloc] initWithFormat:@"降りた回数: %@", floorsDescemded];
                                          
                                          [self updateLabelsStep:stepText distance:distanceText startDate:startDateText endDate:endDateText floorsAcsended:floorAscText floorsDescended:floorDescText];
                                          
                                          
                                          NSString *msg = [[NSString alloc] initWithFormat:@"PedoMeter Result¥n%@¥n%@¥n%@¥n%@¥n%@¥n%@", stepText, distanceText, startDateText, endDateText, floorAscText, floorDescText];
                                          
                                          // ローカルプッシュ通知
                                          [self sendLocalNotificationForMessage:msg soundFlag:NO];
                                          
                                      });
                                  }];
}

- (void)updateLabelsStep:(NSString *)step distance:(NSString *)distance startDate:(NSString *)startDate endDate:(NSString *)endDate floorsAcsended:(NSString *)floorAsc floorsDescended:(NSString *)floorDesc {
    stepLabel.text = step;
    distanceLabel.text = distance;
    startDateLabel.text = startDate;
    endDateLabel.text = endDate;
    floorAscLabel.text = floorAsc;
    floorDescLabel.text = floorDesc;
}

- (void)sendLocalNotificationForMessage:(NSString *)msg soundFlag:(BOOL)soundFlag {
    
    UILocalNotification *localNotification = [UILocalNotification new];
    localNotification.alertBody = msg;
    localNotification.fireDate = [NSDate date];
    if (soundFlag) {
        localNotification.soundName = UILocalNotificationDefaultSoundName;
    }
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

@end
