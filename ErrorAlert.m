//
//  ErrorAlert.m
//  OdinScanner
//
//  Created by Ben McCloskey on 1/31/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "ErrorAlert.h"
#import "UIAlertView+showSafely.h"
#import "LastUpdates+Methods.h"

@implementation ErrorAlert

#pragma mark - invalid input

+(void)emptyField
{
	[self simpleAlertTitle:@"Incomplete Transaction"
				   message:@"Please make sure all fields have values entered"];
}
+(void) invalidQuantity
{
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incorrect Quantity Value"
													message:@"Please make sure the quantity field contains only numbers"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	
	[alert showSafely];
}

+(void) invalidRetail
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incorrect Retail Value"
													message:@"Please make sure the retail amount is valid"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) invalidTax
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incorrect Value"
													message:@"Please make sure the tax field contains only numbers and up to one decimal point, or is left blank (for 0%)"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) studentNotFound:(NSString *)studentID
{	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ID not Found"
													message:[NSString stringWithFormat:@"cannot find id:%@",studentID]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}
+(void) studentNotFetch:(NSString *)studentID
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to fetch student"
													message:[NSString stringWithFormat:@"No connection established to student id: %@",studentID]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}
+(void) studentNotFetchToOfflineMode:(NSString *)studentID
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to fetch student and go Offline Mode"
													message:[NSString stringWithFormat:@"No connection established to student id: %@. The app will not check for student updates until switched back to online mode.",studentID]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];
}
+(void) itemNotFound:(NSString *)itemID
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Item not Found"
													message:[NSString stringWithFormat:@"cannot find item w/ PLU:%@",itemID]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) studentCantAfford:(NSString *)studentID funds:(NSNumber*)funds
{
    NSString* message = [NSString stringWithFormat:@"%@ has available funds: %@", studentID, funds];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Funds not Available"
                                                    message:[NSString stringWithFormat:message]
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
//	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Funds not Available"
//													message:[NSString stringWithFormat:@"Insufficient Funds"]
//												   delegate:self
//										  cancelButtonTitle:@"OK"
//										  otherButtonTitles:nil];
	
	[alert showSafely];
}

+(void) studentCantPurchaseFromLocation:(int)location
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Account Restricted"
													message:[NSString stringWithFormat:@"account cannot purchase items in sales area %i",location]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) emptyFieldError
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Incomplete Transaction"
													message:@"Please make sure all fields have values entered"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) cardPresentAlert
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Process Manually"
													message:@"You must scan a card to sell this item."
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

#pragma mark - Credit Card

+(void)chargeDeclined
{
	[self simpleAlertTitle:@"Card Error" message:@"Charge Declined"];
}
+(void)failToPostToWebservice
{
	[self simpleAlertTitle:@"Transaction Error" message:@"Transaction is charged but fail to deliver to webservice. Moved to Pending"];
}
+(void)failToPostToEmailService
{
	[ErrorAlert simpleAlertTitle:@"Transaction Error" message:@"Transaction is charged but fail to deliver to email service."];
}

#pragma mark - data/connection

+(void) switchedToOfflineMode
{
	
	NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
	[moc setPersistentStoreCoordinator:[CoreDataService getMainStoreCoordinator]];
	
	//get the count for student
	NSArray *allStudents = [CoreDataService getObjectsForEntity:@"OdinStudent"
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
	NSString *alertMessage = [NSString stringWithFormat:@"The app will not check for student updates until switched back to online mode.\n Student count: %lu \n Last Student Update: %@",(unsigned long)[allStudents count], textDate];
	
#ifdef DEBUG
	NSLog(@"updateAllStudents after retest: date %@", textDate);
#endif
	//NSString *lastStudUp = [[lastUpdate lastStudentUpdate] asStringWithFormat:@"@MM/@DD/@YY at @hh:@mm:@ss"];
	//NSString *alertMessage = [NSString stringWithFormat:@"The app will not check for student updates until switched back to online mode.\n Student updates last took place:\n%@",lastStudUp];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Switched To Offline Mode" message:alertMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert showSafely];
	
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];
}
/*+(void)failedSwitchToOnlineMode
{
	
}*/

+(void)cannotSwitchToOnline
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Switch To Online Mode"
													message:@"Please connect to a network and try again."
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}


+(void)cannotUpdateInOffline
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Sync in Offline Mode"
													message:@"Please switch back to Online Mode before ReSync or Update"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) saveFailure
{
	/*
	 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save Error"
	 message:@"Error saving data to disk. Please re-enter data"
	 delegate:self
	 cancelButtonTitle:@"OK"
	 otherButtonTitles:nil, nil];
	 [alert showSafely];
	 */
#ifdef DEBUG
	NSAssert(1==1,@"error saving to disk");
#endif
	NSLog(@"Error saving to disk");
}

+(void) noUploads
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nothing to Upload"
													message:@"All transactions have been posted"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}


+(void) synchedAlert
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Entry cannot be deleted"
													message:@"This entry has already been sent to the network and can no longer be deleted here."
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) noEmail
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Email Account"
													message:@"No email account has been set up on this device, please enable an email account to send your transaction record to Odin."
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) noServer:(NSURL *)path
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Connect"
													message:[NSString stringWithFormat:@"Please check your connection to:\n %@ \n and try again",path]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) noUIDmatch
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Authenticate"
													message:@"Please check that your UID is correctly entered into settings"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}
+(void) noSchoolServer
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Access To Server"
													message:@"Please check wifi access and server settings to connect to your local server"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}
