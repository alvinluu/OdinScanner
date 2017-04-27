//
//  RegisterViewController.m
//  OdinScanner
//
//  Created by Ken Thomsen on 2/22/13.
//
//

#import "RegisterVC.h"
// #import "RegisterItem+Methods.h"
#import "CartItem.h"
#import "Linea.h"
#import "OdinTransaction+Methods.h"
#import "NSString+hackXML.h"

@interface RegisterVC ()

@property (nonatomic, strong) NSMutableArray *cart;
@property (nonatomic) double totalCartAmount;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *popover;
@property (nonatomic, strong) IBOutlet UIView *darken;
@property (nonatomic, strong) IBOutlet UILabel *subtotalLabel;
@property (nonatomic, strong) IBOutlet UILabel *taxLabel;
@property (nonatomic, strong) IBOutlet UILabel *totalLabel;
@property (nonatomic, strong) IBOutlet UITextField *IDTextField;
@property (nonatomic, strong) NSString *selectedIdNumber;
@property (weak, nonatomic) IBOutlet UIButton *idBtn;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) IBOutlet UIButton *processButton;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *resetBtn;
@property (weak, nonatomic) IBOutlet UIButton *summarizeBtn;
@property (weak, nonatomic) IBOutlet UIButton *itemBtn;
@property (nonatomic) UIAlertView* alert;

@property (nonatomic, strong) CardProcessor *ccProcess;
@property (nonatomic) CGPoint tableInitialPoint;
@property (nonatomic) Inventory* inventoryVC;
@property (nonatomic) Patron* patronVC;
@property (nonatomic) NSTimer* myTimer;

-(IBAction)doneWithCart:(id)sender;
-(IBAction)enterTransaction:(id)sender;
-(IBAction)hidePopover:(id)sender;
-(IBAction)resetCart:(id)sender;

@end

@implementation RegisterVC

@synthesize cart, totalCartAmount;
@synthesize tableView;
@synthesize popover, darken;
@synthesize subtotalLabel;
@synthesize taxLabel;
@synthesize totalLabel;
@synthesize IDTextField, nameLabel, idBtn;
@synthesize selectedIdNumber;
@synthesize managedObjectContext;
@synthesize processButton;
@synthesize ccProcess;
@synthesize tableInitialPoint;
@synthesize inventoryVC, patronVC;
@synthesize resetBtn, summarizeBtn, itemBtn;
@synthesize myTimer,alert;
NSMutableArray* tranArray;

#define CONNECTION_ERROR @"Connection Error"
#define TRANSACTION_ERROR @"Transaction Error"
#define PROCESS_OFFLINE_FUNDS @"Process offline funds"
#define PROCESS_INSUFFICIENT_FUNDS @"Process insufficient funds"


//TODO: allow user to edit price of items if they have permission



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
        darken.alpha = 1;
        [UIView commitAnimations];
        
        //Create array of item costs, used to test if student has enough balance
//        self.amounts = [NSMutableArray array];
        totalCartAmount = 0.0;
        double subtotal = 0.0;
        double tax = 0.0;
        double total = 0.0;
        IDTextField.enabled = true;
        IDTextField.backgroundColor = [UIColor whiteColor];
        nameLabel.text = @"";
        
        
        for(int k = 0; k < [self.cart count]; k++) {
            CartItem *itemInCart = [self.cart objectAtIndex:k];
            double amount = itemInCart.item.amount.floatValue;
            double qty = [itemInCart count];
            double itemTotal = amount * qty;
            subtotal += itemTotal;
            //There's already a method to calculate total with quantity and tax
            NSDecimalNumber *itemTotalWithTax = [OdinTransaction getTotalAmountFromQtyEntered:[NSNumber numberWithInt:itemInCart.count] andAmountEntered:itemInCart.item.amount forItem:itemInCart.item];
            total += itemTotalWithTax.floatValue;
//            [self.amounts addObject:itemTotalWithTax];
            if (!itemInCart.item.allow_manual_id.boolValue) {
                IDTextField.enabled = false;
                IDTextField.backgroundColor = [UIColor grayColor];
                IDTextField.text = @"";
            }
        }
        
        idBtn.enabled=IDTextField.enabled;
        idBtn.backgroundColor = idBtn.enabled ? processButton.backgroundColor : [UIColor grayColor];
        
        //TODO: find better way of calculating total tax amount so there are no rounding errors
        tax = (total - subtotal);
        subtotalLabel.text = [NSString stringWithFormat:@"$%.2f", subtotal];
        taxLabel.text = [NSString stringWithFormat:@"$%.2f", tax];
        totalLabel.text = [NSString stringWithFormat:@"$%.2f", total];
        totalCartAmount = total;
        /*[[SettingsHandler sharedHandler] setSubtotal:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.2f",subtotal]]];
         [[SettingsHandler sharedHandler] setTax:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.2f",tax]]];
         [[SettingsHandler sharedHandler] setTotal:[NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.2f",total]]];
         #ifdef DEBUG
         NSLog(@"subtotal %.2f tax %.2f total %.2f",[[[SettingsHandler sharedHandler]subtotal] floatValue],[[[SettingsHandler sharedHandler]tax] floatValue],[[[SettingsHandler sharedHandler]total] floatValue]);
         #endif
         */
        
    }
    else {
        UIAlertView *noItems = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"There are no scanned items to process." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [noItems show];
    }
    [IDTextField resignFirstResponder];
    
}


