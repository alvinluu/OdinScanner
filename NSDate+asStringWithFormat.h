//
//  NSDate+NSDate_asStringWithFormat.h
//  Scanner
//
//  Created by Ben McCloskey on 1/12/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (asStringWithFormat)

/* Takes a format string, and will replace any instances of: DD/MM/YYYY hh:mm:ss l with correct values from NSDate format
 
 NOTE: Must use escape character "@" and is CASE SENSITIVE (you can thank MONTHS/minutes for that!)
 example: [[NSDate date] asStringWithFormat:@"@DD/@MM/@YY at @hh:@mm and @ss seconds with a localization of @l"] returns
 @"01/11/12 at 14:32 and 34 seconds with a localization of +0000"
 */
- (NSString *)asStringWithFormat:(NSString *)format;
- (NSString *)asStringWithNSDate;
+ (NSString *)asStringDateWithFormat:(NSString *)date;
- (NSString *)convertDataToTimestamp;
+ (NSDate*) localDate;
@end
