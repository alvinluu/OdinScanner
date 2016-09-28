//
//  ManagementViewController.m
//  OdinScanner
//
//  Created by Ben McCloskey on 2/9/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "ManagementViewController.h"
#import "OdinViewController.h" //Alvin
//#import "FirstViewController.h"
#import "OdinEvent.h"
#import "OdinTransaction.h"
//#import "Temptran.h"
#import "TestIf.h"
#import "SynchronizationOperation.h"
#import "StudentUpdate.h"
#import "Linea.h"
#import "NSObject+SBJson.h"

@interface ManagementViewController ()

@property (nonatomic, strong) NSArray *unSyncedArray;
@property (nonatomic, strong) NSArray *syncedArray;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) UISwitch *offlineModeSwitch;
@property (nonatomic, strong) UISwitch *holdTransactionsSwitch;

//These two IBActions are actually called through didSelectRowAtPath
-(IBAction)reSync;
-(void)finishReSync;

-(IBAction)uploadTransactions;

-(void)showUploadActivity;
-(void)showUploadHUD:(NSNumber *)numberOfItems;

-(void) sendBatchToPrefServer;
-(void) reloadUnSyncedArray;

@end

@implementation ManagementViewController

@synthesize unSyncedArray, syncedArray;
@synthesize managedObjectContext;
@synthesize offlineModeSwitch,holdTransactionsSwitch;

#pragma mark - HUD Methods

-(void) showUploadActivity
{
	MBProgressHUD *HUD = [HUDsingleton theHUD].HUD;
	
	[[UIApplication sharedApplication].keyWindow addSubview:HUD];
	
	HUD.delegate = self;
	HUD.labelText = @"Connecting...";
	HUD.detailsLabelText = [NSString stringWithFormat:@""];
	[HUD show:YES];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
}

-(void)showUploadHUD:(NSNumber *)numberOfItems
{
	MBProgressHUD *HUD = [HUDsingleton theHUD].HUD;
	HUD.delegate = self;
	HUD.labelText = @"Uploading Transactions...";
	HUD.detailsLabelText = [NSString stringWithFormat:@"(%@ left)",numberOfItems];
	[HUD show:YES];
}
-(void)showVerifyHUD:(NSNumber *)numberOfItems
{
	MBProgressHUD *HUD = [HUDsingleton theHUD].HUD;
	HUD.delegate = self;
	HUD.labelText = @"Verifying Transactions...";
	HUD.detailsLabelText = [NSString stringWithFormat:@"(%@ left)",numberOfItems];
	[HUD show:YES];
}
-(void)showVerifyStatus:(NSString *)message
{
	MBProgressHUD *HUD = [HUDsingleton theHUD].HUD;
	HUD.delegate = self;
	HUD.labelText = @"Verifying Transactions...";
	HUD.detailsLabelText = message;
	[HUD show:YES];
}
#pragma mark - Button methods

//downloads items from server and saves them as OdinEvents (replaces existing OdinEvents)
-(IBAction)reSync
{
	
	
	if ([[AuthenticationStation sharedAuth] isOnline] == FALSE || offlineModeSwitch == FALSE)
	{
		[ErrorAlert cannotUpdateInOffline];
		return;
	}
	
	//reset PHP server path to basePath
	[[AuthenticationStation sharedAuth] reset];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	//disable all alert while re-sync
	[[SettingsHandler sharedHandler] setIsAlertDisplay:YES];
	[self showCacheActivity];

	[[HUDsingleton theHUD].HUD showWhileExecuting:@selector(finishReSync) onTarget:self withObject:nil animated:YES];
}