-(IBAction)resetCart:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cart = nil;
        self.cart = [NSMutableArray array];
        self.totalCartAmount = 0.0;
        selectedIdNumber = nil;
        processButton.enabled = NO;
        [tableView reloadData];
        
        //move table back to top
        //	[self.tableView setContentOffset:CGPointZero animated:NO];
        //	tableView.backgroundColor = [UIColor whiteColor];
        
        //hide the summarize sale
        [self hidePopover:nil];
        self.IDTextField.text = @"";
        self.totalLabel.text = @"0.00";
        [IDTextField resignFirstResponder];
    });
    
}
-(BOOL) hasCheckBalance
{
    
    BOOL hasCheckBalance = false;
    for (CartItem* item in cart) {
        if (item.item.chk_balance.boolValue) {
            hasCheckBalance = true;
        }
    }
    return hasCheckBalance;
}
-(void) showReceiptView
{
    //Show receipt view
    ReceiptVC *rvc  = [self.storyboard instantiateViewControllerWithIdentifier:@"ReceiptVC"];
    rvc.transArray = [[NSArray alloc]initWithArray:tranArray];
    rvc.type = @"Sale";
    [self presentViewController:rvc animated:YES completion:nil];
}

#pragma mark - Linea Delegate calls

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
    if ([SettingsHandler sharedHandler].isProcessingSale) {
        [[DTDevices sharedDevice] badBeep];
        return; }
    if(popover.hidden == YES) {
        OdinEvent *scannedItem = [OdinEvent searchForItemWithBarcode:barcode];
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
        [self processScannedData:barcode];
    }
}


//fires when a swipe card is used
-(void)magneticCardData:(NSString *)track1 track2:(NSString *)track2 track3:(NSString *)track3
{
    NSLog(@"\n\nTrack 1:%@\n\nTrack 2:%@\n\nTrack 3:%@\n\n",track1,track2,track3);
    
    if ([SettingsHandler sharedHandler].isProcessingSale) {
        [[DTDevices sharedDevice] badBeep];
        return;}
    NSString *magneticData = [NSString stringWithFormat:@"%@%@",track1,track2];
    
    float amount = (totalLabel) ? [[totalLabel.text substringFromIndex:1] floatValue] : 0.0;
    
    if ([NetworkConnection isInternetOffline]) {
        //[ErrorAlert simpleAlertTitle:@"No Connection" message:@"Please check your Wifi or data service is turned on"];
        [ErrorAlert noInternetConnection];
        return;
    }else if (self.cart.count <= 0)
    {
        [ErrorAlert simpleAlertTitle:@"Empty Cart" message:@"Please scan barcode and summerize sale"];
        return;
    } else if (popover.hidden) {
        [ErrorAlert simpleAlertTitle:@"Need Summerize Sale" message:@"Please hit \"Summarize Sale\" button when you completed your barcode scan"];
        return;
    } else if (amount <= 0.0)
    {
        [ErrorAlert simpleAlertTitle:@"No Cost"
                             message:[NSString stringWithFormat:@"Selected item cost $%.2f. Doesn't need to pay", amount]];
        
        return;
    }
    
    
    if (track1.length > 0 && track2.length > 0) {
        if ([track1 hasPrefix:@"%B"] && [track1 hasSuffix:@"?"] && [track2 hasPrefix:@";"] && [track2 hasSuffix:@"?"]) { //credit card
            //card smith
            //-- use export id
            //-- StMarks use the last 6 digits on track1 for id (make sure export id is on)
            if ([track1 hasPrefix:@"%B603950"]) { //process as credit card
                NSString* idnumber = [track1 getStMarkExportID];
                
#if DEBUG
                NSLog(@"track1 StMark id %@",idnumber);
                
#endif
                
                if ([SettingsHandler sharedHandler].isProcessingSale) { return; }
                	[self processScannedData:idnumber];
//                [self performSelectorInBackground:@selector(processScannedData:) withObject:idnumber];
//                [[SettingsHandler sharedHandler] processingSaleEnd];
                //                [self barcodeData:idnumber isotype:BAR_ALL];
            } else { //process as cardsmith
                [self initCC:magneticData];
            }
            
            
        }
    } else if (track1.length > 0) {
        if ([track1 hasPrefix:@"$B"] && [track1 hasSuffix:@";"]) {
            [self barcodeData:track1 type:BAR_ALL];
        }
    } else if (track2.length > 0) {
        if ([track1 hasPrefix:@"$B"] && [track1 hasSuffix:@";"]) {
            [self barcodeData:track2 type:BAR_ALL];
        }
        
    }
}

