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

#import <Foundation/Foundation.h>
#import "FirstVC.h"
#import "OdinEvent.h"
#import "OdinTransaction+Methods.h"
#import "OdinStudent.h"
//#import "MBProgressHUD.h"
#import "SynchronizationOperation.h"
#import "StudentUpdate.h"
#import "NSString+hackXML.h"
#import "NetworkConnection.h"
#import "ReceiptVC.h"
@interface FirstVC ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) IBOutlet UIButton *processButton;
@property (nonatomic, strong) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) IBOutlet UILabel *refLabel;
@property (nonatomic, strong) IBOutlet UILabel *dollarLabel;
@property (weak, nonatomic) IBOutlet UILabel *studentNameLabel;
@property (nonatomic, strong) IBOutlet UIPickerView *itemPicker;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UITextField *amtTextBox;
@property (nonatomic, strong) IBOutlet UITextField *qtyTextBox;
@property (nonatomic, strong) IBOutlet UITextField *studentIdTextBox;
@property (weak, nonatomic) IBOutlet UIButton *idButton;
@property (nonatomic, strong) NSArray *itemArrayForPicker;
//@property (nonatomic, strong) NSArray *transactionJobArray;
@property (nonatomic, strong) OdinEvent *selectedItem;
@property (nonatomic, strong) NSString *selectedIdNumber;
@property (nonatomic, strong) UITextField *activeField;

//BOOL flag that makes sure certain methods run only the first time this view is shown
@property (nonatomic) BOOL didAskForStudents;
@property (nonatomic, strong) CardProcessor *ccProcess;
@property (nonatomic) Patron* patronVC;


-(IBAction) backgroundTap;
-(IBAction) enterTransaction;

@end

@implementation FirstVC

@synthesize studentIdTextBox,amtTextBox,qtyTextBox;
@synthesize managedObjectContext;
@synthesize scrollView,activeField, dollarLabel, refLabel;
@synthesize itemPicker, itemArrayForPicker, selectedIdNumber, selectedItem;
@synthesize didAskForStudents;
@synthesize processButton;
@synthesize ccProcess;
@synthesize versionLabel, studentNameLabel, idButton;
@synthesize queue,patronVC;
//NSString* responseString = @"";
NSMutableArray* transArray;
NSTimer* myTimer;
UIAlertView* alert;

//NSString *currentReference;



#define CC_TRANSACTION_ERROR @"Credit Card Transaction Error"
#define PROCESS_OFFLINE_FUNDS @"Process offline funds"
#define PROCESS_INSUFFICIENT_FUNDS @"Process insufficient funds"
#define HAS_FUNDS @"Current Funds"

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}
-(void) showReceiptView
{
    //Load Receipt view
    dispatch_async(dispatch_get_main_queue(), ^{
        //your code here
        ReceiptVC *rvc  = [self.storyboard instantiateViewControllerWithIdentifier:@"ReceiptVC"];
        rvc.transArray = transArray;
        rvc.type = @"Sale";
        [self presentViewController:rvc animated:YES completion:nil];
    });
}

#pragma mark - transaction methods
-(void)resetInput
{
    qtyTextBox.text = @"";
    amtTextBox.text = @"";
    studentIdTextBox.text = @"";
    //    processButton.enabled = NO;
    amtTextBox.enabled = NO;
    qtyTextBox.enabled = NO;
    studentIdTextBox.enabled = NO;
    amtTextBox.backgroundColor = [UIColor grayColor];
    qtyTextBox.backgroundColor = [UIColor grayColor];
    studentIdTextBox.backgroundColor = [UIColor grayColor];
    dollarLabel.text = @"$";
    studentNameLabel.text = @"";
    idButton.enabled = NO;
    idButton.backgroundColor = idButton.enabled ? processButton.backgroundColor : [UIColor grayColor];
}
//Checks input for errors
-(BOOL)inputChecksOut
{
#ifdef DEBUG
    NSLog(@"inputerchecksout");
#endif
    //checks if fields are empty
    if(([[qtyTextBox text] isEqualToString:@""])
       || ([[amtTextBox text] isEqualToString:@""]))
        //|| ([[studentIdTextBox text] isEqualToString:@""]))
    {
        [ErrorAlert emptyFieldError];
        if ([HUDsingleton sharedHUD].isOpaque) {
            [[HUDsingleton sharedHUD] hide:YES afterDelay:2];
        }
        //		[alert emptyField:self.view];
        return NO;
    }
    
    if([[qtyTextBox text] containsNonDecimalNumbers])
    {
        [ErrorAlert invalidQuantity];
        return NO;
    }
    if ([amtTextBox.text containsNonNumbers])
    {
        //[ErrorAlert retailInvalid];
        [ErrorAlert invalidRetail];
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
        //[ErrorAlert cannotEditItem:@"quantity"];
        [ErrorAlert cannotEditItem:@"quantity"];
        return NO;
    }
    //checks if amount has been changed from the default, shows error if not allowed
    if (([selectedItem.allow_amount boolValue] == FALSE)
        && ([amountTextAsNumber floatValue] != [defaultAmount floatValue])
        && !selectedItem.taxable)
    {
        //[ErrorErrorAlert cannotEditItem:@"retail amount"];
        [ErrorAlert cannotEditItem:@"retail amount"];
        return NO;
    }
    return YES;
}

