//
//  AddEditItemViewController.m
//  Scanner
//
//  Created by Ben McCloskey on 12/19/11.
//  Copyright (c) 2011 Odin Inc. All rights reserved.
//

#import "AddEditItemVC.h"
#import "MBProgressHUD.h"


@interface AddEditItemVC ()


@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) IBOutlet UITextField *taxTextBox;
@property (nonatomic, strong) IBOutlet UITextField *pluTextBox;
@property (nonatomic, strong) IBOutlet UITextField *descriptionTextBox;
@property (nonatomic, strong) IBOutlet UITextField *amtTextBox;
@property (nonatomic, strong) IBOutlet UITextField *editQtyTextBox;
@property (nonatomic, strong) IBOutlet UITextField *editRetailTextBox;
@property (nonatomic, strong) IBOutlet UITextField *editTransactionTextBox;
@property (nonatomic, strong) IBOutlet UITextField *editLockedTextBox;
@property (nonatomic, strong) IBOutlet UITextField *checkBalanceTextBox;

-(void) populateItem:(OdinEvent *)selectedItem;

-(BOOL) inputChecksOut;
-(NSDictionary *) selectedItemHasChanged;

-(IBAction)saveItem;


@end

@implementation AddEditItemVC

@synthesize managedObjectContext; 
@synthesize descriptionTextBox,amtTextBox,pluTextBox,taxTextBox;
@synthesize editQtyTextBox,editRetailTextBox,editTransactionTextBox,editLockedTextBox,checkBalanceTextBox;
@synthesize selectedItem,isEditing;


-(BOOL) inputChecksOut
{// Run multiple checks to see if input is good
	pluTextBox.text = [pluTextBox.text uppercaseString];
	
	NSDictionary *changeLog = [self selectedItemHasChanged];
	if ([changeLog count] != 0)
	{	
#ifdef DEBUG
		NSLog(@"%@",[changeLog description]);
#endif
		if ([selectedItem.lock_cfg intValue] == 1)
		{
			[ErrorAlert cannotEditItem];
			return NO;
		}
		if (([changeLog objectForKey:@"item"]) && ([selectedItem.allow_item intValue] == 0)) 
		{
			[ErrorAlert cannotEditItem:@"description"];
			return NO;
		}
		if (([changeLog objectForKey:@"amount"]) && ([selectedItem.allow_amount intValue] == 0)) 
		{
			[ErrorAlert cannotEditItem:@"retail amount"];
			return NO;
		}
		if (([changeLog objectForKey:@"tax"]) && ([selectedItem.allow_amount intValue] == 0)) 
		{
			[ErrorAlert cannotEditItem:@"tax amount"];
			return NO;
		}
	}
	if([[taxTextBox text] containsNonNumbers])
    {
        [ErrorAlert invalidTax];
		return NO;
    }
    // Show alert message if amount field contains anything other than numbers , or '.' (negatives are OK)
    else if ([[amtTextBox text] containsNonNumbers])
    {
        [ErrorAlert invalidRetail];
		return NO;
    }
    // Show alert message if any field is empty
    else if(([[amtTextBox text] isEqualToString:@""])        
			|| ([[descriptionTextBox text] isEqualToString:@""])
			|| ([[pluTextBox text] isEqualToString:@""]))
    {
        [ErrorAlert emptyFieldError];
		return NO;
    }
	// If there's >0 items with same PLU, check if user is adding item, or editing item
	else if([[CoreDataService searchObjectsForEntity:@"OdinEvent" 
									  withPredicate:[NSPredicate predicateWithFormat:@"plu == %@",[pluTextBox text]] 
										 andSortKey:nil 
								   andSortAscending:NO 
										 andContext:self.managedObjectContext] count] != 0)
	{
		NSString *itemsOriginalPLU = selectedItem.plu;
		// If user is adding item, or if user is editing an item and has changed the PLU to an existing one, push alert since we can't have duplicate PLUs
		if ((isEditing == FALSE) ||
			([itemsOriginalPLU isEqualToString:pluTextBox.text] == FALSE))
		{
			[ErrorAlert duplicateItem];
			return NO;
		}			
	}	
	return YES;
}

