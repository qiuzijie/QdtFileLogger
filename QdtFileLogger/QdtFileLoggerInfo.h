//
//  QdtFileLoggerInfo.h
//  QdtFileLogger
//
//  Created by qiuzijie on 2018/3/8.
//  Copyright © 2018年 qiuzijie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QdtFileLoggerInfo : NSObject
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *fileName;
@property (strong, nonatomic) NSDictionary<NSFileAttributeKey, id> *fileAttributes;

@property (strong, nonatomic) NSDate *creationDate;
@property (strong, nonatomic) NSDate *modificationDate;

@property (nonatomic, assign) NSTimeInterval age;

- (instancetype)initWithFilePath:(NSString *)filePath;
@end