//Button call from "Process Sale" button
- (IBAction) enterTransaction
{
#ifdef DEBUG
    NSLog(@"Enter Transaction");
#endif
    
    if (!selectedItem) {
        //alert user to select an item
        //[ErrorAlert simpleAlertTitle:@"No Item" message:@"Please select an item"];
        [ErrorAlert noItemSelected];
        return;
    }
    if ([selectedItem.allow_manual_id boolValue] == TRUE) {
        
        //		dispatch_async(dispatch_get_main_queue(), ^{
        NSString* idNumber = studentIdTextBox.text;
        selectedIdNumber = [idNumber checkExportID];
        studentIdTextBox.text = selectedIdNumber;
        [activeField resignFirstResponder];
        //		});
        [self performSelectorInBackground:@selector(beginTransaction) withObject:nil];
        //        [self beginTransaction];
    } else if ([studentIdTextBox.text isEqualToString:@""]){
        [ErrorAlert noStudentEntre];
    }
    else {
        [ErrorAlert cardPresentAlert];
    }
}

//beginning of fragmented transaction methods
//broken up for purposes of activity indicator

-(void) beginTransaction
{
    //moved [self inputChecksOut] here because app would crash if fields were left blank
#ifdef DEBUG
    NSLog(@"beginTransaction");
#endif
    if ([self inputChecksOut] && [OdinStudent getStudentByIDnumber:studentIdTextBox.text]) {
        
        [self showProcessActivity];
        
        [[SettingsHandler sharedHandler] processingSaleStart];
        
        
        //Gather information to be entered
        NSString *plu = selectedItem.plu;
        NSString *idNumber = selectedIdNumber;
        //calculate total amount, including tax
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        NSNumber *qty = [numberFormatter numberFromString:[qtyTextBox text]];
        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[amtTextBox text]];
        
        //NSDecimalNumber *tax = selectedItem.tax;
        
        NSDecimalNumber *totalAmount = [OdinTransaction getTotalAmountFromQtyEntered:qty andAmountEntered:amount forItem:selectedItem];
        
        //get reference number by taking refNumber and first letter of register code
        
        [self myTimerStartWithID:idNumber];
        
        //--get online balance here
        NSDictionary* student = [OdinStudent getStudentInfoForID:idNumber andMOC:[CoreDataHelper getMainMOC]];
        
#ifdef DEBUG
        NSLog(@"student balance is %@",[student objectForKey:@"present"]);
#endif
        if([TestIf account:student canPurchaseItem:selectedItem forAmount:totalAmount])
        {
            [self postTransaction];
        } else
        {
            NSNumber* funds = [student objectForKey:@"present"];
            if (selectedItem.chk_balance.boolValue) {
                [self alertChargeInsufficient];
            }
            else {
                [self postTransaction];
            }
        }
    } else {
        [ErrorAlert studentNotFound:selectedIdNumber];
        [self hideActivity];
        [[SettingsHandler sharedHandler] processingSaleEnd];
    }
    
#ifdef DEBUG
    NSLog(@"beginTransaction Closing");
