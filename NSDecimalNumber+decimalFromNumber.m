//
//  NSDecimalNumber+decimalFromNumber.m
//  OdinScanner
//
//  Created by Ben McCloskey on 10/23/12.
//
//

#import "NSDecimalNumber+decimalFromNumber.h"

@implementation NSDecimalNumber (decimalFromNumber)

+(NSDecimalNumber *) decimalNumberWithNumber:(NSNumber *)number
{
	return [NSDecimalNumber decimalNumberWithDecimal:[number decimalValue]];
}
-(NSDecimalNumber *) addTax:(NSDecimalNumber*)tax
{
    
    NSDecimalNumber* shift2decimal = [tax decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];
    NSDecimalNumber* percentage = [[NSDecimalNumber decimalNumberWithString:@"1"] decimalNumberByAdding:shift2decimal];
    NSDecimalNumber* dec = [self decimalNumberByMultiplyingBy:percentage];
#ifdef DEBUG
    NSLog(@"shift %.4f",[shift2decimal floatValue]);
    NSLog(@"percentage %.4f",[percentage floatValue]);
    NSLog(@"tax %.4f",[dec floatValue]);
#endif
    return dec;
}
@end
