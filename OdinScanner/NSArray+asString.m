//
//  NSMutableArray+asString.m
//  OdinScanner
//
//  Created by KenThomsen on 8/29/14.
//
//

#import "NSArray+asString.h"
#import "NSString+hackXML.h"

@implementation NSArray (asString)

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
	OdinTransaction* tran = [self objectAtIndex:0];
	
	if (tran.cc_digit) {
#ifdef DEBUG
		NSLog(@"process CC transaction");
#endif
		return [self processCreditCard];
	} else if (tran.id_number) {
#ifdef DEBUG
		NSLog(@"process Debit transaction");
#endif
		return [self processDebitTransaction];
	}
#ifdef DEBUG
	NSLog(@"Unknown transaction type");
#endif
	return @"Unknow transaction trype";
}

-(NSString*) processDebitTransaction {
	
	if (self.count > 0) {
		OdinTransaction* tran = [self objectAtIndex:0];
		NSTimeInterval date = [[NSDate localDate] timeIntervalSince1970];
		NSString* source = (tran.process_on_sync.intValue == 1) ? @"2" : @"1";
		NSArray* array = [NSArray arrayWithObjects:
						  [NSString addData:tran.id_number Tag:@"id_number"],
						  [NSString addData:tran.school Tag:@"school"],
						  //[NSString addData:[NSString stringWithFormat:@"%@ %@",tran.qdate, tran.time] Tag:@"orderdate"],
						  [self getDataWithTag:NAME],
						  [self getDataWithTag:PLU],
						  [self getDataWithTag:QUANTITY],
						  [self getDataWithTag:RETAIL],
						  [self getDataWithTag:DEPARTMENT],
						  [self getDataWithTag:GLCODE],
						  [self getDataWithTag:TOTAL],
						  [NSString addData:tran.reference Tag:@"reference"],
						  [NSString addData:tran.qdate Tag:@"qdate"],
						  [NSString addData:tran.time Tag:@"time"],
						  [NSString addData:tran.first Tag:@"first"],
						  [NSString addData:tran.last Tag:@"last"],
						  [NSString addData:tran.location Tag:@"location"],
						  [NSString addData:source Tag:@"source"],
						  [NSString addData:tran.payment Tag:@"payment"],
						  [NSString addData:tran.tax_amount Tag:@"tax_amount"],
						  [NSString addData:tran.operator Tag:@"operator"],
						  [NSString addData:tran.process_on_sync Tag:@"process_on_sync"],
						  [NSString addData:tran.type Tag:@"type"],
						  [NSString addData:[NSString stringWithFormat:@"%f",date] Tag:@"orderDate"],
						  [NSString addData:[[[UIDevice currentDevice] identifierForVendor] UUIDString] Tag:@"deviceID"],
						  [NSString addData:[[UIDevice currentDevice] systemVersion] Tag:@"iosVersion"],
						  nil];
		
		
		return [array componentsJoinedByString:@""];
	}
#ifdef DEBUG
	NSLog(@"Transaction Array is empty");
#endif
	return @"Transaction Array is empty";
	
}
-(NSString*) processCreditCard {
	if (self.count > 0) {
		OdinTransaction* tran = [self objectAtIndex:0];
		NSTimeInterval date = [[NSDate localDate] timeIntervalSince1970];
		NSString* source = (tran.process_on_sync.intValue == 1) ? @"2" : @"1";
		
		NSArray* array = [NSArray arrayWithObjects:
						  [NSString addData:tran.cc_digit Tag:@"cc"],
						  [NSString addData:tran.school Tag:@"school"],
						  //[NSString addData:[NSString stringWithFormat:@"%@ %@",tran.qdate, tran.time] Tag:@"orderdate"],
						  [self getDataWithTag:NAME],
						  [self getDataWithTag:PLU],
						  [self getDataWithTag:QUANTITY],
						  [self getDataWithTag:RETAIL],
						  [self getDataWithTag:DEPARTMENT],
						  [self getDataWithTag:GLCODE],
						  [self getDataWithTag:TOTAL],
						  [NSString addData:tran.reference Tag:@"reference"],
						  [NSString addData:tran.qdate Tag:@"qdate"],
						  [NSString addData:tran.time Tag:@"time"],
						  [NSString addData:tran.first Tag:@"first"],
						  [NSString addData:tran.last Tag:@"last"],
						  [NSString addData:tran.location Tag:@"location"],
						  [NSString addData:source Tag:@"source"],
						  [NSString addData:tran.payment Tag:@"payment"],
						  [NSString addData:tran.tax_amount Tag:@"tax_amount"],
						  [NSString addData:tran.operator Tag:@"operator"],
						  [NSString addData:tran.process_on_sync Tag:@"process_on_sync"],
						  [NSString addData:tran.type Tag:@"type"],
						  [NSString addData:tran.cc_responsetext Tag:@"responsetext"],
						  [NSString addData:tran.cc_tranid Tag:@"transactionid"],
						  [NSString addData:tran.cc_approval Tag:@"approval"],
						  [NSString addData:tran.cc_timeStamp Tag:@"timeStamp"],
						  [NSString addData:[NSString stringWithFormat:@"%f",date] Tag:@"orderDate"],
						  [NSString addData:[[[UIDevice currentDevice] identifierForVendor] UUIDString] Tag:@"deviceID"],
						  [NSString addData:[[UIDevice currentDevice] systemVersion] Tag:@"iosVersion"],
						  nil];
		
		
		return [array componentsJoinedByString:@""];
	} else {
#ifdef DEBUG
		NSLog(@"Transaction Array is empty");
#endif
	}
	return @"";
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
		} else if ([tag isEqual:GLCODE]) {
			[array addObject:[NSString stringWithFormat:@"\n\t%@",transaction.glcode]];
		} else if ([tag isEqual:TOTAL]) {
			[array addObject:transaction.amount];
		} else {
			[array addObject:@"ERROR"];
		}
	}
	return [NSString addData:array Tag:tag];
}

+(NSString*) getDataWithTag:(NSString*)tag
{
	return [NSArray getDataWithTag:tag];
}
@end