#endif
}
-(void)postTransaction
{
    //processTransaciton is always called on a background thread since main thread is animating the activity indicator
    
    NSString *reference = [[SettingsHandler sharedHandler] getReference];
    [SettingsHandler sharedHandler].processingRef = reference;
    //        [SettingsHandler sharedHandler].ProcessingRef = reference;
    [[SettingsHandler sharedHandler] incrementReference];
    
#ifdef DEBUG
    NSLog(@"Wrapped up working:%@  current:%@ isprocessing:%i isinternt:%i %i %i",reference,
          [SettingsHandler sharedHandler].processingRef,
          [NetworkConnection isInternetOnline],
          [SettingsHandler sharedHandler].isProcessingSale,
          [SettingsHandler sharedHandler].holdTransactions,
          [AuthenticationStation sharedHandler].isOnline);
#endif
    //calculate total amount, including tax
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    NSNumber *qty = [numberFormatter numberFromString:[qtyTextBox text]];
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[amtTextBox text]];
    NSDecimalNumber *totalAmountNoTax = [amount decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithNumber:qty]];
    
    //NSDecimalNumber *tax = selectedItem.tax;
    
    NSDecimalNumber *totalAmount = [OdinTransaction getTotalAmountFromQtyEntered:qty andAmountEntered:amount forItem:selectedItem];
    
    NSManagedObjectContext* moc = [CoreDataHelper getCoordinatorMOC];
    
    [moc performBlock:^{
        OdinTransaction *transaction = [CoreDataService insertObjectForEntity:@"OdinTransaction" andContext:moc];
        //fill out the transaction
        transaction.qty = qty;
        transaction.amount = totalAmount;
        transaction.id_number = selectedIdNumber;
        transaction.plu = selectedItem.plu;
        transaction.timeStamp = [NSDate localDate];
        transaction.sync = [NSNumber numberWithBool:FALSE];
        //total amount = amount + tax, so tax = totalAmount - amount
        transaction.tax_amount = [totalAmount decimalNumberBySubtracting:totalAmountNoTax];
        transaction.reference = reference;
        transaction.location = selectedItem.location;
        transaction.item = selectedItem.item;
        //version 2.6add glcode and dept_code
        transaction.glcode = selectedItem.glcode;
        transaction.dept_code = selectedItem.dept_code;
        transaction.operator = [[SettingsHandler sharedHandler] uid];
        transaction.payment = @"D";
        //			transaction.tax_amount = [NSDecimalNumber decimalNumberWithString:@"0.00"];
        transaction.process_on_sync = selectedItem.process_on_sync;
        transaction.qdate = [transaction.timeStamp asStringWithFormat:@"@YYYY-@MM-@DD"];
        transaction.time = [transaction.timeStamp asStringWithFormat:@"@hh:@mm:@ss"];
        
#ifdef DEBUG
        NSLog(@"Transaction %@ date %@ and time %@",reference, transaction.qdate, transaction.time);
#endif
        transaction.school = [SettingsHandler sharedHandler].school;
        
        transaction.cc_digit = nil;
        transaction.type = @"Sale";
        
        [CoreDataService saveObjectsInContext:moc];
        [self showSuccessful:true];
        [self cancelTimer];
        [[SettingsHandler sharedHandler] processingSaleEnd];
    }];
    
    
}