-(void)initCC:(NSString*)magneticData {
    
    float amount = (totalLabel) ? [[totalLabel.text substringFromIndex:1] floatValue] : 0.0;
    //NSDecimalNumber *totalAmount = [NSDecimalNumber decimalNumberWithString:totalLabel.text];
    
    NSString *reference = [[SettingsHandler sharedHandler] getReference];
    NSString *orderID = [[NSNumber numberWithInt:arc4random()%89999999 + 10000000] stringValue];
    
    ccProcess = [CardProcessor initialize:magneticData];
    if (ccProcess == nil ) {return;}
    [ccProcess setTransactionAmount:[NSString stringWithFormat:@"%.2f",amount]];
    //TODO: change descrition to school name
    NSString* schoolname = [SettingsHandler sharedHandler].school;
    [ccProcess setTransactionDesc:[NSString stringWithFormat:@"%@ %@",schoolname,reference]];
    [ccProcess setTransactionId:[reference stringByAppendingString:orderID]];
    [ccProcess setInvoiceNumber:[reference stringByAppendingString:orderID]];
    //[ccProcess setTransactionAmount:totalLabel.text];
    
    [[SettingsHandler sharedHandler] processingSaleStart];
    if ([ccProcess makePurchase] && [ccProcess getCardLast4Digits]) {
        [self processCCTransactions];
    } else {
        [ErrorAlert chargeDeclined];
        [[SettingsHandler sharedHandler] processingSaleEnd];
    }
}

-(void)processScannedData:(NSString *)dataToProcess
{
    
    
    NSString* idNumber = [dataToProcess cleanBarcode];
    selectedIdNumber = [idNumber checkExportID];
    if (selectedIdNumber == nil) {
        [ErrorAlert simpleAlertTitle:@"Export ID not found!" message:idNumber];
        [self hideActivity];
        return;
    }
    
#ifdef DEBUG
    NSLog(@"seleected id: %@",selectedIdNumber);
#endif
    IDTextField.text = selectedIdNumber;
    
    OdinStudent* student = [OdinStudent getStudentByIDnumber:selectedIdNumber];
    NSString* name = [NSString stringWithFormat:@"%@ %@", [NSString printName:student.student]
                      , [NSString printName:student.last_name]];
    nameLabel.text = name;
    
    [self beginTransaction];
}


// refreshes connection to Linea when returning from inactive state

#pragma mark - Call Views
-(IBAction)showInventory:(id)sender
{
    if (!inventoryVC) {
        //        inventoryVC = [[Inventory alloc] initWithSourceView:self.view];
        
        inventoryVC = [self.storyboard instantiateViewControllerWithIdentifier:@"InventoryVC"];
        [self presentViewController:inventoryVC animated:YES completion:nil];
        inventoryVC.delegate = self;
        self.tabBarController.tabBar.hidden = true;
        [IDTextField resignFirstResponder];
    }
}

-(void)closeInventory:(OdinEvent *)item
{
#ifdef DEBUG
    NSLog(@"closeInventory");
#endif
    if (inventoryVC) {
        if (item) {
            [self addItemToCart:[CartItem cartItemWithOdinItem:item]];
            [self.tableView reloadData];
            if (!popover.hidden) {
                [self doneWithCart:nil];
            }
        }
        //        [inventoryVC.view removeFromSuperview];
        [inventoryVC dismissViewControllerAnimated:YES completion:nil];
    }
    inventoryVC = nil;
    self.tabBarController.tabBar.hidden = false;
}
-(IBAction)showPatron:(id)sender
{
    if (!patronVC) {
        //        patronVC = [[Patron alloc] initWithSourceView:self.view];
        
        patronVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PatronVC"];
        [self presentViewController:patronVC animated:YES completion:nil];
        patronVC.delegate = self;
        self.tabBarController.tabBar.hidden = true;
        [IDTextField resignFirstResponder];
    }
}
- (void) closePatron:(OdinStudent*)student
{
#ifdef DEBUG
    NSLog(@"closePatron student:%@",student.id_number);
#endif
    
    if (patronVC) {
        if (student) {
            IDTextField.text = student.id_number;
            NSString* name = [NSString stringWithFormat:@"%@ %@", student.student, student.last_name];
            nameLabel.text = name;
            
        }
        //        [patronVC.view removeFromSuperview];
        [patronVC dismissViewControllerAnimated:YES completion:nil];
    }
    patronVC = nil;
    self.tabBarController.tabBar.hidden = false;
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
    [super viewDidLoad];
    
#ifdef DEBUG
    NSLog(@"viewdidload");
#endif
    self.cart = [NSMutableArray array];
    [self.IDTextField setDelegate:self];
    processButton.enabled = NO;
    [self clearCart];
    
    //get managedObjectContext from AppDelegate
    if (managedObjectContext == nil)
    {
        managedObjectContext = [CoreDataService getMainMOC];
    }
    
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
    
    //store popover cgpoint
    tableInitialPoint = tableView.frame.origin;
    
}

