//
//  StepCounterViewController.m
//  WearableDevice
//
//  Created by Takuya on 2015/07/06.
//  Copyright (c) 2015年 Takuya. All rights reserved.
//

#import "StepCounterViewController.h"

typedef NS_ENUM(NSInteger, SCTimerMode) {
    SCTimerModeOn = 1,
    SCTimerModeOff
};

@interface StepCounterViewController () {
    NSInteger stepCount;
    BOOL stepFlag;
    CLLocationDistance distance;
    NSDate *startDate;
    NSDate *endDate;
    NSString *confStartTime;
    NSString *confEndTime;
    NSDate *confStartDate;
    NSDate *onTimerDate;
    NSDate *offTimerDate;
    NSDate *confEndDate;
    double filterX;
    double filterY;
    double filterZ;
    SCTimerMode mode;
    HKHealthStore *healthStore;
}

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) UILabel *statusLabel;
@property (strong, nonatomic) UILabel *startDateLabel;
@property (strong, nonatomic) UILabel *stepLabel;
@property (strong, nonatomic) UILabel *distanceLabel;
@property (strong, nonatomic) UIButton *clearBtn;
@property (strong, nonatomic) NSTimer *onTimer;
@property (strong, nonatomic) NSTimer *offTimer;
@property (strong, nonatomic) UIButton *modeButton;

@property (strong, nonatomic) ConfigViewController *configViewController;

@end

@implementation StepCounterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    // フィルターの初期化
    filterX = 0;
    filterY = 0;
    filterZ = 0;
    
    stepFlag = NO;
    [self getMode];
    [self getData];
    
    // 画面生成
    [self createView];
}

- (void)viewWillAppear:(BOOL)animated  {
    [super viewWillAppear:animated];
    // 設定を調べて動作を変更する
    [self checkStatus];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![self getTimerData]) {
        [self toConfigView];
    } else {
        [self checkHealthStoreAuthority];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self syncData];
    [self inactivate];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self syncData];
}

#pragma mark - Public Method

