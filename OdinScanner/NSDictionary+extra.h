//
//  NSDictionary+extra.h
//  My Kids Spending
//
//  Created by Alvin Luu on 2/11/16.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (extra)
-(NSArray *) sortedValues;

-(NSDictionary*) sortItemByDeptNumber;
+(NSDictionary *)downloadDataToDictionary:(id)data;
@end
