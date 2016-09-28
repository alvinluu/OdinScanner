//
//  OdinViewController.m
//  OdinScanner
//
//  Created by Ben McCloskey on 9/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OdinViewController.h"
@interface OdinViewController ()
@end

@implementation OdinViewController

@synthesize unSyncedArray,syncedArray,moc,queue, dtdev;

#pragma mark - CoreData

//loads the array of all transactions that haven't been synced
-(NSManagedObjectContext*)moc
{
    if (!moc) {
        moc = [CoreDataService getMainMOC];
    }
    return moc;
}

#pragma mark - HUD methods
//these are the various methods to show different HUD images to denote activity
//each must be called before the method that will do the work it's displaying

-(void) showProcessActivity
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        HUDsingleton *HUD = [HUDsingleton sharedHUD];
        [[UIApplication sharedApplication].keyWindow addSubview:HUD];
        //		[self.view addSubview:HUD];
        [HUD show:YES];
        
        HUD.delegate = self;
        HUD.labelText = @"Connecting...";
        HUD.detailsLabelText = @"";
        HUD.mode = MBProgressHUDModeIndeterminate;
    });
}
-(void) HUDshowMessage:(NSString*) message {
    
    
#ifdef DEBUG
    NSLog(@"showProcessing start %@", message);
#endif
//    dispatch_async(dispatch_get_main_queue(), ^{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        HUDsingleton *HUD = [HUDsingleton sharedHUD];
        HUD.delegate = self;
        HUD.labelText = message;
        HUD.detailsLabelText = @"";
        HUD.mode = MBProgressHUDModeIndeterminate;
        if (HUD.alpha > 0) {
            
            
        } else {
            
            [HUD show:YES];
        }
        //		[self.view addSubview:HUD];
        //[self hideActivity];
    });
#ifdef DEBUG
    NSLog(@"showProcessing end");
#endif
}
-(void) showProcessing
{
    [self HUDshowMessage:@"Processing"];
}
-(void) showUploading
{
    [self HUDshowMessage:@"Uploading"];
}
-(void) showAuthenticating
{
    [self HUDshowMessage:@"Authenticating"];
}
-(void) showCheckBalance
{
    [self HUDshowMessage:@"Checking Balance"];
}
-(void) showConnecting
{
    [self HUDshowMessage:@"Connecting"];
}
-(void) showSuccessRecall:(NSNotification *)notification
{
    
    NSDictionary* userInfo = notification.userInfo;
    NSNumber* wasASuccess = (NSNumber*)userInfo[@"wasASuccess"];
    NSString* message = userInfo[@"message"];
    NSString* reference = userInfo[@"reference"];
#ifdef DEBUG
    NSLog(@"showSuccessRecall start %@ with reference %@",wasASuccess,reference);
#endif
    
    //    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
    NSLog(@"showSuccessRecall start main %@",wasASuccess);
#endif
    HUDsingleton *HUD = [HUDsingleton sharedHUD];
    BOOL successful = [wasASuccess boolValue];
//    [[UIApplication sharedApplication].keyWindow addSubview:HUD];
    HUD.delegate = self;
    if (successful == TRUE)
    {
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
        if (message) {
            HUD.labelText = [NSString stringWithFormat:@"Success! %@",message];
        } else if (reference) {
            HUD.labelText = [NSString stringWithFormat:@"Success! %@",reference];
        } else {
            HUD.labelText = @"Success!";
            
        }
    } else
    {
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-X.png"]];
        HUD.labelText = @"Error";
    }
    HUD.mode = MBProgressHUDModeCustomView;
    
    
    
    [HUD show:YES];
    [self hideActivity];
    //[self updateManageBadge];
//    [self performSelectorOnMainThread:@selector(updateManageBadge) withObject:nil waitUntilDone:NO];
#ifdef DEBUG
    NSLog(@"showSuccessRecall end %@",wasASuccess);
#endif
    //	});
}