// 監視を開始する
- (void)activate {
    self.statusLabel.text = @"Active";
    self.statusLabel.textColor = [UIColor blueColor];
    self.clearBtn.enabled = YES;
    
    if (![self getData]) {
        [self initData];
        [self syncData];
    }
    
    if (![self checkTodaysData]) {
        [self storeDatatoHealthStore];
    }
    
    [self updateLabel];
    // CMMotionManagerのインスタンスの生成
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    if (_motionManager.accelerometerAvailable) {
        // センサーの更新間隔の指定
        _motionManager.accelerometerUpdateInterval = 1 / UPDATE_FREQUENCY;
        
        // ハンドラを指定
        CMAccelerometerHandler handler = ^(CMAccelerometerData *data, NSError *error) {
            [self countStepWithAccelerationX:data.acceleration.x Y:data.acceleration.y Z:data.acceleration.z];
        };
        
        // 加速度の取得開始
        [_motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    // CLLocationManagerのインスタンスを作成
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    if ([CLLocationManager locationServicesEnabled]) {
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest; // 精度
        _locationManager.activityType = CLActivityTypeFitness;
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        _locationManager.distanceFilter = 100.0; // 指定距離以上移動すると位置情報を更新
        
        // 位置情報の取得開始
        [_locationManager startUpdatingLocation];
    }
    
    [self setOffTimer];
    
}

// 監視をやめる
- (void)inactivate {
    self.statusLabel.text = @"Non-Active";
    self.statusLabel.textColor = [UIColor redColor];
    self.clearBtn.enabled = NO;
    [self setOnTimer];
    
    if (_motionManager) {
        stepFlag = NO;
        [_motionManager stopAccelerometerUpdates];
    }
    /*
    if (_locationManager) {
        [_locationManager stopUpdatingLocation];
    }
     */
}

#pragma mark - Private Method

- (void)checkStatus {
    
    [self getData];
    [self syncData];
    [self updateLabel];
    
    if (mode == SCTimerModeOn) {
        if ([self isActiveTime]) {
            [self activate];
        } else {
            [self inactivate];
        }
    } else {
        [self inactivate];
        // Monitoring全停止
        if (_motionManager) {
            [_motionManager stopAccelerometerUpdates];
        }
        if (_locationManager) {
            [_locationManager stopUpdatingLocation];
        }
        // 登録されている通知を全部削除
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
        // Timer停止
        if (_onTimer) {
            [_onTimer invalidate];
        }
        if (_offTimer) {
            [_offTimer invalidate];
        }
    }
}

//
- (BOOL)checkTodaysData {
    NSDate *now = [NSDate date];
    if ([now compare:endDate] == NSOrderedDescending) {
        return NO;
    }
    return YES;
}

// ラベルを作成
- (void)createView {
    
    self.view.backgroundColor = [UIColor clearColor];

    CGRect rect = [[UIScreen mainScreen] bounds];
    float deviceWidth = rect.size.width;
    float deviceHeight = rect.size.height;
    float height = (deviceHeight-20) / 8;
    //float width = deviceWidth / 3;
    
    [self getData];
    
    UIVisualEffectView *headerField = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
    headerField.frame = CGRectMake(0, 0, deviceWidth, height + 20);
    [self.view addSubview:headerField];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, deviceWidth, height - 5)];
    self.statusLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.statusLabel.font = [UIFont fontWithName:@"AppleGothic" size:25];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.text = @"Non-Active";
    self.statusLabel.textColor = [UIColor redColor];
    [headerField addSubview:self.statusLabel];
    
    
    UIVisualEffectView *monitorField = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    monitorField.frame = CGRectMake(40, 20 + height*2, deviceWidth - 80, height*4);
    monitorField.layer.cornerRadius = 15;
    monitorField.clipsToBounds = YES;
    [self.view addSubview:monitorField];
    
    UILabel *labelStartDate = [[UILabel alloc] initWithFrame:CGRectMake(10, height*0, (deviceWidth - 100)*0.4, height)];
    labelStartDate.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    labelStartDate.font = [UIFont fontWithName:@"AppleGothic" size:20];
    labelStartDate.textAlignment = NSTextAlignmentRight;
    labelStartDate.textColor = [UIColor whiteColor];
    labelStartDate.text = @"Start At:";
    [monitorField addSubview:labelStartDate];
    
    UILabel *labelStep = [[UILabel alloc] initWithFrame:CGRectMake(10, height*1, (deviceWidth - 100)*0.4, height)];
    labelStep.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    labelStep.font = [UIFont fontWithName:@"AppleGothic" size:20];
    labelStep.textAlignment = NSTextAlignmentRight;
    labelStep.textColor = [UIColor whiteColor];
    labelStep.text = @"Step:";
    [monitorField addSubview:labelStep];
    
    UILabel *labelDistance = [[UILabel alloc] initWithFrame:CGRectMake(10, height*2, (deviceWidth - 100)*0.4, height)];
    labelDistance.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    labelDistance.font = [UIFont fontWithName:@"AppleGothic" size:20];
    labelDistance.textAlignment = NSTextAlignmentRight;
    labelDistance.textColor = [UIColor whiteColor];
    labelDistance.text = @"Distance:";
    [monitorField addSubview:labelDistance];
    
    self.startDateLabel = [[UILabel alloc] initWithFrame:CGRectMake((deviceWidth - 100)*0.4, 0, (deviceWidth - 100)*0.6, height)];
    self.startDateLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.startDateLabel.font = [UIFont fontWithName:@"AppleGothic" size:15];
    self.startDateLabel.textColor = [UIColor whiteColor];
    self.startDateLabel.textAlignment = NSTextAlignmentRight;
    self.startDateLabel.textColor = [UIColor whiteColor];
    [monitorField addSubview:self.startDateLabel];
    
    self.stepLabel = [[UILabel alloc] initWithFrame:CGRectMake((deviceWidth - 100)*0.4, height, (deviceWidth - 100)*0.6, height)];
    self.stepLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.stepLabel.font = [UIFont fontWithName:@"AppleGothic" size:20];
    self.stepLabel.textColor = [UIColor whiteColor];
    self.stepLabel.textAlignment = NSTextAlignmentRight;
    self.stepLabel.textColor = [UIColor whiteColor];
    [monitorField addSubview:self.stepLabel];
    
    self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake((deviceWidth - 100)*0.4, height*2, (deviceWidth - 100)*0.6, height)];
    self.distanceLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.distanceLabel.font = [UIFont fontWithName:@"AppleGothic" size:20];
    self.distanceLabel.textAlignment = NSTextAlignmentRight;
    self.distanceLabel.textColor = [UIColor whiteColor];
    [monitorField addSubview:self.distanceLabel];
    
    self.clearBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.clearBtn.frame = CGRectMake(monitorField.frame.size.width/2 - 50, height*3, 100, height);
    [self.clearBtn setTitle:@"Clear" forState:UIControlStateNormal];
    [self.clearBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
    [self.clearBtn addTarget:self
               action:@selector(clear:)
     forControlEvents:UIControlEventTouchUpInside];
    self.clearBtn.enabled = NO;
    [monitorField addSubview:self.clearBtn];
    
    UIVisualEffectView *controlerField = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    controlerField.frame = CGRectMake(0, deviceHeight - height, deviceWidth, height);
    [self.view addSubview:controlerField];
    
    self.modeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.modeButton.frame = CGRectMake(deviceWidth*0.25, 5, deviceWidth*0.5, height);
    [self.modeButton.titleLabel setFont:[UIFont systemFontOfSize:20]];
    [self.modeButton addTarget:self
                   action:@selector(settingMode:)
         forControlEvents:UIControlEventTouchUpInside];
    [self updateModeButton];
    [controlerField addSubview:self.modeButton];
    
}

