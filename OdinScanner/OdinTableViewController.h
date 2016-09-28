//
//  OdinTableViewController.h
//  OdinScanner
//
//  Created by Ben McCloskey on 9/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DTDevices+buttonControls.h"
//#import "UIViewController+HUDControls.h"

@interface OdinTableViewController : UITableViewController
<MBProgressHUDDelegate>

@property (nonatomic, strong) NSArray* unSyncedArray;
@property (nonatomic, strong) NSArray* syncedArray;
@property (nonatomic, strong) NSManagedObjectContext* moc;

-(NSManagedObjectContext*)moc;
-(void) updateManageBadge;
-(void) showProcessActivity;
-(void) showProcessing;
-(void) showSuccess:(NSNumber *)wasASuccess;
-(void) HUDshowMessage:(NSString*) message;
-(void) HUDshowDetail:(NSString*) message;
-(void) HUDshowDetailNotify:(NSNotification*) notification;

-(void) hideActivity;
// refreshes connection to Linea when returning from inactive state
-(void)refreshLinea;
-(void)disconnectLinea;
-(BOOL)isLineaPresent;

@end
