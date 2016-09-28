//
//  NSString+suffix.m
//  OdinScanner
//
//  Created by KenThomsen on 1/21/14.
//
//

#import "NSString+suffix.h"

@implementation NSString (suffix)

-(NSString *)convertToNumberSuffix
{
	
	if ([self isEqualToString: @"1"]) {
		return @"1st";
	} else if ([self isEqualToString: @"2"]) {
		return @"2nd";
	} else if ([self isEqualToString: @"3"]) {
		return @"3rd";
	}
	
	return [NSString stringWithFormat:@"%@th",self];
}

@end
