//
//  AttendanceRecordViewController.h
//  Scanner
//
//  Created by Ken Thomsen on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AttendanceRecordViewController : UITableViewController  <UISearchBarDelegate, LineaDelegate> 

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSMutableArray *attendanceArray;
@property (nonatomic, weak) IBOutlet UISearchBar *idSearch;

- (void)readDataForTable;
-(void) searchForText:(NSString *)searchText;
@end
