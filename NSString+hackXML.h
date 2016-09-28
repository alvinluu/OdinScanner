//
//  NSString+hackXML.h
//  OdinScanner
//
//  Created by Ben McCloskey on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (hackXML)

-(NSString *)extractJSONfromXML;
+(NSString*) addData:(NSObject*)data Tag:(NSString*)tag;

@end
