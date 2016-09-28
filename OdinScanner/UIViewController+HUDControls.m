//
//  UIViewController+HUDControls.m
//  OdinScanner
//
//  Created by Ben McCloskey on 10/31/12.
//
//

#import "UIViewController+HUDControls.h"
#import "SynchronizationOperation.h"
#import "StudentUpdate.h"
#import "Linea.h"

@implementation UIViewController (HUDControls)


//these are the various methods to show different parentHUD images to denote activity
//each must be called before the method that will do the work it's displaying

-(void) showCacheActivity
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        //your background code here
        MBProgressHUD* HUD = [HUDsingleton sharedHUD];
        
        HUD.delegate = self;
        HUD.mode = MBProgressHUDModeIndeterminate;
        HUD.labelText = @"Connecting...";
        HUD.detailsLabelText = @"Authenticating";
        dispatch_async(dispatch_get_main_queue(), ^{
            //your main thread code here
            [[UIApplication sharedApplication].keyWindow addSubview:HUD];
            [HUD show:YES];
        });
    });
	
	[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_DISABLED error:nil];
}
/*-(void)updateConnectionTitle:(NSNotification *) notification
{
	NSDictionary* userInfo = notification.userInfo;
	NSString* message = [userInfo objectForKey:@"errorMsg"];
	[HUDsingleton sharedHUD].HUD.labelText = message;
    
}
-(void)updateConnection:(NSNotification *) notification
{
	NSDictionary* userInfo = notification.userInfo;
	NSString* message = [userInfo objectForKey:@"errorMsg"];
	[HUDsingleton sharedHUD].HUD.detailsLabelText = message;
    
}
-(void)updateConnectionActivity:(NSNotification *)notification
{
	float studentNumber = [[notification object] studentListSize];
	if (studentNumber) {
		[HUDsingleton sharedHUD].HUD.detailsLabelText = @"Connection Success";
	} else
	{
		[HUDsingleton sharedHUD].HUD.detailsLabelText = @"Connection Failed";
	}
}
-(void)updateActivity:(NSNotification *)notification
{	
	float studentNumber = [[notification object] studentListSize];
	float totalStudents = [[notification object] studentListTotalSize];
	if([HUDsingleton sharedHUD].HUD)
	{
		if ([HUDsingleton sharedHUD].HUD.mode == MBProgressHUDModeIndeterminate)
			[HUDsingleton sharedHUD].HUD.mode = MBProgressHUDModeDeterminate;
		
		if (([HUDsingleton sharedHUD].HUD.mode == MBProgressHUDModeDeterminate)
			&& (totalStudents != 0))
		{
			[HUDsingleton sharedHUD].HUD.progress = (1- (studentNumber / totalStudents));
		}
		if (studentNumber == 0)
		{
			[HUDsingleton sharedHUD].HUD.mode = MBProgressHUDModeIndeterminate;
			[HUDsingleton sharedHUD].HUD.labelText = @"Finishing up";
			[HUDsingleton sharedHUD].HUD.detailsLabelText = @"";
		}
		else
		{
			int studentsToDownload = (int)studentNumber;
			[HUDsingleton sharedHUD].HUD.labelText = @"Connected!";
			[HUDsingleton sharedHUD].HUD.detailsLabelText = [NSString stringWithFormat:@"Downloading %i Accounts",studentsToDownload];
		}
	}
}*/

-(void) showProcessing
{	
	[HUDsingleton sharedHUD].delegate = self;
	[HUDsingleton sharedHUD].labelText = @"Processing...";
	[[HUDsingleton sharedHUD] show:YES];
}

-(void) hideActivity
{
//	[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
	dispatch_async(dispatch_get_main_queue(), ^{
		[[HUDsingleton sharedHUD] hide:YES];
	});
	[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"update studentListSize" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"update Connection Status" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"update Connection Title" object:nil];
//	[[HUDsingleton sharedHUD].HUD removeFromSuperview];
//	[HUDsingleton sharedHUD].HUD = nil;
}

/*-(void)showAlertViewToEnterUID
{
	[self performSelectorOnMainThread:@selector(uidAlertView) withObject:nil waitUntilDone:YES];
}

-(void)uidAlertView
{
	UIAlertView *uidEntryAlert = [[UIAlertView alloc] initWithTitle:@"Unable to Sync with UID"
															message:[NSString stringWithFormat:@"Serial:%@",[[AuthenticationStation sharedHandler] getSerialNumber]]
														   delegate:self
												  cancelButtonTitle:@"Later"
												  otherButtonTitles:@"OK", nil];
	[uidEntryAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
	[uidEntryAlert textFieldAtIndex:0].placeholder = [SettingsHandler sharedHandler].uid;
	[uidEntryAlert show];
}*/

//- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex

-(void) initializeAuth
{
	[self showCacheActivity];
	[[HUDsingleton sharedHUD] showWhileExecuting:@selector(finishAuth) onTarget:self withObject:nil animated:YES];
}
-(void) finishAuth
{
	[[AuthenticationStation sharedHandler] doAuth];
	[self hideActivity];
}

// throws an alert to notify the user if the app switches to offline mode

- (void)switchedToOfflineMode
{
	NSLog(@"UIVIEW switchedtoofflinemode");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];
	
}

-(void)failedSwitchToOnlineMode
{
	NSLog(@"UIVIEW failedswitchtoonlinemode");
	if ([NetworkConnection isInternetOffline]) {
		[ErrorAlert noInternetConnection];
	} else if ([[AuthenticationStation sharedHandler] isScannerDeactive]) {
		[ErrorAlert noScannerToOfflineMode];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];

}

@end
