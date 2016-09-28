//
//  ReceiptViewController.m
//  OdinScanner
//
//  Created by KenThomsen on 8/1/14.
//
//

#import "ReceiptVC.h"
#import "NSString+hackXML.h"

@interface ReceiptVC ()

@end

@implementation ReceiptVC

@synthesize transArray, type;
@synthesize parser, soapResults, recordResults, emailAddress, emailBut, airPrintBut, cancelBut;
@synthesize name, school, approval, tranid, totalAmount, chargeStatus;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Linea Delegate

//Fires when a barcode is scanned
-(void) barcodeData:(NSString *)barcode type:(int)type
{
#ifdef DEBUG
    NSLog(@"scanned barcode: %@",barcode);
#endif
    
    
    [[SettingsHandler sharedHandler] processingSaleStart];
    [self performSelectorOnMainThread:@selector(showProcessing) withObject:nil waitUntilDone:YES];
    [self processScannedData:barcode];
    
    [[SettingsHandler sharedHandler] processingSaleEnd];
}


-(void)processScannedData:(NSString *)dataToProcess
{
#ifdef DEBUG
    NSLog(@"Rec processScannedData: %@",dataToProcess);
#endif
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    
    
    
    NSString* idNumber = [dataToProcess cleanBarcode];
    NSString* selectedIdNumber = [idNumber checkExportID];
    if (selectedIdNumber == nil) {
        [ErrorAlert simpleAlertTitle:@"Export ID not found!" message:idNumber];
        [self hideActivity];
        return;
    }
    
        //#endif
        //shows ID number in the text box
    
//        dispatch_async(dispatch_get_main_queue(), ^{
            self.emailAddress.text = [OdinStudent getStudentSecondaryEmailForID:selectedIdNumber];
            [self hideActivity];
//        });
//    });
    //handles matching exportID to ID
    //#ifdef DEBUG
    //    NSLog(@"using fake export id");
    //    NSString *idNumber = [@"3725" checkExportID];
    //#else
}
#pragma mark - View Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	//TODO: remove later
#ifdef DEBUG
	emailAddress.text = @"alvin@odin-inc.com";
#else
    emailAddress.text = @"";
#endif
    
	if (type == nil) {
		type = @"";
	}
	
	//Post larger bottons font size after iOS7
	double reqSysVer = 7.0;
	double curSysVer = [[[UIDevice currentDevice] systemVersion] doubleValue];
	if (curSysVer >= reqSysVer) {
		[emailBut.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:22.0]];
		[airPrintBut.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:22.0]];
		[cancelBut.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:22.0]];
	}
	
	
	[self loadCCTransactions];
	
	
	//change status label based on amount
	//negative = do refund/void (no way to tell it did refund/void)
#ifdef DEBUG
	NSLog(@"You have %lu transaction in Receipt", (unsigned long)transArray.count);
#endif
	if ([[self calculateTotalAmount] floatValue] < 0) {
		chargeStatus.text = @"Refund/Void Success";
	}
}

