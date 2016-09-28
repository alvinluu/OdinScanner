//
//  UIAlertView+showSafely.h
//  OdinScanner
//
//  Created by Ben McCloskey on 2/21/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (showSafely) <UIAlertViewDelegate>
{
	
}

-(void)showSafely;
+(void)showBasicAlertWithTitle:(NSString *)title andMessage:(NSString *)message;

@end