-(void)viewWillAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"viewwillappear");
#endif
    subtotalLabel.textAlignment = NSTextAlignmentRight;
    taxLabel.textAlignment = NSTextAlignmentRight;
    totalLabel.textAlignment = NSTextAlignmentRight;
    
    
    [super viewWillAppear:animated];
    //turn off idle timer so the iPod does not go to sleep while they're scanning cards
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showSuccessRecall:)
                                                 name:@"showHUDPostStatus"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissAlert)
                                                 name:@"dismissAlert"
                                               object:nil];
    
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(updateManageBadge)
    //                                                 name:NSManagedObjectContextDidSaveNotification
    //                                               object:self.moc];
}
-(void)viewDidAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"viewdidappear");
#endif
    [self refreshLinea];
    
    
    float osversion = [UIDevice currentDevice].systemVersion.floatValue;
    if (osversion < 7.0) {
        resetBtn.backgroundColor = [UIColor clearColor];
        summarizeBtn.backgroundColor = [UIColor clearColor];
        itemBtn.backgroundColor = [UIColor clearColor];
    }
    //[[AuthenticationStation sharedHandler] setIsOnline:YES];
}
-(void)viewWillDisappear:(BOOL)animated
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self disconnectLinea];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    CartItem *cartItem = [self.cart objectAtIndex:indexPath.row];
    OdinEvent* item = cartItem.item;
    NSString* name = [NSString stringWithFormat:@"%i %@",cartItem.count,item.item];
    NSString* detail = [NSString stringWithFormat:@"$%.2f",item.amount.floatValue];
    if (item.taxable.boolValue) {
        NSString* taxDetail = [NSString stringWithFormat:@"  taxed: %.2f%%",item.tax.floatValue];
        detail = [detail stringByAppendingString:taxDetail];
    }
    if (!item.allow_manual_id) {
        cell.layer.backgroundColor = [UIColor grayColor].CGColor;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        cell.textLabel.text = name;
        cell.detailTextLabel.text = detail;
    });
    
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
        if (self.cart.count == 0){
            //			processButton.enabled = NO;
            [self resetCart:nil];
        } else if (!popover.hidden) {
            [self doneWithCart:nil];
            
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
        [ErrorAlert emptyField];
        return NO;
    }
    
    //check whether item can be bought with manual ID input
    if(!selectedIdNumber) {
        selectedIdNumber = IDTextField.text;
        for(int j = 0; j < [self.cart count]; j++) {
            CartItem *itemInCart = [self.cart objectAtIndex:j];
            if ([itemInCart.item.allow_manual_id boolValue] == FALSE)
            {
                //[ErrorAlert cardPresentAlert];
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
        
        NSString* idNumber = IDTextField.text;
        selectedIdNumber = [idNumber checkExportID];
        IDTextField.text = selectedIdNumber;
        
        
#ifdef DEBUG
        NSLog(@"Transaction Started");
        UIAlertView *transactionStarted = [[UIAlertView alloc] initWithTitle:@"Transaction Started!" message:@"1" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
#endif
        
            [self showProcessActivity];
            [self processDebitTransaction];
    }
    else {
#ifdef DEBUG
        UIAlertView *cantPurchase = [[UIAlertView alloc] initWithTitle:@"Can't purchase items!" message:@"4" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //        [cantPurchase show];
#endif
        
        [[SettingsHandler sharedHandler] processingSaleEnd];
    }
    
    
}

-(void) processDebitTransaction
{
    [[SettingsHandler sharedHandler] processingSaleStart];
    
    
    NSDictionary* student = [OdinStudent getStudentInfoForID:selectedIdNumber andMOC:self.moc];
    
    
    [self cancelTimer];
    if ([TestIf account:student canPurchaseCart:cart forAmounts:[NSNumber numberWithDouble:totalCartAmount]])
    {
        [self HUDshowMessage:@"Processing.."];
        [self postTransaction];
    } else {
        NSNumber* funds = [student objectForKey:@"present"];
        if ([self hasCheckBalance]) {
            [self alertChargeInsufficient];
        } else {
            [self showSuccessful:YES];
            [[SettingsHandler sharedHandler] processingSaleEnd];
        }
        
    }
}
-(void) processCCTransactions
{
    
    [self showProcessActivity];
    //NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    
    //Gather information to be entered
    //NSString *plu = selectedItem.plu;
    //NSString *idNumber = selectedIdNumber;
    
    //get reference number by taking refNumber and first letter of register code
    NSString *reference = [[SettingsHandler sharedHandler] getReference];
    [SettingsHandler sharedHandler].processingRef = reference;
    [[SettingsHandler sharedHandler] incrementReference];
    //OdinTransaction *transaction = [CoreDataService insertObjectForEntity:@"OdinTransaction" andContext:managedObjectContext];
    //fill out the transaction
    //NSMutableArray* transactions = [[SettingsHandler sharedHandler] getMultiTransactions];
    tranArray = [[NSMutableArray alloc]init];
    
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
        
        NSDecimalNumber *totalAmountNoTax = [amount decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithNumber:qty]];
        NSDecimalNumber *totalAmount = [OdinTransaction getTotalAmountFromQtyEntered:qty andAmountEntered:amount forItem:item];
        //check if the transaction is legal, and if the account has sufficient funds
        //processTransaciton is always called on a background thread since main thread is animating the activity indicator
        [self HUDshowMessage:@"Processing"];
#ifdef DEBUG
        NSLog(@"RV item %@ purchased by account %@ with ref: %@",plu,selectedIdNumber, reference);
#endif
        OdinTransaction *transaction = [CoreDataService insertObjectForEntity:@"OdinTransaction" andContext:self.moc];
        //fill out the transaction
        transaction.qty = qty;
        transaction.amount = totalAmount;
        transaction.id_number = [NSString stringWithFormat:@"CC%@",[ccProcess getCardLast4Digits]];//idNumber;//@"Credit/Debit Card";//selectedIdNumber;
        transaction.plu = plu;
        transaction.timeStamp = [NSDate localDate];
        transaction.sync = [NSNumber numberWithBool:FALSE];
        //total amount = amount + tax, so tax = totalAmount - amount
        transaction.tax_amount = [totalAmount decimalNumberBySubtracting:totalAmountNoTax];
        transaction.reference = reference;
        transaction.location = item.location;
        transaction.item = item.item;
        //version 2.6add glcode and dept_code
        transaction.operator = [[SettingsHandler sharedHandler] uid];//item.operator;
        transaction.dept_code = item.dept_code;
        transaction.glcode = item.glcode;
        transaction.payment = @"G";
        transaction.process_on_sync = item.process_on_sync;
        
        
        //Credit card
        transaction.cc_digit = [ccProcess getCardLast4Digits];
        transaction.cc_tranid = [ccProcess responseTransactionId];
        transaction.first = [ccProcess getCardFirstName];
        transaction.last = [ccProcess getCardLastName];
        transaction.cc_approval = [ccProcess responseApprovalCode];
        transaction.cc_timeStamp = [transaction.timeStamp convertDataToTimestamp];
        transaction.cc_responsetext = [ccProcess responseText];
        //Others
        transaction.qdate = [transaction.timeStamp asStringWithFormat:@"@YYYY-@MM-@DD"];
        transaction.time = [transaction.timeStamp asStringWithFormat:@"@hh:@mm:@ss"];
        transaction.school = [[SettingsHandler sharedHandler] school];
        transaction.type = @"Sale";
#ifdef DEBUG
        NSLog(@"digit %@", transaction.cc_digit);
        NSLog(@"tranid %@", transaction.cc_tranid);
        NSLog(@"first %@", transaction.first);
        NSLog(@"last %@", transaction.last);
        NSLog(@"approval %@", transaction.cc_approval);
#endif
        
        //[transactions addObject:transaction];
        [tranArray addObject:transaction];
    }
    [CoreDataService saveObjectsInContext:self.moc];
    
    [self hideActivity];
    [self clearCart];
    [[SettingsHandler sharedHandler] processingSaleEnd];
    [self showReceiptView];
    
    
    
}
-(void) postTransaction
{
#ifdef DEBUG
    NSLog(@"post transaction");
#endif
    //get reference number by taking refNumber and first letter of register code
    NSString *reference = [[SettingsHandler sharedHandler] getReference];
    [SettingsHandler sharedHandler].processingRef = reference;
    [[SettingsHandler sharedHandler] incrementReference];
    tranArray = [[NSMutableArray alloc]init];
    NSManagedObjectContext* moc = [CoreDataHelper getCoordinatorMOC];
    [moc performBlock:^{
        for(int j = 0; j < [self.cart count]; j++) {
            CartItem *itemInCart = [self.cart objectAtIndex:j];
            OdinEvent *item = [itemInCart item];
            
            //Gather information to be entered
            NSString *plu = item.plu;
            
            
            //calculate total amount, including tax
            NSNumber *qty = [NSNumber numberWithInt: [itemInCart count]];
            NSDecimalNumber *amount = [item amount];
            
            NSDecimalNumber *totalAmountNoTax = [amount decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithNumber:qty]];
            //TODO: should this be used?
            //NSDecimalNumber *tax = [item tax];
            
            NSDecimalNumber *totalAmount = [OdinTransaction getTotalAmountFromQtyEntered:qty andAmountEntered:amount forItem:item];
            //check if the transaction is legal, and if the account has sufficient funds
            //processTransaciton is always called on a background thread since main thread is animating the activity indicator
            [self performSelectorOnMainThread:@selector(showProcessing) withObject:nil waitUntilDone:NO];
#ifdef DEBUG
            NSLog(@"RV item %@ purchased by account %@ with ref: %@",plu,selectedIdNumber, reference);
#endif
            
            
            OdinTransaction *transaction = [CoreDataService insertObjectForEntity:@"OdinTransaction" andContext:moc];
            //fill out the transaction
            transaction.qty = qty;
            transaction.amount = totalAmount;
            transaction.id_number = selectedIdNumber;
            transaction.plu = plu;
            transaction.timeStamp = [NSDate localDate];
            transaction.sync = [NSNumber numberWithBool:FALSE];
            //total amount = amount + tax, so tax = totalAmount - amount
            transaction.tax_amount = [totalAmount decimalNumberBySubtracting:totalAmountNoTax];
            transaction.reference = reference;
            transaction.location = item.location;
            transaction.item = item.item;
            //version 2.6add glcode and dept_code
            transaction.operator = [[SettingsHandler sharedHandler] uid];//item.operator;
            transaction.dept_code = item.dept_code;
            transaction.glcode = item.glcode;
            transaction.payment = @"D";
            transaction.process_on_sync = item.process_on_sync;
            transaction.qdate = [transaction.timeStamp asStringWithFormat:@"@YYYY-@MM-@DD"];
            transaction.time = [transaction.timeStamp asStringWithFormat:@"@hh:@mm:@ss"];
            transaction.school = [SettingsHandler sharedHandler].school;
            transaction.type = @"Sale";
            
            transaction.cc_digit = nil;
            //save all changes to transaction
            [tranArray addObject:transaction];
        }
        [CoreDataService saveObjectsInContext:moc];
        [self showSuccessful:YES];
        [self cancelTimer];
        [self resetCart:nil];
        [[SettingsHandler sharedHandler] processingSaleEnd];
    }];
    
}

