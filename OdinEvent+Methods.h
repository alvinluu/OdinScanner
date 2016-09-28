//
//  OdinEvent+Methods.h
//  OdinScanner
//
//  Created by Ben McCloskey on 10/19/12.
//
//

#import "OdinEvent.h"

@interface OdinEvent (Methods)

-(OdinEvent *)loadValuesFromDictionaryRepresentation:(NSDictionary *)itemAsDictionary;
+(OdinEvent *)searchForItemWithBarcode:(NSString*)barcode;
+(OdinEvent *)searchForItemWithPLU:(NSString*)plu;
+(NSArray*)getAllItems;
+(NSArray*)getItemsBySearch:(NSString *)searchString;
+(int)count;
@end
