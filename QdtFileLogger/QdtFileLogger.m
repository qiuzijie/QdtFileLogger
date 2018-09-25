//
//  QdtFileLogger.m
//  QdtFileLogger
//
//  Created by qiuzijie on 2018/3/8.
//  Copyright © 2018年 qiuzijie. All rights reserved.
//  仿造自 CocoaLumberjack 感谢原作者

#import "QdtFileLogger.h"
#import "QdtFileLoggerInfo.h"
#import <sys/attr.h>
#import <sys/xattr.h>
#import <unistd.h>
#import <UIKit/UIKit.h>

static NSTimeInterval const k24HourTimeInterval = 1;
static NSString const *kLogFilePrefix = @"qdtLogFile";
static NSString const *kLogFileSuffix = @".log";

@interface QdtFileLogger ()
@property (nonatomic, copy  ) NSString *logFileName;
@property (nonatomic, copy  ) NSString *logFileExtension;
@property (nonatomic, assign) NSTimeInterval logFileRollingFrequency;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) QdtFileLoggerInfo *currentFileLoggerInfo;
@property (nonatomic, strong) NSString *logsDirectory;
@property (nonatomic, strong) NSDateFormatter *dateFormater;
@property (nonatomic) dispatch_source_t rollingTimer;
@property (nonatomic) dispatch_source_t currentLogFileVnode;
@property (nonatomic) dispatch_queue_t  logQueue;
@end

@implementation QdtFileLogger

+ (instancetype)defalut{
    static QdtFileLogger *fileLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileLogger = [[QdtFileLogger alloc] init];
    });
    return fileLogger;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fileSaveDays = 7;
        _logFileRollingFrequency = k24HourTimeInterval;
        _filePathCustomComponent = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }
    return self;
}

#pragma mark- public

- (void)logMessage:(NSString *)msg{
    [self logMessage:msg type:QdtFileLogTypeDefalut];
}

- (void)logMessage:(NSString *)msg type:(QdtFileLogType)aType{
    NSString *message = [self formatterMsg:msg type:aType];
    dispatch_async(self.logQueue, ^{
        NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
        [self.fileHandle writeData:data];
    });
}

- (NSData *)logFileData{
    NSArray *sorteNSLogFiles = [self sortedExistLogFiles];
    NSString *appendString = @"*****---- end ----*****";
    for (NSString *path in sorteNSLogFiles) {
        NSString *str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        appendString = [str stringByAppendingString:appendString];
    }
    return [appendString dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark- private


- (NSString *)createFile{
    NSString *directory = [self logsDirectory];
    NSString *fileName  = self.logFileName;
    NSInteger attempt = 0;
    
    do {
        NSString *actualFileName = [fileName stringByAppendingString:self.logFileExtension];
        
        if (attempt >= 1) {
            actualFileName = [fileName stringByDeletingPathExtension];
            actualFileName = [actualFileName stringByAppendingFormat:@"%ld",attempt];
            actualFileName = [actualFileName stringByAppendingString:self.logFileExtension];
        }
        
        NSString *filePath = [directory stringByAppendingPathComponent:actualFileName];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            if (![[NSFileManager defaultManager] createFileAtPath:filePath
                                                         contents:nil
                                                       attributes:@{NSFileProtectionKey:NSFileProtectionNone}]){
                NSLog(@"QdtFileLogger createFileAtPath ERROR");
            }
            NSLog(@"QdtFileLogger currentFilePath %@",filePath);
            [self deleteOldFiles];
            return filePath;
            
        } else{
            attempt ++;
        }
        
    } while (YES);
    
}

- (void)deleteOldFiles{
    NSMutableArray *sortedExistLogFiles = [[self sortedExistLogFiles] mutableCopy];
    if (sortedExistLogFiles.count > self.fileSaveDays) {
        do {
            NSString *deleteFilePath = [sortedExistLogFiles lastObject];
            if (![[NSFileManager defaultManager] removeItemAtPath:deleteFilePath error:nil]) {
                NSLog(@"QdtFileLogger removeItem ERROR");
            }
            [sortedExistLogFiles removeLastObject];
        } while (sortedExistLogFiles.count > self.fileSaveDays);
    }
}

- (NSArray *)sortedExistLogFiles{
    
    NSArray *existFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.logsDirectory error:nil];
    
    NSMutableArray *logFilePaths = [NSMutableArray new];
    
    for (NSString *fileName in existFiles) {
        if ([fileName hasPrefix:self.logFileName] && [fileName hasSuffix:self.logFileExtension]) {
            [logFilePaths addObject:[self.logsDirectory stringByAppendingPathComponent:fileName]];
        }
    }
    
    NSArray *sortedArray = [logFilePaths sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSDate *date1 = [[QdtFileLoggerInfo alloc] initWithFilePath:obj1].creationDate;
        NSDate *date2 = [[QdtFileLoggerInfo alloc] initWithFilePath:obj2].creationDate;
        return [date2 compare:date1];
    }];
    
    return sortedArray;
}