-(void)viewDidAppear:(BOOL)animated {
    [self refreshLinea];
}
- (void)viewWillDisappear:(BOOL)animated {
    
    [self disconnectLinea];
}
- (void)viewDidDisappear:(BOOL)animated
{
	//[[SettingsHandler sharedHandler] setMultiTransactions:nil];
	[self dumpCCTransaction];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button
- (IBAction)closeView:(id)sender {
	[self dismissViewControllerAnimated:YES
							 completion:nil];
}


#pragma mark - Receipt

- (IBAction)printReceipt:(id)sender {
	if ([UIPrintInteractionController isPrintingAvailable]) //IOS7 requires this check
	{
		// Available
		
#ifdef DEBUG
		NSLog(@"airprint available");
#endif
		NSString* htmlString = @"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">		<HTML>		";
		NSString* html_head = @"<HEAD>		<META HTTP-EQUIV=\"CONTENT-TYPE\" CONTENT=\"text/html; charset=utf-8\">		<TITLE></TITLE>		<META NAME=\"GENERATOR\" CONTENT=\"LibreOffice 4.1.3.2 (MacOSX)\">		<META NAME=\"CREATED\" CONTENT=\"20140812;102133725567000\">		<META NAME=\"CHANGED\" CONTENT=\"20140812;102451755960000\">		<STYLE TYPE=\"text/css\">			</STYLE>		</HEAD>";
		NSString* storeInfo = @"<P ALIGN=CENTER STYLE=\"margin-bottom: 0in\">";
		
		SettingsHandler* setting = [SettingsHandler sharedHandler];
		NSMutableArray* stringArray = [setting getReceiptHeader];
		for (NSString* line in stringArray) {
			if (![line isEqual:@""]) {
				storeInfo = [storeInfo stringByAppendingFormat:@"\n%@</BR>",line];
			}
		}
		storeInfo = [storeInfo stringByAppendingString:@"</P>"];
		
		NSString* receiptInfo = @"<TR VALIGN=TOP>";
		
		//show transaction id
		
		
		NSString* items = @"";
		//NSMutableArray* transactions = [setting getMultiTransactions];
		
		
		//if (transactions) {
		
		//Print Receipt Header
			OdinTransaction *transaction = [transArray objectAtIndex:0];
			if (transaction) {
					
				receiptInfo = [receiptInfo stringByAppendingFormat:@"<TD WIDTH=50%%  STYLE=\"border: none; padding: 0in\"><P ALIGN=LEFT>\nTrans ID:%@</P></TD>",[setting showReceiptTranID] ? transaction.cc_tranid : @""];
				
				receiptInfo = [receiptInfo stringByAppendingFormat:@"<TD WIDTH=50%%  STYLE=\"border: none; padding: 0in\"><P ALIGN=RIGHT>\n%@ </P></TD>"
							   ,[setting showReceiptTimestamp] ? [transaction.timeStamp asStringWithNSDate] : @""];
				
				//End and start a new row
				receiptInfo = [receiptInfo stringByAppendingString:@"</TR><TR VALIGN=TOP>"];
				
				
				receiptInfo = [receiptInfo stringByAppendingFormat:@"<TD WIDTH=50%%  STYLE=\"border: none; padding: 0in\"><P ALIGN=LEFT>\nApproval #:%@</P></TD>",[setting showReceiptApprovedCode] ? transaction.cc_approval : @""];
				
			} else {
				receiptInfo = [receiptInfo stringByAppendingString:@"<TD WIDTH=50%%  STYLE=\"border: none; padding: 0in\"></TD>"];
			}
			//show operator
			BOOL showOperator = [setting showReceiptOperator];
			if (showOperator) {
				receiptInfo = [receiptInfo stringByAppendingFormat:@"<TD WIDTH=50%%  STYLE=\"border: none; padding: 0in\"><P ALIGN=RIGHT>\nOperator:%@</P></TD>",[[SettingsHandler sharedHandler]uid]];
			}
		
		//Print Transaction Item
			for (OdinTransaction* tran in transArray) {
				
				items = [items stringByAppendingString:@"\n<TR VALIGN=TOP>"];
				items = [items stringByAppendingFormat:@"<TD WIDTH=6%%  STYLE=\"border: none; padding: 0in\"><P ALIGN=RIGHT>%@</P></TD>"
						 ,[tran.qty stringValue] ];
				items = [items stringByAppendingFormat:@"<TD WIDTH=44%% STYLE=\"border: none; padding: 0in\"><P>   %@</P></TD>"
						 ,tran.item];
				items = [items stringByAppendingFormat:@"<TD WIDTH=50%% STYLE=\"border: none; padding: 0in\"><P ALIGN=RIGHT>$%.2f</P></TD>		</TR>"
						 ,[tran.amount floatValue]];
			}
		//}
		
		receiptInfo = [receiptInfo stringByAppendingString:@"</TR>"];
		
		
		//Print Subtotal/Tax/Total Amount
		//store Info
		NSString* body = [NSString stringWithFormat:@"<BODY LANG=\"en-US\" DIR=\"LTR\">						  <TABLE WIDTH=100%% CELLPADDING=0 CELLSPACING=0>						  <COL WIDTH=256*>						  <TR>						  <TD WIDTH=100%% VALIGN=TOP STYLE=\"border: none; padding: 0in\"><P \n%@</BR>",storeInfo];
		//receipt Info
		body = [body stringByAppendingFormat:@"<TABLE WIDTH=100%% BORDER=0 CELLPADDING=4 CELLSPACING=0>	<COL WIDTH=128*>		<COL WIDTH=128*>		\n%@		</TABLE>",receiptInfo];
		//items
		body = [body stringByAppendingFormat:@"<TABLE WIDTH=100%% BORDER=0 CELLPADDING=4 CELLSPACING=0>	<COL WIDTH=16	<COL WIDTH=112*>		<COL WIDTH=128*>		\n%@		</TABLE>", items ];
		//total amount
		/*body = [body stringByAppendingFormat:@"<P ALIGN=RIGHT STYLE=\"margin-bottom: 0in\">---------------------------</BR>		\nSubtotal: $%.2f</BR>		\nTax: $%.2f</BR>		\nTotal: $%.2f</BR></TD>						  </TR>						  </TABLE>				</BODY>		</HTML>",[[setting subtotal] floatValue],[[setting tax] floatValue],[[setting total] floatValue]];*/
		body = [body stringByAppendingFormat:@"<P ALIGN=RIGHT STYLE=\"margin-bottom: 0in\">---------------------------</BR>		\nSubtotal: $%.2f</BR>		\nTax: $%.2f</BR>		\nTotal: $%.2f</BR></TD>						  </TR>						  </TABLE>				</BODY>		</HTML>",[[self calculateSubtotalAmount] floatValue],[[self calculateTotalTaxAmount] floatValue],[[self calculateTotalAmount] floatValue]];
		UIPrintInteractionController *pic = [UIPrintInteractionController
											 sharedPrintController];
		
		htmlString = [htmlString stringByAppendingFormat:@"%@%@",html_head,body];
#ifdef DEBUG
		NSLog(@"html: %@", htmlString);
#endif
		pic.delegate = self;
		UIPrintInfo *printInfo = [UIPrintInfo printInfo];
		printInfo.outputType = UIPrintInfoOutputGeneral;
		printInfo.jobName = @"test receipt";
		pic.printInfo = printInfo;
		UIMarkupTextPrintFormatter *htmlFormatter = [[UIMarkupTextPrintFormatter alloc] initWithMarkupText:htmlString];
		htmlFormatter.startPage = 0;
		htmlFormatter.contentInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0); // 1 inch margins
		pic.printFormatter = htmlFormatter;
		pic.showsPageRange = YES;
		void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
		^(UIPrintInteractionController *printController, BOOL completed, NSError
		  *error) {
			if (!completed && error) {
				NSLog(@"Printing could not complete because of error: %@", error);
			} };
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[pic presentFromBarButtonItem:sender animated:YES
						completionHandler:completionHandler];
		} else {
			[pic presentAnimated:YES completionHandler:completionHandler];
		}
	} else {
		// Not Available
#ifdef DEBUG
		NSLog(@"airprint not available");
#endif
		
	}
}
- (IBAction)emailReceipt:(id)sender {
	//email, name, school, approval, tranid, amount, TranData: string
	//CardTransaction* transaction = [[SettingsHandler sharedHandler] getTransaction];
	//NSMutableArray* transactions = [[SettingsHandler sharedHandler] getMultiTransactions];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		
		MBProgressHUD* hud = [HUDsingleton sharedHUD];
		hud.labelText = @"Sending";
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.view addSubview:hud];
			[hud show:true];
		});
		
		//Get Receipt Header
		NSString* headerString = [self buildReceiptHeader];
		
		//Get Transdata based on single/multply transactions
		/*NSString* (^makeTransaction)(void) = ^{
		 if(transArray.count)//  [[SettingsHandler sharedHandler]getMultiTransactions].count > 1)
			return [NSString stringWithFormat:@"&TranData={%@,{\"transactions\":{\n\t\"transaction\":[\n%@]}\n}",headerString, [transArray JSON] ];
		 else return [NSString stringWithFormat:@"&TranData={%@,{\n\t\"transaction\":\n%@\n}}",headerString, [transArray JSON] ];
		 };
		 
		 NSString* tranData = makeTransaction();*/        
		NSString* tranData = [NSString stringWithFormat:@"%@",[transArray prepForWebservice]];
		
		//Get All agrugments
		OdinTransaction* transaction = [transArray objectAtIndex:0];
		SettingsHandler* setting = [SettingsHandler sharedHandler];
		NSArray* arguments = [NSArray arrayWithObjects:
							  [NSString addData:emailAddress.text Tag:@"email"],
							  [NSString addData:setting.headerLine1 Tag:@"header1"],
							  [NSString addData:setting.headerLine2 Tag:@"header2"],
							  [NSString addData:setting.headerLine3 Tag:@"header3"],
							  [NSString addData:setting.headerLine4 Tag:@"header4"],
							  [NSString addData:setting.headerLine5 Tag:@"header5"],
							  [NSString addData:type Tag:@"type"],
							  nil];
		
		NSString *post = [NSString stringWithFormat:@"%@%@", tranData, [arguments componentsJoinedByString:@""]];
