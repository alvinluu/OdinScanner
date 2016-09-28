//
//  RegisterItem+Methods.m
//  OdinScanner
//
//  Created by Ken Thomsen on 2/22/13.
//
//

#import "RegisterItem+Methods.h"

@implementation RegisterItem (Methods)

-(RegisterItem *)loadValuesFromDictionaryRepresentation:(NSDictionary *)itemAsDictionary
{
	if ([itemAsDictionary objectForKey:@"retail"])
		self.retail = [itemAsDictionary objectForKey:@"retail"];
	
	if ([itemAsDictionary objectForKey:@"plu"])
		self.plu = [itemAsDictionary objectForKey:@"plu"];
	
	if ([itemAsDictionary objectForKey:@"item"])
		self.item = [itemAsDictionary objectForKey:@"item"];
	
	//if no tax info, default to 0%
	if ([itemAsDictionary objectForKey:@"taxrate"])
		self.taxrate = [itemAsDictionary objectForKey:@"taxrate"];
	else
		self.taxrate = [NSDecimalNumber decimalNumberWithNumber:[NSNumber numberWithInt:0]];
	
	if ([itemAsDictionary objectForKey:@"location"])
		self.location = [itemAsDictionary objectForKey:@"location"];
	
	if ([itemAsDictionary objectForKey:@"barcode"])
		self.barcode = [itemAsDictionary objectForKey:@"barcode"];
	
	if ([itemAsDictionary objectForKey:@"gl_code"])
		self.glCode = [itemAsDictionary objectForKey:@"gl_code"];
	
	if ([itemAsDictionary objectForKey:@"dept_code"])
		self.deptCode = [itemAsDictionary objectForKey:@"dept_code"];
	
	if ([itemAsDictionary objectForKey:@"school"])
		self.school = [itemAsDictionary objectForKey:@"school"];
	
	if ([itemAsDictionary objectForKey:@"taxable"])
		self.taxable = [itemAsDictionary objectForKey:@"taxable"];
	
#ifdef DEBUG
	NSLog(@"Item Added: %@", self.item);
#endif
	return self;
}

@end
