//
//  NSDate+NSDate_asStringWithFormat.m
//  Scanner
//
//  Created by Ben McCloskey on 1/12/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "NSDate+asStringWithFormat.h"

@implementation NSDate (asStringWithFormat)

- (NSString *)asStringWithFormat:(NSString *)format
{
	
	
	//make a string of format yyyy-mm-dd hh:mm:ss +0000
	NSString *dateAsString = [NSString stringWithFormat:@"%@",self];
	//break string into component parts
	NSRange range = NSMakeRange(0,4);
	NSString *fourDigitYear = [NSString stringWithFormat:@"%@",[dateAsString substringWithRange:range]];
	range = NSMakeRange(2,2);
	NSString *twoDigitYear = [NSString stringWithFormat:@"%@",[dateAsString substringWithRange:range]];
	range = NSMakeRange(5,2);
	NSString *month = [NSString stringWithFormat:@"%@",[dateAsString substringWithRange:range]];
	range = NSMakeRange(8,2);
	NSString *day = [NSString stringWithFormat:@"%@",[dateAsString substringWithRange:range]];
	range = NSMakeRange(11,2);
	NSString *hours = [NSString stringWithFormat:@"%@",[dateAsString substringWithRange:range]];
	range = NSMakeRange(14,2);
	NSString *minutes = [NSString stringWithFormat:@"%@",[dateAsString substringWithRange:range]];
	range = NSMakeRange(17,2);
	NSString *seconds = [NSString stringWithFormat:@"%@",[dateAsString substringWithRange:range]];
	char offsetSign = [dateAsString characterAtIndex:20];
	range = NSMakeRange(21,2);
	NSString *hourOffset = [NSString stringWithFormat:@"%@",[dateAsString substringWithRange:range]];
	range = NSMakeRange(23,2);
	NSString *minuteOffset = [NSString stringWithFormat:@"%@",[dateAsString substringWithRange:range]];
	
	if(offsetSign == '+')
	{
		hours =	[NSString stringWithFormat:@"%02i",([hours intValue] + [hourOffset intValue])];
		minutes = [NSString stringWithFormat:@"%02i",([minutes intValue] + [minuteOffset intValue])];
	}
	else if (offsetSign == '-')
	{
		hours = [NSString stringWithFormat:@"%02i",([hours intValue] - [hourOffset intValue])];
		minutes = [NSString stringWithFormat:@"%02i",([minutes intValue] - [minuteOffset intValue])];
	}
	format = [format stringByReplacingOccurrencesOfString:@"@YYYY" withString:fourDigitYear];
	format = [format stringByReplacingOccurrencesOfString:@"@YY" withString:twoDigitYear];
	format = [format stringByReplacingOccurrencesOfString:@"@MM" withString:month];
	format = [format stringByReplacingOccurrencesOfString:@"@DD" withString:day];
	format = [format stringByReplacingOccurrencesOfString:@"@hh" withString:hours];
	format = [format stringByReplacingOccurrencesOfString:@"@mm" withString:minutes];
	format = [format stringByReplacingOccurrencesOfString:@"@ss" withString:seconds];
	
	return format;
}
- (NSString*)asStringWithNSDate
{
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MM/dd/YYYY hh:mma"];
	NSString *textDate = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:self]];
	return textDate;
}
+ (NSString*)asStringDateWithFormat:(NSString*)date
{
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"YYYY-MM-dd"];
	NSDate *dateFromString = [[NSDate alloc]init];
	dateFromString = [dateFormatter dateFromString:date];
	NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
	[dateFormatter2 setDateFormat:@"MM/dd/YYYY"];
	NSString *textDate = [NSString stringWithFormat:@"%@",[dateFormatter2 stringFromDate:dateFromString]];
	return textDate;
}
-(NSString*) convertDataToTimestamp
{
	//Create a timeStamp at 1/1/1900 to current date
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"dd MM yyyy HH:mm:ss ZZ"];
	
	[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"EST"]];
	NSDate *date1900 = [dateFormatter dateFromString:@"01 01 1900 00:00:00 -0000"];
	double day = 3600 * 24;
	
	// Use the user's current calendar and time zone
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    [calendar setTimeZone:timeZone];
	
    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date1900];
	
    // Set the time components manually
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
	
    // Convert back
    NSDate *beginningOfDay = [calendar dateFromComponents:dateComps];
	
	NSTimeInterval dateDiff = [self timeIntervalSinceDate:beginningOfDay];
	NSTimeInterval convertToDay = (dateDiff / day)  + 1 /*add 1 day to offset with hardware*/;
	
	NSString *timestamp = [[[NSString alloc]init] stringByAppendingFormat:@"%f",convertToDay];
	return timestamp;
}
+ (NSDate*) localDate
{
    NSDate* sourceDate = [NSDate date];
    
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    
    NSDate* destinationDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
    
#ifdef DEBUG
//    NSLog(@"your local time is %@", [destinationDate description]);
#endif
    return destinationDate;
}
@end
