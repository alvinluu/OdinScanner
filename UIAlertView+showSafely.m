//
//  UIAlertView+showSafely.m
//  OdinScanner
//
//  Created by Ben McCloskey on 2/21/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "UIAlertView+showSafely.h"

@implementation UIAlertView (showSafely)


-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	
    //u need to change 0 to other value(,1,2,3) if u have more buttons.then u can check which button was pressed.
#ifdef DEBUG
	NSLog(@"UIAlertView Button Pressed %@", alertView.title);
#endif
	
	//Announce Alert View is Dismissed
	//CANCEL BUTTON
	if ([alertView.title isEqualToString:@"No Access To Server"]
		|| [alertView.title isEqualToString:@"No Access To Student"]
		|| [alertView.title isEqualToString:@"No Access To Item"]) {
		if (buttonIndex == 0) {
#ifdef DEBUG
			NSLog(@"No retry");
#endif
			//ReSync
			[AuthenticationStation sharedHandler].isStudentConnectionRetry = NO;
			
		} else if (buttonIndex == 1)
		{
#ifdef DEBUG
			NSLog(@"Retry");
#endif
			[AuthenticationStation sharedHandler].isStudentConnectionRetry = YES;
			
		}
		
	}
	[AuthenticationStation sharedHandler].isLoopingTimer = NO;
}

-(void)showSafely
{
#ifdef DEBUG
	//NSLog(@"isAlertDisplay %d",[[SettingsHandler sharedHandler] isAlertDisplay] );
#endif
	
	//Announce Alert View is Displaying
	if ([[SettingsHandler sharedHandler] isAlertDisplay]) { return; }
	
	//set delegate to self to activate clickedButtonAtIndex when Alert View is closed
	self.delegate = self;
	//run show with main thread
	[self performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
}

+(void)showBasicAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
	//Announce Alert View is Displaying
	if ([[SettingsHandler sharedHandler] isAlertDisplay]) { return; }
	
	[[[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] showSafely];
}

@end
