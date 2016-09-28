//
//  CardValidator.m
//  OdinScanner
//
//  Created by KenThomsen on 7/9/14.
//
//

#import "CardProcess.h"

@implementation CardProcess

+(CardProcess*)initialize:(NSString *)magnetic
{
	CardProcess* cv = [[CardProcess alloc]init];
	[cv setCardMagneticStripe:magnetic];
	return cv;
}
-(NSString*)getCardLast4Digits
{
	NSString *data = [self cardMagneticStripe];
	NSRange range = [data rangeOfString:@"="];
	NSString *digit = [data substringWithRange:NSMakeRange(range.location-4, 4)];
	return digit;
}
-(NSDate*)getCardExpDate
{
	NSString *data = [self cardMagneticStripe];
	NSRange range = [data rangeOfString:@"="];
	NSString *dateString = [data substringWithRange:NSMakeRange(range.location+1, 4)];
	NSDateFormatter *df = [[NSDateFormatter alloc]init];
	[df setDateFormat:@"yyMM"];
	NSDate *date = [df dateFromString:dateString];
	
	return date;
}
-(BOOL)isValidCardExpDate
{
	NSDate *date = [self getCardExpDate];
	NSDate* today = [[NSDate alloc]init];
	NSComparisonResult result = [today compare:date];
	
	return (result == NSOrderedDescending) ? NO : YES;
	
}
@end
