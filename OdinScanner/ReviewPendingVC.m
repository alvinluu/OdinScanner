//
//  ReviewTemptran.m
//  Scanner
//
//  Created by Ben McCloskey on 12/16/11.
//  Copyright (c) 2011 Odin Inc. All rights reserved.
//

#import "ReviewPendingVC.h"
#import "OdinTransaction.h"
#import "OdinEvent.h"
#import "CardProcessor.h"
#import "VoidVC.h"
#import "TableCustomCell.h"

@interface ReviewPendingVC ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;  
@property (nonatomic, retain) NSMutableArray *transactArray;   
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong)	  IBOutlet UISearchBar *idSearch;
-(void) readDataForTable;
-(void) searchForText:(NSString *)searchText;

@end

@implementation ReviewPendingVC

@synthesize managedObjectContext, tableView, idSearch, transactArray;
OdinTransaction *selectedItem2;

#pragma mark - Linea Delegate Calls

-(void) barcodeData:(NSString *)barcode type:(int)type
{// When scanning a card, if table is not editing, search entries for all transactions matching scanned ID
	
	if ([tableView isEditing] == FALSE)
	{
		barcode = [barcode cleanBarcode];
		[idSearch setText:barcode];
		[self searchForText:barcode];
	}
}
//fires when a swipe card is used
//Swipe expired card on test server returns SUCCESS
-(void)magneticCardData:(NSString *)track1 track2:(NSString *)track2 track3:(NSString *)track3
{
	NSLog(@"\n\nTrack 1:%@\n\nTrack 2:%@\n\nTrack 3:%@\n\n",track1,track2,track3);
	
	
	NSString *magneticData = [NSString stringWithFormat:@"%@%@",track1,track2];
	CardProcessor* ccProcess = [CardProcessor initialize:magneticData];
    if (ccProcess == nil ) {return;}
	
#ifdef DEBUG
	NSLog(@"load CC card %@",[SettingsHandler sharedHandler].ccdigitToVoid);
#endif
	NSString* predicate = [NSString stringWithFormat:@"CC%@",[ccProcess getCardLast4Digits]];
	
	if ([tableView isEditing] == FALSE)
	{
		[idSearch setText:predicate];
		[self searchForText:predicate];
	}
}
#pragma mark - Search Bar Delegate Calls

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{	// Searches transactions for ID numbers matching values entered into search bar
	[self searchForText:searchText];
}