-(NSDictionary *) selectedItemHasChanged
{
	NSString *selectedDescription = selectedItem.item;
	NSString *selectedPLU = selectedItem.plu;
	NSString *selectedRetail = [NSString stringWithFormat:@"%.2f",[selectedItem.amount floatValue]];
	NSString *selectedTaxRate = [NSString stringWithFormat:@"%@",selectedItem.tax];
	NSMutableDictionary *whatsChanged = [[NSMutableDictionary alloc] init];
	
 	if (![selectedDescription isEqualToString:descriptionTextBox.text])
		[whatsChanged setObject:[NSNumber numberWithBool:YES] forKey:@"item"];	
	
	if (![selectedPLU isEqualToString:pluTextBox.text])
		[whatsChanged setObject:[NSNumber numberWithBool:YES] forKey:@"plu"];
	
	if (![selectedRetail isEqualToString:amtTextBox.text])					
		[whatsChanged setObject:[NSNumber numberWithBool:YES] forKey:@"amount"];
	
	if (![selectedTaxRate isEqualToString:taxTextBox.text])
		[whatsChanged setObject:[NSNumber numberWithBool:YES] forKey:@"tax"];
	
	return [NSDictionary dictionaryWithDictionary:whatsChanged];
}

#pragma mark - Button Actions

-(IBAction)saveItem
{
	if ([self inputChecksOut])
	{
		
		// Save item to Core Data
		OdinEvent *item = nil;
		NSArray *possibleItems = [CoreDataService searchObjectsForEntity:@"OdinEvent" 
														  withPredicate:[NSPredicate predicateWithFormat:@"plu == %@",selectedItem.plu] 
															 andSortKey:nil 
													   andSortAscending:NO 
															 andContext:self.managedObjectContext];
		// If in edit mode, edit existing item
		if ((isEditing == TRUE) && ([possibleItems count] != 0))
		{			
			item = [possibleItems objectAtIndex:0];
		}
		// Else create new item
		else
		{
			item = (OdinEvent *)[CoreDataService insertObjectForEntity:@"OdinEvent" andContext:self.managedObjectContext];		
		}
		NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];		
		
		//formats contents of amount and tax fields to numbers, then saves
		[item setAmount:[NSDecimalNumber decimalNumberWithNumber:[numberFormatter numberFromString:amtTextBox.text]]];
		[item setItem:descriptionTextBox.text];
		[item setPlu:pluTextBox.text];
		
		// since tax box is optional, equate empty field to tax = 0%
		if ([taxTextBox.text isEqualToString:@""])
			[item setTax:[NSDecimalNumber decimalNumberWithNumber:[NSNumber numberWithInt:0]]];
		else
			[item setTax:[NSDecimalNumber decimalNumberWithNumber:[numberFormatter numberFromString:taxTextBox.text]]];
		[CoreDataService saveObjectsInContext:managedObjectContext];
		//[self performSegueWithIdentifier:@"SaveSegue" sender:self];
		
		
	}
	[self.navigationController popViewControllerAnimated:YES];
}


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{// Hides the keyboard when return key pressed on any text field
	[theTextField resignFirstResponder];
	return YES;
}

- (id)initWithStyle:(UITableViewStyle)style
{
	self = [super initWithStyle:style];
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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	if(self.managedObjectContext == nil)
	{
		id appDelegate = (id)[[UIApplication sharedApplication] delegate]; 
		self.managedObjectContext = [appDelegate managedObjectContext];
	}
	amtTextBox.keyboardType=UIKeyboardTypeDecimalPad;
	taxTextBox.keyboardType=UIKeyboardTypeDecimalPad;
	// Uncomment the following line to preserve selection between presentations.
	// self.clearsSelectionOnViewWillAppear = NO;
	
	// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	// self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self populateItem:selectedItem];
	
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

-(void) populateItem:(OdinEvent *)theSelectedItem;
{// If this controller is accessed through existing item's detail disclosure button, populate the fields	
	
	descriptionTextBox.text = theSelectedItem.item;
	pluTextBox.text = theSelectedItem.plu;
	amtTextBox.text = [NSString stringWithFormat:@"%.2f",[theSelectedItem.amount floatValue]];
	taxTextBox.text = [NSString stringWithFormat:@"%@",theSelectedItem.tax];
	
	
	
	if ([theSelectedItem.allow_qty intValue] == 1)
		editQtyTextBox.text = @"YES";
	else
		editQtyTextBox.text = @"NO";
	
	if ([theSelectedItem.allow_amount intValue] == 1)
		editRetailTextBox.text = @"YES";
	else
		editRetailTextBox.text = @"NO";
	
	if ([theSelectedItem.allow_edit	intValue] == 1)
		editTransactionTextBox.text = @"YES";
	else
		editTransactionTextBox.text = @"NO";
	
	if ([theSelectedItem.chk_balance intValue] == 1)
		checkBalanceTextBox.text = @"YES";
	else
		checkBalanceTextBox.text = @"NO";
	
	if ([theSelectedItem.lock_cfg intValue] == 1)
	{
		editLockedTextBox.text = @"YES";
	}
	else
	{
		editLockedTextBox.text = @"NO";
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// Return the number of sections.
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section ==1)
		return 5;
	else
		return 4;
}

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
