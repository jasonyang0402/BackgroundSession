//
//  SNLog.m
//  Video
//
//  Created by censt on 2020/10/24.
//  Copyright © 2020 cnest. All rights reserved.
//

#import "SNLog.h"
#import <CocoaLumberjack/CocoaLumberjack.h>


@interface DDCustomLogFormatter : NSObject<DDLogFormatter>

@end


@implementation DDCustomLogFormatter
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSDate *currentDate = [NSDate date];

    // 获取当前设备的时区
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];

    // 创建日期格式化器
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    [dateFormatter setTimeZone:timeZone];

    // 将当前时间格式化为精确到毫秒的字符串
    NSString *formattedDateString = [dateFormatter stringFromDate:currentDate];
    
    // 拼接自定义的日志格式，例如："[时间] [日志等级] [文件名:行号] 日志消息"
    NSString *logString = [NSString stringWithFormat:@"[%@] [%lu] [%@:%lu] %@",
                           formattedDateString, (unsigned long)logMessage.flag, logMessage.fileName, (unsigned long)logMessage.line, logMessage.message];
    
    return logString;
}
@end

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation SNLog


+(void)initLogSys{
    // 添加DDASLLogger，你的日志语句将被发送到Xcode控制台
    DDCustomLogFormatter *logFormatter = [[DDCustomLogFormatter alloc] init];
    [[DDOSLogger sharedInstance] setLogFormatter:logFormatter];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    // 添加DDTTYLogger，你的日志语句将被发送到Console.app
//    [DDLog addLogger:[DDASLLogger sharedInstance]];
        
    // 添加DDFileLogger，你的日志语句将写入到一个文件中，默认路径在沙盒的Library/Caches/Logs/目录下，文件名为bundleid+空格+日期.log。
    // Debug模式下日志路径修改为Document/Logs文件夹, 方便测试
    NSString *logDirectory = nil;


//    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    logDirectory = [NSString stringWithFormat:@"%@/Logs", documentDirectory];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:logDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    DDLogFileManagerDefault *defaultLogFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:logDirectory];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:defaultLogFileManager];
//    fileLogger.rollingFrequency = 60 * 60 * 24;
//    fileLogger.maximumFileSize = 1024 * 1024;
//    fileLogger.logFileManager.maximumNumberOfLogFiles = 1;
    // 修改日志生成策略: 不限制大小，时间，每次重新启动创建新的文件，最多保留3个日志文件
    fileLogger.rollingFrequency = 60 * 60 * 24 * 3;
    fileLogger.maximumFileSize = 1024 * 1024 * 12;//单位为字节(Byte),此处设置最大12MB,因为邮件一般只能发送25M以内文件
//    fileLogger.doNotReuseLogFiles = YES;
    fileLogger.logFileManager.maximumNumberOfLogFiles = 1;
    [DDLog addLogger:fileLogger];
    
#if REDIRECT_LOG_PATH
    // log记录
    NSString *curLogPath = [self getLogFile];
    freopen([curLogPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
    freopen([curLogPath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
#endif
    
    //产生Log
//    DDLogVerbose(@"Verbose");
//    DDLogDebug(@"Debug");
//    DDLogInfo(@"Info");
//    DDLogWarn(@"Warn");
//    DDLogError(@"Error");
}




+ (void)logWithLine:(NSUInteger)line
             method:(NSString *)methodName
               time:(NSDate *)timeStr
             format:(NSString *)format{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"]; // 指定日期格式
//    NSDate *date = [dateFormatter dateFromString:timeStr]; // 将时间字符串转换为 NSDate 对象

    // 将日期转换为本地时区时间
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSString *localTimeStr = [dateFormatter stringFromDate:timeStr];
    NSString *logStr = [NSString stringWithFormat:@"[%@][%@]%@ %tu行: ● %@\n", [NSThread currentThread], localTimeStr, methodName,line,format];
    
    DDLogDebug(@"%@",logStr);


}
//#define SNLog(frmt,...) [v logWithLine:__LINE__ method:[NSString stringWithFormat:@"%s", __FUNCTION__] time:[NSDate date] format:[NSString stringWithFormat:frmt, ## __VA_ARGS__]];

+(NSString*)getLogFile{
    
    NSArray *allLoggers=[DDLog sharedInstance].allLoggers;
    DDFileLogger *logger;
    for (id<DDLogger> log in allLoggers) {
        if ([log isKindOfClass:[DDFileLogger class]]) {
            logger=(DDFileLogger*)log;
            break;
        }
    }
    
    DDLogFileInfo *info=logger.currentLogFileInfo;
    return info.filePath;
}

+ (NSArray *)getLogFiles {
    NSArray *allLoggers=[DDLog sharedInstance].allLoggers;
    DDFileLogger *logger;
    NSMutableArray *filePaths = [NSMutableArray array];
    for (id<DDLogger> log in allLoggers) {
        if ([log isKindOfClass:[DDFileLogger class]]) {
            logger=(DDFileLogger*)log;
//            NSArray *array = [logger.logFileManager sortedLogFilePaths];
            NSFileManager *fileManager = [NSFileManager defaultManager];

            NSArray* relativeFilePaths = [fileManager contentsOfDirectoryAtPath:logger.logFileManager.logsDirectory error:nil];
            for (NSString* fileName in relativeFilePaths) {
                BOOL flag = YES;
                NSString* fullPath = [logger.logFileManager.logsDirectory stringByAppendingPathComponent:fileName];
                if ([fileManager fileExistsAtPath:fullPath isDirectory:&flag]) {
                    if (!flag) {
                        [filePaths addObject:@{@"fullPath" : fullPath, @"fileName" : fileName}];
                    }
                }
            }
        }
    }
    return [filePaths copy];
}


@end