//Transaction successfully charged. Need to post to MKS or into Pending. Transaction is built as un-sync. If it successfully posted, it will update sync, which moves transaction to Past.
-(void)processCCTransaction
{
    //	MBProgressHUD* hud = [HUDsingleton sharedHUD].HUD;
    //	hud.mode = MBProgressHUDModeIndeterminate;
    //	hud.labelText = @"Sending";
    //	[hud show:true];
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    NSNumber *qty = [numberFormatter numberFromString:[qtyTextBox text]];
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[amtTextBox text]];
    NSString *reference = [[SettingsHandler sharedHandler] getReference];
    [[SettingsHandler sharedHandler] incrementReference];
    [SettingsHandler sharedHandler].processingRef = reference;
    NSDecimalNumber *totalAmountNoTax = [amount decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithNumber:qty]];
    NSDecimalNumber *totalAmount = [OdinTransaction getTotalAmountFromQtyEntered:qty andAmountEntered:amount forItem:selectedItem];
    
    //Create a new transaction data
    
    NSManagedObjectContext* moc = [CoreDataHelper getMainMOC];
    
    OdinTransaction *transaction = [CoreDataService insertObjectForEntity:@"OdinTransaction" andContext:moc];
    //fill out the transaction
    transaction.qty = qty;
    transaction.amount = totalAmount;
    transaction.id_number = [NSString stringWithFormat:@"CC%@",[ccProcess getCardLast4Digits]];//idNumber;
    transaction.plu = selectedItem.plu;
    transaction.timeStamp = [NSDate localDate];
    transaction.sync = [NSNumber numberWithBool:FALSE];
    //total amount = amount + tax, so tax = totalAmount - amount
    transaction.tax_amount = [totalAmount decimalNumberBySubtracting:totalAmountNoTax];
    transaction.reference = reference;
    transaction.location = selectedItem.location;
    transaction.item = selectedItem.item;
    //version 2.6 add glcode and dept_code
    transaction.glcode = selectedItem.glcode;
    transaction.dept_code = selectedItem.dept_code;
    transaction.operator = [[SettingsHandler sharedHandler] uid];
    transaction.payment = @"G";
    transaction.process_on_sync = selectedItem.process_on_sync;
    //transaction.tax_amount = [NSDecimalNumber decimalNumberWithString:@"0.00"];
    
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
    
    [CoreDataService saveObjectsInContext:moc];
    
    transArray = [[NSMutableArray alloc]initWithObjects:transaction, nil];
    
    [self hideActivity];
    [[SettingsHandler sharedHandler] processingSaleEnd];
    [self showReceiptView];
    
    
}
#pragma mark - Search Student
-(IBAction)showPatron:(id)sender
{
    if (!patronVC) {
        //        patronVC = [[Patron alloc] initWithSourceView:self.view];
        patronVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PatronVC"];
        [self presentViewController:patronVC animated:YES completion:nil];
        patronVC.delegate = self;
        [activeField resignFirstResponder];
        self.tabBarController.tabBar.hidden = true;
    }
}
-(void)closePatron:(OdinStudent *)student
{
#ifdef DEBUG
    NSLog(@"CLOSE PATRON %@",student.student);
#endif
    if (patronVC) {
        if (student) {
            studentIdTextBox.text = student.id_number;
            NSString* name = [NSString stringWithFormat:@"%@ %@",
                              [NSString printName:student.student],
                              [NSString printName:student.last_name]];
            studentNameLabel.text = name;
        }
        
        [patronVC dismissViewControllerAnimated:YES completion:^{
#ifdef DEBUG
            NSLog(@"remove patron from parent");
#endif
        }];
    }
    patronVC = nil;
    self.tabBarController.tabBar.hidden = false;
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
    if ([textField isEqual:studentIdTextBox]) {
        studentNameLabel.text = @"";
    }
    activeField = nil;
    
}
-(BOOL)textFieldShouldClear:(UITextField *)textField
{
#ifdef DEBUG
    NSLog(@"clear textfield");
#endif
    if ([textField isEqual:studentIdTextBox]) {
        studentNameLabel.text = @"";
    }
    return true;
    
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //itemArrayForPicker = nil;
        [self loadItemsForPicker];
        qtyTextBox.text = @"";
        amtTextBox.text = @"";
        selectedItem = nil;
    });
}

