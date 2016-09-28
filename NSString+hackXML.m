//
//  NSString+hackXML.m
//  OdinScanner
//
//  Created by Ben McCloskey on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+hackXML.h"

@implementation NSString (hackXML)

-(NSString *)extractJSONfromXML
{
	if(self)
	{
		if ([self length] > 2)
		{
			NSString *firstChar = [self substringWithRange:NSMakeRange(0,1)];
			NSString *lastChar = [self substringWithRange:NSMakeRange([self length], 1)];
			
			//if we're already a JSON, don't hack it out of the XML
			if ([firstChar isEqualToString:@"{"] && [lastChar isEqualToString:@"}"])
				return self;
			
			//extract JSON string from XML wrapper.
			NSRange rangeOfStringBegin = [self rangeOfString:@"<string xmlns=\"http://www.MyKidsSpending.com/\">"];
			int stringBegin = rangeOfStringBegin.location + rangeOfStringBegin.length;
			
			NSRange rangeOfStringEnd = [self rangeOfString:@"</string>"];
			int stringEnd = rangeOfStringEnd.location;
			
			int stringLength = stringEnd - stringBegin;
			
			NSString * stringToReturn = [self substringWithRange:NSMakeRange(stringBegin, stringLength)];
			
			//escapes '\'s in returned string
			stringToReturn = [stringToReturn stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
			
			//slap on the {} braces if they don't exist for some reason
			firstChar = [stringToReturn substringWithRange:NSMakeRange(0,1)];
			lastChar = [stringToReturn substringWithRange:NSMakeRange([stringToReturn length], 1)];
			
			if (![firstChar isEqualToString:@"{"])
				stringToReturn = [NSString stringWithFormat:@"{%@",stringToReturn];
			if (![lastChar isEqualToString:@"}"])
				stringToReturn = [NSString stringWithFormat:@"%@}",stringToReturn];
			
			return stringToReturn;
		}
	}
	return self;
	
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

+(NSString*) addData:(NSObject*)data Tag:(NSString*)tag
{
	return [[NSString alloc] addData:data Tag:tag];
	
}
@end
