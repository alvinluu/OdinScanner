//
//  NSstring+inputChecks.m
//  OdinScanner
//
//  Created by Ben McCloskey on 1/30/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "NSstring+inputChecks.h"
#import "OdinStudent.h"
#import "SBJson.h"

@implementation NSString (inputChecks)

-(BOOL) containsNonNumbers
{
    int decimalCount = 0;
	int decimalPlaces = 0;
    NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"-0123456789."];
    for (int i = 0; i < [self length]; i++) 
    {
        unichar c = [self characterAtIndex:i]; 
        // allow for negative numbers
        if ((c == '-') && (i != 0)) 
			return YES;
		if (decimalCount == 1)
			decimalPlaces++;					
		if (c == '.') 			
			decimalCount++;
			//returns YES if string contains non-numerical characters or 2+ decimals
        if ((![myCharSet characterIsMember:c]) 
			|| (decimalCount > 1)
			|| (decimalPlaces > 2))
        {
            return YES;
        }
    }
    return NO;
}//returns NO if string contains only numbers and up to one decimal, and up to two decimal places

-(BOOL) containsNonDecimalNumbers
{
    NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString:@"-0123456789"];
    for (int i = 0; i < [self length]; i++) 
    {
        unichar c = [self characterAtIndex:i];
        // allow for negative numbers, but '-' after 1st char
        if ((c == '-') && (i != 0)) 
			return YES;       
        if (![myCharSet characterIsMember:c]) 
            return YES;
        //returns YES if string contains non-numerical decimal point characters
    }
    return NO;
}//returns NO if string contains only numbers (no decimals)


-(BOOL) containsApostrophe
{
	for (int i = 0;i < [self length]; i++)
	{
		unichar c = [self characterAtIndex:i];
		if (c == '\'')
			{
				return YES;
			}
	}
	return NO;
}

-(BOOL) startsWith$B
{
	if ([self length] < 2)
		return NO;	
	else if (([self characterAtIndex:0] == '$') && ([self characterAtIndex:1] == 'B'))
		return YES;
	else
		return NO;		
}

-(NSString *)strip$B
{
	if ([self startsWith$B])
	{
		return [self substringWithRange:NSMakeRange(2, ([self length] -2))];;
	}
	else
		return self;
}

//returns substring between the start/stop markers. Allows for barcodes to include things other than Odin ID
-(NSString *)idStartStop
{
	int idStart = [[SettingsHandler sharedHandler] idStart];
	int idStop  = [[SettingsHandler sharedHandler] idStop];
	if ((idStart == 0) && (idStop == 0))
		return self;
	
	if (idStop == 0 || idStop > self.length)
		idStop = [self length];
	
	return [self substringWithRange:NSMakeRange(idStart, (idStop - idStart))];
		
}
+(NSString *)insertSOAPContent:(NSString*)content action:(NSString*)action
{
    
    if ([action.lowercaseString isEqualToString:@"rcvtran"]) {
#ifdef DEBUG
        NSLog(@"INSERT SOAP content %@ to %@",content,action);
#endif
        return [NSString stringWithFormat:@"<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\"><s:Body><RcvTran xmlns=http://tempuri.org/\"><TranData>%@</TranData></RcvTran></s:Body></s:Envelope>",content];
    }
#ifdef DEBUG
    NSLog(@"INSERT SOAP content %@ to UNKNOWN",content);
#endif
    return content;
}
-(NSString *)cleanBarcode
{
    NSString* cleaned = [[self strip$B] idStartStop];
    
#ifdef DEBUG
    NSLog(@"cleaned id: %@",cleaned);
#endif
    return cleaned;
}

-(NSString *)getStMarkExportID {
    int length = 7;
    int start = self.length - length;
    NSString* exportid = [[self substringFromIndex:start] stringByReplacingOccurrencesOfString:@"?" withString:@""];
//    [ErrorAlert simpleAlertTitle:@"" message:exportid];
    return exportid;
}

//checks if they use export IDs, if so, returns the ID number associated with the exportID
-(NSString *)checkExportID
{
#if DEBUG
    NSLog(@"check export ID %@", self);
#endif
    if ([[SettingsHandler sharedHandler] useExportID]  == TRUE)
    {
#if DEBUG
        NSLog(@"Use export ID is enabled: %@", self);
#endif
        NSArray *arrayOfStudents = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                                            withPredicate:[NSPredicate predicateWithFormat:@"exportid = %@",self]
                                                               andSortKey:nil
                                                         andSortAscending:NO
                                                               andContext:[CoreDataService getMainMOC]];
        if ([arrayOfStudents count] == 0) {
#if DEBUG
            NSLog(@"export is not found and return %@", self);
#endif
            return self;
        } else
        {
#if DEBUG
            NSLog(@"export is found and return %@", self);
#endif
            OdinStudent *student = [arrayOfStudents objectAtIndex:0];
            return student.id_number;
        }
    }
    return self;
}

-(NSString *)stripApostrophes
{
	NSMutableString *string = [NSMutableString stringWithString:self];
	for (int i = 0;i < [string length];i++)
	{
		unichar c = [string characterAtIndex:i];
		if (c == '\'')
		{
			[string deleteCharactersInRange:NSMakeRange(i, 1)];
		}
	}
	return [NSString stringWithString:string];
}

/*
 * compare self to processing reference
 * if it is >=, we can go ahead nd process
 * NOTE: self should never greater than processing reference
 */
-(BOOL)compareReference:(NSString*)reference
{
    int current = [self substringFromIndex:2].intValue;
    int service = [reference substringFromIndex:2].intValue;
#ifdef DEBUG
    NSLog(@"COMPARE REF current:%i, processing:%i",current,service);
#endif
    return (current >= service);
    
}
+(NSString*)printName:(NSString*)name
{
    return name ? name : @"";
}

@end