#ifdef DEBUG
		NSLog(@"email data: %@", post);
#endif
		if (![WebService postTransactionWithStringAFN:post]) {
			[ErrorAlert failToPostToEmailService];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[hud hide:true];
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[self dismissViewControllerAnimated:YES completion:nil];
			});
		});
	});
}
-(NSString*)calculateTotalAmount
{
	
	NSDecimalNumber* totalAmount2 = [NSDecimalNumber decimalNumberWithString:@"0.0"];
	//NSMutableArray* transactions = [[SettingsHandler sharedHandler] getMultiTransactions];
	for (OdinTransaction * trans in transArray) {
		totalAmount2 = [totalAmount2 decimalNumberByAdding: trans.amount ];
	}
	
	return [totalAmount2 stringValue];
}
-(NSString*)calculateTotalTaxAmount
{
	NSDecimalNumber* totalTaxAmount = [NSDecimalNumber decimalNumberWithString:@"0.0"];
	//NSMutableArray* transactions = [[SettingsHandler sharedHandler] getMultiTransactions];
	for (OdinTransaction * trans in transArray) {
		totalTaxAmount = [totalTaxAmount decimalNumberByAdding: trans.tax_amount ];
	}
	
	return [totalTaxAmount stringValue];
}

-(NSString*)calculateSubtotalAmount
{
	NSDecimalNumber* totalAmount2 = [NSDecimalNumber decimalNumberWithString:[self calculateTotalAmount]];
	NSDecimalNumber* totalTaxAmount = [NSDecimalNumber decimalNumberWithString:[self calculateTotalTaxAmount]];
	NSDecimalNumber* subtotalAmount = [totalAmount2 decimalNumberBySubtracting: totalTaxAmount];
	
	return [subtotalAmount stringValue];
}
-(NSString*)buildReceiptHeader
{
#ifdef DEBUG
    NSLog(@"build header");
#endif
	SettingsHandler* setting = [SettingsHandler sharedHandler];
	NSError* error;
	NSDictionary* headerDict = [setting getReceiptHeaderInDictionary];
	NSString* headerString = @"\n\t\"receipt_header\":\n\t\t";
	if (headerDict) {
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:headerDict
														   options:NSJSONReadingAllowFragments
															 error:&error];
		NSString* jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		headerString = [headerString stringByAppendingString:jsonString];
		headerString = [headerString substringToIndex:(headerString.length - 1)];
	}
	
