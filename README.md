# QdtFileLogger
一款简单的本地日志记录工具

我们项目中使用的一个轻量级本地日志保存工具，仿造自 CocoaLumberjack ，其实就是把它的DDFileLogger 模块拆出来改了改。

## 具有以下功能：
1. 异步有序的记录
2. 保存最近X天的记录
3. 格式化记录样式
4. 为每个用户保存日志,切换账号不删除

## 技术实现：
* 一个串联队列异步写入日志。
* NSFileManager 管理文件目录，管理文件等。
* NSFileHandle 对单个文件进行具体操作。
* 以24个小时作为时间界限，每天一个日志文件，最多保存 x 个，上传的时候将内容按时间排序合并。
* 利用 dispatch_source_create 来观察一个文件的修改和删除操作
* 用 GCD 来做了一个定时器，当当前日志文件存储超过最大时间时换新的
* 当本地文件超过最大存储数量时，删除最旧的文件

上传时机：因为我们的需求是只能用户自己上传日志，所以就没弄自动上传..

## 本地文件目录、内容样式
![xxx](https://code.aliyun.com/Qiuzijie/PictureWarehouse/raw/master/Pictures/QdtLogger1.png)

![xxx](https://code.aliyun.com/Qiuzijie/PictureWarehouse/raw/master/Pictures/QdtLogger2.png)
