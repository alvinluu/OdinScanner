//
//  FirstViewController.m
//  Scanner
//
//  Created by Ben McCloskey on 12/2/11.
//  Copyright (c) 2011 Odin Inc. All rights reserved.
//
/*
 This is the main view controller used to scan cards, and process transactions
 */
#import "FirstViewController.h"
#import "OdinEvent.h"
#import "OdinTransaction.h"
#import "OdinStudent.h"
#import "DTDevices.h"
//#import "MBProgressHUD.h"
#import "SynchronizationOperation.h"
#import "StudentUpdate.h"

@interface FirstViewController ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) IBOutlet UITextField *studentIdTextBox;
@property (nonatomic, strong) IBOutlet UITextField *qtyTextBox;
@property (nonatomic, strong) IBOutlet UITextField *amtTextBox;
@property (nonatomic, strong) IBOutlet UIButton *processButton;

@property (nonatomic, strong) UITextField *activeField;

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIPickerView *itemPicker;
@property (nonatomic, strong) NSArray *itemArrayForPicker;

@property (nonatomic, strong) OdinEvent *selectedItem;
@property (nonatomic, strong) NSString *selectedIdNumber;

//BOOL flag that makes sure certain methods run only the first time this view is shown
@property (nonatomic) BOOL didAskForStudents;

@property (nonatomic, strong) CardProcessor *ccProcess;

-(BOOL) inputChecksOut;

-(IBAction) enterTransaction;
-(void) beginTransaction;
-(void) showTransactionResult;

-(IBAction) backgroundTap;

-(void) clearPicker;
-(void) loadItemsForPicker;
-(void) refreshLinea;

-(void) doInitialAuth;

-(void) showSuccess:(NSNumber *)wasASuccess;

@end

@implementation FirstViewController

@synthesize studentIdTextBox,amtTextBox,qtyTextBox;
@synthesize managedObjectContext;
@synthesize scrollView,activeField;
@synthesize selectedItem, selectedIdNumber;
@synthesize itemPicker, itemArrayForPicker;
@synthesize didAskForStudents;
@synthesize processButton;
@synthesize ccProcess;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - HUD methods
//these are the various methods to show different HUD images to denote activity
//each must be called before the method that will do the work it's displaying

-(void) showProcessActivity
{
	MBProgressHUD *HUD = [HUDsingleton theHUD].HUD;
	
	[[UIApplication sharedApplication].keyWindow addSubview:HUD];
	
	HUD.delegate = self;
	HUD.labelText = @"Connecting...";
	HUD.detailsLabelText = nil;
	
	[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_DISABLED error:nil];
	[activeField resignFirstResponder];
}

-(void) showProcessing
{
	MBProgressHUD *HUD = [HUDsingleton theHUD].HUD;
	HUD.delegate = self;
	HUD.labelText = @"Processing...";
	[HUD show:YES];
}

-(void) showSuccess:(NSNumber *)wasASuccess
{
	MBProgressHUD *HUD = [HUDsingleton theHUD].HUD;
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
}

-(void) hideActivity
{
	[studentIdTextBox setText:@""];
	[super hideActivity];
}

#pragma mark - transaction methods