//gets items from Core Data, loads names into Picker
-(void)loadItemsForPicker
{
    NSManagedObjectContext* moc = [CoreDataHelper getMainMOC];
    itemArrayForPicker = [CoreDataService getObjectsForEntity:@"OdinEvent"
                                                  withSortKey:@"item"
                                             andSortAscending:YES
                                                   andContext:moc];
    
    //    dispatch_async(dispatch_get_main_queue(), ^{
    [itemPicker reloadAllComponents];
    if (selectedItem.plu)
    {
//        qtyTextBox.text = [NSString stringWithFormat:@"%@",selectedItem.qty];
        //            amtTextBox.text = [NSString stringWithFormat:@"%@",selectedItem.amount];
        
        NSDecimalNumber* totalAmountWithTax = [OdinTransaction getTotalAmountFromQtyEntered:selectedItem.qty andAmountEntered:selectedItem.amount forItem:selectedItem];
//        amtTextBox.text = [NSString stringWithFormat:@"%.2f",totalAmountWithTax.floatValue];
    }
    
    //    });
    
#ifdef DEBUG
    NSLog(@"selectedItem: %@ student: %@", selectedItem, selectedIdNumber);
#endif
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
            [self resetInput];
            selectedItem = nil;
        }
        else
        {
            //            processButton.enabled = YES;
            selectedItem = [itemArrayForPicker objectAtIndex:(row - 1)];
            //uses row-1 since first row is reserved for "ITEM LIST" placeholder
            qtyTextBox.text = [NSString stringWithFormat:@"%@",selectedItem.qty];
            
            //            if (selectedItem.taxable.boolValue) {
            NSNumber* qty = [NSNumber numberWithInt:1]; //this is always one because we only tally up one item
            NSDecimalNumber* amountEntered = selectedItem.amount;
            NSDecimalNumber* totalAmountWithTax = [OdinTransaction getTotalAmountFromQtyEntered:qty andAmountEntered:amountEntered forItem:selectedItem];
            
            dollarLabel.text = selectedItem.taxable.boolValue ?  @"Taxed $:" : @"$:";
            amtTextBox.text = [NSString stringWithFormat:@"%.2f",totalAmountWithTax.floatValue];
            amtTextBox.enabled = selectedItem.allow_amount.boolValue;
            amtTextBox.backgroundColor = amtTextBox.enabled ? [UIColor whiteColor]:[UIColor grayColor];
            qtyTextBox.enabled = selectedItem.allow_qty.boolValue;
            qtyTextBox.backgroundColor = qtyTextBox.enabled ? [UIColor whiteColor]:[UIColor grayColor];
            studentIdTextBox.enabled = selectedItem.allow_manual_id.boolValue;
            studentIdTextBox.backgroundColor = studentIdTextBox.enabled ? [UIColor whiteColor]:[UIColor grayColor];
            idButton.enabled = selectedItem.allow_manual_id.boolValue;
            idButton.backgroundColor = idButton.enabled ? processButton.backgroundColor : [UIColor grayColor];
            
#ifdef DEBUG
            NSLog([NSString stringWithFormat: @"picker selected item %@ %@ %@ edit:%@ manual:%@", selectedItem.item, selectedItem.amount, selectedItem.qty, selectedItem.allow_edit, selectedItem.allow_manual_id]);
#endif
            
        }
    }
}

#pragma mark - Linea Delegate calls


//Fires when a barcode is scanned
-(void) barcodeData:(NSString *)barcode type:(int)type
{
    //check exportid and adjust barcode if using exportID
#ifdef DEBUG
    NSLog(@"process barcodeData %@", barcode);
#endif
    
    if (!selectedItem) {
        //alert user to select an item
        //[ErrorAlert simpleAlertTitle:@"No Item" message:@"Please select an item"];
        [[DTDevices sharedDevice] badBeep];
        [ErrorAlert noItemSelected];
        return;
    }
    
    if ([SettingsHandler sharedHandler].isProcessingSale) {
        [[DTDevices sharedDevice] badBeep];
        return;
    }
    [[SettingsHandler sharedHandler] processingSaleStart];
    [self showProcessActivity];
    //    [self performSelectorOnMainThread:@selector(showProcessActivity) withObject:nil waitUntilDone:YES];
    //	[self processScannedData:barcode];
    [self performSelectorInBackground:@selector(processScannedData:) withObject:barcode];
    //	[[SettingsHandler sharedHandler] processingSaleEnd];
}

