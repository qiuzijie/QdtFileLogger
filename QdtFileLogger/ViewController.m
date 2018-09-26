//
//  ViewController.m
//  QdtFileLogger
//
//  Created by qiuzijie on 2018/3/8.
//  Copyright © 2018年 qiuzijie. All rights reserved.
//

#import "ViewController.h"
#import "QdtFileLogger.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //配置基本信息
    [QdtFileLogger defalut].filePathCustomComponent = @"user_001";
    [QdtFileLogger defalut].fileSaveDays = 3;
    
    //记录日志到本地
    QdtLogInfo(@"普通日志");
    QdtLogWarn(@"警告日志");
    QdtLogError(@"错误日志");
    QdtLogImportant(@"重要日志");
    
    NSLog(@"path: %@", [QdtFileLogger defalut].currentFilePath);
    
    //获取所有本地日志记录，用于传递给服务器等
    NSData *data = [[QdtFileLogger defalut] logFileData];
    
}

@end