//Checks input for errors
-(BOOL)inputChecksOut
{
	//checks if fields are empty
	if(([[qtyTextBox text] isEqualToString:@""])
	   || ([[amtTextBox text] isEqualToString:@""])
	   || ([[studentIdTextBox text] isEqualToString:@""]))
    {
		[ErrorAlert emptyFieldError];
		return NO;
    }
	
	if([[qtyTextBox text] containsNonDecimalNumbers])
    {
        [ErrorAlert qtyInvalid];
		return NO;
    }
	if ([amtTextBox.text containsNonNumbers])
    {
		[ErrorAlert retailInvalid];
		return NO;
    }
	
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	//checks if quantity has been edited, show error if that's not allowed
	NSNumber *defaultQty = selectedItem.qty;
	NSNumber *currentQty = [numberFormatter numberFromString:qtyTextBox.text];
    NSDecimalNumber *defaultAmount = selectedItem.amount;
	NSNumber *amountTextAsNumber = [numberFormatter numberFromString:amtTextBox.text];
	
	if (([selectedItem.allow_qty boolValue] == FALSE)
		&& ([defaultQty isEqualToNumber:currentQty] == FALSE))
	{
		[ErrorAlert cannotEditItem:@"quantity"];
		return NO;
	}
	//checks if amount has been changed from the default, shows error if not allowed
	if (([selectedItem.allow_amount boolValue] == FALSE)
		&& ([amountTextAsNumber floatValue] != [defaultAmount floatValue]))
	{
		[ErrorAlert cannotEditItem:@"retail amount"];
		return NO;
	}
	return YES;
}

//Button call from "Process Sale" button
- (IBAction) enterTransaction
{
	if ([selectedItem.allow_manual_id boolValue] == TRUE) {
        selectedIdNumber = studentIdTextBox.text;
		[self beginTransaction];
    }
	else {
		[ErrorAlert cardPresentAlert];
    }
}

//beginning of fragmented transaction methods
//broken up for purposes of activity indicator
- (void) beginTransaction
{
#ifdef DEBUG
	NSLog(@"Transaction Started");
#endif
	[self showProcessActivity];
	[[HUDsingleton theHUD].HUD showWhileExecuting: @selector(showTransactionResult) onTarget:self withObject:nil animated:YES];
}

//the actual method for processing a sale
- (void) showTransactionResult
{
	BOOL transactionWasSuccessful = [self isTransactionSuccessful];
	[self performSelectorOnMainThread:@selector(showSuccess:) withObject:[NSNumber numberWithBool:transactionWasSuccessful] waitUntilDone:YES];
#ifdef DEBUG
	NSLog(@"Transaction Completed");
#endif
	if (transactionWasSuccessful == TRUE)
	{
		//increment reference number
		[[SettingsHandler sharedHandler] incrementReference];
		// sleep delays HUD long enough (outside loop, in order to update UI) to display success
		sleep(2);
	}
	else
	{
		[[DTDevices sharedDevice] badBeep];
		// also has benefit of delaying Linea button for a second when showing error alert
		sleep(2);
	}
	[self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:YES];
}