-(void) showSuccessful:(BOOL)successful
{
    
#ifdef DEBUG
    NSLog(@"show successful hud");
#endif
        HUDsingleton *HUD = [HUDsingleton sharedHUD];
        HUD.delegate = self;
        if (successful == TRUE)
        {
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
            HUD.labelText = @"Success!";
        } else
        {
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-X.png"]];
            HUD.labelText = @"Error";
        }
        HUD.mode = MBProgressHUDModeIndeterminate;
        [HUD show:YES];
        [self hideActivity];
}
-(void) showSuccess:(NSNumber *)wasASuccess
{
    
#ifdef DEBUG
    NSLog(@"showSuccess start %@",wasASuccess);
#endif
    
    //    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
    NSLog(@"showSuccess start main %@",wasASuccess);
#endif
    HUDsingleton *HUD = [HUDsingleton sharedHUD];
    BOOL successful = [wasASuccess boolValue];
    HUD.delegate = self;
    if (successful == TRUE)
    {
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
        HUD.labelText = @"Success!";
    } else
    {
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-X.png"]];
        HUD.labelText = @"Error";
    }
    HUD.mode = MBProgressHUDModeIndeterminate;
    [HUD show:YES];
    [self hideActivity];
    //[self updateManageBadge];
#ifdef DEBUG
    NSLog(@"showSuccess end %@",wasASuccess);
#endif
    //	});
}

-(void) hideActivity
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        HUDsingleton *HUD = [HUDsingleton sharedHUD];
        if (HUD) {
            [HUD hide:YES afterDelay:1];
        }
    });
    
}

#pragma mark - Linea Device
//Connection delegate method sends messages to class when connection state changes
-(void)connectionState:(int)state
{
    dtdev = [DTDevices sharedDevice];
    NSError* error;
    switch (state) {
        case CONN_DISCONNECTED:
            //[dtdev setPassThroughSync:true error:&error];
        case CONN_CONNECTING:
            
#ifdef DEBUG
            NSLog(@"[LINEA] Linea connectionState=CONNECTING/DISCONNECTED");
#endif
            break;
        case CONN_CONNECTED:
            [[DTDevices sharedDevice] barcodeSetScanMode:0 error:nil];
            [[DTDevices sharedDevice] barcodeSetScanButtonMode:BUTTON_ENABLED error:nil];
            [[DTDevices sharedDevice] msSetCardDataMode:MS_PROCESSED_CARD_DATA error:nil];
            //Turn on the beep
            int beepData[] = {1200,100};
#ifdef DEBUG
            [[DTDevices sharedDevice] barcodeSetScanBeep:TRUE volume:0 beepData:beepData length:sizeof(beepData) error:nil];
#else
            [[DTDevices sharedDevice] barcodeSetScanBeep:TRUE volume:10 beepData:beepData length:sizeof(beepData) error:nil];
#endif
            //slow down the automatic disconnection on LP5
            if([dtdev.deviceName rangeOfString:@"LINEAPro5"].location!=NSNotFound) //checks for LP5
            {
                [[DTDevices sharedDevice] setAutoOffWhenIdle:3600 whenDisconnected:3600 error:nil]; //sets USB auto off at 1hr
            }
            //[dtdev setPassThroughSync:false error:&error];
#ifdef DEBUG
            NSLog(@"[LINEA] Linea connectionState=CONNECTED TO FIRSTVC");
#endif
            break;
    }
}
// refreshes connection to Linea when returning from inactive state
-(void)refreshLinea
{
    dtdev = [DTDevices sharedDevice];
    if ([dtdev isPresent:DEVICE_TYPE_LINEA]) {
        [dtdev addDelegate:self];
        [dtdev connect];
        [dtdev enableButton];
    }
#ifdef DEBUG
    NSLog(@"Refreshing Linea connection to FVC");
#endif
}

-(void)disconnectLinea
{
    dtdev = [DTDevices sharedDevice];
    if ([dtdev isPresent:DEVICE_TYPE_LINEA]) {
        [dtdev removeDelegate:self];
        [dtdev disconnect];
        [dtdev disableButton];
    }
}
-(BOOL)isLineaPresent {
    dtdev = [DTDevices sharedDevice];
    return [dtdev isPresent:DEVICE_TYPE_LINEA];
}
- (void)viewDidLoad
{
    // Do any additional setup after loading the view.
    // self as an oserver in case offline mode switches to "off"
    
    [super viewDidLoad];
}
- (void)viewWillAppear:(BOOL)animated
{
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(switchedToOfflineMode)
//                                                 name:@"switched to offline mode"
//                                               object:nil];
    
    /*[[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(showAlertViewToEnterUID)
     name:@"show uid alert"
     object:nil];*/
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
