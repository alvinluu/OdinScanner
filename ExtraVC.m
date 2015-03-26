//
//  ExtraVC.m
//  OdinScanner
//
//  Created by KenThomsen on 10/14/14.
//
//

#import "ExtraVC.h"
#import "VoidVC.h"
#import "CardProcessor.h"

@interface ExtraVC ()

@property (nonatomic, strong) NSArray *syncedArray;
@property (nonatomic, strong) NSManagedObjectContext *moc;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) MBProgressHUD *voidHUD;
@end

@implementation ExtraVC

@synthesize syncedArray;
@synthesize moc;
@synthesize HUD,voidHUD;

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	// Get managedObjectContext from AppDelegate
	if (moc == nil)
	{
		moc = [CoreDataHelper getMainMOC];
	}
	
	
	HUD = [HUDsingleton theHUD].HUD;
	HUD.delegate = self;
	[self.view addSubview:HUD];
}
- (void)viewDidAppear:(BOOL)animated {
	
	[[DTDevices sharedDevice] addDelegate:self];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showSwipeCreditDebitCard
{
	voidHUD.labelText = @"Void";
	voidHUD.detailsLabelText = @"Swipe your credit/debit card";
	[voidHUD show:NO];
}
- (IBAction)voidCreditDebitTransaction:(id)sender {
	voidHUD = [[MBProgressHUD alloc] init];
	voidHUD.delegate = self;
	[self.view addSubview:voidHUD];
	[self showSwipeCreditDebitCard];
	//[voidHUD showWhileExecuting:@selector(showSwipeCreditDebitCard) onTarget:self withObject:nil animated:NO];
}

//fires when a swipe card is used
//Swipe expired card on test server returns SUCCESS
-(void)magneticCardData:(NSString *)track1 track2:(NSString *)track2 track3:(NSString *)track3
{
	[voidHUD hide:YES];
	NSLog(@"\n\nTrack 1:%@\n\nTrack 2:%@\n\nTrack 3:%@\n\n",track1,track2,track3);
	
	
	NSString *magneticData = [NSString stringWithFormat:@"%@%@",track1,track2];
	CardProcessor* ccProcess = [CardProcessor initialize:magneticData];
	NSNumber *ccdigit = [ccProcess getCardLast4Digits];
	[[SettingsHandler sharedHandler] setCCdigitToVoid:[ccdigit stringValue]];
	
	VoidVC *voidvc  = [self.storyboard instantiateViewControllerWithIdentifier:@"voidvc"];
	//[self.view addSubview:voidvc.view];
	[self.navigationController pushViewController:voidvc animated:YES];
}
-(void)loadCreditCardPastTransaction
{
	
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
