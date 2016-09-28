 //
//  TransactionTests.m
//  OdinScanner
//
//  Created by Ben McCloskey on 10/16/12.
//
//

#import "TransactionTests.h"

#import "OdinScanner-Prefix.pch"
#import "OdinEvent.h"
#import "TestIf.h"

@implementation TransactionTests
{
	OdinEvent *anItem;
}
- (void)setUp
{
    [super setUp];
	anItem = [self createAnItem];
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    anItem = nil;
    [super tearDown];
}

-(void)testReferenceIsIncremented
{
	NSString *initRef = [[SettingsHandler sharedHandler] getReference];
	NSString *initRefNumberString = [initRef substringFromIndex:2];
	
	[[SettingsHandler sharedHandler] incrementReference];
	
	NSString *postRef = [[SettingsHandler sharedHandler] getReference];
	NSString *postRefNumberString = [postRef substringFromIndex:2];
	
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	int initRefNumber = [[formatter numberFromString:initRefNumberString] intValue];
	int postRefNumber = [[formatter numberFromString:postRefNumberString] intValue];
	
	XCTAssertEqual((initRefNumber + 1), postRefNumber, @"Failed to properly increment reference number");
	
	//since we incremented it, set it back
	[[NSUserDefaults standardUserDefaults] setValue:initRefNumberString forKey:@"reference"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	NSString *actualRefNumberString = [[NSUserDefaults standardUserDefaults] objectForKey:@"reference"];
	int actualRefNumber = [[formatter numberFromString:actualRefNumberString] intValue];
	
	XCTAssertEqual(initRefNumber, actualRefNumber, @"Failed to properly re-set reference number");
}

- (void)testCanPurchaseWithBalance;
{
	//if ([TestIf account:[self createAccountWithBalance] canPurchaseItem:anItem forAmount:[NSNumber numberWithInt:1]] == FALSE)
	//	XCTFail(@"Failed purchasing item with balance");
}

- (void)testCanPurchaseWithoutBalance;
{
	//if ([TestIf account:[self createAccountWithNoBalance] canPurchaseItem:anItem forAmount:[NSNumber numberWithInt:1]])
	//	XCTFail(@"Able to purchase item without a balance");
}

- (NSDictionary *)createAccountWithBalance
{
	NSDictionary *billyBigBucks = [NSDictionary dictionaryWithObjectsAndKeys:
								   @"Johnny",@"student",
								   @"BigBucks",@"last_name",
								   @"9999",@"id_number",
								   @"1000000",@"present",
								   nil];
	return billyBigBucks;
}

- (NSDictionary *)createAccountWithNoBalance
{
	NSDictionary *zoeZeroBucks = [NSDictionary dictionaryWithObjectsAndKeys:
								  @"Zoe",@"student",
								  @"ZeroBucks",@"last_name",
								  @"0000",@"id_number",
								  @"0",@"present",
								  nil];
	return zoeZeroBucks;
}

-(OdinEvent *) createAnItem
{
	anItem = [CoreDataService insertObjectForEntity:@"OdinEvent" andContext:ctx];
	anItem.chk_balance = [NSNumber numberWithBool:TRUE];
	
	NSError *saveError = nil;
	if ([ctx save:&saveError])
	{
		NSArray *itemsArray = [CoreDataService getObjectsForEntity:@"OdinEvent" withSortKey:nil andSortAscending:NO andContext:ctx];
		if ([itemsArray count] >0 )
		{
			OdinEvent *theItem = [itemsArray objectAtIndex:0];
			return theItem;
		}
		else
			return nil;
	}
	else
		return nil;
}

@end
