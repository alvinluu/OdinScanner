//
//  Inventory.m
//  OdinScanner
//
//  Created by Alvin Luu on 1/26/16.
//
//

#import "Inventory.h"
#import "OdinEvent+Methods.h"

@interface Inventory ()

@property (nonatomic) OdinEvent* selectedItem;
@property (nonatomic) NSArray* itemArray;
@end

@implementation Inventory

@synthesize delegate, table, searchField;
@synthesize selectedItem, itemArray;

-(void)closeInventory
{
    [delegate closeInventory:selectedItem];
}
#pragma mark -TextField
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
//    float osversion = [UIDevice currentDevice].systemVersion.floatValue;
//    if (osversion >= 7.0) {
    //    } else {
//    [HUDsingleton sharedHUD].mode = MBProgressHUDModeIndeterminate;
//    [[HUDsingleton sharedHUD] showWhileExecuting:@selector(reloadTable) onTarget:self withObject:nil animated:YES];
    [self reloadTable];
//    }
    return false;
}
-(BOOL)textFieldShouldClear:(UITextField *)textField
{
#ifdef DEBUG
    NSLog(@"clear inventory");
#endif
    searchField.text = @"";
    [self reloadTable];

    return true;
}


-(IBAction)search:(id)sender
{
    float osversion = [UIDevice currentDevice].systemVersion.floatValue;
//    if (osversion >= 7.0) {
        [self reloadTable];
//    } else {
//    }
}

#pragma mark -Table View

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    OdinEvent* item = [itemArray objectAtIndex:indexPath.row];
    NSString* name = [NSString stringWithFormat:@"%i %@",item.qty.intValue,item.item];
    NSString* detail = [NSString stringWithFormat:@"$%.2f",item.amount.floatValue];
    if (item.taxable) {
        NSString* taxDetail = [NSString stringWithFormat:@"  taxed:%.2f",item.tax.floatValue];
        detail = [detail stringByAppendingString:taxDetail];
    }
//    dispatch_async(dispatch_get_main_queue(), ^{
        cell.textLabel.text = name;
        cell.detailTextLabel.text = detail;
//    });
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedItem = [itemArray objectAtIndex:indexPath.row];
    [self closeInventory];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return itemArray ? itemArray.count : 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (IBAction)buttonAction:(id)sender {
#ifdef DEBUG
    NSLog(@"Inventory button Pressed");
#endif
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton* btn = (UIButton*)sender;
        NSString* title = btn.titleLabel.text.lowercaseString;
        if ([title isEqualToString:@"submit"]) {
            [self closeInventory];
        } else {
            selectedItem = nil;
            [self closeInventory];
        }
    }
}

-(void)reloadTable
{
//    itemArray = [CoreDataService getStudentsBySearch:searchField.text];
    itemArray = [OdinEvent getItemsBySearch:searchField.text];
    [table reloadData];
}

#pragma mark -View
- (Inventory*)initWithSourceView:(UIView*)source
{
    [[NSBundle mainBundle] loadNibNamed:@"Inventory" owner:self options:nil];
    [source addSubview:self.view];
    self.view.frame = source.bounds;
    
    [self reloadTable];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
#ifdef DEBUG
    NSLog(@"load Inventory");
#endif
    [self reloadTable];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