-(void) clearCart
{
    [UIView animateWithDuration:1 animations:^{
        darken.alpha = 0;
    } completion:^(BOOL finished) {
        popover.hidden = YES;
        nameLabel.text = @"";
        [self resetCart:nil];
    }];
}

#pragma mark - keyboard movements
- (void)keyboardWillShow:(NSNotification *)notification
{
    /*[UIView animateWithDuration:0.3 animations:^{
     CGRect f = darken.frame;
     f.origin.y = -100.0f;  //set the -35.0f to your required value
     darken.frame = f;
     }];*/
    int tableHeaderHeight = 22;
    int tableCellTotalHeight = cart.count * 43;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = tableView.frame;
        f.origin.y = tableInitialPoint.y-100.0f - tableHeaderHeight - tableCellTotalHeight;
        tableView.frame = f;
    }];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    /*[UIView animateWithDuration:0.3 animations:^{
     CGRect f = darken.frame;
     f.origin.y = 0.0f;
     darken.frame = f;
     }];*/
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = tableView.frame;
        f.origin.y = tableInitialPoint.y;
        tableView.frame = f;
    }];
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

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [IDTextField resignFirstResponder];
    return  YES;
}

-(IBAction)hidePopover:(id)sender
{
    [UIView beginAnimations:@"fade-out" context:NULL];
    [UIView setAnimationDuration:0.4];
    darken.alpha = 0;
    [UIView commitAnimations];
    popover.hidden = YES;
    //	selectedIdNumber = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.IDTextField.text = @"";
        self.tableView.backgroundColor = [UIColor whiteColor];
        //        [self.tableView setContentOffset:CGPointZero animated:YES];
        //        [self.IDTextField resignFirstResponder];
    });
    
    //move table back to top
    //
    //int tableHeaderHeight = 22;
    //popover.center = CGPointMake(popover.center.x, popoverInitialPoint.y
    //							 + (self.cart.count * 43) + tableHeaderHeight);
    //	[UIView animateWithDuration:0.3 animations:^{
    //		CGRect f = tableView.frame;
    //		f.origin.y = tableInitialPoint.y;
    //		tableView.frame = f;
    //	}];
}
//#pragma mark - Alert
//-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//
//	//u need to change 0 to other value(,1,2,3) if u have more buttons.then u can check which button was pressed.
//#ifdef DEBUG
//	NSLog(@"Management Alert Button Pressed");
//#endif
//	NSString* title = alertView.title;
//
//	//Announce Alert View is Dismissed
//	if ([title isEqualToString:TRANSACTION_ERROR]) {
//		if (buttonIndex == 0) {
//			//Run verify past transaction
//			[self showReceiptView];
//		}
//	}
//
//}