-(BOOL) isTransactionSuccessful
{
    //moved [self inputChecksOut] here because app would crash if fields were left blank
	BOOL isSuccess = FALSE;
    if ([self inputChecksOut]) {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        
        //Gather information to be entered
        NSString *plu = selectedItem.plu;
        NSString *idNumber = selectedIdNumber;
        
        //get reference number by taking refNumber and first letter of register code
        NSString *reference = [[SettingsHandler sharedHandler] getReference];
        
        //calculate total amount, including tax
        NSNumber *qty = [numberFormatter numberFromString:[qtyTextBox text]];
        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[amtTextBox text]];
		
        //TODO: should this be used?
        //NSDecimalNumber *tax = selectedItem.tax;
        
        NSDecimalNumber *totalAmount = [OdinTransaction getTotalAmountFromQtyEntered:qty andAmountEntered:amount forItem:selectedItem];
        //check if the transaction is legal, and if the account has sufficient funds
        if([TestIf account:[OdinStudent getStudentInfoForID:idNumber andMOC:managedObjectContext]
           canPurchaseItem:selectedItem
                 forAmount:totalAmount])
        {
            //processTransaciton is always called on a background thread since main thread is animating the activity indicator
            [self performSelectorOnMainThread:@selector(showProcessing) withObject:nil waitUntilDone:NO];
#ifdef DEBUG
            NSLog(@"FV item %@ purchased by account %@",plu,idNumber);
#endif
            OdinTransaction *transaction = [CoreDataHelper insertObjectForEntity:@"OdinTransaction" andContext:managedObjectContext];
            //fill out the transaction
            transaction.qty = qty;
            transaction.amount = totalAmount;
            transaction.id_number = idNumber;
            transaction.plu = selectedItem.plu;
            transaction.timeStamp = [NSDate date];
            transaction.sync = [NSNumber numberWithBool:FALSE];
            //total amount = amount + tax, so tax = totalAmount - amount
            //transaction.tax_amount = [totalAmount decimalNumberBySubtracting:amount];
            transaction.reference = reference;
            transaction.location = selectedItem.location;
            transaction.item = selectedItem.item;
			//version 2.6add glcode and dept_code
			transaction.glcode = selectedItem.glcode;
			transaction.dept_code = selectedItem.dept_code;
            transaction.operator = [[SettingsHandler sharedHandler] uid];
			
			
			NSDictionary *transactionWebItem = [transaction preppedForWeb];
			
            //if in online mode, upload the transaction immediately
            if (([[SettingsHandler sharedHandler] holdTransactions] == FALSE)
                && ([[AuthenticationStation sharedAuth] isOnline] == TRUE))
            {
                if ([TestIf appCanUseSchoolServer])
                {
                    transaction.sync = [NSNumber numberWithBool:TRUE];
                    if ([WebService postTransaction:transactionWebItem])
                    {
						//[StreamInOut writeLogFileWithTransaction:transactionWebItem Note:@"Manual Uploaded"];
                        isSuccess = TRUE;
                    }
                    else {
                        //if there is a problem with sync, transaction will be added to pending transactions
                        transaction.sync = [NSNumber numberWithBool:FALSE];
                    }
                }
            }
            //if in offline mode, call it a success
            else
            {
				//[StreamInOut writeLogFileWithTransaction:transactionWebItem Note:@"Manual Stored Into Pending"];
                isSuccess = TRUE;
            }
            //save all changes to transaction
#ifdef DEBUG
			NSLog(@"save transaction to core data");
#endif
            [CoreDataHelper saveObjectsInContext:managedObjectContext];
        }
        return isSuccess;
    }
    return isSuccess;
}

#pragma mark - Keyboard Methods
// Hides keyboard when background is tapped
-(IBAction)backgroundTap
{
#ifdef DEBUG
	NSLog(@"Background Tapped");
#endif
    [activeField resignFirstResponder];
}

//manages activeField property for several other methods
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    activeField = nil;
}

// Hides the keyboard when return key pressed on any text field
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    [theTextField resignFirstResponder];
    return YES;
}


#pragma mark - Picker methods

-(void)clearPicker
{
	itemArrayForPicker = nil;
	qtyTextBox.text = @"";
	amtTextBox.text = @"";
}

//gets items from Core Data, loads names into Picker
-(void)loadItemsForPicker
{
	itemArrayForPicker = [CoreDataHelper getObjectsForEntity:@"OdinEvent"
												 withSortKey:@"item"
											andSortAscending:YES
												  andContext:managedObjectContext];
	
	if (selectedItem.plu)
	{
		qtyTextBox.text = [NSString stringWithFormat:@"%@",selectedItem.qty];
		amtTextBox.text = [NSString stringWithFormat:@"%@",selectedItem.amount];
	}
	[itemPicker reloadAllComponents];
}

//if there is a single item in the Picker, this selects it
-(void)selectSingleItemInPicker
{
	if ([itemPicker numberOfRowsInComponent:0] == 1)
	{
		[itemPicker selectRow:1 inComponent:0 animated:NO];
		[self pickerView:itemPicker didSelectRow:1 inComponent:0];
	}
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component
{
	//+1 is for line "ITEM LIST:"
	return ([itemArrayForPicker count] + 1);
}


- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	//displays "Downloading Items..." while picker is empty
	if ([itemArrayForPicker count] == 0)
		return @"Downloading Items...";
	
	//if there are items, make the first row say "ITEM LIST:"
	else if (row == 0)
		return @"ITEM LIST:";
	
	//row-1 is to account for "ITEM LIST:" row displayed in Picker
	OdinEvent *itemForPicker = [itemArrayForPicker objectAtIndex:(row-1)];
	return [itemForPicker item];
	
}

