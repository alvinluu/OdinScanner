//
//  NSstring+inputChecks.h
//  OdinScanner
//
//  Created by Ben McCloskey on 1/30/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (inputChecks)

-(BOOL) containsNonNumbers;
-(BOOL) containsNonDecimalNumbers;
-(BOOL) containsApostrophe;
-(NSString *) cleanBarcode;
-(NSString *) stripApostrophes;
-(NSString *) checkExportID;
-(NSString *) getStMarkExportID;
-(NSString *) strip$B;
-(NSString *) idStartStop;
+(NSString *)insertSOAPContent:(NSString*)content action:(NSString*)action;
-(BOOL) compareReference:(NSString*)reference;
+(NSString*)printName:(NSString*)name;
@end