// ラベルの更新
- (void)updateLabel {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd HH:mm"];
    
    // 画面に表示
    if ([self getData]) {
        self.startDateLabel.text = [dateFormatter stringFromDate:startDate];
        self.stepLabel.text = [NSString stringWithFormat:@"%ld", (long)stepCount];
        self.distanceLabel.text = [NSString stringWithFormat: @"%.1fkm", distance / 1000];
    } else {
        self.startDateLabel.text = @"--/-- --:--";
        self.stepLabel.text = @"--";
        self.distanceLabel.text = @"--km";
    }
}

// Config Viewへの遷移
- (void)toConfigView {
    if (!_configViewController) {
        _configViewController = [[ConfigViewController alloc] init];
        _configViewController.delegate = self;
        _configViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        
    }
    [self presentViewController:_configViewController animated:YES completion:nil];
}

// 設定時間ないかどうかを調べる
- (BOOL)isActiveTime {
    
    // 登録されている通知を全部削除
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
     // Timer停止
    if (_onTimer) {
        [_onTimer invalidate];
    }
    if (_offTimer) {
        [_offTimer invalidate];
    }
    
    if (![self getTimerData]) {
        return NO;
    }
    
    NSDate *now = [NSDate date];
    if ([now compare:confStartDate] == NSOrderedAscending || [now compare:confEndDate] == NSOrderedDescending) {
        return NO;
    }
    
    return YES;
}

- (void)setOffTimer {
    if (![self getTimerData]) {
        return;
    }
    
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm"];
    NSString *msg = [NSString stringWithFormat:@"%@\n記録を終了しました。\nおつかれさまでした。",[dateFormatter stringFromDate:confEndDate]];
    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:END_NOTIFICATION_INFO forKey:NOTIFICATION_INFO_TYPE];
    [self sendLocalNotificationForMessage:msg fireDate:confEndDate UserInfo:infoDict];
    
    _offTimer = [NSTimer scheduledTimerWithTimeInterval:[confEndDate timeIntervalSinceNow] target:self selector:@selector(off:) userInfo:nil repeats:NO];
}
                                                                               
