//
//  QdtFileLogger.h
//  QdtFileLogger
//
//  Created by qiuzijie on 2018/3/8.
//  Copyright © 2018年 qiuzijie. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, QdtFileLogType){
    QdtFileLogTypeDefalut,
    QdtFileLogTypeError,
    QdtFileLogTypeImportant,
    QdtFileLogTypeWarn
};

#define QdtLogInfoType(msg,aType) [[QdtFileLogger defalut] logMessage:msg type:aType];
#define QdtLogInfo(msg) [[QdtFileLogger defalut] logMessage:msg];
#define QdtLogError(msg) [[QdtFileLogger defalut] logMessage:msg type:QdtFileLogTypeError];
#define QdtLogImportant(msg) [[QdtFileLogger defalut] logMessage:msg type:QdtFileLogTypeImportant];
#define QdtLogWarn(msg) [[QdtFileLogger defalut] logMessage:msg type:QdtFileLogTypeWarn];

@interface QdtFileLogger : NSObject
//默认为7天
@property (nonatomic, assign) NSInteger fileSaveDays;
//默认为设备的UUID
@property (nonatomic, copy  ) NSString *filePathCustomComponent;
//当前文件目录
@property (nonatomic, copy  , readonly) NSString *currentFilePath;

+ (instancetype)defalut;

- (void)logMessage:(NSString *)msg;
- (void)logMessage:(NSString *)msg type:(QdtFileLogType)aType;
- (NSData *)logFileData;

@end
