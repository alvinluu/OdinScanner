//
//  NSString+extra.m
//  My Kids Spending
//
//  Created by Alvin Luu on 2/10/16.
//
//

#import "NSString+extra.h"

@implementation NSString (extra)
-(NSNumber*)toNumber
{
    
    NSNumberFormatter *numFormat = [[NSNumberFormatter alloc] init];
    [numFormat setNumberStyle:NSNumberFormatterDecimalStyle];
    [numFormat setMaximumFractionDigits:2];
    [numFormat setMinimumFractionDigits:2];
    return [numFormat numberFromString:self];
}
-(NSString*)nameCorrection
{
    NSString* str = [self stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    str = [str stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    return [str capitalizedString];
}
-(NSString*)dollar
{
    return [@"$" stringByAppendingFormat:@"%.2f",self.toNumber.floatValue];
}
+(NSString*)dataToString:(NSData*)data
{
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
+(NSString *)downloadDataToString:(id)data
{
    NSError *error;
    NSPropertyListFormat format;
    
//    NSDictionary *tempDict = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error]; //depreciated
    NSDictionary* tempDict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:&error];
    if (error != nil) {
        NSLog(@"Error while reading plist: %@", error);
    } else
    {
        if ([tempDict.description hasPrefix:@"<plist"]) {
            NSLog(@"Decode xml plist again");
            NSData* newData = [tempDict.description dataUsingEncoding:NSUTF8StringEncoding];
            tempDict = [NSPropertyListSerialization propertyListWithData:newData options:NSPropertyListImmutable format:&format error:&error];
        }
        return tempDict.description;
    }
    return nil;
}

@end
