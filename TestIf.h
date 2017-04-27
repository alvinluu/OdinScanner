//
//  Test.h
//  OdinScanner
//
//  Created by Ben McCloskey on 2/9/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OdinTransaction.h"
#import "OdinEvent.h"
#import "AFNetworking.h"

//Collection of functions designed to outsource testing of certain conditions for the program
@interface TestIf : NSObject
-(double) totalPendingTransactionAmountWithID:(NSString*)idNumber;
-(BOOL) account:(NSDictionary *)student canAffordAmounts:(NSNumber *)amount;
//Checks if the ID that is scanned can purchase an item (including restrictions)
+(BOOL) account:(NSDictionary *)student canPurchaseItem:(OdinEvent *)theItem forAmount:(NSNumber *)amount;

//Checks if the ID that is scanned can purchase an entire cart of items (including restrictions)
+(BOOL) account:(NSDictionary *)student canPurchaseCart:(NSArray *)items forAmounts:(NSNumber *)amounts;

+(double)studentOfflineBalanceWithID:(NSString*)idNumber;
//Checks if there is an existing connection to the "School" server
+(NSArray*) appCanUseSchoolServerAFN;

/*
//Checks if Wifi/WWAN is turned on 
//Currently unused (4/4/12)
+(BOOL) appIsOnWifi;
+(BOOL) appIsOnWWAN;
*/

//Checks if app is currently authorized (facade for AuthenticationStation)
+(BOOL) appIsSynchronized;

//Checks if an item can be deleted (based on allow_edit)
+(BOOL) canDeleteTransaction:(OdinTransaction *)transaction;

@end
