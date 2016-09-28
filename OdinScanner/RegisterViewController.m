//
//  RegisterViewController.m
//  OdinScanner
//
//  Created by Ken Thomsen on 2/22/13.
//
//

#import "RegisterViewController.h"
// #import "RegisterItem+Methods.h"
#import "CartItem.h"
#import "OdinTransaction.h"

@interface RegisterViewController ()

@property (nonatomic, strong) NSMutableArray *cart;
@property (nonatomic, strong) NSMutableArray *amounts;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *popover;
@property (nonatomic, strong) IBOutlet UIView *darken;
@property (nonatomic, strong) IBOutlet UILabel *subtotalLabel;
@property (nonatomic, strong) IBOutlet UILabel *taxLabel;
@property (nonatomic, strong) IBOutlet UILabel *totalLabel;
@property (nonatomic, strong) IBOutlet UITextField *IDTextField;
@property (nonatomic, strong) NSString *selectedIdNumber;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) IBOutlet UIButton *processButton;

@property (nonatomic, strong) CardProcessor *ccProcess;

-(IBAction)doneWithCart:(id)sender;
-(IBAction)enterTransaction:(id)sender;
-(IBAction)hidePopover:(id)sender;
-(IBAction)resetCart:(id)sender;

-(void) showSuccess:(NSNumber *)wasASuccess;

@end

@implementation RegisterViewController

@synthesize cart, amounts;
@synthesize tableView;
@synthesize popover, darken;
@synthesize subtotalLabel;
@synthesize taxLabel;
@synthesize totalLabel;
@synthesize IDTextField;
@synthesize selectedIdNumber;
@synthesize managedObjectContext;
@synthesize processButton;
@synthesize ccProcess;


//TODO: allow user to edit price of items if they have permission

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	
    //u need to change 0 to other value(,1,2,3) if u have more buttons.then u can check which button was pressed.
	NSLog(@"Alert Button Pressed");
	
    if (buttonIndex == 0) {
		[[SettingsHandler sharedHandler] setIsAlertDisplay:NO];
    }
}

//Creates array of all items with matching barcode, takes first entry in array (should only be one)
-(OdinEvent *)searchForItemWithBarcode:(NSString*)barcode
{
	NSArray *itemsWithBarcode = [CoreDataHelper searchObjectsForEntity:@"OdinEvent"
														 withPredicate:[NSPredicate predicateWithFormat:@"plu == %@",barcode]
															andSortKey:nil
													  andSortAscending:NO
															andContext:[CoreDataHelper getMainMOC]];
	if ([itemsWithBarcode count] > 0)
	{
		OdinEvent *selectedItem = [itemsWithBarcode objectAtIndex:0];
		return selectedItem;
	}
	else
		return nil;
}

