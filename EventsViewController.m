//
//  EventsViewController.m
//  Scanner
//
//  Created by Ben McCloskey on 12/16/11.
//  Copyright (c) 2011 Odin Inc. All rights reserved.
//

#import "EventsViewController.h"
#import "OdinEvent.h"
#import "AddEditItemVC.h"

@interface EventsViewController ()

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;  
@property (nonatomic, retain) NSMutableArray *eventArray;   
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) OdinEvent *selectedItem;

-(void) readDataForTable;  
-(void) searchForText:(NSString *)searchText;

@end

@implementation EventsViewController

@synthesize managedObjectContext, eventArray, tableView, selectedItem; 

#pragma mark - 

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{// pass selected item's indexPath to AddEditItemVC.
	if ([segue.identifier isEqualToString:@"EditSegue"])
	{
		AddEditItemVC *editItemVC = [segue destinationViewController];
		editItemVC.selectedItem = self.selectedItem;
		editItemVC.isEditing = TRUE;
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
		eventArray = [CoreDataService searchObjectsForEntity:@"OdinEvent" 
											  withPredicate:[NSPredicate predicateWithFormat:@"item beginswith[c] %@",searchText] 
												 andSortKey:@"item" 
										   andSortAscending:YES 
												 andContext:managedObjectContext];	
		
		#ifdef DEBUG 
		NSLog(@"Loading table data filtered for SearchText: \"%@\"", searchText);
		#endif
	}
	else [self readDataForTable];
    //  Force table refresh			 
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{// cancel button blanks search bar and removes keyboard
	[searchBar resignFirstResponder];
	[searchBar setText:@""];
	[self readDataForTable];
	
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{// Search button clears keyboard and searches for ID entered, similar to textDidChange
	[self searchForText:[searchBar text]];
	[searchBar resignFirstResponder];	
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(self.managedObjectContext == nil)
    {
        managedObjectContext = [CoreDataService getMainMOC];
    }
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.clearsSelectionOnViewWillAppear = NO;
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
    [super viewWillAppear:animated];
	[self readDataForTable];
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

- (void)readDataForTable
{
    //  Grab the data
    eventArray = [CoreDataService getObjectsForEntity:@"OdinEvent" 
										 withSortKey:@"item" 
									andSortAscending:YES 
										  andContext:self.managedObjectContext];

	#ifdef DEBUG 
	NSLog(@"Loading data for Items table");
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
    return [eventArray count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellId = @"Cell";
    
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		
    }
	
	
    // Get the core data object we need to use to populate this table cell
    OdinEvent *currentCell = [eventArray objectAtIndex:indexPath.row];
    //  Fill in the cell contents
    cell.textLabel.text = currentCell.item;
    cell.detailTextLabel.text = currentCell.plu;
    return cell;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)_tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{// Allows deletion of items
	
	selectedItem = [eventArray objectAtIndex:indexPath.row];
	if (editingStyle == UITableViewCellEditingStyleDelete) 
	{
		[managedObjectContext deleteObject:selectedItem];
		[CoreDataService saveObjectsInContext:self.managedObjectContext];
		[eventArray removeObjectAtIndex:indexPath.row];
		[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];		
	}
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	
	selectedItem = [eventArray objectAtIndex:indexPath.row];
	
	[self performSegueWithIdentifier:@"EditSegue" sender:self];
	
	
}



@end
