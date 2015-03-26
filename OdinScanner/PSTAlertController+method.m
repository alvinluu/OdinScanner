//
//  PSTAlertController+method.m
//  OdinScanner
//
//  Created by KenThomsen on 1/7/15.
//
//

#import "PSTAlertController+method.h"

@implementation PSTAlertController (method)

#pragma mark - Invalid Input
+(void)emptyField:(UIViewController *)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Incomplete Transaction"
													message:@"Please make sure all fields have values entered"
												 controller:vc];
}

+(void)invalidQuantity:(UIViewController *)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Incorrect Quantity Value"
													message:@"Please make sure the quantity field contains only numbers"
												 controller:vc];
}

+(void)invalidTax:(UIViewController *)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Incorrect Tax Value"
													message:@"Please make sure the tax field contains only numbers and up to one decimal point, or is left blank (for 0%)"
												 controller:vc];
}

+(void)invalidRetail:(UIViewController *)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Incorrect Retail Value"
													message:@"Please make sure the retail amount is valid"
												 controller:vc];
}
+(void)noItemSelected:(UIViewController*)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"No Item Selected"
													message:@"Please select an item"
												 controller:vc];
}

+(void)noCost:(UIViewController *)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"No Cost"
													message:@"Selected item cost $0.00. Doesn't need to pay"
												 controller:vc];
	
}
+(void)cardPresentAlert:(UIViewController *)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Incomplete Transaction"
													message:@"Please make sure all fields have values entered"
												 controller:vc];
}
+(void) studentCantAfford:(NSString *)studentID controller:(UIViewController*)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Funds not Available"
													message:@"Insufficient Funds"
												 controller:vc];
}
#pragma mark - Data / Connection
+(void) switchedToOfflineMode:(UIViewController*)vc
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
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Switched To Offline Mode" message:alertMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert showSafely];
	
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];
}
+(void)cannotEditItem:(UIViewController *)vc
{
	[PSTAlertController cannotEditItem:@"" controller:vc];
}

+(void)cannotEditItem:(NSString *)specifier controller:(UIViewController *)vc
{
						  
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Unable to Edit"
													message:[NSString stringWithFormat:@"Editing %@ is not allowed for this item", specifier]
												 controller:vc];
}

+(void)noSchoolServer:(UIViewController *)vc
{
	
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"No Access To Server"
													message:@"Please check wifi access and server settings to connect to your local server"
												 controller:vc];
}

+(void)noStudentConnection:(NSString *)id_number controller:(UIViewController *)vc
{
	
	
	NSString* msg = @"Please check wifi access and server settings to connect to your local server";
	if (id_number)
		msg = [NSString stringWithFormat:@"Cannot fetch ID: %@ \nPlease check wifi access and server settings to connect to your local server",id_number ];
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"No Access To Student"
													message:msg
												 controller:vc];
	PSTAlertController* alert = [PSTAlertController alertWithTitle:@"No Access To Student" message:msg];
	[alert addAction:[PSTAlertAction actionWithTitle:@"Retry" handler:^(PSTAlertAction *action) {
		
	}]];
	[alert addCancelActionWithHandler:^(PSTAlertAction *action) {
		
		[AuthenticationStation sharedAuth].isStudentConnectionRetry = NO;
	}];
	
	[alert showWithSender:nil controller:vc animated:YES completion:^(void) {
		[AuthenticationStation sharedAuth].isLoopingTimer = NO;
		[[SettingsHandler sharedHandler] setIsAlertDisplay:NO];
	}];
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
+(void) synchedAlert:(UIViewController*)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Entry cannot be deleted"
													message:@"This entry has already been sent to the network and can no longer be deleted here."
												 controller:vc];
}

+(void)cannotSwitchToOnline:(UIViewController*)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Cannot Switch To Online Mode"
													message:@"Please connect to a network and try again."
												 controller:vc];
}


+(void)cannotUpdateInOffline:(UIViewController*)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Cannot Sync in Offline Mode"
													message:@"Please switch back to Online Mode before ReSync or Update"
												 controller:vc];
}
+(void) noScannerToOfflineMode:(UIViewController*)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"No Scanner Detected and to Offline Mode"
													message:@"Please click scan button till you see laser light to awake scanner. The app will go into OFFLINE MODE and will not check for student updates until switched back to online mode."
												 controller:vc];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];
	
	
}

+(void) noInternetConnection:(UIViewController*)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"No Internet Connection"
													message:@"Please connect to the internet. Device will stay in Offline Mode."
												 controller:vc];
	//[AuthenticationStation sharedAuth].isOnline = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];
}
#pragma mark - Credit Card

+(void)chargeDeclined:(UIViewController *)vc
{
	
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Card Error"
													message:@"Charge Declined"
												 controller:vc];
}
+(void)failToPostToWebservice:(UIViewController *)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Card Transaction Error"
													message:@"Transaction is charged but fail to deliver to webservice."
												 controller:vc];
}
+(void)failToPostToEmailService:(UIViewController *)vc
{
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:@"Card Transaction Error"
													message:@"Transaction is charged but fail to deliver to email service."
												 controller:vc];
	
}
#pragma mark - Custom Alert
+(void)customSimpleAlertWithTitle:(NSString *)title message:(NSString *)message controller:(UIViewController *)vc
{
	
	[[[PSTAlertController alloc] init] simpleAlertWithTitle:title
													message:message
												 controller:vc];
}
#pragma mark - Private instance
-(void) simpleAlertWithTitle:(NSString *)title message:(NSString *)message controller:(UIViewController*)vc
{
	PSTAlertController* alert = [PSTAlertController alertWithTitle:title message:message];
	[alert addOKActionWithHandler:nil];
	[alert showWithSender:nil controller:vc animated:YES completion:nil];
}

- (void)addOKActionWithHandler:(void (^)(PSTAlertAction *action))handler {
	[self addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:PSTAlertActionStyleCancel handler:handler]];
}
@end
