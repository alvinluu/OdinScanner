//
//  NSMutableArray+asString.m
//  OdinScanner
//
//  Created by KenThomsen on 8/29/14.
//
//

#import "NSArray+asString.h"

@implementation NSArray (asString)
#define NAME @"name"
#define PLU @"plu"
#define QUANTITY @"quantity"
#define RETAIL @"retails"
#define DEPARTMENT @"departments"
#define TOTAL @"total"

/*
 convert OdinTransaction to JSON
 */
-(NSString*) JSON
{
	NSMutableArray* array = [[NSMutableArray alloc] init];
	for (OdinTransaction * transaction in self) {
		if ([transaction isKindOfClass:[OdinTransaction class]]) {
			
			[array addObject:[NSString stringWithFormat:@"\t\t%@",[transaction JSON]]];
			transaction.sync = [NSNumber numberWithBool:TRUE];
		}
	}
	return [array componentsJoinedByString:@","];
}

-(NSString*) prepForWebservice {
	NSMutableArray* array = [[NSMutableArray alloc]init];
	OdinTransaction* tran = [self objectAtIndex:0];
	NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
	
	[array addObjectsFromArray:@[[self addData:tran.cc_digit Tag:@"cc"],
								 [self addData:tran.school Tag:@"school"],
								 //[self addData:[NSString stringWithFormat:@"%@ %@",tran.qdate, tran.time] Tag:@"orderdate"],
								 [self getDataWithTag:NAME],
								 [self getDataWithTag:PLU],
								 [self getDataWithTag:QUANTITY],
								 [self getDataWithTag:RETAIL],
								 [self getDataWithTag:DEPARTMENT],
								 [self getDataWithTag:TOTAL],
								 [self addData:tran.reference Tag:@"reference"],
								 [self addData:tran.qdate Tag:@"qdate"],
								 [self addData:tran.time Tag:@"time"],
								 [self addData:tran.cc_first Tag:@"first"],
								 [self addData:tran.cc_last Tag:@"last"],
								 [self addData:@"Sale" Tag:@"type"],
								 [self addData:tran.cc_responsetext Tag:@"responsetext"],
								 [self addData:tran.cc_tranid Tag:@"transactionid"],
								 [self addData:tran.cc_approval Tag:@"approval"],
								 [self addData:tran.cc_timeStamp Tag:@"timeStamp"],
								 [self addData:[NSString stringWithFormat:@"%f",date] Tag:@"orderDate"],
								 [self addData:[[[UIDevice currentDevice] identifierForVendor] UUIDString] Tag:@"deviceID"],
								 [self addData:[[UIDevice currentDevice] systemVersion] Tag:@"iosVersion"]
								 ]];
	
	
	return [array componentsJoinedByString:@""];
}

-(NSString*) getDataWithTag:(NSString*)tag
{
	NSMutableArray* array = [[NSMutableArray alloc]init];
	for (OdinTransaction* transaction in self) {
		if ([tag isEqual:NAME]) {
			[array addObject:[NSString stringWithFormat:@"\n\t%@",transaction.item]];
		} else if ([tag isEqual:PLU]) {
			[array addObject:[NSString stringWithFormat:@"\n\t%@",transaction.plu]];
		} else if ([tag isEqual:QUANTITY]) {
			[array addObject:[NSString stringWithFormat:@"\n\t%@",transaction.qty]];
		} else if ([tag isEqual:RETAIL]) {
			[array addObject:[NSString stringWithFormat:@"\n\t%@",transaction.amount]];
		} else if ([tag isEqual:DEPARTMENT]) {
			[array addObject:[NSString stringWithFormat:@"\n\t%@",transaction.dept_code]];
		} else if ([tag isEqual:TOTAL]) {
			[array addObject:transaction.amount];
		} else {
			[array addObject:@"ERROR"];
		}
	}
	return [self addData:array Tag:tag];
}


-(NSString*) addData:(NSObject*)data Tag:(NSString*)tag
{
	if ([data isKindOfClass:[NSString class]]) {
		return [NSString stringWithFormat:@"<%@>%@</%@>",tag,(NSString*)data,tag];
	} else if ([data isKindOfClass:[NSNumber class]]) {
		return [NSString stringWithFormat:@"<%@>%@</%@>",tag,[(NSNumber*)data stringValue],tag];
	} else if ([data isKindOfClass:[NSDecimalNumber class]]) {
		return [NSString stringWithFormat:@"<%@>%@</%@>",tag,[(NSDecimalNumber*)data stringValue],tag];
	} else if ([data isKindOfClass:[NSArray class]]) {
		NSArray* array = (NSArray*)data;
		
		if ([tag isEqual:TOTAL]) {
			return [NSString stringWithFormat:@"<%@>%@</%@>",tag,[array valueForKeyPath:@"@sum.self"],tag];
		}
		return [NSString stringWithFormat:@"<%@>(%@\n)</%@>",tag,[array componentsJoinedByString:@","],tag];
		
	}else {
		return [NSString stringWithFormat:@"<%@>%@</%@>",tag,@"ERROR",tag];
	}
}
@end
