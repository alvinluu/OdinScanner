//
//  UIAlertView+ReSync.m
//  OdinScanner
//
//  Created by KenThomsen on 1/23/14.
//
//

#import "UIAlertView+ReSync.h"


@implementation UIAlertView (ReSync)



-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	
    //u need to change 0 to other value(,1,2,3) if u have more buttons.then u can check which button was pressed.
#ifdef DEBUG
	//NSLog(@"Alert Button Pressed");
#endif
	
	//Announce Alert View is Dismissed
    if (buttonIndex == 0) {
    }
	else {
		
	}
}
-(void)showReSync
{
#ifdef DEBUG
	//NSLog(@"isAlertDisplay %d",[[SettingsHandler sharedHandler] isAlertDisplay] );
#endif
	
	//Announce Alert View is Displaying
	
	//set delegate to self to activate clickedButtonAtIndex when Alert View is closed
	self.delegate = self;
	//run show with main thread
	[self performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
}



@end