- (void)scheduleTimerToRollLogFileDueToAge{
    
    if (self.rollingTimer) {
        dispatch_source_cancel(self.rollingTimer);
        self.rollingTimer = nil;
    }
    
    if (self.fileHandle == nil || self.logFileRollingFrequency <= 0) {
        return;
    }
    
    //设置一个定时器
    NSDate *logFileCreationDate = self.currentFileLoggerInfo.creationDate;
    
    NSTimeInterval ti = [logFileCreationDate timeIntervalSinceReferenceDate];
    ti += self.logFileRollingFrequency;
    
    NSDate *logFileRollingDate = [NSDate dateWithTimeIntervalSinceReferenceDate:ti];
    
    self.rollingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.logQueue);
    
    dispatch_source_set_event_handler(self.rollingTimer, ^{
        [self maybeRollLogFile];
    });
    
    uint64_t delay = (uint64_t)([logFileRollingDate timeIntervalSinceNow] * (NSTimeInterval) NSEC_PER_SEC);
    dispatch_time_t fireTime = dispatch_time(DISPATCH_TIME_NOW, delay);
    dispatch_source_set_timer(self.rollingTimer, fireTime, DISPATCH_TIME_FOREVER, 1ull * NSEC_PER_SEC);
    dispatch_resume(self.rollingTimer);
    
}

- (void)maybeRollLogFile{
    if (self.logFileRollingFrequency > 0 && self.currentFileLoggerInfo.age >= self.logFileRollingFrequency) {
        [self rollLogNow];
    } else {
        [self scheduleTimerToRollLogFileDueToAge];
    }
}

- (void)rollLogNow{
    if (_fileHandle == nil) {
        return;
    }
    
    [_fileHandle synchronizeFile];
    [_fileHandle closeFile];
    _fileHandle = nil;
    
    _currentFileLoggerInfo = nil;
    
    if (_currentLogFileVnode) {
        dispatch_source_cancel(_currentLogFileVnode);
        _currentLogFileVnode = nil;
    }
    
    if (_rollingTimer) {
        dispatch_source_cancel(_rollingTimer);
        _rollingTimer = nil;
    }
    
}

- (void)resetLogger{
    [self.fileHandle synchronizeFile];
    [self.fileHandle closeFile];
    self.fileHandle = nil;
    self.currentFileLoggerInfo = nil;
    
    if (self.currentLogFileVnode) {
        dispatch_cancel(self.currentLogFileVnode);
        self.currentLogFileVnode = nil;
    }
    
    if (self.rollingTimer) {
        dispatch_cancel(self.rollingTimer);
        self.rollingTimer = nil;
    }
}

- (NSString *)formatterMsg:(NSString *)msg type:(QdtFileLogType)aType{
    NSString *message = [NSString stringWithFormat:@"%@       ",[self currentDate]];
    switch (aType) {
        case QdtFileLogTypeDefalut:
            ;
            break;
        case QdtFileLogTypeError:
            message = [message stringByAppendingString:@"❌"];
            break;
        case QdtFileLogTypeImportant:
            message = [message stringByAppendingString:@"‼️"];
            break;
        case QdtFileLogTypeWarn:
            message = [message stringByAppendingString:@"⚠️"];
        default:
            break;
    }
    message = [message stringByAppendingString:msg];
    if (![message hasSuffix:@"\n"]) {
        message = [message stringByAppendingString:@"\n"];
    }
    return message;
}

