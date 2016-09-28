//
//  CardValidator.h
//  OdinScanner
//
//  Created by KenThomsen on 7/9/14.
//
//

#import <Foundation/Foundation.h>
//Credit card
#import "InPayRetail.h"

@interface CardProcessor : InPayRetail
@property (nonatomic, strong) NSString* stripData;

+(CardProcessor*)initialize:(NSString*)magnetic;

//Charge transaction to Credit/Debit card
-(BOOL)makePurchase;

//Get the last 4 digits
-(NSNumber*)getCardLast4Digits;
//InPayRetail doesn't decypher magnetic strip expire date
-(NSDate*)getCardExpDate;
-(NSString*)getCardName;
-(NSString*)getCardFirstName;
-(NSString*)getCardLastName;
//Check expire date has pass today date
-(BOOL)isValidCardExpDate;
-(BOOL)setTerminal;
@end