//loads default qty and amount for the item selected from the picker
- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	if ([itemArrayForPicker count] != 0)
	{
		//empties amt and qty if "ITEM LIST:" is chosen
		if (row == 0)
		{
			qtyTextBox.text = @"";
			amtTextBox.text = @"";
            processButton.enabled = NO;
            selectedItem = nil;
		}
		else
		{
            processButton.enabled = YES;
			selectedItem = [itemArrayForPicker objectAtIndex:(row - 1)];
			//uses row-1 since first row is reserved for "ITEM LIST" placeholder
			qtyTextBox.text = [NSString stringWithFormat:@"%@",selectedItem.qty];
			amtTextBox.text = [NSString stringWithFormat:@"%@",selectedItem.amount];
			
			if ([selectedItem.allow_amount intValue] != 1)
				amtTextBox.enabled = NO;
			else
				amtTextBox.enabled = YES;
			
			if ([selectedItem.allow_qty intValue] != 1)
				qtyTextBox.enabled = NO;
			else
				qtyTextBox.enabled = YES;
			
		}
	}
}

#pragma mark - Linea Delegate calls

//Connection delegate method sends messages to class when connection state changes
-(void)connectionState:(int)state
{
	DTDevices *dtdev;
	switch (state) {
		case CONN_DISCONNECTED:
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
			 [dtdev setAutoOffWhenIdle:3600 whenDisconnected:3600 error:nil]; //sets USB auto off at 1hr
			 }
#ifdef DEBUG
			NSLog(@"[LINEA] Linea connectionState=CONNECTED TO FIRSTVC");
#endif
			break;
	}
}

//Fires when a barcode is scanned
-(void) barcodeData:(NSString *)barcode type:(int)type
{
	//check exportid and adjust barcode if using exportID
#ifdef DEBUG
    NSLog(@"process barcodeData");
#endif
	[self processScannedData:barcode];
}

//fires when a swipe card is used
//Swipe expired card on test server returns SUCCESS
-(void)magneticCardData:(NSString *)track1 track2:(NSString *)track2 track3:(NSString *)track3
{
	NSLog(@"\n\nTrack 1:%@\n\nTrack 2:%@\n\nTrack 3:%@\n\n",track1,track2,track3);
	
	
	NSString *magneticData = [NSString stringWithFormat:@"%@%@",track1,track2];
	
	//[self processScannedData:track1];
	
	
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	
	//calculate total amount, including tax
	NSNumber *qty = [numberFormatter numberFromString:[qtyTextBox text]];
	NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[amtTextBox text]];
	if ([NetworkConnection isInternetOffline]) {
		[ErrorAlert simpleAlertTitle:@"No Connection" message:@"Please check your Wifi or data service is turn on"];
		return;
	}else if (!selectedItem) {
		//Alert user to select an item
		[ErrorAlert simpleAlertTitle:@"No Item" message:@"Please select an item"];
		return;
	} else if ([amount floatValue] <= 0.0) {
		//Alert user to select item doesn't need to pay
		[ErrorAlert simpleAlertTitle:@"No Cost"
							 message:[NSString stringWithFormat:@"Selected item cost $%.2f. Doesn't need to pay",[amount floatValue]]];
		return;
	}
		
	//get reference number by taking refNumber and first letter of register code
	NSString *reference = [[SettingsHandler sharedHandler] getReference];
	NSString *orderID = [[NSNumber numberWithInt:arc4random()%89999999 + 10000000] stringValue];
	
	ccProcess = [CardProcessor initialize:magneticData];
	[ccProcess setTransactionAmount:[amount stringValue]];
	[ccProcess setTransactionDesc:selectedItem.item];
	[ccProcess setTransactionId:[reference stringByAppendingString:orderID]];
	[ccProcess setInvoiceNumber:[reference stringByAppendingString:orderID]];
