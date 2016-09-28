//
//  CartItem.m
//  OdinScanner
//
//  Created by Ken Thomsen on 4/3/13.
//
//

#import "CartItem.h"

@implementation CartItem

-(CartItem *)initWithItem:(OdinEvent *)item
{
	if (self = [super init])
	{
		
		self.count = 1;
		self.item = item;
		return self;
	}
	return nil;
}

+(CartItem *)cartItemWithOdinItem:(OdinEvent *)item
{
	return [[CartItem alloc] initWithItem:item];
}


@end