//fires when a swipe card is used
//Swipe expired card on test server returns SUCCESS
-(void)magneticCardData:(NSString *)track1 track2:(NSString *)track2 track3:(NSString *)track3
{
    NSLog(@"\n\nTrack 1:%@\n\nTrack 2:%@\n\nTrack 3:%@\n\n",track1,track2,track3);
    
    studentIdTextBox.text = @"";
    if ([SettingsHandler sharedHandler].isProcessingSale) {
        [[DTDevices sharedDevice] badBeep];
        return;
    }
    
    NSString *magneticData = [NSString stringWithFormat:@"%@",track2];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    
    //calculate total amount, including tax
    NSNumber *qty = [numberFormatter numberFromString:[qtyTextBox text]];
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[amtTextBox text]];
    if ([NetworkConnection isInternetOffline]) {
        //[ErrorAlert simpleAlertTitle:@"No Connection" message:@"Please check your Wifi or data service is turned on"];
        [ErrorAlert noInternetConnection];
        return;
    }else if (!selectedItem) {
        //Alert user to select an item
        //[ErrorAlert simpleAlertTitle:@"No Item" message:@"Please select an item"];
        [ErrorAlert noItemSelected];
        return;
    } else if ([amount floatValue] <= 0.0) {
        //Alert user to select item doesn't need to pay
        //		[ErrorAlert simpleAlertTitle:@"No Cost"
        //							 message:[NSString stringWithFormat:@"Selected item cost $%.2f. Doesn't need to pay",[amount floatValue]]];
        
        [ErrorAlert noCost];
        return;
    }
    
    if (track1.length > 0 && track2.length > 0) {
        if ([track1 hasPrefix:@"%B"] && [track1 hasSuffix:@"?"] && [track2 hasPrefix:@";"] && [track2 hasSuffix:@"?"]) { //credit card
            //card smith
            //-- use export id
            //-- StMarks use the last 6 digits on track1 for id (make sure export id is on)
            if ([track1 hasPrefix:@"%B603950"]) { //process as card smith
                NSString* idnumber = [track1 getStMarkExportID];
                
#if DEBUG
                NSLog(@"track1 StMark id %@",idnumber);
                
#endif
                
                if ([SettingsHandler sharedHandler].isProcessingSale) { return; }
                [[SettingsHandler sharedHandler] processingSaleStart];
                [self showProcessActivity];
                //                [self performSelectorOnMainThread:@selector(showProcessActivity) withObject:nil waitUntilDone:YES];
                [self processScannedData:idnumber];
                //                [self performSelectorInBackground:@selector(processScannedData:) withObject:idnumber];
                //                [[SettingsHandler sharedHandler] processingSaleEnd];
                //                [self barcodeData:idnumber isotype:BAR_ALL];
            } else { //process as credit card
                [self initCC:magneticData];
            }
            
            
        }
    } else if (track1.length > 0) {
        if ([track1 hasPrefix:@"$B"]) {
            [self barcodeData:track1 type:BAR_ALL];
        }
    } else if (track2.length > 0) {
        if ([track1 hasPrefix:@"$B"]) {
            [self barcodeData:track2 type:BAR_ALL];
        }
        
    } else {
        [ErrorAlert simpleAlertTitle:@"Unable to read track" message:[NSString stringWithFormat:@"track1:%@ \ntrack2:%@",track1,track2]];
    }
    
}
-(void)initCC:(NSString*) magneticData {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    NSNumber *qty = [numberFormatter numberFromString:[qtyTextBox text]];
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[amtTextBox text]];
    
    //get reference number by taking refNumber and first letter of register code
    NSString *reference = [[SettingsHandler sharedHandler] getReference];
    NSString *orderID = [[NSNumber numberWithInt:arc4random()%89999999 + 10000000] stringValue];
    
    ccProcess = [CardProcessor initialize:magneticData];
    if (ccProcess == nil ) {return;}
    [ccProcess setTransactionAmount:[amount stringValue]];
    
    //TODO: change descrition to school name
    NSString* schoolname = [SettingsHandler sharedHandler].school;
    [ccProcess setTransactionDesc:[NSString stringWithFormat:@"%@ %@",schoolname,reference]];
    [ccProcess setTransactionId:[reference stringByAppendingString:orderID]];
    [ccProcess setInvoiceNumber:[reference stringByAppendingString:orderID]];
#ifdef DEBUG
    NSLog(@"trans ID: %@",[reference stringByAppendingString:orderID]);
#endif
    
    //Charge the transaction
    if ([ccProcess makePurchase] && [ccProcess getCardLast4Digits]) {
        [[SettingsHandler sharedHandler] processingSaleStart];
        //        [self performSelectorOnMainThread:@selector(showProcessActivity) withObject:nil waitUntilDone:YES];
        [self showProcessActivity];
        [self processCCTransaction];
        //        [self performSelectorInBackground:@selector(processCCTransaction) withObject:nil];
    }
}

-(void)processScannedData:(NSString *)dataToProcess
{
#ifdef DEBUG
    NSLog(@"FV processScannedData: %@",dataToProcess);
#endif
    //handles matching exportID to ID
    //#ifdef DEBUG
    //    NSLog(@"using fake export id");
    //    NSString *idNumber = [@"3725" checkExportID];
    //#else
    
    //    dispatch_async(dispatch_get_main_queue(), ^{
    self.studentIdTextBox.text = dataToProcess;
    //    });
    
    NSString* idNumber = [dataToProcess cleanBarcode];
    selectedIdNumber = [idNumber checkExportID];
    if (selectedIdNumber == nil) {
        [ErrorAlert simpleAlertTitle:@"Export ID not found!" message:idNumber];
        [[SettingsHandler sharedHandler] processingSaleEnd];
        [self hideActivity];
        return;
    }
    
    //    dispatch_async(dispatch_get_main_queue(), ^{
    self.studentIdTextBox.text = selectedIdNumber;
    //    });
    [self beginTransaction];
}

