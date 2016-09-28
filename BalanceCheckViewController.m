//
//  BalanceCheckViewController.m
//  OdinScanner
//
//  Created by Ben McCloskey on 2/8/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "BalanceCheckViewController.h"

@interface BalanceCheckViewController ()

@property (nonatomic, strong) IBOutlet UITextField *studentIdTextBox;
@property (nonatomic, strong) IBOutlet UITextField *studentBalanceTextBox;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) UITextField *activeField;
@property (nonatomic, strong) MBProgressHUD *HUD;

-(IBAction)checkBalance;
-(void) processCheckBalance;

@end

@implementation BalanceCheckViewController

@synthesize studentIdTextBox, studentBalanceTextBox, activeField;
@synthesize scrollView;
@synthesize HUD;

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

#pragma mark - HUD methods

-(void) showActivity
{
	
	self.HUD = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
	
	[[UIApplication sharedApplication].keyWindow addSubview:self.HUD];
	
	self.HUD.delegate = self;
	self.HUD.labelText = @"Connecting...";
	
	
	[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_DISABLED error:nil];
	[activeField resignFirstResponder];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

-(void) showProcessing
{
	HUD.delegate = self;
	HUD.labelText = @"Processing...";
	[HUD show:YES];
}

-(void) showSuccess:(NSNumber *)successful
{
	if ([successful boolValue] == TRUE)
	{
		HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
		
		// Set custom view mode
		HUD.mode = MBProgressHUDModeCustomView;
		
		HUD.delegate = self;
		HUD.labelText = @"Success!";
		
		[HUD show:YES];
	}
}

-(void) hideActivity
{
	[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	[HUD removeFromSuperview];
}


-(IBAction)checkBalance
{
	[studentIdTextBox resignFirstResponder];
	
	//control for empty string, 'cause obviously it's not going to find anything
	if (![studentIdTextBox.text isEqualToString:@""])
	{
		if ([[SettingsHandler sharedHandler] checkBalance] == TRUE)
		{
			[self showActivity];	
			[HUD showWhileExecuting: @selector(processCheckBalance) onTarget:self withObject:nil animated:YES];
		}
		else
		{
			[ErrorAlert cannnotCheckBalance];
		}
	}
	else
		studentBalanceTextBox.text = @"";
}

-(void) processCheckBalance
{
	if ([TestIf appCanUseSchoolServer])
	{
		NSString *idNumber = studentIdTextBox.text;
		NSDictionary *fetchedStudentData = [WebService fetchStudentWithID:idNumber];
		
		if (fetchedStudentData)
		{
			[self showSuccess:[NSNumber numberWithBool:TRUE]];
			float presentValue = [[fetchedStudentData objectForKey:@"present"] floatValue];
			[studentBalanceTextBox performSelectorOnMainThread:@selector(setText:) 
													withObject:[NSString stringWithFormat:@"$%.2f",presentValue] 
												 waitUntilDone:YES];
		}	
	}
	
	[self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:YES];
}

-(IBAction)backgroundTap
{
	// Hide keyboard when background is tapped
    #ifdef DEBUG 
	NSLog(@"Background Tapped");
	#endif
    [activeField resignFirstResponder];
}


#pragma mark - Bookkeeping Methods


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

- (void)keyboardWasShown:(NSNotification*)aNotification
{//when keyboard is shown, get kb size info, and scroll view to account for it if necessary
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    [scrollView setContentInset:contentInsets];
    [scrollView setScrollIndicatorInsets:contentInsets];    
    // If active text field is hidden by keyboard, scroll it so it's visible
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) 
    {
        CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y-kbSize.height+10);
        [scrollView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    CGPoint scrollPoint = CGPointMake(0.0, 0.0);
    [scrollView setContentOffset:scrollPoint animated:YES];    
} 

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    activeField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{// Hides the keyboard when return key pressed on any text field
    [theTextField resignFirstResponder];
    return YES;
}

#pragma mark - Linea Delegate calls


-(void)connectionState:(int)state 
{
	switch (state) {
		case CONN_DISCONNECTED:
		case CONN_CONNECTING:
			#ifdef DEBUG 
			NSLog(@"[LINEA] Linea connectionState=CONNECTING/DISCONNECTED");
			#endif
			break;
		case CONN_CONNECTED:
			[[DTDevices sharedDevice] barcodeSetScanButtonMode:1 error:nil];
			[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
            //Turn on the beep 
            int beepData[] = {1200,100};
			[[DTDevices sharedDevice] barcodeSetScanBeep:TRUE volume:10 beepData:beepData length:sizeof(beepData) error:nil];
			#ifdef DEBUG
			NSLog(@"[LINEA] Linea connectionState=CONNECTED TO FIRSTVC");
			#endif
            
			break;
	}
}


-(void) barcodeData:(NSString *)barcode type:(int)type
{
    [studentIdTextBox setText:[barcode cleanBarcode]];
	[studentBalanceTextBox setText:@""];
	[self checkBalance];
}


- (void) refreshLinea
{	// refreshes connection to Linea when returning from inactive state
    [[DTDevices sharedDevice] addDelegate:self];
    [[DTDevices sharedDevice] connect];
	[[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
	#ifdef DEBUG 
	NSLog(@"Refreshing Linea connection to Balance Check Controller");
	#endif
}


#pragma mark - View lifecycle

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad
 {
 [super viewDidLoad];
 }
 */

-(void) viewWillAppear:(BOOL)animated
{
	[self registerForKeyboardNotifications];     
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLinea) name:@"refreshLinea" object:nil];
    #ifdef DEBUG 
	NSLog(@"Loading BalanceCheck");
	#endif
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated]; 
	[self refreshLinea];    
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];    
    [self releaseKeyboardNotifications];    
    // Cleanup notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];    
	#ifdef DEBUG 
	NSLog(@"Removing BalanceCheck from notification center");
	#endif
    [[DTDevices sharedDevice] removeDelegate:self];
	//[[DTDevices sharedDevice] disconnect];
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
