//
//  StreamInOut.h
//  OdinScanner
//
//  Created by KenThomsen on 2/7/14.
//
//

#import <Foundation/Foundation.h>

@interface StreamInOut : NSObject
+(NSString *)getPrivateDocsDir;
+(NSString *)getPrivateDocsDirInPending;
+(NSString*)readLogFileWithLocation:(NSString*)fileLocation;
+(NSString*)readPendingFileWithLocation:(NSString*)fileLocation;
+(BOOL)writeLogFileWithTransaction:(NSDictionary*)transaction Note:(NSString*)note;
+(BOOL)resetPendingFile;
+(BOOL)deletePendingItemInFileWithTransaction:(NSDictionary*)transaction;
+(BOOL)updatePendingItemInFileWithTransaction:(NSDictionary*)transaction;
@end
