//
//  HUDsingleton.m
//  OdinScanner
//
//  Created by Ben McCloskey on 10/31/12.
//
//

#import "HUDsingleton.h"

@implementation HUDsingleton

//@synthesize HUD;


//static HUDsingleton *sharedHUD = nil;

+(HUDsingleton *)sharedHUD
{
//	@synchronized(self)
//	{
//		if (sharedHUD == nil)
//			sharedHUD = [[HUDsingleton alloc] init];
//	}
//	return sharedHUD;
    static HUDsingleton* shared = nil;
    @synchronized(self) {
        if (shared == nil) {
            shared = [[self alloc] init];
        }
    }
    return shared;
}


//-(HUDsingleton *)HUD
//{
//	if (HUD)
//		return HUD;
//	
//	//if no HUD and no keywindow, return nil	
//	else if(![UIApplication sharedApplication].keyWindow)	
//		return nil;
//	
//	//else assign and return sharedHUD
//	else
//	{
//		HUD = [[HUDsingleton alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
//		return HUD;
//	}
//}

@end