#ifdef DEBUG
    NSLog(@"trans ID: %@",[reference stringByAppendingString:orderID]);
#endif
	
	
	if ([ccProcess makePurchase]) {
#ifdef DEBUG
		NSLog(@"enter");
#endif
		//TODO: should this be used?
		//NSDecimalNumber *tax = selectedItem.tax;
		[[HUDsingleton theHUD].HUD showWhileExecuting:@selector(processTransaction) onTarget:self withObject:nil animated:YES];
		
	}
	
	
	
}
-(void)validateCreditCard:(NSString*)data
{
#ifdef DEBUG
	NSLog(@"Validate Card");
#endif
	
	InPayCardValidator *cv = [[InPayCardValidator alloc] init];
	[cv setTrackData:data];
	[cv validateCard];
#ifdef DEBUG
	NSLog(@"Validate Date %i",[cv dateCheckPassed]);
#endif
}
-(void)processScannedData:(NSString *)dataToProcess
{
#ifdef DEBUG
	NSLog(@"process scannedData");
#endif
	//handles matching exportID to ID
	NSString *idNumber = [dataToProcess checkExportID];
	//shows ID number in the text box
	selectedIdNumber = [idNumber cleanBarcode];
	studentIdTextBox.text = selectedIdNumber;
	[self beginTransaction];
}

// refreshes connection to Linea when returning from inactive state
-(void)refreshLinea
{
	[[DTDevices sharedDevice] addDelegate:self];
	[[DTDevices sharedDevice] connect];
	[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
#ifdef DEBUG
	NSLog(@"Refreshing Linea connection to FVC");
#endif
}
-(void)processTransaction
{
	
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	NSNumber *qty = [numberFormatter numberFromString:[qtyTextBox text]];
	NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[amtTextBox text]];
	NSString *reference = [[SettingsHandler sharedHandler] getReference];
	NSDecimalNumber *totalAmount = [OdinTransaction getTotalAmountFromQtyEntered:qty andAmountEntered:amount forItem:selectedItem];
	OdinTransaction *transaction = [CoreDataHelper insertObjectForEntity:@"OdinTransaction" andContext:managedObjectContext];
	//fill out the transaction
	transaction.qty = qty;
	transaction.amount = totalAmount;
	transaction.id_number = [NSString stringWithFormat:@"CC%@",[ccProcess getCardLast4Digits]];//idNumber;
	transaction.plu = selectedItem.plu;
	transaction.timeStamp = [NSDate date];
	transaction.sync = [NSNumber numberWithBool:FALSE];
	//total amount = amount + tax, so tax = totalAmount - amount
	//transaction.tax_amount = [totalAmount decimalNumberBySubtracting:amount];
	transaction.reference = reference;
	transaction.location = selectedItem.location;
	transaction.item = selectedItem.item;
	//version 2.6add glcode and dept_code
	transaction.glcode = selectedItem.glcode;
	transaction.dept_code = selectedItem.dept_code;
	transaction.operator = [[SettingsHandler sharedHandler] uid];
	
	//Credit card
	transaction.cc_digit = [ccProcess getCardLast4Digits];
	transaction.cc_tranid = [ccProcess responseTransactionId];
	transaction.cc_first = [ccProcess getCardFirstName];
	transaction.cc_last = [ccProcess getCardLastName];
	transaction.cc_approval = [ccProcess responseApprovalCode];
	
	//Others
	transaction.qdate = [transaction.timeStamp asStringWithFormat:@"@YYYY-@MM-@DD"];
	transaction.time = [transaction.timeStamp asStringWithFormat:@"@hh:@mm:@ss"];
	transaction.school = [[SettingsHandler sharedHandler] school];
#ifdef DEBUG
	NSLog(@"digit %@", transaction.cc_digit);
	NSLog(@"tranid %@", transaction.cc_tranid);
	NSLog(@"first %@", transaction.cc_first);
	NSLog(@"last %@", transaction.cc_last);
	NSLog(@"approval %@", transaction.cc_approval);
#endif
	
	NSString *xmlString = [transaction JSON];
	xmlString = [NSString stringWithFormat:@"TranData={\"transaction\":%@,%@}",xmlString,[xmlString encryptMessage]];
	
	[CoreDataHelper saveObjectsInContext:managedObjectContext];
	[[SettingsHandler sharedHandler] incrementReference];
	
	if([WebService postCreditCardWithString:xmlString])
	{
		transaction.sync = [NSNumber numberWithBool:TRUE];
	}
	
	[CoreDataHelper saveObjectsInContext:managedObjectContext];
	//[[SettingsHandler sharedHandler] setTransaction:transaction];
	NSMutableArray *trans = [[SettingsHandler sharedHandler] getMultiTransactions];
	[trans addObject:transaction];
	[[SettingsHandler sharedHandler]setMultiTransactions:trans];
	[[SettingsHandler sharedHandler] setSubtotal:amount];
	[[SettingsHandler sharedHandler] setTotal:amount];
	//Load Receipt view
	ReceiptVC *rvc  = [self.storyboard instantiateViewControllerWithIdentifier:@"ReceiptVC"];
	[self presentViewController:rvc animated:YES completion:nil];
}
#pragma mark - Auth Methods