#pragma mark - Alert
-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    //u need to change 0 to other value(,1,2,3) if u have more buttons.then u can check which button was pressed.
#ifdef DEBUG
    NSLog(@"Register Alert Button Pressed %@",alertView.title);
#endif
    NSString* title = alertView.title;
    SettingsHandler* setting = [SettingsHandler sharedHandler];
    //Announce Alert View is Dismissed
    if ([title isEqualToString:TRANSACTION_ERROR]) {
        if (buttonIndex == 0) {
            //Run verify past transaction
            [self showReceiptView];
        }
    } else if ([alertView.title hasPrefix:PROCESS_OFFLINE_FUNDS] ||
               [alertView.title hasPrefix:PROCESS_INSUFFICIENT_FUNDS]) {
        NSString* processsingRef = [SettingsHandler sharedHandler].getReference;
        //        OdinTransaction* curTran = [OdinTransaction getTransactionByReference:processsingRef];
        //        if (curTran) {
        
        
        if (buttonIndex == 0) { //Cancel
            //                if (setting.isProcessingSale) {
            //                    NSString* message = [NSString stringWithFormat:@"Cancelled %@ Failed", processsingRef];
            
            //-transaction is cancelled. we can go ahead and deleted last transaction
            //                    if ([curTran deleteCurrentTransaction]) {
            //                    [[SettingsHandler sharedHandler] decrementReference];
            NSString* message = [NSString stringWithFormat:@"Cancelled %@",processsingRef];
            //                    }
            [self HUDshowMessage:message];
            [self hideActivity];
            [setting processingSaleEnd];
        } else {
            //--check if it is still processing sales and if user wants to process offline funds
            //--If it is still processing, tell sale processing is done, so when connection is completed it will do nothing
            //                if (setting.isProcessingSale) {
            //--finish up sale
            //--upload transaction if needed
            
            [self performSelectorInBackground:@selector(postTransaction) withObject:nil];
            
        }
    }
    
}
-(void)cancelTimer
{
    if (myTimer) {
#ifdef DEBUG
        //    NSLog(@"FV: myTimerStart");
        //        [self HUDshowMessage:@"timer cancelled"];
#endif
        [myTimer invalidate];
        myTimer = nil;
    }
}
-(void)myTimerStartWithID:(NSString*)idnumber reference:(NSString*)reference
{
#ifdef DEBUG
    NSLog(@"FV: myTimerStart");
#endif
    if ([NetworkConnection isInternetOffline]) {
        return;
    }
    //    if (myTimer == nil) {
    //        myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(callAfterTenSeconds:) userInfo:nil repeats:NO];
    //        [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(callAfterTenSeconds) userInfo:nil repeats:NO];
    
    //    }
    //    dispatch_async(dispatch_get_main_queue(), ^{
    
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.001 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
    
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    //        [self performSelector:@selector(callAfterTenSeconds) withObject:nil afterDelay:1];
    //    });
    
#ifdef DEBUG
    //    NSLog(@"FV: myTimerStart");
    [self HUDshowMessage:@"Start timer"];
#endif
    NSString* copyIdnumber = [NSString stringWithFormat:@"%@",idnumber];
    myTimer = [NSTimer timerWithTimeInterval:10.0 target:self selector:@selector(callAfterTenSeconds:) userInfo:@{@"idnumber":copyIdnumber, @"reference":reference} repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:myTimer forMode:NSDefaultRunLoopMode];
    
#ifdef DEBUG
    //    NSLog(@"FV: myTimerStart");
    [self HUDshowMessage:@"timer created"];
#endif
    //    NSTimer* timer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(callAfterTenSeconds) userInfo:nil repeats:NO];
    //    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}
-(void) callAfterTenSeconds
{
    
#ifdef DEBUG
    NSLog(@"FV: callAfterTenSeconds");
    [self HUDshowMessage:@"call after then seconds"];
#endif
    
    MBProgressHUD* hud = [HUDsingleton  sharedHUD];
    if (hud != nil && hud.alpha > 0) {
        
        //            [hud hide:NO];
        if ([self hasCheckBalance]) {
            [self HUDshowMessage:@"show charge offline"];
            [NSThread detachNewThreadSelector:@selector(alertChargeInsufficient) toTarget:self withObject:nil];
        } else {
            [self showSuccessful:true];
        }
        
        //        [self alertChargeInsufficient];
    }
    //    myTimer = nil;
}

-(void) alertChargeInsufficient
{
    
#ifdef DEBUG
    NSLog(@"alertChargeInsufficient %@ %@",PROCESS_INSUFFICIENT_FUNDS,selectedIdNumber);
#endif
    [self cancelTimer];
    
    NSDictionary* student = [OdinStudent getStudentOfflineInfoForID:selectedIdNumber andMOC:managedObjectContext];
    
    //    NSNumber* funds = [student objectForKey:@"present"];
    NSString* idNumber = [student objectForKey:@"id_number"];
    NSString* titleMsg = [AuthenticationStation sharedHandler].isOnline ? PROCESS_INSUFFICIENT_FUNDS : PROCESS_OFFLINE_FUNDS;
    
    NSDecimalNumber* funds = [student objectForKey:@"present"];
    NSString* title = [NSString stringWithFormat:@"%@ \n[%@]",titleMsg,[SettingsHandler sharedHandler].getReference];
    NSString* message = [NSString stringWithFormat:@"%@ has funds:$%.2f?",idNumber, funds.doubleValue];
    if ([SettingsHandler sharedHandler].allowOverride) {
        alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    } else {
        alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    }
    
    
#ifdef DEBUG
    NSLog(@"Remove HUD and show alert for student %@",selectedIdNumber);
#endif
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([SettingsHandler sharedHandler].isProcessingSale) {
            [alert show];
        }
    });
}
-(void) callAfterTenSeconds:(NSNotification*)notification
{
    
#ifdef DEBUG
    NSLog(@"notify callAfterTenSeconds %@",selectedIdNumber);
#endif
    NSDictionary* userInfo = notification.userInfo;
    NSString* idnumber = userInfo[@"idnumber"];
    NSString* reference = userInfo[@"reference"];
    
    
    if ([SettingsHandler sharedHandler].isProcessingSale &&
        [reference compareReference:[SettingsHandler sharedHandler].processingRef]) {
        
        if ([self hasCheckBalance] == false) {
            [self showSuccessful:true];
            [[SettingsHandler sharedHandler] processingSaleEnd];
            return;
        } else {
            MBProgressHUD* hud = [HUDsingleton  sharedHUD];
            if ((hud != nil && hud.alpha > 0) && [selectedIdNumber isEqualToString: idnumber]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSDictionary* student = [OdinStudent getStudentOfflineInfoForID:idnumber andMOC:managedObjectContext];
                    
#ifdef DEBUG
                    NSLog(@"callAfterTenSeconds %@ %@ student:%@",PROCESS_OFFLINE_FUNDS,idnumber,student);
#endif
                    
                    NSNumber* funds = [student objectForKey:@"present"];
                    NSString* idNumber = [student objectForKey:@"id_number"];
                    NSString* title = [NSString stringWithFormat:@"%@ [%@]",PROCESS_OFFLINE_FUNDS,reference];
                    NSString* message = [NSString stringWithFormat:@"Charge %@ offline funds:%@?",idNumber, funds];
#ifdef DEBUG
                    message = [NSString stringWithFormat:@"FV: Charge %@ offline funds:%@? Item:%@ CB:%i",idNumber, funds,@"ODIN CART",[self hasCheckBalance]];
#endif
                    alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
                    
                    //            NSString* cur = [SettingsHandler sharedHandler].currentReference; {
                    
                    [self hideActivity];
                    
                    [alert show];
                    
                });
            }
        }
        
    }
    //[self updateManageBadge];
    //    myTimer = nil;
}
-(void)dismissAlert
{
#ifdef DEBUG
    NSLog(@"dismissConnectingAlert %@",alert.title);
#endif
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [alert dismissWithClickedButtonIndex:alert.cancelButtonIndex animated:YES];
    });
}

-(void)dismissAlert:(NSNotification*)notification
{
#ifdef DEBUG
    NSLog(@"notify dismissConnectingAlert %@",alert.title);
#endif
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [alert dismissWithClickedButtonIndex:alert.cancelButtonIndex animated:YES];
    });
    
    
}@end

