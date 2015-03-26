//
//  ALAlertView+methods.m
//  OdinScanner
//
//  Created by KenThomsen on 3/2/15.
//
//

#import "ALAlertView+methods.h"

@implementation ALAlertView (methods)

#pragma mark - Invalid Input
-(void)emptyField:(UIView *)vc
{
	NSLog(@"alalert emptyfield");
	
	[self showInView:vc
									 title:@"Incomplete Transaction"
								   message:@"Please make sure all fields have values entered"];
}

-(void)invalidQuantity:(UIView *)vc
{
	[self showInView:vc
									 title:@"Incorrect Quantity Value"
								   message:@"Please make sure the quantity field contains only numbers"];
}

-(void)invalidTax:(UIView *)vc
{
	[self showInView:vc
									 title:@"Incorrect Tax Value"
								   message:@"Please make sure the tax field contains only numbers and up to one decimal point, or is left blank (for 0%)"];
}

-(void)invalidRetail:(UIView *)vc
{
	[self showInView:vc
	 title:@"Incorrect Retail Value"
													message:@"Please make sure the retail amount is valid"
												 ];
}
-(void)noItemSelected:(UIView*)vc
{
	[self showInView:vc
									 title:@"No Item Selected"
													message:@"Please select an item"];
}

-(void)noCost:(UIView *)vc
{
	[self showInView:vc
									 title:@"No Cost"
													message:@"Selected item cost $0.00. Doesn't need to pay"
												];
	
}
-(void)cardPresentAlert:(UIView *)vc
{
	[self showInView:vc title:
	 @"Incomplete Transaction"
													message:@"Please make sure all fields have values entered"
												 ];
}
-(void) studentCantAfford:(NSString *)studentID sourceView:(UIView*)vc
{
	[self showInView:vc
									 title:@"Funds not Available"
													message:[NSString stringWithFormat: @"%@ has insufficient fund",studentID]
												 ];
}
#pragma mark - Data / Connection
-(void) switchedToOfflineMode:(UIView*)vc
{
	
	NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
	[moc setPersistentStoreCoordinator:[CoreDataHelper getMainStoreCoordinator]];
	
	//get the count for student
	NSArray *allStudents = [CoreDataHelper getObjectsForEntity:@"OdinStudent"
												   withSortKey:nil
											  andSortAscending:YES
													andContext:moc];
	
	//get the last Update
	LastUpdates *lastUpdate = [LastUpdates getLastUpdatefromMOC:moc];
	NSDate *lastStudDate = [lastUpdate lastStudentUpdate];
	NSString *textDate = [lastStudDate asStringWithNSDate];
	
	if ([lastStudDate isEqualToDate: [NSDate distantFuture]]) {
		textDate = @"no update";
	}
	NSString *alertMessage = [NSString stringWithFormat:@"The app will not check for student updates until switched back to online mode.\n Student count: %i \n Last Student Update: %@",[allStudents count], textDate];
	
#ifdef DEBUG
	NSLog(@"updateAllStudents after retest: date %@", textDate);
#endif
	//NSString *lastStudUp = [[lastUpdate lastStudentUpdate] asStringWithFormat:@"@MM/@DD/@YY at @hh:@mm:@ss"];
	//NSString *alertMessage = [NSString stringWithFormat:@"The app will not check for student updates until switched back to online mode.\n Student updates last took place:\n%@",lastStudUp];
	[self  showInView:vc
										   title:@"Switched To Offline Mode"
												 message:alertMessage
												 buttons:@[@"Cancel",@"Retry"]
						  ];
	
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];
}
-(void)cannotEditItem:(UIView *)vc
{
	[self cannotEditItem:@"" sourceView:vc];
}

-(void)cannotEditItem:(NSString *)specifier sourceView:(UIView *)vc
{
	
	[self showInView:vc
									 title:@"Unable to Edit"
													message:[NSString stringWithFormat:@"Editing %@ is not allowed for this item", specifier]
												 ];
}

-(void)noSchoolServer:(UIView *)vc
{
	
	[self showInView:vc
									 title:@"No Access To Server"
													message:@"Please check wifi access and server settings to connect to your local server"
												 ];
}

