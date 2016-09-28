//
//  AttendanceViewController.m
//  Scanner
//
//  Created by Ken Thomsen on 1/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AttendanceViewController.h"
#import "OdinTransaction.h"
#import "OdinAttendance.h"

@implementation AttendanceViewController

@synthesize backgroundView, eventIdTextBox, studentIdTextBox, studentTicketsLeft, studentTicketsPurchased, managedObjectContext, processIdButton, activeField, isConnectedToLinea;

#pragma mark - Linea Delegate Calls

-(void)connectionState:(int)state 
{
	switch (state) {
		case CONN_DISCONNECTED:
		case CONN_CONNECTING:
			NSLog(@"[LINEA] Linea connectionState=CONNECTING/DISCONNECTED");
			self.isConnectedToLinea = FALSE;
			break;
		case CONN_CONNECTED:
            [[Linea sharedDevice] setScanMode:0];
            //Turn off the beep (beep will be played based on attendance)      
			self.isConnectedToLinea = TRUE;
            [[Linea sharedDevice] setScanBeep:FALSE volume:10 beepData:nil length:0]; 
			NSLog(@"[LINEA] Linea connectionState=CONNECTED TO ATTENDING");
            
			break;
	}
}


-(void) barcodeData:(NSString *)barcode type:(int)type
{
    [studentIdTextBox setText:barcode];
	[self processId];
	
}

-(void) processId
{
	// with student barcode and EventID, search data for all transactions involving the ID	
	NSMutableArray *ticketArray = [CoreDataHelper searchObjectsForEntity:@"OdinTransaction"
														   withPredicate:[NSPredicate predicateWithFormat:@"(eventId == %@)", [eventIdTextBox text]] 
															  andSortKey:nil
														andSortAscending:NO
															  andContext:self.managedObjectContext];
	if([ticketArray count] == 0)
	{// Control for incorrect/nonexistant PLU
		[ErrorAlert noItem];
	}
	else
	{// This is for a correct PLU
		ticketArray = [CoreDataHelper searchObjectsForEntity:@"OdinTransaction"
											   withPredicate:[NSPredicate predicateWithFormat:@"(idNumber == %@) AND (eventId == %@) AND (sync == TRUE)",[studentIdTextBox text], [eventIdTextBox text]] 
												  andSortKey:@"timeStamp"
											andSortAscending:YES
												  andContext:self.managedObjectContext];
		// find the number of purchased tickets and number of outstanding tickets available to the ID number
		int ticketsPurchased = 0;
		int ticketsRemaining = 0;
		for(int x = 0; x < [ticketArray count]; x++)
		{
			ticketsPurchased += [[[ticketArray objectAtIndex:x] qty] intValue];
			ticketsRemaining += [[[ticketArray objectAtIndex:x] attending] intValue];
		}
		[[self studentTicketsPurchased] setText:[NSString stringWithFormat:@"%i",ticketsPurchased]];
		if (ticketsRemaining < 1)
		{// Since student has no tickets, play "badBeep" and push alert message			
			int badBeep[] = {1200,100,900,100,600,100};
			if ([self isConnectedToLinea])
			{
				[[Linea sharedDevice] playSound:100 beepData:badBeep length:sizeof(badBeep)];
			}
			[ErrorAlert attendanceDenied];
			
		}
		// increase the attending count by one for earliest timestamped transaction
		else
		{
			int goodBeep[] = {1200,100,1400,100,1600,100};
			if ([self isConnectedToLinea])
				[[Linea sharedDevice] playSound:100 beepData:goodBeep length:sizeof(goodBeep)];
			//decrease tickets remaining by one
			ticketsRemaining--;
			// enter into attendance DB
			OdinAttendance *attendanceRecord = [NSEntityDescription insertNewObjectForEntityForName:@"OdinAttendance" inManagedObjectContext:self.managedObjectContext];
			attendanceRecord.studentId = [studentIdTextBox text];
			attendanceRecord.eventId = [eventIdTextBox text];
			attendanceRecord.timeStamp =[NSDate date];
			
			for(int x = 0; x < [ticketArray count]; x++)
			{
				//find the earliest timestamped positive attending value
				if([[[ticketArray objectAtIndex:x] attending] intValue] > 0)
				{
					//decrease it by one
					OdinTransaction *modifiedTransaction = [ticketArray objectAtIndex:x];
					[modifiedTransaction setAttending:[NSNumber numberWithInt:
													   ([[modifiedTransaction attending] intValue] - 1)]];
					//break the for loop
					x = [ticketArray count];
				}
			}
		}
		[CoreDataHelper saveObjectsInContext:self.managedObjectContext];
		[[self studentTicketsLeft] setText:[NSString stringWithFormat:@"%i",ticketsRemaining]];
	}
	[activeField resignFirstResponder];	
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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
#pragma mark - Bookkeeping Methods

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{//hides keyboard when return key pressed on any text field
	[theTextField resignFirstResponder];
	NSLog(@"Text Field resigning First Responder");
	return YES;
}
/*
 - (void)registerForKeyboardNotifications
 {//call to allow class to receive KB notifications  
 [[NSNotificationCenter defaultCenter] addObserver:self
 selector:@selector(keyboardWasShown:)
 name:UIKeyboardWillShowNotification object:nil];
 
 [[NSNotificationCenter defaultCenter] addObserver:self
 selector:@selector(keyboardWillBeHidden:)
 name:UIKeyboardWillHideNotification object:nil];
 }
 
 -(void) releaseKeyboardNotifications
 {//call to release class from KB notifications 
 [[NSNotificationCenter defaultCenter] removeObserver:self];
 [[NSNotificationCenter defaultCenter] removeObserver:self];
 }
 */
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	
	activeField = nil;
}

-(IBAction)backgroundTap
{
	NSLog(@"Background Tapped");
	[activeField resignFirstResponder];
}//hides keyboard when background is tapped

#pragma mark - View lifecycle

- (void) refreshLinea
{	// refreshes connection to Linea when returning from inactive state
	[[Linea sharedDevice] addDelegate:self];
	[[Linea sharedDevice] connect];	
	NSLog(@"Refreshing Linea connection to AttendanceVC");
}
/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	[super viewDidLoad];
	if (self.managedObjectContext == nil)
	{
		id appDelegate = (id)[[UIApplication sharedApplication] delegate]; 
		self.managedObjectContext = [appDelegate managedObjectContext];
	}	
	
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	NSLog(@"Loading Attendance");	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLinea) name:@"refreshLinea" object:nil];
	[eventIdTextBox setText:[AppDelegate getDefaultItemPLUFromManagedObjectContext:self.managedObjectContext]];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[[Linea sharedDevice] addDelegate:self];	
	[[Linea sharedDevice] connect]; 
	
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];    
	// Cleanup notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
	NSLog(@"Removing attendance from notification center");
	[[Linea sharedDevice] removeDelegate:self];
	[[Linea sharedDevice] disconnect];
}
- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