- (NSString *)currentDate{
    [self.dateFormater setDateFormat:(@"yyyy-MM-dd HH:mm:ss")];
    return [self.dateFormater stringFromDate:[NSDate date]];
}

#pragma mark- getter / setter


- (dispatch_queue_t)logQueue{
    if (_logQueue == nil) {
        _logQueue = dispatch_queue_create("QdtLogQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _logQueue;
}

- (NSString *)logFileName{
    if (_logFileName == nil) {
        _logFileName = [NSString stringWithFormat:@"%@",kLogFilePrefix];
    }
    return _logFileName;
}

- (NSString *)logFileExtension{
    if (_logFileExtension == nil) {
        _logFileExtension = [NSString stringWithFormat:@"%@",kLogFileSuffix];
    }
    return _logFileExtension;
}

- (NSString *)logsDirectory {
    if (self.filePathCustomComponent.length == 0) {
        
        return nil;
    }
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    path = [path stringByAppendingPathComponent:@"QdtCaches"];
    path = [path stringByAppendingPathComponent:self.filePathCustomComponent];
    _logsDirectory = [path stringByAppendingPathComponent:@"QdtLog"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_logsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:_logsDirectory
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:nil]) {
            NSLog(@"QdtFileLogger createDirectoryAtPath ERROR");
        };
    }
    
    return _logsDirectory;
}

- (QdtFileLoggerInfo *)currentFileLoggerInfo{
    if (_currentFileLoggerInfo == nil) {
        
        NSArray *sorteNSLogPaths = [self sortedExistLogFiles];
        if (sorteNSLogPaths.count > 0) {
            QdtFileLoggerInfo *theNewlyFileInfo = [[QdtFileLoggerInfo alloc] initWithFilePath:[sorteNSLogPaths firstObject]];
            if (theNewlyFileInfo.age <= self.logFileRollingFrequency) {
                _currentFileLoggerInfo = theNewlyFileInfo;
                NSLog(@"%@", [sorteNSLogPaths firstObject]);
            }
        }
        
        if (!_currentFileLoggerInfo) {
            NSString *path = [self createFile];
            _currentFileLoggerInfo = [[QdtFileLoggerInfo alloc] initWithFilePath:path];
        }
    }
    return _currentFileLoggerInfo;
}

- (NSFileHandle *)fileHandle{
    if (_fileHandle == nil) {
        
        NSString *filePath = self.currentFileLoggerInfo.filePath;
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        [_fileHandle seekToEndOfFile];
        
        if (_fileHandle) {
            [self scheduleTimerToRollLogFileDueToAge];
            
            //观察文件
            self.currentLogFileVnode = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                                              [self.fileHandle fileDescriptor],
                                                              DISPATCH_VNODE_DELETE | DISPATCH_VNODE_RENAME,
                                                              self.logQueue);
            
            dispatch_source_set_event_handler(self.currentLogFileVnode, ^{
                [self rollLogNow];
            });
            dispatch_resume(self.currentLogFileVnode);
        }
    }
    return _fileHandle;
}

- (void)setFilePathCustomComponent:(NSString *)filePathCustomComponent{
    _filePathCustomComponent = filePathCustomComponent;
    [self resetLogger];
}

- (NSDateFormatter *)dateFormater{
    if (_dateFormater == nil) {
        _dateFormater = [NSDateFormatter new];
        [_dateFormater setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Shanghai"]];
        [_dateFormater setLocale:[NSLocale localeWithLocaleIdentifier:@"zh_Hans_CN"]];
    }
    return _dateFormater;
}

#pragma mark- dealloc

- (void)dealloc{
    [_fileHandle synchronizeFile];
    [_fileHandle closeFile];
    
    if (self.currentLogFileVnode) {
        dispatch_cancel(self.currentLogFileVnode);
        self.currentLogFileVnode = nil;
    }
    
    if (self.rollingTimer) {
        dispatch_cancel(self.rollingTimer);
        self.rollingTimer = nil;
    }
}

@end