+(void) noStudentConnection:(NSString*)id_number
{
	NSString* msg = @"Please check wifi access and server settings to connect to your local server";
	if (id_number)
		msg = [NSString stringWithFormat:@"Cannot fetch ID: %@ \nPlease check wifi access and server settings to connect to your local server",id_number ];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Access To Student"
													message:msg
												   delegate:self
										  cancelButtonTitle:@"QUIT"
										  otherButtonTitles:@"RETRY",nil];
	if ([NetworkConnection isInternetOffline]) {
		[self noInternetConnection];
	}
	else
		[alert showSafely];
	
}

+(void) noStudentConnection:(NSString*)id_number error:(NSString*)error
{
	NSString* msg = [NSString stringWithFormat:@"%@",error];
	if (id_number)
		msg = [NSString stringWithFormat:@"Cannot fetch ID: %@ \nPlease check wifi access and server settings to connect to your local server",id_number ];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Access To Student"
													message:msg
												   delegate:self
										  cancelButtonTitle:@"QUIT"
										  otherButtonTitles:@"RETRY",nil];
	if ([NetworkConnection isInternetOffline]) {
		[self noInternetConnection];
	}
	else
		[alert showSafely];
	
}
+(void) noItemConnection
{
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Access To Item"
													message:@"Please check wifi access and server settings to connect to your local server"
												   delegate:self
										  cancelButtonTitle:@"QUIT"
										  otherButtonTitles:@"RETRY",nil];
	[alert showSafely];
}
+(void) noSeverConnection
{
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Access To Server"
													message:@"Please check wifi access and server settings to connect to your local server"
												   delegate:self
										  cancelButtonTitle:@"QUIT"
										  otherButtonTitles:@"RETRY",nil];
	[alert showSafely];
}
+(void) noItem
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Matching Items"
													message:@"No such item on network"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void)noItemSelected
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Item Selected"
													message:@"Please select an item"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void)noStudentEntre
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Student Entered"
                                                    message:@"Please enter an student"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert showSafely];
}
+(void)noCost
{
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Cost"
													message:@"Selected item cost $0.00. Doesn't need to pay"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}
+(void) noScanner
{
#ifdef DEBUG
	NSLog(@"noScanner");
#endif
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Scanner Detected"
													message:@"Please click the scan button to awake scanner."
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	
	[alert showSafely];
	
}
+(void) noScannerToOfflineMode
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Scanner Detected and to Offline Mode"
													message:@"Please click scan button till you see laser light to awake scanner. The app will go into OFFLINE MODE and will not check for student updates until switched back to online mode."
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	
	[alert showSafely];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];
	
	
}

+(void) noInternetConnection
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Internet Connection"
													message:@"Please connect to the internet. Device will stay in Offline Mode."
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
	//[AuthenticationStation sharedHandler].isOnline = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"switch offline button off" object:nil];
}

+(void) duplicateItem
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Duplicate PLU"
													message:@"The new PLU matches the PLU for another item. Make sure the PLU is unique."
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) attendanceDenied
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Denied"
													message:@"No uses available for this item for this ID. Please note that only sales uploaded to Odin are available for attendance."
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) cannotEditItem
{
	[ErrorAlert cannotEditItem:@""];
}

+(void) cannotEditItem:(NSString *)specifier
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Edit"
													message:[NSString stringWithFormat:@"Editing %@ is not allowed for this item", specifier]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) appIsNotSynchronized
{
	//NSString *message = @"Please check your internet connection and enter your provided UID in the application settings. \n\nTo obtain a UID, please email support@odin-inc.com";
	NSString *message = [NSString stringWithFormat:@"Serial:%@ \n\n UID:%@",[SettingsHandler sharedHandler].serialNumber,[[SettingsHandler sharedHandler] uid]];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Device is Not Synchronized"
													message:message
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}


+(void) appCannotUseSchoolServer
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Data Connection"
													message:@"App cannot connect to student data server. To check balances and upload transactions directly, please make sure you can connect to the correct server"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}


+(void) errorUploadingData
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Uploading Data"
													message:@"An error has occurred. Please re-try the upload. If you continue to see this error, contact support@odin-inc.com"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

+(void) cannnotCheckBalance
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cannot Check Balance" 
													message:@"Balances cannot be viewed on this device" 
												   delegate:self 
										  cancelButtonTitle:@"OK" 
										  otherButtonTitles:nil];
	[alert showSafely];
}

#pragma mark - General
+(void) dismissAllAlert
{
#ifdef DEBUG
    NSLog(@"dismissAllAlert");
#endif
    for (UIWindow * w in [UIApplication sharedApplication].windows) {
#ifdef DEBUG
        NSLog(@"checking window");
#endif
        for (NSObject * o in w.subviews){
#ifdef DEBUG
            NSLog(@"found view");
#endif
            if([o isKindOfClass:[UIAlertView class]]) {
                UIAlertView* a = (UIAlertView*)o;
#ifdef DEBUG
                NSLog(@"dismiss Alert: %@",a.title);
#endif
                dispatch_async(dispatch_get_main_queue(), ^{
                    [a dismissWithClickedButtonIndex:[(UIAlertView*)a cancelButtonIndex] animated:YES];
                });
            }
        }
    }
}

+(void) simpleAlertTitle:(NSString*)title message:(NSString*)msg
{
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
													message:msg
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}

#pragma mark - Testing
+(void) testAlert
{
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Test Alert"
													message:@"This alert is for testing purpose for developer"
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];
}
+(void) testAlert:(NSString*) serial_number
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Test Alert"
													message:[NSString stringWithFormat:@"This alert is for testing purpose for developer. The serial number is %@",serial_number]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert showSafely];}
@end