#pragma mark - Auth Methods

//method to Authorize the app only once on startup
- (void) initialAuth
{
    if ([[AuthenticationStation sharedHandler] isOnline])
    {
        [self showCacheActivity];
        [[HUDsingleton sharedHUD] showWhileExecuting:@selector(doInitialAuth) onTarget:self withObject:nil animated:YES];
    }
}

- (void) doInitialAuth
{
    [[AuthenticationStation sharedHandler] doAuth];
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

//#pragma mark - XML parser
//-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
//    responseString = string;
//}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    //adds decimal place to the keyboard for $ amount text field
    amtTextBox.keyboardType = UIKeyboardTypeDecimalPad;
    itemPicker.showsSelectionIndicator = YES;
    //    processButton.enabled = NO;
    //get managedObjectContext from AppDelegate
    if (managedObjectContext == nil)
    {
        managedObjectContext = [CoreDataService getMainMOC];
    }
    queue = [OdinOperationQueue sharedHandler];
    [self resetInput];
    //    [SettingsHandler sharedHandler].isProcessingSale = false;
    [[AuthenticationStation sharedHandler] endAuth];
    NSString *deviceDetail = @"Version: ";
    //    deviceDetail = [deviceDetail stringByAppendingString:@"Version: " ];
    deviceDetail = [deviceDetail stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [versionLabel setText:deviceDetail];
    //    [versionLabel setFont:[UIFont fontWithName:@"Helvetica" size:12.0]];
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
    //	[[NSNotificationCenter defaultCenter] addObserver:self
    //											 selector:@selector(refreshLinea)
    //												 name:@"refreshLinea"
    //											   object:nil];
    //clears/reloads the picker when ManagedObjectContext saves. Prevents locking the picker/corrupting data
    //    [[NSNotificationCenter defaultCenter] addObserver:self
    //                                             selector:@selector(clearPicker)
    //                                                 name:NSManagedObjectContextWillSaveNotification
    //                                               object:managedObjectContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadItemsForPicker)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:managedObjectContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showSuccessRecall:)
                                                 name:@"showHUDPostStatus"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissAlert)
                                                 name:@"dismissAlert"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callAfterTenSeconds)
                                                 name:@"callAfterTenSeconds"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateReferenceLabel)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    
    NSLog(@"first");
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
#ifdef DEBUG
#endif
    [self refreshLinea];
    
    //turn off idle timer so the iPod does not go to sleep while they're scanning cards
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    
    //initial setup on first boot. Authorize uid/serial and ask to download students
    if ([[AuthenticationStation sharedHandler] didInitialSync] == FALSE)
    {
        if ([TestIf appCanUseSchoolServerAFN])
        {
            [[HUDsingleton sharedHUD] showWhileExecuting:@selector(initialAuth) onTarget:self withObject:nil animated:YES];
        }
    }
    
    [self loadItemsForPicker];
    if ([itemArrayForPicker count] == 1)
        [self selectSingleItemInPicker];
    
    
    [self updateReferenceLabel];
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // Cleanup notifications/delegates
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#ifdef DEBUG
    NSLog(@"Removing FVC from notification center");
#endif
    [self disconnectLinea];
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

-(void) updateReferenceLabel
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        refLabel.text = [NSString stringWithFormat:@"Ref: %@",[SettingsHandler sharedHandler].getReference];
    });
}
#pragma mark - Alert

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    //u need to change 0 to other value(,1,2,3) if u have more buttons.then u can check which button was pressed.
#ifdef DEBUG
    NSLog(@"Management Alert Button Pressed %@",alertView.title);
