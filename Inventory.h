//
//  Inventory.h
//  OdinScanner
//
//  Created by Alvin Luu on 1/26/16.
//
//

#import <UIKit/UIKit.h>
@protocol InventoryDelegate
@required
- (void) closeInventory:(OdinEvent*)item;
@end


@interface Inventory : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (retain) id delegate;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet UITextField *searchField;


- (Inventory*)initWithSourceView:(UIView*)source;

@end

