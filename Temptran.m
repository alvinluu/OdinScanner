//
//  Temptran.m
//  OdinScanner
//
//  Created by Ben McCloskey on 1/25/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "Temptran.h"
#import "NSDate+asStringWithFormat.h"
#import "PropertyUtility.h"

@implementation Temptran

@synthesize id_number;
@synthesize plu;
@synthesize item;
@synthesize payment;
@synthesize reference;
@synthesize operator;
@synthesize location;
@synthesize glcode;
@synthesize dept_code;
@synthesize qty; 
@synthesize amount;
@synthesize tax_amount;
@synthesize time;
@synthesize qdate;
@synthesize school;

-(id)init
{	
	school = [[SettingsHandler sharedHandler] school];
	
	id_number = @"";
	plu = @"";
	item = @"";
	payment = @"";
	time = @"";
	qdate = @"";
	qty = 0; 
	amount = 0;
	tax_amount = 0;
	
	glcode = 0;
	dept_code = 0;
	
	return self;
}

-(Temptran *)builtFromTransaction:(OdinTransaction *)transaction
{		
	id_number = [transaction idNumber];
	plu = [transaction plu];
	qty = [transaction qty];
	amount = [NSString stringWithFormat:@"%.2f",[[transaction amount] floatValue]];
	qdate = [transaction.timeStamp asStringWithFormat:@"@YYYY-@MM-@DD"];
	time = [transaction.timeStamp asStringWithFormat:@"@hh:@mm:@ss"];
	tax_amount = [transaction taxAmount];
	reference = [transaction reference];
	return self;
}

@end
