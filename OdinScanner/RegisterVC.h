//
//  RegisterViewController.h
//  OdinScanner
//
//  Created by Ken Thomsen on 2/22/13.
//
//

#import "OdinViewController.h"
#import "CardProcessor.h"
#import "ReceiptVC.h"
#import "Inventory.h"
#import "Patron.h"

@interface RegisterVC : OdinViewController
<UITableViewDelegate,
UITableViewDataSource,
UITextFieldDelegate,
MBProgressHUDDelegate,
InventoryDelegate,
PatronDelegate,
InPayRetailDelegate>


@end
