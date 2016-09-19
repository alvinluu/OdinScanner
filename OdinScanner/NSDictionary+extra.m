//
//  NSDictionary+extra.m
//  My Kids Spending
//
//  Created by Alvin Luu on 2/11/16.
//
//

#import "NSDictionary+extra.h"

@implementation NSDictionary (extra)
-(NSArray *) sortedValues
{
    
    NSArray* sortedArray = [self keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)];
    return sortedArray;
    
}

-(NSDictionary*) sortItemByDeptNumber
{
    
    //sorted key by dept number
    NSArray* sortedKeys = [self keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        //index 4 is dept number
        return [[obj1 objectAtIndex:4] compare:[obj2 objectAtIndex:4]];
        
        //		return obj1;
    }];
    
    //create a new sorted dictionary
    NSMutableDictionary* sortedDict = [[NSMutableDictionary alloc]init];
    for (NSString* key in sortedKeys) {
        [sortedDict setValue:[self objectForKey:key] forKey:key];
    }
    //overwrite old dictionary to a sorted dicationary
    //	[appDelegate.selectedItemsDict setDictionary:sortedDict];
    return sortedDict;
    
}
+(NSDictionary *)downloadDataToDictionary:(id)data
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
        return tempDict;
    }
    return nil;
}
@end
