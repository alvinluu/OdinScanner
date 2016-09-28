//
//  NSDecimalNumber+decimalFromNumber.h
//  OdinScanner
//
//  Created by Ben McCloskey on 10/23/12.
//
//

#import <Foundation/Foundation.h>

@interface NSDecimalNumber (decimalFromNumber)

+(NSDecimalNumber *) decimalNumberWithNumber:(NSNumber *)number;
-(NSDecimalNumber *) addTax:(NSDecimalNumber*)tax;

@end
