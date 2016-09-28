//
//  AttendanceViewController.h
//  Scanner
//
//  Created by Ken Thomsen on 1/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LineaSDK.h"

@interface AttendanceViewController : UIViewController <LineaDelegate>

@property (nonatomic, weak) IBOutlet UIView *backgroundView;
@property (nonatomic, weak) IBOutlet UITextField *studentIdTextBox;
@property (nonatomic, weak) IBOutlet UITextField *eventIdTextBox;
@property (nonatomic, weak) IBOutlet UILabel *studentTicketsLeft;
@property (nonatomic, weak) IBOutlet UILabel *studentTicketsPurchased;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) IBOutlet UIButton *processIdButton;
@property (nonatomic, strong) UITextField *activeField;
@property (nonatomic) BOOL isConnectedToLinea;

//-(void) setBackgroundTo:(NSString *)newColor;
-(IBAction) processId;
-(IBAction) backgroundTap;
@end
