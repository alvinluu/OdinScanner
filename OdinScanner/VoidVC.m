//
//  VoidVC.m
//  OdinScanner
//
//  Created by KenThomsen on 11/13/14.
//
//

#import "VoidVC.h"
#import "ReceiptVC.h"
#import "CardProcessor.h"
#import "NSString+hackXML.h"

@interface VoidVC ()

@property (nonatomic, retain) NSManagedObjectContext *moc;
@property (nonatomic, retain) NSMutableArray *transactArray;
@property (nonatomic, strong) IBOutlet UITableView *atableView;
@property (strong, nonatomic) IBOutlet UILabel *refundAmount;
@end

@implementation VoidVC
@synthesize moc;
@synthesize transactArray;
@synthesize atableView, selectedItem, refundAmount;


#pragma mark - Actions
-(IBAction)voidAndRefund:(id)sender {
	float refund = [refundAmount.text floatValue];
	float total = [[self calculateTotalAmount] floatValue];
	
	
	CardProcessor* ccProcess = [CardProcessor initialize:@"0"];
    if (ccProcess == nil) {return;}
	[ccProcess setTerminal];
	
	if (transactArray.count > 0) {
		
		
		//do void/refund
		(refund < total) ? [self doRefund:ccProcess] : [self doVoid:ccProcess];
	} else {
		[ErrorAlert simpleAlertTitle:@"No Transaction" message:@"No transaction to refund/void"];
	}
	
}

#pragma mark - View
- (void)viewDidLoad {
    [super viewDidLoad];
#ifdef DEBUG
	NSLog(@"VoidVC appeared");
#endif
	// Get managedObjectContext from AppDelegate
	if (moc == nil)
	{
		moc = [CoreDataService getMainMOC];
	}
	
	self.atableView.delegate = self;
	self.atableView.dataSource = self;
	
	//self.tableView = nil;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
}