//	if ([setting showReceiptOperator]) {
//		NSString* jsonString = [NSString stringWithFormat:@"\"operator\":%@",[[SettingsHandler sharedHandler]uid]];
//	}
//	headerString = [headerString stringByAppendingString:@"}"];
//	CardTransaction* transaction = [[[SettingsHandler sharedHandler]getMultiTransactions] objectAtIndex:0];
//	if ([setting showReceiptTranID]) {
//		
//		NSString* jsonString = [NSString stringWithFormat:@"\"transid\":%@",transaction.cc_tranid];
//	}
//	if ([setting showReceiptApprovedCode]) {
//		
//		NSString* jsonString = [NSString stringWithFormat:@"\"approval\":%@",transaction.cc_approval];
//	}
//	if ([setting showReceiptTimestamp]) {
//		
//		NSString* jsonString = [NSString stringWithFormat:@"\"timestamp\":%@",[transaction.timeStamp asStringWithNSDate]];
//	}
	
	return headerString;
}
#pragma mark - Connection

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //parser = [[NSXMLParser alloc] initWithData:balData];
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:YES];
    [parser parse];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{

}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *)qName
   attributes: (NSDictionary *)attributeDict
{
	if( [elementName isEqualToString:@"string"])
	{
		soapResults = nil;
        soapResults = [[NSMutableString alloc] init];
	}
}
-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if( recordResults )
	{
		[soapResults appendString: string];
	}
}
-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if( [elementName isEqualToString:@"string"])
	{
		
        soapResults = nil;
    }
    else {
        soapResults = nil;
	}
	
}
- (IBAction)backgroundTap:(id)sender {
#ifdef DEBUG
    NSLog(@"background tap receipt");
#endif
	[emailAddress resignFirstResponder];
}

#pragma mark - CoreData
-(void) loadCCTransactions
{
	NSManagedObjectContext* moc = [CoreDataService getMainMOC];
	//transArray = [CoreDataService searchObjectsForEntity:@"CardTransaction" withPredicate:nil andSortKey:nil andSortAscending:NO andContext:moc];
}

-(void) dumpCCTransaction
{
	NSManagedObjectContext* moc = [CoreDataService getMainMOC];
	//[CoreDataService deleteAllObjectsForEntity:@"CardTransaction" andContext:moc];
	transArray = nil;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