// Fires when "Process Sale" button above cart is pressed
-(IBAction)doneWithCart:(id)sender
{
    //make sure there are items in the cart before showing checkout popover view
    if([self.cart count] > 0) {
		//change background color
		tableView.backgroundColor = self.view.backgroundColor;
		
        popover.hidden = NO;
        darken.hidden = NO;
        //fade background to darker color
        [UIView beginAnimations:@"fade-in" context:NULL];
        [UIView setAnimationDuration:0.4];
        darken.alpha = 0.6;
        [UIView commitAnimations];
        
        //Create array of item costs, used to test if student has enough balance
        self.amounts = [NSMutableArray array];
        float subtotal = 0.0;
        float tax = 0.0;
        float total = 0.0;
		
        for(int k = 0; k < [self.cart count]; k++) {
            CartItem *itemInCart = [self.cart objectAtIndex:k];
            float amount = [[[itemInCart item] amount] floatValue];
            float qty = [itemInCart count];
            float itemTotal = amount * qty;
            subtotal += itemTotal;
            //There's already a method to calculate total with quantity and tax
            NSDecimalNumber *itemTotalWithTax = [OdinTransaction getTotalAmountFromQtyEntered:[NSNumber numberWithInt:[itemInCart count]] andAmountEntered:[[itemInCart item] amount] forItem:[itemInCart item]];
            total += [itemTotalWithTax floatValue];
            [self.amounts addObject:itemTotalWithTax];
        }
        //TODO: find better way of calculating total tax amount so there are no rounding errors
        tax = (total - subtotal);
        subtotalLabel.text = [NSString stringWithFormat:@"$%.2f", subtotal];
        taxLabel.text = [NSString stringWithFormat:@"$%.2f", tax];
        totalLabel.text = [NSString stringWithFormat:@"$%.2f", total];
		[[SettingsHandler sharedHandler] setSubtotal:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.2f",subtotal]]];
		[[SettingsHandler sharedHandler] setTax:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.2f",tax]]];
		[[SettingsHandler sharedHandler] setTotal:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.2f",total]]];
#ifdef DEBUG
		NSLog(@"subtotal %.2f tax %.2f total %.2f",[[[SettingsHandler sharedHandler]subtotal] floatValue],[[[SettingsHandler sharedHandler]tax] floatValue],[[[SettingsHandler sharedHandler]total] floatValue]);
#endif
    }
    else {
        UIAlertView *noItems = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"There are no scanned items to process." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noItems show];
    }
	[IDTextField resignFirstResponder];
	
}


-(IBAction)resetCart:(id)sender
{
    self.cart = nil;
    self.cart = [NSMutableArray array];
    self.amounts = nil;
    selectedIdNumber = nil;
    IDTextField.text = nil;
    processButton.enabled = NO;
	totalLabel.text = @"0.00";
    [tableView reloadData];
	
	//move table back to top
	[self.tableView setContentOffset:CGPointZero animated:NO];
	tableView.backgroundColor = [UIColor whiteColor];
	
	//hide the summarize sale
	[self hidePopover:nil];
	[IDTextField resignFirstResponder];
	
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
    
    //make keyboard go away when order is submitted
	if([IDTextField isFirstResponder]){
        [IDTextField resignFirstResponder];
    }
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
	[IDTextField setText:@""];
	[super hideActivity];
}


#pragma mark - Linea Delegate calls

//Connection delegate method sends messages to class when connection state changes
-(void)connectionState:(int)state
{
	switch (state) {
		case CONN_DISCONNECTED:
		case CONN_CONNECTING:
			
			//#ifdef DEBUG
			// NSLog(@"[LINEA] Linea connectionState=CONNECTING/DISCONNECTED");
			// #endif
			
			break;
		case CONN_CONNECTED:
            [[DTDevices sharedDevice] barcodeSetScanMode:0 error:nil];
			[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
			[[DTDevices sharedDevice] msSetCardDataMode:MS_PROCESSED_CARD_DATA error:nil];
            //Turn on the beep
            int beepData[] = {1200,100};
			[[DTDevices sharedDevice] barcodeSetScanBeep:TRUE volume:10 beepData:beepData length:sizeof(beepData) error:nil];
			
#ifdef DEBUG
			NSLog(@"[LINEA] Linea connectionState=CONNECTED TO Register ViewC");
#endif
			break;
	}
}

//add 1 to qty of items if one is already in the cart
//if not, add it to the cart
-(void)addItemToCart:(CartItem *)scannedItem
{
    processButton.enabled = YES;
    BOOL duplicate = NO;
	for(int i = 0; i < [self.cart count]; i++) {
        CartItem *itemInCart = [self.cart objectAtIndex:i];
        if ([itemInCart item] == [scannedItem item])
        {
            int indexOfMatchingItem = i;
            int existingQty = [itemInCart count];
            int newQty = existingQty+1;
            itemInCart.count = newQty;
            [self.cart replaceObjectAtIndex:indexOfMatchingItem withObject:itemInCart];
            duplicate = YES;
        }
    }
    if(duplicate == NO) {
        [self.cart addObject:scannedItem];
    }
}
//Fires when a barcode is scanned
-(void) barcodeData:(NSString *)barcode type:(int)type
{
#ifdef DEBUG
	NSLog(@"scanned barcode: %@",barcode);
#endif
    if(popover.hidden == YES) {
        OdinEvent *scannedItem = [self searchForItemWithBarcode:barcode];
        if (scannedItem)
        {
            [self addItemToCart:[CartItem cartItemWithOdinItem:scannedItem]];
#ifdef DEBUG
            NSLog([self.cart description]);
#endif
        } else {
            [[DTDevices sharedDevice] badBeep];
        }
        [self.tableView reloadData];
		
    }
    
    else {
        //check exportid and adjust barcode if using exportID
        [self processScannedData:barcode];
    }
}


//fires when a swipe card is used
-(void)magneticCardData:(NSString *)track1 track2:(NSString *)track2 track3:(NSString *)track3
{
    NSLog(@"\n\nTrack 1:%@\n\nTrack 2:%@\n\nTrack 3:%@\n\n",track1,track2,track3);
	
	
	NSString *magneticData = [NSString stringWithFormat:@"%@%@",track1,track2];
	
	float amount = (totalLabel) ? [[totalLabel.text substringFromIndex:1] floatValue] : 0.0;
	
	if ([NetworkConnection isInternetOffline]) {
		[ErrorAlert simpleAlertTitle:@"No Connection" message:@"Please check your Wifi or data service is turn on"];
		return;
	}else if (self.cart.count <= 0)
	{
		[ErrorAlert simpleAlertTitle:@"Empty Cart" message:@"Please scan barcode and summerize sale"];
		return;
	} else if (popover.hidden) {
		[ErrorAlert simpleAlertTitle:@"Summerize Sale" message:@"Please hit \"Summarize Sale\" button when you completed your barcode scan"];
		return;
	} else if (amount <= 0.0)
	{
		[ErrorAlert simpleAlertTitle:@"No Cost"
							 message:[NSString stringWithFormat:@"Selected item cost $%.2f. Doesn't need to pay", amount]];
		return;
	}
	
	
	
	//NSDecimalNumber *totalAmount = [NSDecimalNumber decimalNumberWithString:totalLabel.text];
	
	NSString *reference = [[SettingsHandler sharedHandler] getReference];
	NSString *orderID = [[NSNumber numberWithInt:arc4random()%89999999 + 10000000] stringValue];
	
	ccProcess = [CardProcessor initialize:magneticData];
	[ccProcess setTransactionAmount:[NSString stringWithFormat:@"%.2f",amount]];
	[ccProcess setTransactionDesc:@"test item"];
	[ccProcess setTransactionId:[reference stringByAppendingString:orderID]];
	//[ccProcess setTransactionAmount:totalLabel.text];
	
	//[self processTransactions];
	MBProgressHUD *HUD = [HUDsingleton theHUD].HUD;
	[HUD show:YES];
	[HUD showWhileExecuting:@selector(processTransactions) onTarget:self withObject:nil animated:YES];
	
	
}


-(void)processScannedData:(NSString *)dataToProcess
{
	//handles matching exportID to ID
	NSString *idNumber = [dataToProcess checkExportID];
	//shows ID number in the text box
	selectedIdNumber = [idNumber cleanBarcode];
	IDTextField.text = selectedIdNumber;
	[self beginTransaction];
}


// refreshes connection to Linea when returning from inactive state
- (void) refreshLinea
{
	[[DTDevices sharedDevice] addDelegate:self];
	[[DTDevices sharedDevice] connect];
	[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
#ifdef DEBUG
	NSLog(@"Refreshing Linea connection to Register VC");
#endif
}


#pragma mark - Init Methods


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Custom initialization
	}
	return self;
}

- (void)viewDidLoad
{
	self.cart = [NSMutableArray array];
	[self.IDTextField setDelegate:self];
	processButton.enabled = NO;
	//get managedObjectContext from AppDelegate
	if (managedObjectContext == nil)
	{
		managedObjectContext = [CoreDataHelper getMainMOC];
	}
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
		if([UIScreen mainScreen].bounds.size.height == 568.0)
		{
			//move to your iphone5 storyboard
			UITableView *v = (UITableView*)[self.view viewWithTag:500];
			[v setFrame: CGRectMake(10, v.frame.origin.y, v.frame.size.width, 500)];
			
		}
		else{
			//move to your iphone4s storyboard
		}
	}
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self refreshLinea];
	//turn off idle timer so the iPod does not go to sleep while they're scanning cards
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
-(void)viewDidAppear:(BOOL)animated
{
	[[AuthenticationStation sharedAuth] setIsOnline:YES];
}
-(void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[[DTDevices sharedDevice] removeDelegate:self];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}
#pragma mark - keyboard movements
- (void)keyboardWillShow:(NSNotification *)notification
{
	[UIView animateWithDuration:0.3 animations:^{
		CGRect f = darken.frame;
		f.origin.y = -100.0f;  //set the -35.0f to your required value
		darken.frame = f;
	}];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
	[UIView animateWithDuration:0.3 animations:^{
		CGRect f = darken.frame;
		f.origin.y = 0.0f;
		darken.frame = f;
	}];
}

#pragma mark - Table Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	// Return the number of sections.
	return 1;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	NSString *title = @"Scanned items:";
	return title;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellId = @"itemInCartCell";
	
	UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellId];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
	}
	
	// Get the core data object we use to populate the cell in a given row
	CartItem *currentItem = [self.cart objectAtIndex:indexPath.row];
	
	//  Fill in the cell contents
	cell.textLabel.text = [NSString stringWithFormat:@"Qty: %d  %@",[currentItem count],[[currentItem item] item]];
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section
{
	// Return the number of rows in the section.
	return [self.cart count];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	// Return YES if you want the specified item to be editable.
	return YES;
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.cart removeObjectAtIndex:indexPath.row];
		[aTableView reloadData];
		if ([self.cart count] == 0){
			processButton.enabled = NO;
		}
	}
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - transaction methods

