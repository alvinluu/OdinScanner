//
//  ReceiptViewController.m
//  OdinScanner
//
//  Created by KenThomsen on 8/1/14.
//
//

#import "ReceiptViewController.h"

@interface ReceiptViewController ()

@end

@implementation ReceiptViewController

@synthesize parser, soapResults, recordResults, emailAddress, emailBut, airPrintBut, cancelBut;
@synthesize name, school, approval, tranid, totalAmount;

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
    // Do any additional setup after loading the view.
	
	//TODO: remove later
	emailAddress.text = @"alvin@odin-inc.com";
}
- (void)viewDidDisappear:(BOOL)animated
{
	[[SettingsHandler sharedHandler] setMultiTransactions:nil];
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
	if ([UIPrintInteractionController isPrintingAvailable])
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
		NSMutableArray* transactions = [setting getMultiTransactions];
		
		if (transactions) {
			OdinTransaction *transaction = [transactions objectAtIndex:0];
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
			
			for (OdinTransaction* tran in transactions) {
				
				items = [items stringByAppendingString:@"\n<TR VALIGN=TOP>"];
				items = [items stringByAppendingFormat:@"<TD WIDTH=6%%  STYLE=\"border: none; padding: 0in\"><P ALIGN=RIGHT>%@</P></TD>"
						 ,[tran.qty stringValue] ];
				items = [items stringByAppendingFormat:@"<TD WIDTH=44%% STYLE=\"border: none; padding: 0in\"><P>   %@</P></TD>"
						 ,tran.item];
				items = [items stringByAppendingFormat:@"<TD WIDTH=50%% STYLE=\"border: none; padding: 0in\"><P ALIGN=RIGHT>$%.2f</P></TD>		</TR>"
						 ,[tran.amount floatValue]];
			}
		}
		
		receiptInfo = [receiptInfo stringByAppendingString:@"</TR>"];
		
		//store Info
		NSString* body = [NSString stringWithFormat:@"<BODY LANG=\"en-US\" DIR=\"LTR\">						  <TABLE WIDTH=100%% CELLPADDING=0 CELLSPACING=0>						  <COL WIDTH=256*>						  <TR>						  <TD WIDTH=100%% VALIGN=TOP STYLE=\"border: none; padding: 0in\"><P \n%@</BR>",storeInfo];
		//receipt Info
		body = [body stringByAppendingFormat:@"<TABLE WIDTH=100%% BORDER=0 CELLPADDING=4 CELLSPACING=0>	<COL WIDTH=128*>		<COL WIDTH=128*>		\n%@		</TABLE>",receiptInfo];
		//items
		body = [body stringByAppendingFormat:@"<TABLE WIDTH=100%% BORDER=0 CELLPADDING=4 CELLSPACING=0>	<COL WIDTH=16	<COL WIDTH=112*>		<COL WIDTH=128*>		\n%@		</TABLE>", items ];
		//total amount
		body = [body stringByAppendingFormat:@"<P ALIGN=RIGHT STYLE=\"margin-bottom: 0in\">---------------------------</BR>		\nSubtotal: $%.2f</BR>		\nTax: $%.2f</BR>		\nTotal: $%.2f</BR></TD>						  </TR>						  </TABLE>				</BODY>		</HTML>",[[setting subtotal] floatValue],[[setting tax] floatValue],[[setting total] floatValue]];
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
	//OdinTransaction* transaction = [[SettingsHandler sharedHandler] getTransaction];
	NSMutableArray* transactions = [[SettingsHandler sharedHandler] getMultiTransactions];
	
	
	//Get Receipt Header
	NSString* headerString = [self buildReceiptHeader];

	//Get Transdata
	NSString* (^makeTransaction)(void) = ^{
		if([[SettingsHandler sharedHandler]getMultiTransactions].count > 1)
			return [NSString stringWithFormat:@"&TranData={%@,{\"transactions\":{\n\t\"transaction\":[\n%@]}\n}",headerString, [transactions JSON] ];
		else return [NSString stringWithFormat:@"&TranData={%@,{\n\t\"transaction\":\n%@\n}}",headerString, [transactions JSON] ];
	};
	
	NSString* tranData = makeTransaction();
	
	//Get All agrugments
	OdinTransaction* transaction = [transactions objectAtIndex:0];
	NSString* cc_data = [transaction getCreditCardData];
	NSString* argument = [NSString stringWithFormat:@"email=%@%@&amount=%.2f",emailAddress.text, cc_data, [[[SettingsHandler sharedHandler] total] floatValue]];
	
	
	
	NSString *post = [NSString stringWithFormat:@"%@%@", argument, tranData];
	[WebService postEmailReceipt:post];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self dismissViewControllerAnimated:YES completion:nil];
}
-(NSString*)getTotalAmount//depreciated
{
	if (totalAmount == 0 || !totalAmount) {
		totalAmount = [NSDecimalNumber decimalNumberWithString:@"0.0"];
		
		NSMutableArray* transactions = [[SettingsHandler sharedHandler] getMultiTransactions];
			for (OdinTransaction * trans in transactions) {
				totalAmount = [totalAmount decimalNumberByAdding: trans.amount ];
			}
	}
	
	return [totalAmount stringValue];
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
//	OdinTransaction* transaction = [[[SettingsHandler sharedHandler]getMultiTransactions] objectAtIndex:0];
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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	
}
- (IBAction)backgroundTap:(id)sender {
#ifdef DEBUG
    NSLog(@"background tap receipt");
#endif
	[emailAddress resignFirstResponder];
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
