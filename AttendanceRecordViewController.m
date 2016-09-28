//
//  AttendanceRecordViewController.m
//  Scanner
//
//  Created by Ken Thomsen on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AttendanceRecordViewController.h"
#import "OdinAttendance.h"
#import "OdinEvent.h"
#import "DefaultItem.h"
#import "NSDate+asStringWithFormat.h"

@implementation AttendanceRecordViewController

@synthesize attendanceArray, managedObjectContext, idSearch;

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

- (void)readDataForTable
{
    //  Grab the data from persistent store
    attendanceArray = [CoreDataHelper getObjectsForEntity:@"OdinAttendance" 
											  withSortKey:@"timeStamp" 
										 andSortAscending:NO 
											   andContext:self.managedObjectContext];
    NSLog(@"Loading data for table");
    //  Force table refresh
    [self.tableView reloadData];
}

- (void) refreshLinea
{	// refreshes connection to Linea when returning from inactive state
    [[Linea sharedDevice] addDelegate:self];
    [[Linea sharedDevice] connect];
	NSLog(@"Refreshing Linea connection to ReviewTemptranVC");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Get managedObjectContext from AppDelegate
    if (self.managedObjectContext == nil)
    {
        id appDelegate = (id)[[UIApplication sharedApplication] delegate]; 
        self.managedObjectContext = [appDelegate managedObjectContext];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	[self setTableView:nil];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{	
    [self readDataForTable];	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLinea) name:@"refreshLinea" object:nil];
    [super viewWillAppear:animated];
	NSLog(@"Loading Attendance Review");
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
    NSLog(@"Removing ReviewVC from notifications");
	[[Linea sharedDevice] removeDelegate:self];
	[[Linea sharedDevice] disconnect];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Linea Delegate Calls

-(void)connectionState:(int)state 
{
	switch (state) {
		case CONN_DISCONNECTED:
		case CONN_CONNECTING:
			NSLog(@"[LINEA] Linea connectionState=CONNECTING/DISCONNECTED");
			break;
		case CONN_CONNECTED:
			// If Linea is connected, enable multi-scan and enable regular beep
            [[Linea sharedDevice] setScanMode:0];
            //Turn on the beep 
            int beepData[] = {1200,100};
            [[Linea sharedDevice] setScanBeep:TRUE volume:10 beepData:beepData length:sizeof(beepData)]; 
			NSLog(@"[LINEA] Linea connectionState=CONNECTED TO REVIEWATTENDANCE");            
			break;
	}
}

-(void) barcodeData:(NSString *)barcode type:(int)type
{// When scanning a card, if table is not editing, search entries for all transactions matching scanned ID
	
	[idSearch setText:barcode];
	[self searchForText:barcode];
	
}

-(void) searchForText:(NSString *)searchText
{
	if ([searchText length] != 0)
	{		
		attendanceArray = [CoreDataHelper searchObjectsForEntity:@"OdinAttendance" 
												   withPredicate:[NSPredicate predicateWithFormat:@"studentId beginswith[c] %@",searchText]
													  andSortKey:@"timeStamp" 
												andSortAscending:NO 
													  andContext:managedObjectContext];		
		
		NSLog(@"Loading table data filtered for SearchText: \"%@\"", searchText);
	}
	else [self readDataForTable];
    //  Force table refresh			 
    [self.tableView reloadData];
}

#pragma mark - Search Bar Delegate Calls

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{	// Searches transactions for ID numbers matching values entered into search bar
	[self searchForText:searchText];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [attendanceArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    OdinAttendance *currentCell = [attendanceArray objectAtIndex:indexPath.row];
    
    //  Fill in the cell contents
    cell.textLabel.text = [currentCell studentId];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Used \"%@\" on %@",[currentCell eventId],[[currentCell timeStamp] asStringWithFormat:@"@DD/@MM at @hh:@mm:@ss"]];
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

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
