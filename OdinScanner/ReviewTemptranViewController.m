//
//  ReviewTemptran.m
//  Scanner
//
//  Created by Ben McCloskey on 12/16/11.
//  Copyright (c) 2011 Odin Inc. All rights reserved.
//

#import "ReviewTemptranViewController.h"
#import "OdinTransaction.h"
#import "OdinEvent.h"

@interface ReviewTemptranViewController ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;  
@property (nonatomic, retain) NSMutableArray *transactArray;   
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong)	  IBOutlet UISearchBar *idSearch;

-(void) readDataForTable;
-(void) searchForText:(NSString *)searchText;

@end

@implementation ReviewTemptranViewController

@synthesize managedObjectContext, tableView, idSearch, transactArray;

#pragma mark - Linea Delegate Calls

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
			// If Linea is connected, enable multi-scan and enable regular beep
            [[DTDevices sharedDevice] barcodeSetScanMode:0 error:nil];
            //Turn on the beep 
            int beepData[] = {1200,100};
			[[DTDevices sharedDevice] barcodeSetScanBeep:TRUE volume:10 beepData:beepData length:sizeof(beepData) error:nil];
			#ifdef DEBUG 
			NSLog(@"[LINEA] Linea connectionState=CONNECTED TO REVIEWTEMPTRAN ");
			#endif
			break;
	}
}

-(void) barcodeData:(NSString *)barcode type:(int)type
{// When scanning a card, if table is not editing, search entries for all transactions matching scanned ID
	
	if ([tableView isEditing] == FALSE)
	{
		barcode = [barcode cleanBarcode];
		[idSearch setText:barcode];
		[self searchForText:barcode];
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
		transactArray = [CoreDataHelper searchObjectsForEntity:@"OdinTransaction" 
												 withPredicate:[NSPredicate predicateWithFormat:@"sync == false and id_number beginswith[c] %@",searchText] 
													andSortKey:@"plu" 
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

- (void) refreshLinea
{	// refreshes connection to Linea when returning from inactive state
	[[DTDevices sharedDevice] addDelegate:self];
    [[DTDevices sharedDevice] connect];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (managedObjectContext == nil)
    {
        managedObjectContext = [CoreDataHelper getMainMOC];
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
    [[DTDevices sharedDevice] addDelegate:self];
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
	[[DTDevices sharedDevice] removeDelegate:self];
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
    transactArray = [CoreDataHelper searchObjectsForEntity:@"OdinTransaction" 
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
    static NSString *CellId = @"Cell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
    }
    
    // Get the core data object we use to populate the cell in a given row
    OdinTransaction *currentCell = [transactArray objectAtIndex:indexPath.row];
#ifdef DEBUG
	//NSLog(@"%@",[[currentCell asDictionary] description]);
#endif	
    
    //  Fill in the cell contents
    cell.textLabel.text = [NSString stringWithFormat:@"[%@] %@",[NSDate asStringDateWithFormat:[currentCell qdate]] ,[currentCell id_number]];
	
    cell.detailTextLabel.text = [NSString stringWithFormat:@"[%@] %@ %@ for $%.2f",[currentCell reference],[currentCell qty],[currentCell item], [[currentCell amount] floatValue]];
    
    return cell;
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{// Allows deletion of unsyc'd transactions
	
	OdinTransaction *currentCell = [transactArray objectAtIndex:indexPath.row];
	if ((editingStyle == UITableViewCellEditingStyleDelete) && ([TestIf canDeleteTransaction:currentCell]))
	{		
		// delete object from: table's datasource array, core data, and tableview itself
        [managedObjectContext deleteObject:currentCell];
        [CoreDataHelper saveObjectsInContext:self.managedObjectContext];
        [transactArray removeObjectAtIndex:indexPath.row];
        [aTableView reloadData];
	}
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
