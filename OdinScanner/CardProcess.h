//
//  CardValidator.h
//  OdinScanner
//
//  Created by KenThomsen on 7/9/14.
//
//

#import <Foundation/Foundation.h>

@interface CardProcess : InPayRetail

+(CardProcess*)initialize:(NSString*)magnetic;
-(NSString*)getCardLast4Digits;
-(NSDate*)getCardExpDate;
-(BOOL)isValidCardExpDate;
@end