-(void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self readDataForTable];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)readDataForTable
{
	//  Grab the data from persistent store
#ifdef DEBUG
	NSLog(@"load CC card %@",selectedItem.cc_tranid);
#endif
	NSString* predicate = [NSString stringWithFormat:@"cc_tranid == %@",selectedItem.cc_tranid];
	transactArray = [CoreDataService searchObjectsForEntity:@"OdinTransaction"
											 withPredicate:[NSPredicate predicateWithFormat:predicate]
												andSortKey:@"timeStamp"
										  andSortAscending:NO
												andContext:moc];
#ifdef DEBUG
	NSLog(@"Loading data for table %lu", (unsigned long)[transactArray count]);
#endif
	//  Force table refresh
	if (transactArray.count) {
		[self.atableView reloadData];
	}
}
#pragma mark - View Cycle
-(void)viewDidAppear:(BOOL)animated
{
	[self loadTableAmount];
	[self refreshLinea];
}
-(void)viewDidDisappear:(BOOL)animated
{
}
-(void)viewWillDisappear:(BOOL)animated
{
	[self disconnectLinea];
}
#pragma mark - Linea Delegate Calls
-(void)magneticCardData:(NSString *)track1 track2:(NSString *)track2 track3:(NSString *)track3
{
	NSLog(@"\n\nTrack 1:%@\n\nTrack 2:%@\n\nTrack 3:%@\n\n",track1,track2,track3);
	
	
	NSString *magneticData = [NSString stringWithFormat:@"%@%@",track1,track2];
	
	float refund = [refundAmount.text floatValue];
	float total = [[self calculateTotalAmount] floatValue];
	
	
	CardProcessor* ccProcess = [CardProcessor initialize:magneticData];
    
    if (ccProcess == nil ) {return;}
	[ccProcess setTerminal];
	
	if (transactArray.count > 0) {
		
		OdinTransaction* tran = [transactArray objectAtIndex:0];
		//compare last 4 digits. give error if card mismatch
		if (![tran.cc_digit isEqual:[ccProcess getCardLast4Digits]]) {
			[ErrorAlert simpleAlertTitle:@"Mismatched Card" message:@"This transaction wasn't purchased with this card. Please try a different card"];
			return;
		}
		
		//do void/refund
		(refund < total) ? [self doRefund:ccProcess] : [self doVoid:ccProcess];
	} else {
		[ErrorAlert simpleAlertTitle:@"No Transaction" message:@"No transaction to refund/void"];
	}
	
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	return [transactArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellId = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
	}
	
	// Get the core data object we use to populate the cell in a given row
	OdinTransaction *currentCell = [transactArray objectAtIndex:indexPath.row];
	if (currentCell==nil) {
		return cell;
	}
	
	//  Fill in the cell contents
	cell.textLabel.text = [NSString stringWithFormat:@"[%@] %@",[NSDate asStringDateWithFormat:[currentCell qdate]] ,[currentCell id_number]];
	
	cell.detailTextLabel.text = [NSString stringWithFormat:@"[%@] %@ %@ for $%.2f",[currentCell reference], [currentCell qty],[currentCell item], [[currentCell amount] floatValue]];
	if ([currentCell.item isEqualToString:selectedItem.item]) {
		[tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:YES];
	}
	return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray* listOfSelectedRows = tableView.indexPathsForSelectedRows;
	float total = 0;
	for (NSIndexPath *path in listOfSelectedRows) {
			OdinTransaction* currentCell = [transactArray objectAtIndex:path.row];
			total += [currentCell.amount floatValue];
	}
	
	refundAmount.text = [NSString stringWithFormat:@"%.2f",total];
	//[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray* listOfSelectedRows = tableView.indexPathsForSelectedRows;
	float total = 0;
	for (NSIndexPath *path in listOfSelectedRows) {
		OdinTransaction* currentCell = [transactArray objectAtIndex:path.row];
		total += [currentCell.amount floatValue];
	}
	
	refundAmount.text = [NSString stringWithFormat:@"%.2f",total];
	//[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Others
//Refund Transaction on partial amount
-(void) doRefund:(CardProcessor*)ccProcess
{
	OdinTransaction* transaction = [transactArray objectAtIndex:0];
	
	MBProgressHUD* HUD = [HUDsingleton sharedHUD];
	[[UIApplication sharedApplication].keyWindow addSubview:HUD];
	[HUD show:YES];
	
	[ccProcess refund:transaction.cc_tranid :refundAmount.text];
	
	[HUD hide:YES];
	
	NSLog(@"Do Refund with Amount %@ with Total %@ on Tranid %@", refundAmount.text, [self calculateTotalAmount], transaction.cc_tranid);
	if ([ccProcess responseApproved]) {
		NSLog(@"Good, Your response is %@",[ccProcess responseText]);
		NSMutableArray* transArray = [[NSMutableArray alloc] init];
		//Load transaction(s) to CoreDate
		NSArray* listOfSelectedRows = atableView.indexPathsForSelectedRows;
		for (NSIndexPath *path in listOfSelectedRows) {
			OdinTransaction* currentCell = [transactArray objectAtIndex:path.row];
			currentCell.id_number = [NSString stringWithFormat:@"%@ Refunded",currentCell.id_number];
			currentCell.type = @"Refund";
			//convert to CardTransaction
			//CardTransaction* tran = [currentCell saveToCardTransactionWithMOC:moc];
			
			//tran.amount = [tran.amount decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1.0"]];
			[transArray addObject:currentCell];
			[self uploadTransaction:currentCell CardProcessor:ccProcess];
			[CoreDataService saveObjectsInContext:moc];
		}
		
		ReceiptVC* rvc = [self.storyboard instantiateViewControllerWithIdentifier:@"ReceiptVC"];
		rvc.transArray = transArray;
		rvc.type = @"Refund";
		[self presentViewController:rvc animated:YES completion:nil];
	} else
	{
		NSLog(@"Bad, Your response is %@", [ccProcess responseText]);
		[ErrorAlert simpleAlertTitle:@"Card Declined" message:[ccProcess responseText]];
	}
}

	//TODO:How to check refund success

/*
 *Void Transaction on full amount
 *If we cannot void, it is possible it is already charged, therefore, try refund.
 */
-(void) doVoid:(CardProcessor*)ccProcess
{
	OdinTransaction* transaction = [transactArray objectAtIndex:0];
	
	MBProgressHUD* HUD = [HUDsingleton sharedHUD];
	[[UIApplication sharedApplication].keyWindow addSubview:HUD];
	[HUD show:YES];
	
	[ccProcess voidTransaction:transaction.cc_tranid];
	
	[HUD hide:YES];
	
	if ([ccProcess responseApproved]) {
		NSLog(@"Good, Your response is %@",[ccProcess responseText]);
		
		NSMutableArray* transArray = [[NSMutableArray alloc] init];
		//Load transaction(s) to CoreDate
		NSArray* listOfSelectedRows = atableView.indexPathsForSelectedRows;
		for (NSIndexPath *path in listOfSelectedRows) {
			OdinTransaction* currentCell = [transactArray objectAtIndex:path.row];
			currentCell.id_number = [NSString stringWithFormat:@"%@ Voided",currentCell.id_number];
			currentCell.type = @"Void";
			//CardTransaction* tran = [currentCell saveToCardTransactionWithMOC:moc];
			//tran.amount = [tran.amount decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1.0"]];
#ifdef DEBUG
			//NSLog(@"you new tran amount is %@",[tran.amount stringValue]);
#endif
			[transArray addObject:currentCell];
			[self uploadTransaction:currentCell CardProcessor:ccProcess];
			[CoreDataService saveObjectsInContext:moc];
		}
		
		ReceiptVC* rvc = [self.storyboard instantiateViewControllerWithIdentifier:@"ReceiptVC"];
		rvc.transArray = transArray;
		rvc.type = @"Void";
		[self presentViewController:rvc animated:YES completion:nil];
	} else
	{
//		NSLog(@"Bad, Your response is %@", [ccProcess responseText]);
//		[ErrorAlert simpleAlertTitle:@"Card Declined" message:[ccProcess responseText]];
		[self doRefund:ccProcess];
	}
}
-(void) uploadTransaction:(OdinTransaction*)currentCell CardProcessor:(CardProcessor*)ccProcess
{
    NSManagedObjectContext* persistancemoc = [CoreDataHelper getCoordinatorMOC];
    [persistancemoc performBlock:^{
        
        OdinTransaction *newtransaction = [CoreDataService insertObjectForEntity:@"OdinTransaction" andContext:moc];
        
        newtransaction.qty = @([currentCell.qty floatValue] * -1);
        newtransaction.amount = [currentCell.amount decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]];
        newtransaction.id_number = currentCell.id_number;
        newtransaction.plu = currentCell.plu;
        newtransaction.timeStamp = [NSDate localDate];
        newtransaction.sync = [NSNumber numberWithBool:FALSE];
        //total amount = amount + tax, so tax = totalAmount - amount
        newtransaction.tax_amount = currentCell.tax_amount;
        newtransaction.reference = [[SettingsHandler sharedHandler] getReference];
        [[SettingsHandler sharedHandler] incrementReference];
        newtransaction.location = currentCell.location;
        newtransaction.item = currentCell.item;
        //version 2.6add glcode and dept_code
        newtransaction.glcode = currentCell.glcode;
        newtransaction.dept_code = currentCell.dept_code;
        newtransaction.operator = [[SettingsHandler sharedHandler] uid];
        newtransaction.payment = @"G";
        newtransaction.process_on_sync = currentCell.process_on_sync;
        newtransaction.qdate = [currentCell.timeStamp asStringWithFormat:@"@YYYY-@MM-@DD"];
        newtransaction.time = [currentCell.timeStamp asStringWithFormat:@"@hh:@mm:@ss"];
        newtransaction.school = [SettingsHandler sharedHandler].school;
        
        newtransaction.cc_digit = [ccProcess getCardLast4Digits];
        newtransaction.cc_tranid = [ccProcess responseTransactionId];
        newtransaction.first = [ccProcess getCardFirstName];
        newtransaction.last = [ccProcess getCardLastName];
        newtransaction.cc_approval = [ccProcess responseApprovalCode];
        newtransaction.cc_timeStamp = [currentCell.timeStamp convertDataToTimestamp];
        newtransaction.cc_responsetext = [ccProcess responseText];
        newtransaction.type = currentCell.type;
        [CoreDataHelper saveObjectsInContext:persistancemoc];
    }];
}

-(NSString*)calculateTotalAmount
{
	
	NSDecimalNumber* totalAmount2 = [NSDecimalNumber decimalNumberWithString:@"0.0"];
	for (OdinTransaction * trans in transactArray) {
		totalAmount2 = [totalAmount2 decimalNumberByAdding: trans.amount ];
	}
	
	return [totalAmount2 stringValue];
}
-(void)loadTableAmount
{
	NSArray* listOfSelectedRows = atableView.indexPathsForSelectedRows;
	float total = 0;
	for (NSIndexPath *path in listOfSelectedRows) {
		OdinTransaction* currentCell = [transactArray objectAtIndex:path.row];
		total += [currentCell.amount floatValue];
	}
	
	refundAmount.text = [NSString stringWithFormat:@"%.2f",total];
}
/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