-(void)finishReSync
{
	[[AuthenticationStation sharedAuth] doAuth];
	
	//TODO: set reference number temoprary
	//Check device has any pending and uploaded transaction and empty item in memory
	
	NSManagedObjectContext *moc = [CoreDataHelper getMainMOC];
	NSArray *syncArray = [CoreDataHelper searchObjectsForEntity:@"OdinTransaction"
													withPredicate:nil
													   andSortKey:nil
												 andSortAscending:NO
													   andContext:moc];
	if ([syncArray count] < 1) {
#ifdef DEBUG
		NSLog(@"get reference");
#endif
		[[SettingsHandler sharedHandler] setReference:[WebService fetchReferenceNumber]];
	}
	
	[self hideActivity];
	[[SettingsHandler sharedHandler] setIsAlertDisplay:NO];
	[[[UIAlertView alloc] initWithTitle:@"Re-Sync Status!"
								message:[NSString stringWithFormat:@"Re-Sync Item: %@ \n Re-Sync Student: %@",
										 ([[SettingsHandler sharedHandler] isItemSuccessReSync]) ? [NSString stringWithFormat: @"SUCCESS"]: [NSString stringWithFormat:@"FAILED"],
										 ([[SettingsHandler sharedHandler] isStudentSuccessReSync]) ? [NSString stringWithFormat: @"SUCCESS"]: [NSString stringWithFormat:@"FAILED"]]
							   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil, nil] showSafely];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

//uploads all saved transactions without a sync == TRUE
-(IBAction)uploadTransactions
{
#ifdef DEBUG
	NSLog(@"uploadTransactions start");
#endif
	[self showCacheActivity];
	MBProgressHUD *HUD = [HUDsingleton theHUD].HUD;
	if ([unSyncedArray count] == 0)
	{
		[ErrorAlert noUploads];
		[HUD hide:YES];
		
		return;
	}
	else if ([[AuthenticationStation sharedAuth] isOnline] == FALSE)
	{
		[ErrorAlert cannotUpdateInOffline];
		[HUD hide:YES];
		return;
	}
	
	//Test connection and start uploading transaction
	[[HUDsingleton theHUD].HUD showWhileExecuting:@selector(startUploadTransaction) onTarget:self withObject:nil animated:YES];
}

-(void) startUploadTransaction
{
	if ([TestIf appIsSynchronized])
	{
#ifdef DEBUG
		NSLog(@"uploading transaction");
#endif
		
		if ([TestIf appCanUseSchoolServer])
		{
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
			
			//Show connection status on HUD title
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:@"Authenticating" forKey:@"errorMsg"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"update Connection Title" object:self userInfo:userInfo];
			[userInfo setObject:@"Success" forKey:@"errorMsg"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"update Connection Status" object:self userInfo:userInfo];
			sleep(2);
			[self sendBatchToPrefServer];
		} else
		{
			
			//Show connection status on HUD title
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:@"Authenticating" forKey:@"errorMsg"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"update Connection Title" object:self userInfo:userInfo];
			[userInfo setObject:@"Failed" forKey:@"errorMsg"];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"update Connection Status" object:self userInfo:userInfo];
			sleep(2);
		}
		
		
	} else
	{
		
		//Show connection status on HUD title
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:@"Uploading Transaction" forKey:@"errorMsg"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"update Connection Title" object:self userInfo:userInfo];
		[userInfo setObject:@"Failed" forKey:@"errorMsg"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"update Connection Status" object:self userInfo:userInfo];
		sleep(2);
	}
}
#pragma mark - Offline Transaction Methods
/******
	verifyUploadedTransaction is similar to sendBatchToPrefServer
	main difference are:
		compare uploaded transaction to live data and insert missing transaction to live data (last 60 days transaction)
		use webservice URI transactionUploaded (this will log in a different log file)
		use syncedArray which is inside uploaded transaction
		there is no failed alert when items are failed to verify
		NOTICE: This function is created because unknown reason of missing transaction not registered to live data and sync=1
 *****/