-(void)noStudentConnection:(NSString *)id_number sourceView:(UIView *)vc
{
	
	
	NSString* msg = @"Please check wifi access and server settings to connect to your local server";
	if (id_number)
		msg = [NSString stringWithFormat:@"Cannot fetch ID: %@ \nPlease check wifi access and server settings to connect to your local server",id_number ];
	[self showInView:vc
									 title:@"No Access To Student"
													message:msg
												 ];
	//TODO: need to fix alert
	/*ALAlertView* alert = [ALAlertView alertWithTitle:@"No Access To Student" message:msg];
	[alert addAction:[PSTAlertAction actionWithTitle:@"Retry" handler:^(PSTAlertAction *action) {
		
	}]];
	[alert addCancelActionWithHandler:^(PSTAlertAction *action) {
		
		[AuthenticationStation sharedAuth].isStudentConnectionRetry = NO;
	}];
	
	[alert showWithSender:nil controller:vc animated:YES completion:^(void) {
		[AuthenticationStation sharedAuth].isLoopingTimer = NO;
		[[SettingsHandler sharedHandler] setIsAlertDisplay:NO];
	}];*/
	/*NSString* msg = @"Please check wifi access and server settings to connect to your local server";
	 if (id_number)
		msg = [NSString stringWithFormat:@"Cannot fetch ID: %@ \nPlease check wifi access and server settings to connect to your local server",id_number ];
	 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Access To Student"
	 message:msg
	 delegate:self
	 cancelButtonTitle:@"QUIT"
	 otherButtonTitles:@"RETRY",nil];
	 */
}
-(void) synchedAlert:(UIView*)vc
{
	[self showInView:vc
									 title:@"Entry cannot be deleted"
													message:@"This entry has already been sent to the network and can no longer be deleted here."
												 ];
}

-(void)cannotSwitchToOnline:(UIView*)vc
{
	[self showInView:vc
									 title:@"Cannot Switch To Online Mode"
													message:@"Please connect to a network and try again."
												 ];
}


-(void)cannotUpdateInOffline:(UIView*)vc
{
	[self showInView:vc
									 title:@"Cannot Sync in Offline Mode"
													message:@"Please switch back to Online Mode before ReSync or Update"
												 ];
}
-(void) noScannerToOfflineMode:(UIView*)vc
{
	[self showInView:vc
									 title:@"No Scanner Detected and to Offline Mode"
													message:@"Please click scan button till you see laser light to awake scanner. The app will go into OFFLINE MODE and will not check for student updates until switched back to online mode."
												 ];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];
	
	
}

-(void) noInternetConnection:(UIView*)vc
{
	[self showInView:vc
									 title:@"No Internet Connection"
													message:@"Please connect to the internet. Device will stay in Offline Mode."
												 ];
	//[AuthenticationStation sharedAuth].isOnline = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];
}
#pragma mark - Credit Card

-(void)chargeDeclined:(UIView *)vc
{
	
	[self showInView:vc
									 title:@"Card Error"
													message:@"Charge Declined"
												 ];
}
-(void)failToPostToWebservice:(UIView *)vc
{
	[self showInView:vc
									 title:@"Card Transaction Error"
													message:@"Transaction is charged but fail to deliver to webservice."
												 ];
}
-(void)failToPostToEmailService:(UIView *)vc
{
	[self showInView:vc
									 title:@"Card Transaction Error"
													message:@"Transaction is charged but fail to deliver to email service."
												 ];
	
}
#pragma mark - Custom Alert
-(void)customshowInView:(NSString *)title message:(NSString *)message sourceView:(UIView *)vc
{
	
	[self showInView:vc
									 title:title
													message:message
												 ];
}
#pragma mark - Private instance
-(void) simpleAlertInView:(NSString *)title message:(NSString *)message sourceView:(UIView*)vc
{
//	ALAlertView* alert = [ALAlertView alertWithTitle:title message:message];
//	[alert addOKActionWithHandler:nil];
//	[alert showWithSender:nil controller:vc animated:YES completion:nil];
	[self showInView:vc title:title message:message];
}
@end
