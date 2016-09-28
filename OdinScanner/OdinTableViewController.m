//
//  OdinTableViewController.m
//  OdinScanner
//
//  Created by Ben McCloskey on 9/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OdinTableViewController.h"
#import "SynchronizationOperation.h"

@interface OdinTableViewController ()

@property (nonatomic, strong) NSString *uidAlertTitle;

@end

@implementation OdinTableViewController

@synthesize unSyncedArray,syncedArray,moc;
DTDevices* dtdev;

#pragma mark - CoreData

//loads the array of all transactions that haven't been synced
-(NSManagedObjectContext*)moc
{
    return moc? moc : [CoreDataService getMainMOC];
}
#pragma mark - Tab Bar Items
-(void)updateManageBadge
{
    unSyncedArray = [OdinTransaction reloadUnSyncedArray];
#ifdef DEBUG
    NSLog(@"OdinTable updateManageBadge %@",@(unSyncedArray.count));
#endif
    NSString* newLabel = [NSString stringWithFormat:@"%@",@(unSyncedArray.count)];
    newLabel = [newLabel isEqualToString:@"0"] ? nil : newLabel;
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBarItem* tabItem = [self.tabBarController.viewControllers objectAtIndex:2].tabBarItem;
        tabItem.badgeValue = newLabel;
    });
}

#pragma mark - HUD methods
//these are the various methods to show different HUD images to denote activity
//each must be called before the method that will do the work it's displaying

-(void) showProcessActivity
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *HUD = [HUDsingleton sharedHUD];
        [[UIApplication sharedApplication].keyWindow addSubview:HUD];
        //			[self.view addSubview:HUD];
        [HUD show:YES];
        
        HUD.delegate = self;
        HUD.labelText = @"Connecting...";
        HUD.detailsLabelText = @"";
        HUD.mode = MBProgressHUDModeIndeterminate;
        [[DTDevices sharedDevice] disableButton];
        [self hideActivity];
    });
}

-(void) showProcessing
{
	MBProgressHUD *HUD = [HUDsingleton sharedHUD];
	HUD.delegate = self;
	HUD.labelText = @"Processing...";
	HUD.mode = MBProgressHUDModeIndeterminate;
	[HUD show:YES];
    [self hideActivity];
}

-(void) showSuccess:(NSNumber *)wasASuccess
{
	MBProgressHUD *HUD = [HUDsingleton sharedHUD];
	BOOL successful = [wasASuccess boolValue];
	HUD.delegate = self;
	if (successful == TRUE)
	{
		HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
		HUD.labelText = @"Success!";
	}
	if (successful == FALSE)
	{
		HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-X.png"]];
		HUD.labelText = @"Error";
	}
	HUD.mode = MBProgressHUDModeCustomView;
	[HUD show:YES];
    [self hideActivity];
}
-(void) HUDshowMessage:(NSString*) message {
    
    
#ifdef DEBUG
    NSLog(@"showProcessing start %@", message);
#endif
    dispatch_async(dispatch_get_main_queue(), ^{
        
        HUDsingleton *HUD = [HUDsingleton sharedHUD];
        HUD.delegate = self;
        HUD.labelText = message;
        HUD.detailsLabelText = @"";
        HUD.mode = MBProgressHUDModeIndeterminate;
        [HUD show:YES];
    });
#ifdef DEBUG
    NSLog(@"showProcessing end");
#endif
}

