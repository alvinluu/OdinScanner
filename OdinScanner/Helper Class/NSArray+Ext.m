//
//  NSArray+Ext.m
//  OdinScanner
//
//  Created by Alvin Luu on 4/27/17.
//
//

#import "NSArray+Ext.h"
#import "CartItem.h"

@implementation NSArray (Ext)
-(BOOL) hasCheckBalanceInCart
{
    for (CartItem *itemInCart in self) {
        
        OdinEvent *theItem = [itemInCart item];
        if (theItem.chk_balance.boolValue) {
            return true;
        }
    }
    return false;
}
-(NSNumber*) totalAmountInCart
{
    double total = 0.0;
    for (CartItem *itemInCart in self) {
        
        OdinEvent *theItem = [itemInCart item];
        total += theItem.amount.doubleValue;
    }
    return [NSNumber numberWithDouble: total];
}

@end
