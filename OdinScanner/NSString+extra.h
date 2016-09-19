//
//  NSString+extra.h
//  My Kids Spending
//
//  Created by Alvin Luu on 2/10/16.
//
//

#import <Foundation/Foundation.h>

@interface NSString (extra)
-(NSNumber*)toNumber;
-(NSString*)nameCorrection;
-(NSString*)dollar;
+(NSString*)dataToString:(NSData*)data;
+(NSString*)downloadDataToString:(id)data;
@end