-(void) HUDshowDetailNotify:(NSNotification*) notification;
{
    NSDictionary* userInfo = notification.userInfo;
    NSString* message = userInfo[@"count"];
#ifdef DEBUG
NSLog(@"showProcessing start %@", message);
#endif
dispatch_async(dispatch_get_main_queue(), ^{
    
    HUDsingleton *HUD = [HUDsingleton sharedHUD];
    HUD.delegate = self;
    HUD.detailsLabelText = message;
    HUD.mode = MBProgressHUDModeIndeterminate;
    
});
#ifdef DEBUG
NSLog(@"showProcessing end");
#endif

}
-(void) HUDshowDetail:(NSString*) message {
    
    
#ifdef DEBUG
    NSLog(@"showProcessing start %@", message);
#endif
    dispatch_async(dispatch_get_main_queue(), ^{
        
        HUDsingleton *HUD = [HUDsingleton sharedHUD];
        HUD.delegate = self;
        HUD.detailsLabelText = message;
        HUD.mode = MBProgressHUDModeIndeterminate;
    });
#ifdef DEBUG
    NSLog(@"showProcessing end");
#endif
}
-(void) hideActivity
{
    dispatch_async(dispatch_get_main_queue(), ^{
    MBProgressHUD *HUD = [HUDsingleton sharedHUD];
        [HUD hide:YES afterDelay:1.0];
    });
}

#pragma mark - Linea Device

//Connection delegate method sends messages to class when connection state changes
-(void)connectionState:(int)state
{
	dtdev = [DTDevices sharedDevice];
	NSError* error;
	switch (state) {
		case CONN_DISCONNECTED:
			//[dtdev setPassThroughSync:true error:&error];
		case CONN_CONNECTING:
			
#ifdef DEBUG
			NSLog(@"[LINEA] Linea connectionState=CONNECTING/DISCONNECTED");
#endif
			break;
		case CONN_CONNECTED:
			[[DTDevices sharedDevice] barcodeSetScanMode:0 error:nil];
			[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
			[[DTDevices sharedDevice] msSetCardDataMode:MS_PROCESSED_CARD_DATA error:nil];
			//Turn on the beep
			int beepData[] = {1200,100};
			[[DTDevices sharedDevice] barcodeSetScanBeep:TRUE volume:10 beepData:beepData length:sizeof(beepData) error:nil];
			//slow down the automatic disconnection on LP5
			if([dtdev.deviceName rangeOfString:@"LINEAPro5"].location!=NSNotFound) //checks for LP5
			{
			 [[DTDevices sharedDevice] setAutoOffWhenIdle:3600 whenDisconnected:3600 error:nil]; //sets USB auto off at 1hr
			}
			//[dtdev setPassThroughSync:false error:&error];
#ifdef DEBUG
			NSLog(@"[LINEA] Linea connectionState=CONNECTED TO FIRSTVC");
#endif
			break;
	}
}
// refreshes connection to Linea when returning from inactive state
-(void)refreshLinea
{
	dtdev = [DTDevices sharedDevice];
	if ([dtdev isPresent:DEVICE_TYPE_LINEA]) {
		[dtdev addDelegate:self];
		[dtdev connect];
		[dtdev enableButton];
	}
#ifdef DEBUG
	NSLog(@"Refreshing Linea connection to FVC");
#endif
}

-(void)disconnectLinea
{
	dtdev = [DTDevices sharedDevice];
	if ([dtdev isPresent:DEVICE_TYPE_LINEA]) {
		[dtdev removeDelegate:self];
		[dtdev disconnect];
		[dtdev disableButton];
	}
}
-(BOOL)isLineaPresent {
	dtdev = [DTDevices sharedDevice];
	return [dtdev isPresent:DEVICE_TYPE_LINEA];
}

//these are the various methods to show different parentHUD images to denote activity
//each must be called before the method that will do the work it's displaying

//////////////////////////////////////stock UITableView methods \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
	// Do any additional setup after loading the view.
	// self as an oserver in case offline mode switches to "off"
	
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	/*[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(switchedToOfflineMode)
												 name:@"switched to offline mode"
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(failedSwitchToOnlineMode)
												 name:@"failed switch to online mode"
											   object:nil];*/
	
	/*[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showAlertViewToEnterUID)
												 name:@"show uid alert"
											   object:nil];*/
    [super viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated
{
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:NO];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
