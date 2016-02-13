//
//  Const.h
//  WearableDevice
//
//  Created by Takuya on 2015/07/09.
//  Copyright (c) 2015年 Takuya. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * 定数
 */

// 加速度の1秒間あたりの取得頻度
#define UPDATE_FREQUENCY 10
// 歩行判定用の上側閾値
#define UPPER_THRESHOLD 1.3
// 歩行判定用の下側閾値
#define LOWER_THRESHOLD 0.93
// ローパスフィルタの係数
#define kFilteringFactor 0.1
// dataのラベル
#define DATA_START_DATE_TAG @"StartDate"
#define DATA_END_DATE_TAG @"EndDate"
#define DATA_STEP_TAG @"Step"
#define DATA_DISTANCE_TAG @"Distance"
// 設定用ラベル
#define CONFIG_MODE_TAG @"mode"
#define CONFIG_START_TIME_TAG @"StartTime"
#define CONFIG_END_TIME_TAG @"EndTime"

#define DEFAULT_START_TIME @"08:00"
#define DEFAULT_END_TIME @"22:00"
#define DATE_FORMAT @"HH:mm"

#define NOTIFICATION_INFO_TYPE @"type"
#define START_NOTIFICATION_INFO @"StartNotification"
#define END_NOTIFICATION_INFO @"EndNotification"

@interface Const : NSObject

@end