-(void) verifyUploadedTransaction
{
	
	//disable idleTimer so the app will not turn off during long uploads
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
	[self reloadSyncedArray];
	
	BOOL hadError = NO;
	int postedTransactions = 0;
	int transactionsToPost = [syncedArray count];
	

#ifdef DEBUG
	//NSLog(@"Posting %i uploaded transactions",transactionsToPost);
#endif
	for (OdinTransaction *transactionToUpload in syncedArray)
	{
		[self performSelectorOnMainThread:@selector(showVerifyHUD:)
							   withObject:[NSNumber numberWithInt:(transactionsToPost - postedTransactions)]
							waitUntilDone:YES];
		//send to webservice
		if ([WebService postUploadedTransaction:[transactionToUpload preppedForWeb]])
		{
			//if it posts successfully, change the sync value for the transaction, and set the student to be first to be updated
			[transactionToUpload setSync:[NSNumber numberWithBool:TRUE]];
			OdinStudent *studentToUpdate = [OdinStudent getStudentObjectForID:transactionToUpload.id_number andMOC:managedObjectContext];
			
			studentToUpdate.last_update = [NSDate distantPast];
			
			postedTransactions++;
			
		}
		else
		{
			postedTransactions++;
		}
	}
	if (hadError == NO)
	{
		[self performSelectorOnMainThread:@selector(showVerifyStatus:)
							withObject:@"Verify done"
						 waitUntilDone:YES];
	}
	else
	{
		[self performSelectorOnMainThread:@selector(showVerifyStatus:)
							   withObject:@"Verify failed"
							waitUntilDone:YES];
	}
	
	//clean up
	[CoreDataHelper saveObjectsInContext:managedObjectContext];
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	//[self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:YES];

}
//the actual upload method, will always run in background thread
-(void) sendBatchToPrefServer
{
	//disable idleTimer so the app will not turn off during long uploads
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
	BOOL hadError = NO;	
	int postedTransactions = 0;
	int transactionsToPost = [unSyncedArray count];

#ifdef DEBUG 
	//NSLog(@"Posting %i transactions",transactionsToPost);
#endif	
	for (OdinTransaction *transactionToUpload in unSyncedArray)
	{  	
		[self performSelectorOnMainThread:@selector(showUploadHUD:) 
							   withObject:[NSNumber numberWithInt:(transactionsToPost - postedTransactions)] 
							waitUntilDone:YES];
		//send to webservice
		if ([WebService postTransaction:[transactionToUpload preppedForWeb]])
		{
			//if it posts successfully, change the sync value for the transaction, and set the student to be first to be updated
			[transactionToUpload setSync:[NSNumber numberWithBool:TRUE]];
			OdinStudent *studentToUpdate = [OdinStudent getStudentObjectForID:transactionToUpload.id_number andMOC:managedObjectContext];
			
			studentToUpdate.last_update = [NSDate distantPast];
			
			postedTransactions++;
			
			[CoreDataHelper saveObjectsInContext:managedObjectContext];
			//save transaction to log
			//[StreamInOut writeLogFileWithTransaction:[transactionToUpload preppedForWeb] Note:@"Batch Uploaded Success"];
		}
		//if an error during upload,  make sure we show how many failed to update, but post others that should work
		else
		{
			//save transaction to log
			//[StreamInOut writeLogFileWithTransaction:[transactionToUpload preppedForWeb] Note:@"Batch Uploaded Failed"];
			hadError = YES;
		}
	}	
	if (hadError == NO)
	{
		[[[UIAlertView alloc] initWithTitle:@"Upload Successful!" 
									message:[NSString stringWithFormat:@"%i transaction(s) posted",postedTransactions] 
								   delegate:nil 
						  cancelButtonTitle:@"OK" 
						  otherButtonTitles:nil, nil] showSafely];
		
		//remove all transaction pending
		if ([StreamInOut resetPendingFile] == NO) {
			
			[[[UIAlertView alloc] initWithTitle:@"Transaction Log Error"
										message:[NSString stringWithFormat:@"OOPS!! Failed to save transaction_pending.txt"]
									   delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil, nil] showSafely];
		}
	}
	else
	{
		[[[UIAlertView alloc] initWithTitle:@"Upload Error" 
									message:[NSString stringWithFormat:@"%i transactions posted successfully, \n%i did not post\nPlease verify your connection and re-try the upload",postedTransactions, (transactionsToPost - postedTransactions)]
								   delegate:nil 
						  cancelButtonTitle:@"OK" 
						  otherButtonTitles:nil, nil] showSafely]; 
	}
	
	//clean up
	[self reloadUnSyncedArray];
	[CoreDataHelper saveObjectsInContext:managedObjectContext];
	[self verifyUploadedTransaction];
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	[self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:YES];
}



//loads the array of all transactions that haven't been synced
-(void) reloadUnSyncedArray
{
	unSyncedArray = [CoreDataHelper searchObjectsForEntity:@"OdinTransaction" 
											 withPredicate:[NSPredicate predicateWithFormat:@"sync == FALSE"]
												andSortKey:nil 
										  andSortAscending:NO 
												andContext:self.managedObjectContext];
}

