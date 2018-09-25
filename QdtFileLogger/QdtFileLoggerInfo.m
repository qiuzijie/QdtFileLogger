//
//  QdtFileLoggerInfo.m
//  QdtFileLogger
//
//  Created by qiuzijie on 2018/3/8.
//  Copyright © 2018年 qiuzijie. All rights reserved.
//

#import "QdtFileLoggerInfo.h"

@interface QdtFileLoggerInfo ()


@end

@implementation QdtFileLoggerInfo

- (instancetype)initWithFilePath:(NSString *)filePath{
    if ((self = [super init])) {
        _filePath = [filePath copy];
    }
    return self;
}

- (NSString *)fileName{
    if (_fileName == nil) {
        _fileName = [self.filePath lastPathComponent];
    }
    return _fileName;
}

- (NSDictionary<NSFileAttributeKey,id> *)fileAttributes{
    if (_fileAttributes == nil) {
        _fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_filePath error:nil];
    }
    return _fileAttributes;
}

- (NSDate *)modificationDate {
    if (_modificationDate == nil) {
        _modificationDate = self.fileAttributes[NSFileModificationDate];
    }
    
    return _modificationDate;
}

- (NSDate *)creationDate {
    if (_creationDate == nil) {
        _creationDate = self.fileAttributes[NSFileCreationDate];
    }
    
    return _creationDate;
}

- (NSTimeInterval)age {
    return ([self.creationDate timeIntervalSinceNow] * -1.0);
}

@end