- (void)setOnTimer {
    if (![self getTimerData]) {
        return;
    }
    [self getData];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm"];
    if ([[NSDate date] compare:confStartDate] == NSOrderedDescending) {
        onTimerDate = [confStartDate initWithTimeInterval:1*24*60*60 sinceDate:confStartDate];
    } else {
        onTimerDate = confStartDate;
    }
    
    NSString *msg = [NSString stringWithFormat:@"%@\n記録を開始しました。\n今日も頑張りましょう。",[dateFormatter stringFromDate:confStartDate]];
    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:START_NOTIFICATION_INFO forKey:NOTIFICATION_INFO_TYPE];
    [self sendLocalNotificationForMessage:msg fireDate:onTimerDate UserInfo:infoDict];

    _onTimer = [NSTimer scheduledTimerWithTimeInterval:[onTimerDate timeIntervalSinceNow] target:self selector:@selector(on:) userInfo:nil repeats:NO];
}

// 加速度センサーデータ処理
- (void)countStepWithAccelerationX:(double)acceX Y:(double)acceY Z:(double)acceZ {
  
    
    // ローパスフィルタをかける
    filterX = (acceX * kFilteringFactor) + (filterX * (1.0 - kFilteringFactor));
    filterY = (acceY * kFilteringFactor) + (filterY * (1.0 - kFilteringFactor));
    filterZ = (acceZ * kFilteringFactor) + (filterZ * (1.0 - kFilteringFactor));
    
    // 加速度の合成
    double resultantAcce = sqrt(pow(filterX, 2) + pow(filterY, 2) + pow(filterZ, 2));
    
    // 歩数を数える
    if (stepFlag) {
        if (resultantAcce < LOWER_THRESHOLD) {
            stepCount++;
            [self syncData];
            [self updateLabel];
            stepFlag = NO;
        }
    } else {
        if (resultantAcce > UPPER_THRESHOLD) {
            stepFlag = YES;
        }
    }
}

// 通知の登録
- (void)sendLocalNotificationForMessage:(NSString *)msg fireDate:(NSDate *)fireDate UserInfo:(NSDictionary *)info {
    
    UILocalNotification *localNotification = [UILocalNotification new];
    
    localNotification.alertBody = msg;
    localNotification.fireDate = fireDate;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.alertAction = @"Open";
    // 通知識別のための情報
    localNotification.userInfo = info;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)updateModeButton {
    switch (mode) {
        case SCTimerModeOn:
            [self.modeButton setTitle:@"Timer ON" forState:UIControlStateNormal];
            [self.modeButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
            break;
            
        case SCTimerModeOff:
            [self.modeButton setTitle:@"Timer OFF" forState:UIControlStateNormal];
            [self.modeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

- (void)switchMode:(SCTimerMode)changeMode {
    if (mode != changeMode) {
        mode = changeMode;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setInteger:mode forKey:CONFIG_MODE_TAG];
        [userDefaults synchronize];
        [self updateModeButton];
        [self checkStatus];
    }
}

#pragma mark - Timer Event Method
// 起動タイマー作動時
- (void)on:(NSTimer *)timer {
    [timer invalidate];
    [StepCounterViewController clearData];
    [self activate];
}

//
- (void)off:(NSTimer *)timer {
    [timer invalidate];
    [self storeDatatoHealthStore];
    [self inactivate];
}

#pragma mark - Button Event Method

// Clearボタン押下処理
- (void)clear:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:@"現在のデータを削除します。よろしいですか？"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"	
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          [StepCounterViewController clearData];
                                                          [self initData];
                                                          [self syncData];
                                                          [self updateLabel];
                                                      }
                                ]];
    [self presentViewController:alertController animated:YES completion:nil];
}

