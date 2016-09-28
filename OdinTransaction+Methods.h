//
//  OdinTransaction+Methods.h
//  OdinScanner
//
//  Created by Ben McCloskey on 10/19/12.
//
//

//@class OdinTransaction;
//@class OdinEvent;
#import "OdinTransaction.h"
#import "OdinEvent+Methods.h"

@interface OdinTransaction (Methods)

+(NSDecimalNumber *)getTotalAmountFromQtyEntered:(NSNumber *)qty andAmountEntered:(NSDecimalNumber *)amount forItem:(OdinEvent *)selectedItem;

-(NSString*) prepForWebservice;
-(NSString* )getCreditCardData;
-(NSDictionary *)preppedForWeb;
-(NSString *)XML;
-(NSString *)JSON;
-(BOOL)existIn:(NSManagedObjectContext*)moc;
+(NSArray*) reloadUnSyncedArray;
+(NSArray*) reloadUnSyncedArrayWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*) reloadSyncedArray;

+(BOOL) deleteTransactionByReference:(NSString*)reference;
+(BOOL) deleteCurrentTransaction:(NSString*)reference;
-(BOOL) deleteCurrentTransaction;
+(OdinTransaction*) getTransactionByReference:(NSString*)reference;
+(OdinTransaction *)getTransactionByReference:(NSString *)reference andContext:(NSManagedObjectContext*)moc;
+(OdinTransaction *)getTransaction:(NSDictionary*)transaction andContext:(NSManagedObjectContext*)moc;
@end