//method to Authorize the app only once on startup
- (void) initialAuth
{
	if ([[AuthenticationStation sharedAuth] isOnline])
	{
		[self showCacheActivity];
		[[HUDsingleton theHUD].HUD showWhileExecuting:@selector(doInitialAuth) onTarget:self withObject:nil animated:YES];
	}
}

- (void) doInitialAuth
{
	[[AuthenticationStation sharedAuth] doAuth];
	[self hideActivity];
}
#pragma mark - Credit Card
- (void) submitOrder
{
	
	
}
/*-(NSString*) encryptMessage: (NSString*) message
 {
 NSString *strToEncrypt  = [NSString stringWithFormat:@"%@",message];
 
 //Add HASH balance
 NSString *key        = @"T8xkoI32o9aEv3e8vAG9zZ20";
 NSString *hexHmac       = [strToEncrypt HMACWithSecret:key];
 
 
 message = [NSString stringWithFormat:@"\"hash\":%@",hexHmac];
 
 return message;
 }*/




#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Do any additional setup after loading the view, typically from a nib.
	
	//adds decimal place to the keyboard for $ amount text field
	amtTextBox.keyboardType = UIKeyboardTypeDecimalPad;
	itemPicker.showsSelectionIndicator = YES;
	processButton.enabled = NO;
	//get managedObjectContext from AppDelegate
	if (managedObjectContext == nil)
	{
		managedObjectContext = [CoreDataHelper getMainMOC];
	}
}

- (void) viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	//[self registerForKeyboardNotifications];
	//Commented since KB currently will not obscure text fields. Kept in case it might in future  (4/4/12)
	NSLog(@"FVC will appear");
	[self refreshLinea];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(refreshLinea)
												 name:@"refreshLinea"
											   object:nil];
	//clears/reloads the picker when ManagedObjectContext saves. Prevents locking the picker/corrupting data
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(clearPicker)
												 name:NSManagedObjectContextWillSaveNotification
											   object:managedObjectContext];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(loadItemsForPicker)
												 name:NSManagedObjectContextDidSaveNotification
											   object:managedObjectContext];

}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	//turn off idle timer so the iPod does not go to sleep while they're scanning cards
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	[[DTDevices sharedDevice] addDelegate:self];
	
	[[AuthenticationStation sharedAuth] setIsOnline:YES];
	
	//initial setup on first boot. Authorize uid/serial and ask to download students
	if ([[AuthenticationStation sharedAuth] didInitialSync] == FALSE)
	{
		if ([TestIf appCanUseSchoolServer])
		{
			[[HUDsingleton theHUD].HUD showWhileExecuting:@selector(initialAuth) onTarget:self withObject:nil animated:YES];
		}
	}
	[self refreshLinea];
	[self loadItemsForPicker];
	
	if ([itemArrayForPicker count] == 1)
		[self selectSingleItemInPicker];
	
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	// Cleanup notifications/delegates
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#ifdef DEBUG
	NSLog(@"Removing FVC from notification center");