// 設定ボタンアクション
- (void)settingMode:(id)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Select Timer Mode." message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"ON"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action){
                                                          [self switchMode:SCTimerModeOn];
                                                  }
                                ]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OFF"
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action){
                                                          [self switchMode:SCTimerModeOff];
                                                  }
                                ]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Change Activate Time"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action){
                                                          [self toConfigView];
                                                      }
                                ]];
    
    // iPad用コード
    alertController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *pop = alertController.popoverPresentationController;
    pop.sourceView = self.modeButton;
    pop.sourceRect = self.modeButton.bounds;
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Data Method

// UserDefaultから値を取得
- (BOOL)getData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults objectForKey:DATA_START_DATE_TAG] != nil) {
        startDate = [userDefaults objectForKey:DATA_START_DATE_TAG];
    } else {
        startDate = nil;
        return NO;
    }
    if ([userDefaults objectForKey:DATA_END_DATE_TAG] != nil) {
        endDate = [userDefaults objectForKey:DATA_END_DATE_TAG];
    } else {
        endDate = nil;
        return NO;
    }
    
    if ([userDefaults integerForKey:DATA_STEP_TAG] >= 0) {
        stepCount = [userDefaults integerForKey:DATA_STEP_TAG];
    } else {
        stepCount = -1;
        return NO;
    }
    if ([userDefaults doubleForKey:DATA_DISTANCE_TAG] >= 0) {
        distance = [userDefaults doubleForKey:DATA_DISTANCE_TAG];
    } else {
        distance = -1;
        return NO;
    }
    return YES;
}

- (void)getMode {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults integerForKey:CONFIG_MODE_TAG]) {
        mode = (SCTimerMode)[userDefaults integerForKey:CONFIG_MODE_TAG];
    } else {
        mode = SCTimerModeOff;
        [userDefaults setInteger:mode forKey:CONFIG_MODE_TAG];
        [userDefaults synchronize];
    }
}

- (BOOL)getTimerData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:CONFIG_START_TIME_TAG]) {
        confStartTime = [userDefaults stringForKey:CONFIG_START_TIME_TAG];
    } else {
        return NO;
    }
    if ([userDefaults stringForKey:CONFIG_END_TIME_TAG]) {
        confEndTime = [userDefaults objectForKey:CONFIG_END_TIME_TAG];
    } else {
        return NO;
    }
    
    NSDateFormatter *dateFromatter = [[NSDateFormatter alloc] init];
    [dateFromatter setDateFormat:@"yyyy/MM/dd"];
    
    NSDate* date = [NSDate date];
    
    NSString *stringConfEndDate = [NSString stringWithFormat:@"%@ %@:00", [dateFromatter stringFromDate:date], confEndTime];
    NSString *stringConfStartDate = [NSString stringWithFormat:@"%@ %@:00", [dateFromatter stringFromDate:date], confStartTime];
    
    [dateFromatter setDateFormat:[NSString stringWithFormat:@"yyyy/MM/dd %@:ss",DATE_FORMAT]];
    
    confStartDate = [dateFromatter dateFromString:stringConfStartDate];
    confEndDate = [dateFromatter dateFromString:stringConfEndDate];
    
    if ([confStartDate compare:confEndDate] == NSOrderedDescending) {
        confEndDate = [confEndDate initWithTimeInterval:1*24*60*60 sinceDate:confEndDate];
    }
    return YES;
}

- (void)initData {
    startDate = [NSDate date];
    endDate = confEndDate;
    stepCount = 0;
    distance = 0.;
}

