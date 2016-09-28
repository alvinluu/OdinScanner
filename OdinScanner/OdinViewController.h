//
//  OdinViewController.h
//  OdinScanner
//
//  Created by Ben McCloskey on 9/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HUDsingleton.h"
#import "UIViewController+HUDControls.h"
#import "DTDevices+buttonControls.h"

#import "CardProcessor.h"
#import "Linea.h"
#import "OdinOperationQueue.h"

@interface OdinViewController : UIViewController
<MBProgressHUDDelegate,
DTDeviceDelegate>

@property (nonatomic, strong) NSArray* unSyncedArray;
@property (nonatomic, strong) NSArray* syncedArray;
@property (nonatomic, strong) NSManagedObjectContext* moc;
@property (nonatomic, strong) OdinOperationQueue* queue;
@property (nonatomic) DTDevices *dtdev;

-(NSManagedObjectContext*)moc;

-(void) showProcessActivity;
-(void) showProcessing;
-(void) showCheckBalance;
-(void) showAuthenticating;
-(void) showUploading;
-(void) showConnecting;
-(void) showSuccessful:(BOOL)wasASuccess;
-(void) showSuccess:(NSNumber *)wasASuccess;
-(void) showSuccessRecall:(NSNotification *)notification;
-(void) hideActivity;
-(void) HUDshowMessage:(NSString*) message;

// refreshes connection to Linea when returning from inactive state
-(void)refreshLinea;
-(void)disconnectLinea;
-(BOOL)isLineaPresent;

@end
