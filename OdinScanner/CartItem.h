//
//  CartItem.h
//  OdinScanner
//
//  Created by Ken Thomsen on 4/3/13.
//
//

#import <Foundation/Foundation.h>

@interface CartItem : NSObject

@property OdinEvent *item;
@property int count;

+(CartItem *)cartItemWithOdinItem:(OdinEvent *)item;

@end
