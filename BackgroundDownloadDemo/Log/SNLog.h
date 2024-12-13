//
//  SNLog.h
//  Video
//
//  Created by censt on 2020/10/24.
//  Copyright © 2020 cnest. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SNLog : NSObject

+(void)initLogSys;

+ (void)logWithLine:(NSUInteger)line
//            classStr:(NSString*)classStr
             method:(NSString *)methodName
               time:(NSDate *)timeStr
             format:(NSString *)format;

+(NSString*)getLogFile;
+ (NSArray *)getLogFiles;

@end

NS_ASSUME_NONNULL_END
