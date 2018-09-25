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
    [QdtFileLogger defalut].fileSaveDays = 7;
    
    //记录日志到本地
    QdtLogInfo(@"1111");
    QdtLogWarn(@"2222");
    QdtLogError(@"3333");
    QdtLogImportant(@"4444");
    
    //获取所有本地日志记录，用于传递给服务器等
    NSData *data = [[QdtFileLogger defalut] logFileData];
    
}

@end