//Checks input for errors
-(BOOL)inputChecksOut
{
	//checks if fields are empty
	if([IDTextField.text isEqualToString:@""] || !IDTextField.text)
	{
		[ErrorAlert emptyFieldError];
		return NO;
	}
	
	//check whether item can be bought with manual ID input
	if(!selectedIdNumber) {
		selectedIdNumber = IDTextField.text;
		for(int j = 0; j < [self.cart count]; j++) {
			CartItem *itemInCart = [self.cart objectAtIndex:j];
			if ([itemInCart.item.allow_manual_id boolValue] == FALSE)
			{
				[ErrorAlert cardPresentAlert];
				IDTextField.text = nil;
				selectedIdNumber = nil; //clear out sectedIdNumber otherwise can bypass restriction
				return NO;
			}
		}
	}
	return YES;
}

//Button call from "Process Sale" button in popover view
- (IBAction) enterTransaction:(id)sender;
{
	[self beginTransaction];
}

//beginning of fragmented transaction methods
//broken up for purposes of activity indicator
- (void) beginTransaction
{
	if([self inputChecksOut]) {
#ifdef DEBUG
		NSLog(@"Transaction Started");
		UIAlertView *transactionStarted = [[UIAlertView alloc] initWithTitle:@"Transaction Started!" message:@"1" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		//    [transactionStarted show];
#endif
		[self showProcessActivity];
		[[HUDsingleton theHUD].HUD showWhileExecuting: @selector(showTransactionResult) onTarget:self withObject:nil animated:YES];
	}
	else {
#ifdef DEBUG
		UIAlertView *cantPurchase = [[UIAlertView alloc] initWithTitle:@"Can't purchase items!" message:@"4" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		//        [cantPurchase show];
#endif
	}
	
	
}

//the actual method for processing a sale
- (void) showTransactionResult
{
	BOOL transactionWasSuccessful = [self isTransactionSuccessful];
	[self performSelectorOnMainThread:@selector(showSuccess:) withObject:[NSNumber numberWithBool:transactionWasSuccessful] waitUntilDone:YES];
#ifdef DEBUG
	NSLog(@"Transaction Completed");
	UIAlertView *transactionCompleted = [[UIAlertView alloc] initWithTitle:@"Transaction Completed!" message:@"1" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	//    [transactionCompleted show];
#endif
	if (transactionWasSuccessful == TRUE)
	{
		//increment reference number
		/*
		 self.cart = nil;
		 self.cart = [NSMutableArray array];
		 self.amounts = nil;
		 selectedIdNumber = nil;
		 IDTextField.text = nil;
		 [self.tableView reloadData];
		 //move table back to top
		 [self.tableView setContentOffset:CGPointZero animated:NO];
		 // sleep delays HUD long enough (outside loop, in order to update UI) to display success
		 sleep(1);
		 [UIView beginAnimations:@"fade-out" context:NULL];
		 [UIView setAnimationDuration:0.4];
		 darken.alpha = 0;
		 [UIView commitAnimations];
		 popover.hidden = YES;*/
		[self clearCart];
		[[SettingsHandler sharedHandler] incrementReference];
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
	if ([TestIf account:[OdinStudent getStudentInfoForID:selectedIdNumber andMOC:managedObjectContext]
	   canPurchaseItems:cart
			 forAmounts:amounts])
	{
#ifdef DEBUG
		UIAlertView *canPurchase = [[UIAlertView alloc] initWithTitle:@"Can purchase items!" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		//        [canPurchase show];
#endif
		//get reference number by taking refNumber and first letter of register code
		NSString *reference = [[SettingsHandler sharedHandler] getReference];
		for(int j = 0; j < [self.cart count]; j++) {
			CartItem *itemInCart = [self.cart objectAtIndex:j];
			OdinEvent *item = [itemInCart item];
			
			//Gather information to be entered
			NSString *plu = item.plu;
			
			
			//calculate total amount, including tax
			NSNumber *qty = [NSNumber numberWithInt: [itemInCart count]];
			NSDecimalNumber *amount = [item amount];
			
			//TODO: should this be used?
			//NSDecimalNumber *tax = [item tax];
			
			NSDecimalNumber *totalAmount = [OdinTransaction getTotalAmountFromQtyEntered:qty andAmountEntered:amount forItem:item];
			//check if the transaction is legal, and if the account has sufficient funds
			//processTransaciton is always called on a background thread since main thread is animating the activity indicator
			[self performSelectorOnMainThread:@selector(showProcessing) withObject:nil waitUntilDone:NO];
#ifdef DEBUG
			NSLog(@"RV item %@ purchased by account %@ with ref: %@",plu,selectedIdNumber, reference);
#endif
			OdinTransaction *transaction = [CoreDataHelper insertObjectForEntity:@"OdinTransaction" andContext:managedObjectContext];
			//fill out the transaction
			transaction.qty = qty;
			transaction.amount = totalAmount;
			transaction.id_number = selectedIdNumber;
			transaction.plu = plu;
			transaction.timeStamp = [NSDate date];
			transaction.sync = [NSNumber numberWithBool:FALSE];
			//total amount = amount + tax, so tax = totalAmount - amount
			//transaction.tax_amount = [totalAmount decimalNumberBySubtracting:amount];
			transaction.reference = reference;
			transaction.location = item.location;
			transaction.item = item.item;
			//version 2.6add glcode and dept_code
			transaction.operator = [[SettingsHandler sharedHandler] uid];//item.operator;
			transaction.dept_code = item.dept_code;
			transaction.glcode = item.glcode;
			
			
			NSDictionary *transactionWebItem = [transaction preppedForWeb];
			
			//if in online mode, upload the transaction immediately
			if (([[SettingsHandler sharedHandler] holdTransactions] == FALSE)
				&& ([[AuthenticationStation sharedAuth] isOnline] == TRUE))
			{
				if ([TestIf appCanUseSchoolServer])
				{
					if ([WebService postTransaction:transactionWebItem])
					{
						transaction.sync = [NSNumber numberWithBool:TRUE];
						
						//save transaction to log
						//[StreamInOut writeLogFileWithTransaction:transactionWebItem Note:@"Batch Uploaded"];
						return FALSE;
					}
					else{
						//save transaction to log
						//[StreamInOut writeLogFileWithTransaction:transactionWebItem Note:@"Batch Store Into Pending"];
					}
				}
			}
			//if in offline mode, call it a success
			/*
			 else
			 {
			 return TRUE;
			 }
			 */
			//save all changes to transaction
			[CoreDataHelper saveObjectsInContext:managedObjectContext];
		}
		return TRUE;
	}
	else {
#ifdef DEBUG
		UIAlertView *cantPurchase = [[UIAlertView alloc] initWithTitle:@"Can't purchase items!" message:@"1" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		//[cantPurchase show];
#endif
		return FALSE;
	}
}
-(void) processTransactions
{
	
	if ([ccProcess makePurchase]) {
		//NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
		
		//Gather information to be entered
		//NSString *plu = selectedItem.plu;
		//NSString *idNumber = selectedIdNumber;
		
		//get reference number by taking refNumber and first letter of register code
		NSString *reference = [[SettingsHandler sharedHandler] getReference];
		//OdinTransaction *transaction = [CoreDataHelper insertObjectForEntity:@"OdinTransaction" andContext:managedObjectContext];
		//fill out the transaction
		NSMutableArray* transactions = [[SettingsHandler sharedHandler] getMultiTransactions];
		for(int j = 0; j < cart.count; j++) {
			CartItem *itemInCart = [self.cart objectAtIndex:j];
			OdinEvent *item = [itemInCart item];
			
			//Gather information to be entered
			NSString *plu = item.plu;
			
			
			//calculate total amount, including tax
			NSNumber *qty = [NSNumber numberWithInt: [itemInCart count]];
			NSDecimalNumber *amount = [item amount];
			
			//TODO: should this be used?
			//NSDecimalNumber *tax = [item tax];
			
			NSDecimalNumber *amount2 = [OdinTransaction getTotalAmountFromQtyEntered:qty andAmountEntered:amount forItem:item];
			//check if the transaction is legal, and if the account has sufficient funds
			//processTransaciton is always called on a background thread since main thread is animating the activity indicator
			[self performSelectorOnMainThread:@selector(showProcessing) withObject:nil waitUntilDone:NO];
#ifdef DEBUG
			NSLog(@"RV item %@ purchased by account %@ with ref: %@",plu,selectedIdNumber, reference);
#endif
			OdinTransaction *transaction = [CoreDataHelper insertObjectForEntity:@"OdinTransaction" andContext:managedObjectContext];
			//fill out the transaction
			transaction.qty = qty;
			transaction.amount = amount2;
			transaction.id_number = @"Credit/Debit Card";//selectedIdNumber;
			transaction.plu = plu;
			transaction.timeStamp = [NSDate date];
			transaction.sync = [NSNumber numberWithBool:FALSE];
			//total amount = amount + tax, so tax = totalAmount - amount
			//transaction.tax_amount = [totalAmount decimalNumberBySubtracting:amount];
			transaction.reference = reference;
			transaction.location = item.location;
			transaction.item = item.item;
			//version 2.6add glcode and dept_code
			transaction.operator = [[SettingsHandler sharedHandler] uid];//item.operator;
			transaction.dept_code = item.dept_code;
			transaction.glcode = item.glcode;
			
			
			//Credit card
			transaction.cc_digit = [ccProcess getCardLast4Digits];
			transaction.cc_tranid = [ccProcess responseTransactionId];
			transaction.cc_first = [ccProcess getCardFirstName];
			transaction.cc_last = [ccProcess getCardLastName];
			transaction.cc_approval = [ccProcess responseApprovalCode];
			transaction.cc_timeStamp = [transaction.timeStamp convertDataToTimestamp];
			
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
			
			[transactions addObject:transaction];
			
			[CoreDataHelper saveObjectsInContext:managedObjectContext];
		}
		
		[[SettingsHandler sharedHandler] setMultiTransactions:transactions];
		[[SettingsHandler sharedHandler] incrementReference];
		
		
		NSString* (^makeTransaction)(void) = ^{
			if (transactions.count > 1) {
				return [NSString stringWithFormat:@"{\"transactions\":{\n\t\"transaction\":[\n%@]}",[transactions JSON]];
			}
			return [NSString stringWithFormat:@"{\n\t\"transaction\":{\n%@}}",[transactions JSON]];
		};
		NSString* xmlString = makeTransaction();
		
		xmlString = [NSString stringWithFormat:@"TranData=%@,\n%@}",xmlString,[xmlString encryptMessage]];
		
		if([WebService postCreditCardWithString:xmlString]) {
			[self clearCart];
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id_number = \"Credit/Debit Card\" && sync = FALSE"];
			NSArray* unsyncedArray = [CoreDataHelper searchObjectsForEntity:@"OdinTransaction"
															  withPredicate:predicate
																 andSortKey:nil
														   andSortAscending:NO
																 andContext:self.managedObjectContext];
			for (OdinTransaction* trans in unsyncedArray) {
				trans.sync = [NSNumber numberWithBool:TRUE];
			}
			[CoreDataHelper saveObjectsInContext:managedObjectContext];
			//Show receipt view
			ReceiptVC *rvc  = [self.storyboard instantiateViewControllerWithIdentifier:@"ReceiptVC"];
			[self presentViewController:rvc animated:YES completion:nil];
			//[self.view addSubview:rvc.view];
		}
		
		//[[SettingsHandler sharedHandler] setMultiTransactions:nil];
	}
}
-(void) clearCart
{
	
	//increment reference number
	[[SettingsHandler sharedHandler] incrementReference];
	[self resetCart:nil];
	//self.cart = nil;
	//self.cart = [NSMutableArray array];
	//self.amounts = nil;
	//selectedIdNumber = nil;
	//IDTextField.text = nil;
	//[self.tableView reloadData];
	//move table back to top
	//[self.tableView setContentOffset:CGPointZero animated:NO];
	// sleep delays HUD long enough (outside loop, in order to update UI) to display success
	sleep(1);
	
	[UIView beginAnimations:@"fade-out" context:NULL];
	[UIView setAnimationDuration:0.4];
	darken.alpha = 0;
	[UIView commitAnimations];
	popover.hidden = YES;
}
#pragma mark - Keyboard Methods

// Get rid of popover view if someone taps background
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch = [[event allTouches] anyObject];
	if([IDTextField isFirstResponder]){
		[IDTextField resignFirstResponder];
	}
	else if ([touch view] == darken) {
		[UIView beginAnimations:@"fade-out" context:NULL];
		[UIView setAnimationDuration:0.4];
		darken.alpha = 0;
		[UIView commitAnimations];
		popover.hidden = YES;
		selectedIdNumber = nil;
		IDTextField.text = nil;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	[theTextField resignFirstResponder];
	return YES;
}


-(IBAction)hidePopover:(id)sender
{
	[UIView beginAnimations:@"fade-out" context:NULL];
	[UIView setAnimationDuration:0.4];
	darken.alpha = 0;
	[UIView commitAnimations];
	popover.hidden = YES;
	selectedIdNumber = nil;
	IDTextField.text = nil;
	
	//move table back to top
	[self.tableView setContentOffset:CGPointZero animated:NO];
	tableView.backgroundColor = [UIColor whiteColor];
}

@end