- (void)syncData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:stepCount forKey:DATA_STEP_TAG];
    [userDefaults setDouble:distance forKey:DATA_DISTANCE_TAG];
    [userDefaults setObject:startDate forKey:DATA_START_DATE_TAG];
    [userDefaults setObject:endDate forKey:DATA_END_DATE_TAG];
    [userDefaults synchronize];
    
    startDate = [userDefaults objectForKey:DATA_START_DATE_TAG];
    endDate = [userDefaults objectForKey:DATA_END_DATE_TAG];
    stepCount = [userDefaults integerForKey:DATA_STEP_TAG];
    distance = [userDefaults doubleForKey:DATA_DISTANCE_TAG];
}

+ (void)clearData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:DATA_START_DATE_TAG];
    [userDefaults removeObjectForKey:DATA_STEP_TAG];
    [userDefaults removeObjectForKey:DATA_DISTANCE_TAG];
    [userDefaults synchronize];
}

#pragma mark - CLLocationManagerDelegate
// CLLocationManagerのインスタンスを作成すると最初に呼ばれる
- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusNotDetermined) {
        // ユーザが位置情報の使用許可を選択していない
        [manager requestAlwaysAuthorization];
    }else if (status == kCLAuthorizationStatusAuthorizedAlways) {
        [manager startUpdatingLocation];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"位置情報の取得が許可されていません。"
                                                                                 message:@"移動距離の取得に位置情報を使用します。\n[設定]>[プライパシー]>[位置情報サービス]から位置情報の取得を許可してください。"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        self.distanceLabel.text = @"Don't Allow.";
    }
}

// 移動距離の更新
-(void)locationManager:(CLLocationManager *)manager
   didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    [self checkStatus];
    
    if (oldLocation && stepFlag) {
        distance += [newLocation distanceFromLocation:oldLocation];
        [self syncData];
        [self updateLabel];
    }
}

#pragma mark - Health Kit code
// HealthKitへの権限がない場合のAlert表示
- (void)checkHealthStoreAuthority {
    if (![self isHealthStoreAvalable]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"ヘルスケアデータの書き込みが許可されておりません。"
                                                                                 message:@"ヘルスケアアプリとの連携を行わない場合、過去のデータは完全に削除されます。\n過去のデータを記録するには\n[ヘルスケア]>[ソース]>[APP]からデータの書き込みを許可してください。"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

// HealthKitへの権限のcheck
- (BOOL)isHealthStoreAvalable {
    // Health Kitが使用できるか
    // Health KitはiOS 8.0 以上のみ
    if (NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable]) {
        if (!healthStore) {
            healthStore = [[HKHealthStore alloc] init];
        }
        if ([healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]] != HKAuthorizationStatusSharingAuthorized ||
            [healthStore authorizationStatusForType:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning]] != HKAuthorizationStatusSharingAuthorized) {
            return NO;
        }
    }
    return YES;
}

- (void)storeDatatoHealthStore {
    // Health Kitが使用できるか
    // Health KitはiOS 8.0 以上のみ
    if (NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable]) {
        
        if (!healthStore) {
            healthStore = [[HKHealthStore alloc] init];
        }
        
        if (![self getData] || ![self getTimerData]) {
            return;
        }
        
        HKQuantityType *typeOfStep = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
        HKQuantityType *typeOfDistance = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
        
        HKQuantity *stepQuantity = [HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:(double)stepCount];
        HKQuantity *distanceQuantity = [HKQuantity quantityWithUnit:[HKUnit meterUnit] doubleValue:distance];
        
        HKQuantitySample *stepSample = [HKQuantitySample quantitySampleWithType:typeOfStep quantity:stepQuantity startDate:startDate endDate:endDate];
        HKQuantitySample *distanceSample = [HKQuantitySample quantitySampleWithType:typeOfDistance quantity:distanceQuantity startDate:startDate endDate:endDate];
        
        [healthStore saveObjects:@[stepSample, distanceSample] withCompletion:^(BOOL success, NSError *error) {
            [StepCounterViewController clearData];
            [self initData];
            [self syncData];
        }];
         
    }
}

@end
