//
//  ConfigViewController.m
//  WearableDevice
//
//  Created by Takuya on 2015/07/08.
//  Copyright (c) 2015年 Takuya. All rights reserved.
//

#import "ConfigViewController.h"
#import "StepCounterViewController.h"

@interface ConfigViewController ()
{
    UIDatePicker *startDatePicker;
    UIDatePicker *endDatePicker;
}
@property (readonly, nonatomic) NSString *startTime;
@property (readonly, nonatomic) NSString *endTime;

@end

@implementation ConfigViewController

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getData];
    [self createView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Private Method
- (void)createView {
    self.view.backgroundColor = [UIColor clearColor];
    
    float deviceHeight = self.view.frame.size.height;
    float deviceWidth = self.view.frame.size.width;
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = CGRectMake(0, 0, deviceWidth, deviceHeight);
    [self.view addSubview:blurView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(deviceWidth*0.1, deviceHeight*0.1, deviceWidth*0.8, deviceHeight*0.3)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = @"Change Monitor Time.";
    titleLabel.font = [UIFont fontWithName:@"AppleGothic" size:20];
    titleLabel.textColor = [UIColor whiteColor];
    [blurView addSubview:titleLabel];
    
    UIView *startDateField = [[UIView alloc] initWithFrame:CGRectMake(deviceWidth*0, deviceHeight*0.25, deviceWidth*0.5, deviceHeight*0.5)];
    startDateField.backgroundColor =[UIColor clearColor];
    [blurView addSubview:startDateField];
    
    startDatePicker = [[UIDatePicker alloc] init];
    [startDatePicker setDatePickerMode:UIDatePickerModeTime];
    startDatePicker.center = CGPointMake(deviceWidth*0.25, deviceHeight*0.25);
    startDatePicker.backgroundColor = [UIColor clearColor];
    startDatePicker.minuteInterval = 11;
    [startDateField addSubview:startDatePicker];
    
    UIView *endDateField = [[UIView alloc] initWithFrame:CGRectMake(deviceWidth*0.5, deviceHeight*0.25, deviceWidth*0.5, deviceHeight*0.5)];
    endDateField.backgroundColor =[UIColor clearColor];
    [blurView addSubview:endDateField];
    
    endDatePicker = [[UIDatePicker alloc] init];
    [endDatePicker setDatePickerMode:UIDatePickerModeTime];
    endDatePicker.center = CGPointMake(deviceWidth*0.25, deviceHeight*0.25);
    endDatePicker.backgroundColor = [UIColor clearColor];
    endDatePicker.minuteInterval = 1;
    [endDateField addSubview:endDatePicker];
    
    UILabel *separateLabelL = [[UILabel alloc] initWithFrame:CGRectMake(deviceWidth*0.7, deviceHeight*0.25, deviceWidth*0.1, deviceHeight*0.5)];
    separateLabelL.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    separateLabelL.textColor = [UIColor whiteColor];
    separateLabelL.textAlignment = NSTextAlignmentCenter;
    separateLabelL.text = @":";
    separateLabelL.font = [UIFont fontWithName:@"AppleGothic" size:20];
    separateLabelL.textColor = [UIColor whiteColor];
    [blurView addSubview:separateLabelL];
    
    UILabel *separateLabelC = [[UILabel alloc] initWithFrame:CGRectMake(deviceWidth*0.45, deviceHeight*0.25, deviceWidth*0.1, deviceHeight*0.5)];
    separateLabelC.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    separateLabelC.textColor = [UIColor whiteColor];
    separateLabelC.textAlignment = NSTextAlignmentCenter;
    separateLabelC.text = @"-";
    separateLabelC.font = [UIFont fontWithName:@"AppleGothic" size:20];
    separateLabelC.textColor = [UIColor whiteColor];
    [blurView addSubview:separateLabelC];
    
    UILabel *separateLabelR = [[UILabel alloc] initWithFrame:CGRectMake(deviceWidth*0.2, deviceHeight*0.25, deviceWidth*0.1, deviceHeight*0.5)];
    separateLabelR.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    separateLabelR.textColor = [UIColor whiteColor];
    separateLabelR.textAlignment = NSTextAlignmentCenter;
    separateLabelR.text = @":";
    separateLabelR.font = [UIFont fontWithName:@"AppleGothic" size:20];
    separateLabelR.textColor = [UIColor whiteColor];
    [blurView addSubview:separateLabelR];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cancelButton.frame = CGRectMake(deviceWidth*0.05, deviceHeight*0.7, deviceWidth*0.4, deviceHeight*0.1);
    cancelButton.backgroundColor = [UIColor clearColor];
    cancelButton.titleLabel.font = [UIFont fontWithName:@"AppleGothic" size:20];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self
                     action:@selector(cancel:)
           forControlEvents:UIControlEventTouchUpInside];
    [blurView addSubview:cancelButton];
    
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    saveButton.frame = CGRectMake(deviceWidth*0.55, deviceHeight*0.7, deviceWidth*0.4, deviceHeight*0.1);
    saveButton.backgroundColor = [UIColor clearColor];
    saveButton.titleLabel.font = [UIFont fontWithName:@"AppleGothic" size:20];
    [saveButton setTitle:@"Save" forState:UIControlStateNormal];
    [saveButton addTarget:self
                   action:@selector(save:)
         forControlEvents:UIControlEventTouchUpInside];
    [blurView addSubview:saveButton];
    
    [self syncPicker];
}

- (void)syncPicker {
    NSString *startTime = _startTime ? _startTime : DEFAULT_START_TIME;
    NSString *endTime = _endTime ? _endTime : DEFAULT_END_TIME;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:DATE_FORMAT];
    
    [startDatePicker setDate:[dateFormatter dateFromString:startTime]];
    [endDatePicker setDate:[dateFormatter dateFromString:endTime]];
}

- (void)closeView {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate checkStatus];
}

#pragma mark - Config Data Method
- (void)getData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults stringForKey:CONFIG_START_TIME_TAG]) {
        _startTime = [userDefaults stringForKey:CONFIG_START_TIME_TAG];
    }
    if ([userDefaults stringForKey:CONFIG_END_TIME_TAG]) {
        _endTime = [userDefaults stringForKey:CONFIG_END_TIME_TAG];
    }
}

- (void)saveData {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_startTime forKey:CONFIG_START_TIME_TAG];
    [userDefaults setObject:_endTime forKey:CONFIG_END_TIME_TAG];
    [userDefaults synchronize];
}

- (BOOL)isUpdated {
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:DATE_FORMAT];
    
    NSString *startTime = [dateformatter stringFromDate:startDatePicker.date];
    NSString *endTime = [dateformatter stringFromDate:endDatePicker.date];
    
    if ([startTime isEqualToString:_startTime] && [endTime isEqualToString:_endTime]) {
        return NO;
    } else {
        _startTime = startTime;
        _endTime = endTime;
    }
    return YES;
}

#pragma mark - Button Event Method
// Cancelボタン押下処理
- (void)cancel:(id)sender {
    [self closeView];
}

// Saveボタン押下処理
- (void)save:(id)sender {
    if ([self isUpdated]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:@"現在のデータを削除します。よろしいですか？"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              [self saveData];
                                                              [StepCounterViewController clearData];
                                                              [self closeView];
                                                          }
                                    ]];
        [self presentViewController:alertController animated:YES completion:nil];
        
    } else {
        [self closeView];
    }
}

@end