#endif
    NSString* title = alertView.title;
    SettingsHandler* setting = [SettingsHandler sharedHandler];
    //Announce Alert View is Dismissed
    if ([title isEqualToString:CC_TRANSACTION_ERROR]) {
        if (buttonIndex == 0) {
            //Run verify past transaction
            [self showReceiptView];
        }
    } else if ([alertView.title hasPrefix:PROCESS_OFFLINE_FUNDS] ||
               [alertView.title hasPrefix:PROCESS_INSUFFICIENT_FUNDS]) {
        NSString* processsingRef = [SettingsHandler sharedHandler].getReference;
        //        OdinTransaction* curTran = [OdinTransaction getTransactionByReference:processsingRef];
        if (buttonIndex == 0) { //Cancel
            if (setting.isProcessingSale) {
                //                NSString* message = [NSString stringWithFormat:@"Cancelled %@ Failed", processsingRef];
                
                //-transaction is cancelled. we can go ahead and deleted last transaction
                //                if ([curTran deleteCurrentTransaction]) {
                //                    [[SettingsHandler sharedHandler] decrementReference];
                NSString* message = [NSString stringWithFormat:@"Cancelled %@", processsingRef];
                //                }
                [self HUDshowMessage:message];
                [self hideActivity];
                [setting processingSaleEnd];
            } else {
                //                [self showSuccess:[NSNumber numberWithBool:YES]];
                [HUDsingleton sharedHUD].labelText = @"Processed";
                [self hideActivity];
                [setting processingSaleEnd];
            }
        } else {
            //--check if it is still processing sales and if user wants to process offline funds
            //--If it is still processing, tell sale processing is done, so when connection is completed it will do nothing
            if (setting.isProcessingSale) {
                //--finish up sale
                //--upload transaction if needed
                [self postTransaction];
            } else {
                //--processing is connected and completed
                //--we should do nothing (this should never run because alertview should have disappeared when connection is done)
                //--alert user this already prcessed while waiting
                [HUDsingleton sharedHUD].labelText = @"Processed";
                [self hideActivity];
                [setting processingSaleEnd];
            }
            
        }
        //        [queue cancelOperationByReference:[SettingsHandler sharedHandler].currentReference];
        
        
        //        [self performSelectorOnMainThread:@selector(updateManageBadge) withObject:nil waitUntilDone:NO];
    } else if ([alertView.title hasPrefix:HAS_FUNDS])
    {
        NSString* processsingRef = [SettingsHandler sharedHandler].getReference;
        NSString* message = [NSString stringWithFormat:@"Cancelled %@", processsingRef];
        [self HUDshowMessage:message];
        [self hideActivity];
        [setting processingSaleEnd];
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
-(void)myTimerStartWithID:(NSString*)idnumber
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
    myTimer = [NSTimer timerWithTimeInterval:10.0 target:self selector:@selector(callAfterTenSeconds:) userInfo:@{@"idnumber":copyIdnumber} repeats:NO];
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
        if (selectedItem.chk_balance.boolValue) {
            
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
        //        if ([currentReference compareReference:[SettingsHandler sharedHandler].currentReference]) {
        //        }
    });
    //    });
    //    dispatch_async(dispatch_get_main_queue(), ^{
    //    });
}

-(void) callAfterTenSeconds:(NSNotification*)notification
{
    
#ifdef DEBUG
    NSLog(@"notify callAfterTenSeconds %@",selectedIdNumber);
#endif
    NSDictionary* userInfo = notification.userInfo;
    NSString* idnumber = userInfo[@"idnumber"];
    //    NSString* reference = userInfo[@"reference"];
    
    
    if ([SettingsHandler sharedHandler].isProcessingSale) {
        
        if (selectedItem.chk_balance.boolValue == false) {
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
                    if ([SettingsHandler sharedHandler].allowOverride) {
                        
                        
                        NSString* title = [NSString stringWithFormat:@"%@",PROCESS_OFFLINE_FUNDS];
                        NSString* message = [NSString stringWithFormat:@"Charge %@ offline funds:%.2f?",idNumber, funds.floatValue];
#ifdef DEBUG
                        message = [NSString stringWithFormat:@"FV: Charge %@ offline funds:%@? Item:%@ CB:%i",idNumber, funds,selectedItem.item,selectedItem.chk_balance.boolValue];
#endif
                        alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
                        
                    } else {
                        NSString* title = [NSString stringWithFormat:@"%@ \n[%@]",HAS_FUNDS,[SettingsHandler sharedHandler].getReference];
                        NSString* message = [NSString stringWithFormat:@"%@ has funds:%.2f?",idNumber, funds.floatValue];
                        alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    }
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
    
    
}

@end

