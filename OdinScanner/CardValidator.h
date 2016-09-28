//
//  CardValidator.h
//  OdinScanner
//
//  Created by KenThomsen on 7/9/14.
//
//

#import <Foundation/Foundation.h>

@interface CardValidator : InPayRetail

+(CardValidator*)initialize:(NSString*)magnetic;
-(NSString*)getCardLast4Digits;
-(NSDate*)getCardExpDate;
-(BOOL)isValidCardExpDate;
@end
