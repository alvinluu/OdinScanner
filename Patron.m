//
//  Patron.m
//  OdinScanner
//
//  Created by Alvin Luu on 1/26/16.
//
//

#import "Patron.h"
#import "OdinStudent+Methods.h"

@interface Patron ()

@property OdinStudent* selectedStudent;
@property NSArray* studentArray;

@end

@implementation Patron

@synthesize delegate, table, searchField;
@synthesize selectedStudent, studentArray;

-(void)closePatron
{
    [delegate closePatron:selectedStudent];
}
#pragma mark -TextField
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
//    float osversion = [UIDevice currentDevice].systemVersion.floatValue;
//    if (osversion >= 7.0) {
//    } else {
    //        [self reloadTable];
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
#ifdef DEBUG
    if ([sender isKindOfClass:[UITextField class]]) {
        UITextField* tf = (UITextField*)sender;
        NSLog(@"search Patron %@",tf.text);
    }
#endif
    float osversion = [UIDevice currentDevice].systemVersion.floatValue;
//    if (osversion >= 7.0) {
        [self reloadTable];
//    }
}

#pragma mark -Table View

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    OdinStudent* student = [studentArray objectAtIndex:indexPath.row];
    NSString* name = [NSString stringWithFormat:@"%@ %@",
                      [NSString printName:student.student],
                      [NSString printName:student.last_name]];
//    dispatch_async(dispatch_get_main_queue(), ^{
    
        cell.textLabel.text = name;
        cell.detailTextLabel.text = student.id_number;
//    });
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedStudent = [studentArray objectAtIndex:indexPath.row];
//    [WebService fetchStudentWithID:selectedStudent.id_number];
    [self closePatron];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return studentArray ? studentArray.count : 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (IBAction)buttonAction:(id)sender {
#ifdef DEBUG
    NSLog(@"Patron button Pressed");
#endif
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton* btn = (UIButton*)sender;
        NSString* title = btn.titleLabel.text.lowercaseString;
        if ([title isEqualToString:@"submit"]) {
            [self closePatron];
        } else {
            selectedStudent = nil;
            [self closePatron];
        }
    }
}

-(void)reloadTable
{
    NSManagedObjectContext* moc = [CoreDataHelper getMainMOC];
    studentArray = [OdinStudent getStudentsBySearch:searchField.text withMOC:moc];
    [table reloadData];
}

#pragma mark -View
- (Patron*)initWithSourceView:(UIView*)source
{
    [[NSBundle mainBundle] loadNibNamed:@"Patron" owner:self options:nil];
    [source addSubview:self.view];
    self.view.frame = source.bounds;
    
    [self reloadTable];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
#ifdef DEBUG
    NSLog(@"load Patron");
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