//loads the array of all transactions that have been synced
-(void) reloadSyncedArray
{
	NSCalendar *cal = [NSCalendar currentCalendar];
	NSDateComponents *components = [cal components:( NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:[[NSDate alloc] init]];
	
	[components setHour:-[components hour]];
	[components setMinute:-[components minute]];
	[components setSecond:-[components second]];
	NSDate *today = [cal dateByAddingComponents:components toDate:[[NSDate alloc] init] options:0]; //This variable should now be pointing at a date object that is the start of today (midnight);
	
	//change to 20days after 2.6.0 previously 60days
	[components setDay:-20];
	NSDate *sixtyDaysAgo = [cal dateByAddingComponents:components toDate: today options:0];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sync == TRUE && qdate > %@", sixtyDaysAgo];
	syncedArray = [CoreDataHelper searchObjectsForEntity:@"OdinTransaction"
											 withPredicate:predicate
												andSortKey:nil
										  andSortAscending:NO
												andContext:self.managedObjectContext];
	
}

#pragma mark - View lifecycle


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	managedObjectContext = [CoreDataHelper getMainMOC];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(refreshHoldTransactionSwitch)
												 name:@"holdTransactionsChanged"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(switchHoldTransactionsOn)
												 name:@"holdTransactionSwitchOn"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(switchHoldTransactionsOn)
												 name:@"switched to offline mode"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(switchOnlineModeButtonOff)
												 name:@"switch offline button off"
											   object:nil];
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
    [offlineModeSwitch setOn:[AuthenticationStation sharedAuth].isOnline];
	[self refreshHoldTransactionSwitch];
	[self reloadUnSyncedArray];
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{	
    // Return the number of rows in the section.
    return [super tableView:tableView numberOfRowsInSection:section];
}

#pragma mark - Table view delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ((indexPath.section == 2) && (indexPath.row == 0))
	{
		
		UITableViewCell *cellWithSwitch = [super tableView:tableView cellForRowAtIndexPath:indexPath];
		offlineModeSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		[offlineModeSwitch addTarget:self action:@selector(flipOnlineSwitch) forControlEvents:UIControlEventValueChanged];
		cellWithSwitch.accessoryView = offlineModeSwitch;
		return cellWithSwitch;
	}
	else if ((indexPath.section == 2) && (indexPath.row == 1))
	{
		UITableViewCell *cellWithSwitch = [super tableView:tableView cellForRowAtIndexPath:indexPath];
		holdTransactionsSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		[holdTransactionsSwitch addTarget:self action:@selector(flipHoldTransactionsSwitch) forControlEvents:UIControlEventValueChanged];
		cellWithSwitch.accessoryView = holdTransactionsSwitch;
		return cellWithSwitch;
	}
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (void) switchOnlineModeButtonOff
{
#ifdef DEBUG
	NSLog(@"switchOnlineModeButtonOff %d", offlineModeSwitch.on);
#endif
	[offlineModeSwitch setOn:NO animated:YES];
}


-(void)switchHoldTransactionsOn
{
	[holdTransactionsSwitch setOn:YES animated:YES];
}


-(void)flipOnlineSwitch
{
#ifdef DEBUG
	NSLog(@"flipOnlineSwitch");
#endif
	
	[self showUploadActivity];
	if ([AuthenticationStation sharedAuth].isOnline) {
		[HUDsingleton theHUD].HUD.labelText = @"Disconnecting...";
	} else {
		[HUDsingleton theHUD].HUD.labelText = @"Connecting...";
		//[[AuthenticationStation sharedAuth] reset];
#ifdef DEBUG
		NSLog(@"test");
#endif
	}
	
	[[HUDsingleton theHUD].HUD showWhileExecuting:@selector(doOnlineConnection) onTarget:self withObject:nil animated:YES];
	
}
-(void)doOnlineConnection
{
	BOOL statue = [AuthenticationStation sharedAuth].isOnline;
	[[AuthenticationStation sharedAuth] setIsOnline:!statue];
}

-(void)flipHoldTransactionsSwitch
{
	[[SettingsHandler sharedHandler] setHoldTransactions:holdTransactionsSwitch.on];
}

-(void)refreshHoldTransactionSwitch
{
	[holdTransactionsSwitch setOn:[[SettingsHandler sharedHandler] holdTransactions]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	//Hacky way of turning table rows into buttons (necessary to keep correct highlighting)
	
	if (indexPath.section == 1)
	{				
		if (indexPath.row == 0)
			[self uploadTransactions];
		
		else if (indexPath.row == 1)
			[self reSync];
	}
	else if (indexPath.section == 2)
	{
		//[self flipSwitch];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}
-(void)refreshLinea
{
	
	[[DTDevices sharedDevice] addDelegate:self];
	[[DTDevices sharedDevice] connect];
	[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
#ifdef DEBUG
	NSLog(@"Refreshing Linea connection to FVC");
#endif
	
	//turn off idle timer so the iPod does not go to sleep while they're scanning cards
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[DTDevices sharedDevice] addDelegate:self];
	
}
@end