-(void) searchForText:(NSString *)searchText
{
	if ([searchText length] != 0)
	{		
		transactArray = [CoreDataService searchObjectsForEntity:@"OdinTransaction" 
												 withPredicate:[NSPredicate predicateWithFormat:@"sync == false and id_number beginswith[c] %@ or item contains[c] %@",searchText,searchText]
													andSortKey:@"timeStamp" 
											  andSortAscending:NO 
													andContext:managedObjectContext];	
		
		#ifdef DEBUG 
		NSLog(@"Loading table data filtered for SearchText: \"%@\"", searchText);
		#endif
	}
	else [self readDataForTable];
    //  Force table refresh			 
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{// Search button clears keyboard and searches for ID entered, similar to textDidChange
	[self searchForText:[searchBar text]];
	[searchBar resignFirstResponder];	
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{// cancel button blanks search bar and removes keyboard
	[searchBar resignFirstResponder];
	[searchBar setText:@""];
	[self readDataForTable];	
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar 
{// Shows cancel button when user begins entering search term
	[searchBar setShowsCancelButton:YES animated:YES];
    return YES;  
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar 
{// Hides cancel button when user begins entering search term
    [searchBar setShowsCancelButton:NO animated:YES];
    return YES;  
} 

#pragma mark - View Init

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
    if (managedObjectContext == nil)
    {
        managedObjectContext = [CoreDataService getMainMOC];
    }
	// Add edit button
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	self.tableView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{	
    [self readDataForTable];	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLinea) name:@"refreshLinea" object:nil];
    [super viewWillAppear:animated];
	#ifdef DEBUG
NSLog(@"Loading ReviewTemptran");
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
	// Cleanup notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    #ifdef DEBUG 
	NSLog(@"Removing ReviewVC from notifications");
	#endif
	[self disconnectLinea];
	//[[DTDevices sharedDevice] disconnect];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (void)readDataForTable
{
	// loads all unsynch'd transactions into table's dataArray
    //  Grab the data from persistent store and load into transactArray
    transactArray = [CoreDataService searchObjectsForEntity:@"OdinTransaction" 
											 withPredicate:[NSPredicate predicateWithFormat:@"sync == false"] 
												andSortKey:@"timeStamp"
										  andSortAscending:NO 
												andContext:managedObjectContext];	
    #ifdef DEBUG 
	NSLog(@"Loading data for table");
	#endif
    //  Force table refresh
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [transactArray count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellId = @"cell";
    
    TableCustomCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellId];
    if (cell != nil) {
        // Get the core data object we use to populate the cell in a given row
        OdinTransaction *currentCell = [transactArray objectAtIndex:indexPath.row];
        
        //  Fill in the cell contents
        cell.title.text = [NSString stringWithFormat:@"[%@ %@] %@",[NSDate asStringDateWithFormat:[currentCell qdate]],[currentCell time] ,[currentCell id_number]];
        if (currentCell.first || currentCell.last) {
#ifdef DEBUG
            NSLog(@"has first %@ or last name %@",currentCell.first,currentCell.last);
#endif
        } else {
            OdinStudent* student = [OdinStudent getStudentByIDnumber:currentCell.id_number];
            currentCell.first = student.student;
            currentCell.last = student.last_name;
#ifdef DEBUG
            NSLog(@"has first %@ or last name %@",currentCell.first,currentCell.last);
#endif
            [CoreDataHelper saveObjectsInContext:managedObjectContext];
        }
        
        cell.detail.text = [NSString stringWithFormat:@"%@ %@",[NSString printName:currentCell.first],[NSString printName:currentCell.last]];
        
        cell.detail2.text = [NSString stringWithFormat:@"[%@] %@ %@ for $%.2f",[currentCell reference], [currentCell qty],[currentCell item], [[currentCell amount] floatValue]];
        
        cell.accessoryButton.hidden = ![currentCell.payment isEqualToString:@"G"];
        }
    return cell;
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{// Allows deletion of unsyc'd transactions
	
	OdinTransaction *currentCell = [transactArray objectAtIndex:indexPath.row];
	if ((editingStyle == UITableViewCellEditingStyleDelete) && ([TestIf canDeleteTransaction:currentCell]))
	{		
		// delete object from: table's datasource array, core data, and tableview itself
        [managedObjectContext deleteObject:currentCell];
        [CoreDataService saveObjectsInContext:self.managedObjectContext];
        [transactArray removeObjectAtIndex:indexPath.row];
        [aTableView reloadData];
	} else {
		
		if ([currentCell.sync boolValue]) {
			//can't be deleted if it's already been uploaded
			[ErrorAlert synchedAlert];
		} else {
			//can't be deleted if "allow_edit" is false
			[ErrorAlert cannotEditItem:currentCell.item];
		}
	}
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	selectedItem2 = [transactArray objectAtIndex:indexPath.row];
#ifdef DEBUG
	NSLog(@"Tran item %@ %@ %@",selectedItem2.item, selectedItem2.cc_approval, selectedItem2.cc_tranid);
#endif
	if (selectedItem2.cc_approval) {
		
		
		[self performSegueWithIdentifier:@"voidCreditCard" sender:self];
	}
}

#pragma mark - Segue
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{// pass selected item's indexPath to AddEditItemVC.
	if ([segue.identifier isEqualToString:@"voidCreditCard"])
	{
#ifdef DEBUG
		NSLog(@"prepareforSegue");
#endif
		VoidVC *editItemVC = [segue destinationViewController];
		editItemVC.selectedItem = selectedItem2;
	}
}
@end