#endif
	[[DTDevices sharedDevice] removeDelegate:self];
	//turn idleTimer back on since we turned it off in viewWillAppear
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	//(UIInterfaceOrientationPortraitUpsideDown | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight));
}

//call to allow class to receive KB notifications
//allows the screen to move to adjust if the keyboard will cover a text field
//currently unused as keyboard only covers the itemPicker (4/4/12)
- (void)registerForKeyboardNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasShown:)
												 name:UIKeyboardWillShowNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillBeHidden:)
												 name:UIKeyboardWillHideNotification object:nil];
}

//Checks it kyboard will obscure the active text field, scrolls screen up if it will
//currently unused (4/4/12)
- (void)keyboardWasShown:(NSNotification*)aNotification
{
	//when keyboard is shown, get kb size info, and scroll view to account for it if necessary
	NSDictionary* info = [aNotification userInfo];
	CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
	UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
	[scrollView setContentInset:contentInsets];
	[scrollView setScrollIndicatorInsets:contentInsets];
	// If active text field is hidden by keyboard, scroll it so it's visible
	CGRect aRect = self.scrollView.frame;
	aRect.size.height -= kbSize.height;
	CGPoint fieldOrigin = (activeField.frame.origin);
	if (!CGRectContainsPoint(aRect, fieldOrigin) )
	{
		CGPoint scrollPoint = CGPointMake(0.0, (activeField.frame.origin.y - kbSize.height - 10));
		[scrollView setContentOffset:scrollPoint animated:YES];
	}
}

//Called when the UIKeyboardWillHideNotification is sent, scrolls screen back to normal
//currently unused (4/4/12)

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
	CGPoint scrollPoint = CGPointMake(0.0, 0.0);
	[scrollView setContentOffset:scrollPoint animated:YES];
}


@end
/*
 2.6.0
 Add DataModel version 13
 -cc_digit (Number) //last 4 digits
 -cc_tranid (String) //Transaction ID received from Credit Card Gateway
 _cc_first (String) //Credit Card first name
 _cc_last (String) //Credit Card last name
 CardProcessor
 -add getCardLast4Digit
 -add getCardName
 -add getCardFirstName
 -add getcardLastName
 -add isValidCardExpDate
 
 TODO:
 Receipt Handling
 -send to email
 -AirPrint
 -nothing
 Send successed transaction to uploaded transaction list
 Hash Data
 
 2.5.9
 FirstViewController -> isTransactionSuccessful: fix an issue scanned items may not committed
 Add DataModel version 12
 -Added deptcode (String) in OdinEvent
 Defined deptcode in OdinEvent as NSString
 Changed deptcode in OdinTransaction from NSNumber to NSString
 Set OdinEvent deptcode value during sync
 Added a feature to resume reference number during resync
 -Check Inventory Item and Transaction array are empty
 glcode, operator, and deptcode are register from device rather than from webservice
 -Changed OdinEvent operator is set to device operator instead of webservice friendly
 -glcode from device is write into database instead of webservice retrieving glcode during resync
 Updated DTDevice 1.88 and included new firmwares
 
 Todo Before release
 ManagementViewController -> reloadSyncedArray: change verifiy day to -60
 AuthenticationStation -> reset: get reference number from database when Odin is freshly install
 match school, serial, operator and get lastest qdate, time, reference
 
 */
