//
//  ManagementViewController.m
//  OdinScanner
//
//  Created by Ben McCloskey on 2/9/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "ManagementVC.h"
#import "OdinViewController.h" //Alvin
#import "OdinEvent.h"
#import "OdinTransaction.h"
//#import "Temptran.h"
#import "TestIf.h"
#import "SynchronizationOperation.h"
#import "StudentUpdate.h"
#import "NSObject+SBJson.h"
#import "Linea.h"
#import "NetworkConnection.h"

#import "UIAlertView+showSafely.h"

@interface ManagementVC ()

@property (nonatomic, strong) UISwitch *offlineModeSwitch;
@property (nonatomic, strong) UISwitch *holdTransactionsSwitch;
@property (weak, nonatomic) IBOutlet UILabel *pendingLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadedLabel;
@property (weak, nonatomic) IBOutlet UILabel *resyncLabel;


//These two IBActions are actually called through didSelectRowAtPath
-(IBAction) reSync;
-(void) finishReSync;
-(IBAction) uploadTransactions;
-(void) showUploadActivity;
-(void) showUploadHUD:(NSNumber *)numberOfItems;
-(void) sendBatchToPrefServer;
-(void) updateItemList:(NSNotification*)notification;
-(void) updateStudentList:(NSNotification*)notification;
-(void) updateReferenceNumberNotif:(NSNotification*)notification;
-(void) updateReferenceNumber;
-(void) finishUploadTransaction:(NSNotification*)notification;

@end

@implementation ManagementVC

@synthesize offlineModeSwitch,holdTransactionsSwitch;
#define ERR_FAIL_TO_CONNECT_TO_SERVER @"Failed to connect to server"
#define ERR_FAIL_TO_DOWNLOAD_ITEM @"Failed to download items"
#define ERR_FAIL_TO_DOWNLOAD_STUDENT @"Failed to download students"
#define ERR_UNABLE_TO_FIND_UID @"Unable to Sync with UID"

#pragma mark - HUD Methods

bool successItemDownload;
bool successStudentDownload;
bool successReferenceDownload;

-(void) showUploadActivity
{
    MBProgressHUD *HUD = [HUDsingleton sharedHUD];
    [[UIApplication sharedApplication].keyWindow addSubview:HUD];
    HUD.delegate = self;
    HUD.labelText = @"Connecting...";
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.detailsLabelText = [NSString stringWithFormat:@""];
    [HUD show:YES];
}

-(void)showUploadHUD:(NSNumber *)numberOfItems
{
    dispatch_async(dispatch_get_main_queue()
                   , ^{
                       MBProgressHUD *HUD = [HUDsingleton sharedHUD];
                       HUD.delegate = self;
                       HUD.labelText = @"Uploading Transactions...";
                       HUD.detailsLabelText = [NSString stringWithFormat:@"(%@ left)",numberOfItems];
                       [HUD show:YES];
                   });
}
-(void)showVerifyHUD:(NSNumber *)numberOfItems
{
    dispatch_async(dispatch_get_main_queue()
                   , ^{
                       MBProgressHUD *HUD = [HUDsingleton sharedHUD];
                       HUD.delegate = self;
                       HUD.labelText = @"Verifying Transactions...";
                       HUD.detailsLabelText = [NSString stringWithFormat:@"(%@ left)",numberOfItems];
                   });
    //	[HUD show:YES];
}
-(void)showVerifyStatus:(NSString *)message
{
    MBProgressHUD *HUD = [HUDsingleton sharedHUD];
    HUD.delegate = self;
    HUD.labelText = @"Verifying Transactions...";
    HUD.detailsLabelText = message;
    //	[HUD show:YES];
}
#pragma mark - Button methods

//downloads items from server and saves them as OdinEvents (replaces existing OdinEvents)
-(IBAction)reSync
{
    
    if ([NetworkConnection isInternetOffline]) {
        [ErrorAlert noInternetConnection];
        return;
    }
    
    
    //If uid is empty, prompt user to input uid; otherwise, synchronize
    if ([[AuthenticationStation sharedHandler].serialNumber hasPrefix:@"no device"]) {
        if ([SettingsHandler sharedHandler].useLineaDevice) {
            [ErrorAlert simpleAlertTitle:@"Serial Not Found" message:@"Scanner is inactive. \nClick scan button and try again."];
        } else {
            [ErrorAlert simpleAlertTitle:@"Serial Not Found" message:@""];
        }
    } else if ([[SettingsHandler sharedHandler].uid isEqualToString:@""]) {
#ifdef DEBUG
        NSLog(@"no uid");
#endif
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"show uid alert" object:self];
        [UIView animateWithDuration:0 animations:^{
            [self showAlertViewToEnterUID];
        } completion:^(BOOL finished) {
            [[AuthenticationStation sharedHandler] startAuth];
            [TestIf appCanUseSchoolServerAFN];
            [[AuthenticationStation sharedHandler] endAuth];
        }];
    } else {
        [self doSync];
    }
}

-(void)doSync
{
#ifdef DEBUG
    NSLog(@"doSync");
#endif
    //tell auth station we're starting a sync
    
    
    //    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //disable all alert while re-sync
    //[[HUDsingleton sharedHUD].HUD showWhileExecuting:@selector(finishReSync) onTarget:self withObject:nil animated:YES];
    //    [self performSelectorOnMainThread:@selector(showCacheActivity) withObject:nil waitUntilDone:true ];
    //do something
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //your background code here
        [self showCacheActivity];
        //reset PHP server path to basePath
        [[AuthenticationStation sharedHandler] reset];
        [self resetResyncSettings];
        //do something
        NSArray* connection_status = [TestIf appCanUseSchoolServerAFN];
#ifdef DEBUG
        NSLog(@"connection_status %@", [connection_status description]);
#endif
        
        if ([connection_status count] > 0) {
            id status = [connection_status objectAtIndex:0];
            //NSDictionary* status = [WebService getAuthStatus];
            
            if ([status isKindOfClass:[NSDictionary class]]) {
                if ([[status valueForKey:@"response_code"] isEqualToString:@"200"]) {
                    
                    //Synchronize Settings
                    //					[SynchronizationOperation syncSettings];
                    
                    NSString* responseString = [status valueForKey:@"response_string"];
                    [SynchronizationOperation updateSettings:[responseString JSONValue]];
                    
                    [[AuthenticationStation sharedHandler] startAuth];
                    [self startItemList];
                    
                } else {
                    NSString* responseString = [status valueForKey:@"response_string"];
                    NSString* responseError = [status valueForKey:@"response_error"];
                    
                    if ([responseString hasSuffix:@"uid not found!!"]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            [self hideActivity];
                            [self showAlertViewToEnterUID];
                        });
                    } else {
                        NSString* message = [NSString stringWithFormat:@"%@ \n\n%@",responseString,responseError];
                        //[ErrorAlert simpleAlertTitle:@"Failed to Connect to Server" message:message];
                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ERR_FAIL_TO_CONNECT_TO_SERVER message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry",@"Email", nil];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // Update the UI
                            
                            [alert show];
                        });
                    }
                    return;
                }
                
            } else {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    //your code here
                    [ErrorAlert simpleAlertTitle:@"Not a return status object" message:@""];
                });
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //your main thread code here
        });
    });
    
    
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    
    //    });
    
    
}

-(void) finishReSync
{
    
    [self updateStatus];
    
    //tell AuthStation we're done syncing
    
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* itemMSG = [NSString stringWithFormat:@"SUCCESS (%i)",[OdinEvent count]];
        NSString* studentMSG = [NSString stringWithFormat:@"SUCCESS (%i)",[OdinStudent count]];
        NSString* reference = [NSString stringWithFormat:@"SUCCESS (%@)",[SettingsHandler sharedHandler].getReference];
        NSString* message = [NSString stringWithFormat:@"Item: %@ \nStudent: %@ \nReference:%@",
                             ([SettingsHandler sharedHandler].isItemSuccessReSync) ?  itemMSG: @"FAILED",
                             ([SettingsHandler sharedHandler].isStudentSuccessReSync) ?  studentMSG: @"FAILED",
                             [SettingsHandler sharedHandler].getReference];
        
        [ErrorAlert simpleAlertTitle:@"Re-Sync Status!" message:message];
        [self hideActivity];
    });
    [[AuthenticationStation sharedHandler] endAuth];
    
#ifdef DEBUG
    NSLog(@"finish resync");
#endif
}

#pragma mark - Upload Transactions
//uploads all saved transactions without a sync == TRUE
-(IBAction)uploadTransactions
{
#ifdef DEBUG
    NSLog(@"uploadTransactions start");
#endif
    if ([NetworkConnection isInternetOffline]) {
        [ErrorAlert noInternetConnection];
        return;
    }
    
    
    
    self.unSyncedArray = [OdinTransaction reloadUnSyncedArray];
    if ([self.unSyncedArray count] == 0)
    {
        //[ErrorAlert noUploads];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nothing to Upload"
                                                        message:@"All transactions have been posted"
                                                       delegate:self
                                              cancelButtonTitle:@"Verify Past"
                                              otherButtonTitles:@"OK",nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
        
        return;
    }
    
    [self performSelectorInBackground:@selector(startUploadTransaction) withObject:nil];
}

-(void) startUploadTransaction
{
    //	[self performSelectorOnMainThread:@selector(showCacheActivity) withObject:nil waitUntilDone:true ];
    [[AuthenticationStation sharedHandler]startAuth];
    [self showCacheActivity];
    MBProgressHUD* HUD = [HUDsingleton sharedHUD];
    
#ifdef DEBUG
    NSLog(@"uploading transaction");
#endif
    
    if ([TestIf appCanUseSchoolServerAFN])
    {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        //Show connection status on HUD title
        HUD.labelText = @"Authenticating";
        HUD.detailsLabelText = @"Success";
        
        [self sendBatchToPrefServer];
    } else
    {
        //[ErrorAlert noSchoolServer];
        [ErrorAlert noSchoolServer];
        //Show connection status on HUD title
        HUD.labelText = @"Authenticating";
        HUD.detailsLabelText = @"Failed";
        [HUD hide:true afterDelay:1];
        [[AuthenticationStation sharedHandler]endAuth];
    }
}
-(void)finishUploadTransaction:(NSNotification*)notification
{
#ifdef DEBUG
    NSLog(@"finishUploadTransaction");
#endif
    
    [self hideActivity];
    //        [self reloadTableLabel];
    sleep(1);
    int count = [OdinTransaction reloadUnSyncedArray].count;
    NSString* message = count > 0 ? [NSString stringWithFormat:@"%i Failed",count] : @"";
    [ErrorAlert simpleAlertTitle:@"Upload Completed!!" message:message];
    [[AuthenticationStation sharedHandler]endAuth];
}
#pragma mark - Synchoronize Functions

-(void) resetResyncSettings
{
    successItemDownload = false;
    successStudentDownload = false;
    successReferenceDownload = false;
}
/*
 * Download items from webservice /Portable/Items (protable.prtblconfig) and update to ipod FirstViewController
 * version 2.5.9 add return dept_code
 */
-(void) startItemList
{
    [self HUDshowMessage:@"Download Items"];
    [WebService fetchItemList];
    
}
-(void) updateItemList:(NSNotification*)notification
{
#ifdef DEBUG
    NSLog(@"updateItemList");
#endif
    
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
    [self HUDshowMessage:@"Update Items"];
    
    NSDictionary* userInfo = notification.userInfo;
    NSString* responseCode = userInfo[@"response_code"];
    NSString* responseString = userInfo[@"response_string"];
    NSArray* itemsArray = [[NSArray alloc] init];
    if ([responseString  isEqual: @""] || [responseString  isEqual: @"{}"]) {
        
    } else {
        itemsArray = [responseString JSONValue];
    }
    
    
    //    [[SettingsHandler sharedHandler] setIsItemSuccessReSync:NO];
    
    //download item list
    //	NSArray *itemsArray = [WebService fetchItemList];
    __block int itemListSize = [itemsArray count];
    
    if (itemListSize > 0)
    {
        
        //ERROR: downloading
        NSDictionary* status = [itemsArray objectAtIndex:0];
        if ([status valueForKey:@"response_code"]) {
            [self hideActivity];
            NSString* serial = [NSString stringWithFormat:@"serial:%@",[AuthenticationStation sharedHandler].serialNumber];
            NSString* portid = [NSString stringWithFormat:@"portableid:%@",[SettingsHandler sharedHandler].uid];
            NSString* message = [NSString stringWithFormat:@"%@\n%@\n%@",[status valueForKey:@"response_error"],serial,portid];
            //[ErrorAlert simpleAlertTitle:@"Failed to Connect to Server" message:message];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ERR_FAIL_TO_DOWNLOAD_ITEM message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry",@"Email", nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                // Update the UI
                
                [alert show];
            });
            
        } else {
            successItemDownload = true;
            __block int itemListTotalSize = itemListSize;
            __block int randamount = itemListTotalSize > 50 ? 50 : 1;
            __block int randnum = arc4random()%itemListTotalSize%randamount;
            
            //HUD.detailsLabelText = [NSString stringWithFormat:@"Retrieving %i Items Success", [itemsArray count]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //your code here
                NSManagedObjectContext *moc = [CoreDataHelper getMainMOC];
                
                [CoreDataService deleteAllObjectsForEntity:@"OdinEvent" andContext:moc];
                
                for (NSDictionary *itemAsDictionary in itemsArray)
                {
                    itemListSize--;
                    randnum--;
                    OdinEvent *itemToAdd = [CoreDataService insertObjectForEntity:@"OdinEvent" andContext:moc];
                    [itemToAdd loadValuesFromDictionaryRepresentation:itemAsDictionary];
                    
                    //				dispatch_async(dispatch_get_main_queue(), ^{
                    //                     Update the UI
                    if (randnum < 0) {
                        randamount = itemListTotalSize > 50 ? 50 : 1;
                        randnum = arc4random()%itemListTotalSize%randamount;
                        //                        //						HUD.detailsLabelText = [NSString stringWithFormat:@"Updating items %i", itemListSize];
                        //
                        //                        NSString* message = [NSString stringWithFormat:@"Updating items %i", itemListSize];
                        //                        [self HUDshowDetail:message];
                        NSString* message = [NSString stringWithFormat:@"%i items", itemListSize];
                        [self HUDshowDetail:message];
                    }
                    
                    //				});
                }
                //			HUD.detailsLabelText = @"Updating item done";
                [self HUDshowDetail:@"Updating item done"];
                [CoreDataService saveObjectsInContext:moc];
                
            });
            [[SettingsHandler sharedHandler] setIsItemSuccessReSync:YES];
            
            [self startStudentList];
            
        }
    } else
    {
        //		HUD.labelText = @"Retrieving Items Failed";
        [self HUDshowDetail:@"Retrieving items failed"];
        [self finishReSync];
    }
    //    });
}
-(void) startStudentList
{
    [self HUDshowMessage:@"Download Students"];
    [WebService fetchStudentList];
}
-(void) updateStudentList:(NSNotification*)notification
{
    
    //Show connection status on HUD title
#ifdef DEBUG
    NSLog(@"updateAllStudents start");
#endif
    
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
    [self HUDshowMessage:@"Update Students"];
    
    NSString* responseCode = @"000";
    NSString* responseString = @"[:]";
    NSDictionary* userInfo = notification.userInfo;
    if (userInfo != nil) {
        responseString = userInfo[@"response_string"];
        responseCode = userInfo[@"response_code"];
    }
    NSArray* studentArray = [responseString JSONValue];
    
    
    //declare a few necessary variables
    //    NSManagedObjectContext *moc = [CoreDataHelper getMainMOC];
    //update away!
    //	NSArray *studentArray = [WebService	fetchStudentList];
#ifdef DEBUG
    NSLog(@"studentArray count :%ld",(unsigned long)[studentArray count]);
#endif
    
    [self HUDshowMessage:@"Adding Students"];
    __block int studentListSize = [studentArray count];
    
    if (studentListSize > 0) {
        if ([responseCode isEqualToString:@"200"]) {
            
            successStudentDownload = true;
            __block int studentListTotalSize = studentListSize;
            __block int randamount = studentListTotalSize > 50 ? 50 : studentListTotalSize > 10 ? 3 : 1;
            __block int randnum = arc4random()%studentListTotalSize%randamount;
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //your code here
                NSManagedObjectContext *moc = [CoreDataHelper getMainMOC];
                
                
                [CoreDataService deleteAllObjectsForEntity:@"OdinStudent" andContext:moc];
                for (NSDictionary *individualStudent in studentArray)
                {
                    studentListSize--;
                    randnum--;
                    //                    [UIView animateWithDuration:0 animations:^{
                    // Update the UI
                    
                    if (randnum < 0) {
#ifdef DEBUG
                        NSLog(@"update view");
#endif
                        randamount = studentListTotalSize > 50 ? 50 : 1;
                        randnum = arc4random()%studentListTotalSize%randamount;
                        NSString* message = [NSString stringWithFormat:@"%i students", studentListSize];
                        [self HUDshowDetail:message];
                    }
                    
                    [OdinStudent updateThisStudentWith:individualStudent andMOC:moc sync:true];
                    
                }
                
                [self HUDshowDetail:@"Updating students done"];
                //update last Student Update date
                
                //save our changes
                [CoreDataService saveObjectsInContext:moc];
                
                
                LastUpdates *lastUpdates = [LastUpdates getLastUpdatefromMOC:moc];
                lastUpdates.lastStudentUpdate = [NSDate localDate];
                [CoreDataService saveObjectsInContext:moc];
            });
            
            [[SettingsHandler sharedHandler] setIsStudentSuccessReSync:YES];
            
            if ((int)[OdinTransaction reloadUnSyncedArray].count > 0) {
                
                [self HUDshowDetail:@"Closing Student"];
                [self finishReSync];
            } else {
                [self startReferenceNumber];
            }
        } else {
            [[AuthenticationStation sharedHandler] endAuth];
            [self hideActivity];
            NSString* serial = [NSString stringWithFormat:@"serial:%@",[SettingsHandler sharedHandler].serialNumber];
            NSString* portid = [NSString stringWithFormat:@"portableid:%@",[SettingsHandler sharedHandler].uid];
            
            NSDictionary* status = [studentArray objectAtIndex:0];
            
            NSString* message = [NSString stringWithFormat:@"%@\n%@\n%@",[status valueForKey:@"response_error"],serial,portid];
            //[ErrorAlert simpleAlertTitle:@"Failed to Connect to Server" message:message];
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:ERR_FAIL_TO_DOWNLOAD_STUDENT message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry",@"Email", nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                // Update the UI
                
                [alert show];
            });
        }
    } else
    {
        //		HUD.labelText = @"Retrieving Students Failed";
        [self HUDshowDetail:@"Retrieving Students Failed"];
        [self finishReSync];
    }
    
    //    });
}
-(void) startReferenceNumber
{
    
    [self HUDshowMessage:@"Download Reference"];
    if ([SettingsHandler sharedHandler].referenceNum.intValue > 1) {
        successReferenceDownload = true;
        [self finishReSync];
        return;
    }
    
    [WebService fetchReferenceNumberAFNRecall];
}
-(void) updateReferenceNumberNotif:(NSNotification*)notification
{
    NSError* error;
    NSDictionary* userInfo = notification.userInfo;
    id responseObject = userInfo[@"response_object"];
    NSString* responseString = userInfo[@"response_string"];
    //    NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
    //    NSDictionary* json = ([responseString isEqualToString:@""]) ? @{@"reference" : @"I 0"} : [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
    
    
#ifdef DEBUG
    NSLog(@"notification Reference Download: %@",responseString );
#endif
    
    //    NSString* referenceString = [json objectForKey:@"reference"];
    NSString* responseCode = userInfo[@"response_code"];
    //if we don't have any posted or pending transaction, we check online
    if ([responseCode isEqualToString:@"200"]) {
        NSString* referenceString = responseString;
        NSString* refCode = [referenceString substringToIndex:2];
        refCode = [refCode stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSString* refNum = [referenceString substringFromIndex:2];
#ifdef DEBUG
        NSLog(@"notification Reference %@ code:%@ num:%@",referenceString, refCode, refNum );
#endif
        [[SettingsHandler sharedHandler] setReference:(refNum.intValue+1)];
        [[SettingsHandler sharedHandler] setRegisterCode:refCode];
#ifdef DEBUG
        NSLog(@"New reference #: %@", [SettingsHandler sharedHandler].getReference);
#endif
        successReferenceDownload = true;
    } else {
        successReferenceDownload = false;
    }
    
    [self finishReSync];
}

-(void) updateReferenceNumber
{
    __block NSArray *syncArray = [[NSArray alloc] init];
    dispatch_async(dispatch_get_main_queue(), ^{
        //your code here
        NSManagedObjectContext *moc = [CoreDataService getMainMOC];
        //Fetch reference number from database if CoreData is empty or start from default value
        syncArray = [CoreDataService searchObjectsForEntity:@"OdinTransaction"
                                              withPredicate:nil
                                                 andSortKey:nil
                                           andSortAscending:NO
                                                 andContext:moc];
        
    });
    //if we don't have any posted or pending transaction, we check online
    if ([syncArray count] < 1) {
        [[SettingsHandler sharedHandler] setReference:[WebService fetchReferenceNumberAFN]];
#ifdef DEBUG
        NSLog(@"New reference #: %@", [SettingsHandler sharedHandler].getReference);
#endif
        successReferenceDownload = true;
    } else {
        successReferenceDownload = true;
    }
}
-(void) updateStatus
{
    NSManagedObjectContext *moc = [CoreDataService getCoordinatorMOC];
    [moc performBlock:^{
        
        LastUpdates *lastUpdate = [LastUpdates getLastUpdatefromMOC:moc];
        //can't pass nils into setObjectForKey apparently, these ifs should catch that
        NSString* serialNumber = [AuthenticationStation sharedHandler].serialNumber;
        lastUpdate.lastSerial = (serialNumber == nil) ? @"N" : [SettingsHandler sharedHandler].serialNumber;
        
        lastUpdate.lastUID = ([[SettingsHandler sharedHandler] uid] == nil) ? @"N" : [[SettingsHandler sharedHandler] uid];
        
        lastUpdate.lastAuth = [NSDate localDate];
        @synchronized(self)
        {
            [CoreDataService saveObjectsInContext:moc];
        }
    }];
}
#pragma mark - Functions
-(void)reloadTableLabel
{
#ifdef DEBUG
    NSLog(@"reload Table Label");
#endif
    self.unSyncedArray = [OdinTransaction reloadUnSyncedArray];
    NSString* newPendingLabel = [NSString stringWithFormat:@"Pending Transaction (%@)",@(self.unSyncedArray.count)];
    self.syncedArray = [OdinTransaction reloadSyncedArray];
    NSString* newUploadedLabel = [NSString stringWithFormat:@"Uploaded Transaction (%@)",@(self.syncedArray.count)];
    NSString* newResynceLabel = [NSString stringWithFormat:@"Re-Sync (I:%i | S:%i)",[OdinEvent count],[OdinStudent count]];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _pendingLabel.text = newPendingLabel;
        _uploadedLabel.text = newUploadedLabel;
        _resyncLabel.text = newResynceLabel;
        
    });
    
}

-(void)addNotification:(SEL)selector name:(NSString*)name
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:selector name:name object:nil];
}
#pragma mark - Offline Transaction Methods
/******
	verifyUploadedTransaction is similar to sendBatchToPrefServer
	main difference are:
 compare uploaded transaction to live data and insert missing transaction to live data (last 60 days transaction)
 use webservice URI transactionUploaded (this will log in a different log file)
 use syncedArray which is inside uploaded transaction
 there is no failed alert when items are failed to verify
 NOTICE: This function is created because unknown reason of missing transaction not registered to live data and sync=1
 *****/
-(void) verifyUploadedTransaction
{
    
    
    //disable idleTimer so the app will not turn off during long uploads
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    //     = true;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self showCacheActivity];
        self.syncedArray = [OdinTransaction reloadSyncedArray];
        
        BOOL hadError = NO;
        int postedTransactions = 0;
        int transactionsToPost = [self.syncedArray count];
        
        
#ifdef DEBUG
        //NSLog(@"Posting %i uploaded transactions",transactionsToPost);
#endif
        for (OdinTransaction *transactionToUpload in self.syncedArray)
        {
            [self performSelectorOnMainThread:@selector(showVerifyHUD:)
                                   withObject:[NSNumber numberWithInt:(transactionsToPost - postedTransactions)]
                                waitUntilDone:YES];
            //send to webservice
            if ([WebService postUploadedTransactionAFN:[transactionToUpload preppedForWeb]])
            {
                //if it posts successfully, change the sync value for the transaction, and set the student to be first to be updated
                [transactionToUpload setSync:[NSNumber numberWithBool:TRUE]];
                OdinStudent *studentToUpdate = [OdinStudent getStudentObjectForID:transactionToUpload.id_number andMOC:self.moc];
                studentToUpdate.last_update = [NSDate distantPast];
                
                postedTransactions++;
                
            }
            else
            {
                hadError = YES;
            }
        }
        
        
        if (hadError == NO)
        {
            [self performSelectorOnMainThread:@selector(showVerifyStatus:)
                                   withObject:@"Verify done"
                                waitUntilDone:YES];
            
            [[[UIAlertView alloc] initWithTitle:@"Verify Successful!"
                                        message:[NSString stringWithFormat:@"%i transaction(s) posted",postedTransactions]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil, nil] showSafely];
        }
        else
        {
            [self performSelectorOnMainThread:@selector(showVerifyStatus:)
                                   withObject:@"Verify failed"
                                waitUntilDone:YES];
            
            [[[UIAlertView alloc] initWithTitle:@"Verify Error"
                                        message:[NSString stringWithFormat:@"%i transactions posted successfully, \n%i did not post\nPlease verify your connection and re-try the upload",postedTransactions, (transactionsToPost - postedTransactions)]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil, nil] showSafely];
        }
        
        //clean up
        [CoreDataService saveObjectsInContext:self.moc];
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
#ifdef DEBUG
        NSLog(@"verify done");
#endif
        [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:YES];
    });
    
}
//the actual upload method, will always run in background thread
-(void) sendBatchToPrefServer
{
    //disable idleTimer so the app will not turn off during long uploads
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    NSManagedObjectContext* moc = [CoreDataHelper getCoordinatorMOC];
    [moc performBlock:^{
        
        NSArray* toBeSyncArary = [OdinTransaction reloadUnSyncedArrayWithMoc:moc];
        int count = self.unSyncedArray.count;
        if (count > 0) {
            [SettingsHandler sharedHandler].numberOfUploadTransaction = self.unSyncedArray.count;
            [self HUDshowDetail:@"Uploading"];
            
            for (OdinTransaction *transactionToUpload in toBeSyncArary)
            {
                [WebService postTransactionAFN:[transactionToUpload preppedForWeb]];
                [self HUDshowDetail:[NSString stringWithFormat:@"%i uploading",count--]];
            }
        }
        [self finishUploadTransaction:nil];
    }];
}




#pragma mark - View lifecycle


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
#ifdef DEBUG
    NSLog(@"management viewdidload");
#endif
    [super viewDidLoad];
    self.moc = [CoreDataService getMainMOC];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [[UIApplication sharedApplication].keyWindow addSubview:[HUDsingleton sharedHUD]];
}

- (void)viewDidUnload
{
#ifdef DEBUG
    NSLog(@"management viewdidunload");
#endif
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    
    //	[[UIApplication sharedApplication].keyWindow addSubview:[HUDsingleton sharedHUD].HUD];
#ifdef DEBUG
    NSLog(@"management");
#endif
    [self addNotification:@selector(refreshHoldTransactionSwitch) name:@"holdTransactionsChanged"];
    [self addNotification:@selector(switchHoldTransactionsOn) name:@"holdTransactionSwitchOn"];
    [self addNotification:@selector(switchHoldTransactionsOn) name:@"switched to offline mode"];
    [self addNotification:@selector(switchOnlineModeButtonOff) name:@"switch offline button off"];
    [self addNotification:@selector(updateItemList:) name:NOTIFICATION_WEB_UPDATE_ITEM];
    [self addNotification:@selector(updateStudentList:) name:NOTIFICATION_WEB_UPDATE_STUDENT];
    [self addNotification:@selector(updateReferenceNumberNotif:) name:NOTIFICATION_WEB_UPDATE_REFERENCE];
    [self addNotification:@selector(reloadTableLabel) name:NOTIFICATION_RELOAD_VIEW];
    [self addNotification:@selector(finishUploadTransaction:) name:NOTIFICATION_WEB_UPLOAD_TRANSACTION];
    [self addNotification:@selector(HUDshowDetailNotify:) name:NOTIFICATION_UPDATE_HUD];
    
    [super viewWillAppear:animated];
    
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [self reloadTableLabel];
    [self refreshLinea];
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
    [self disconnectLinea];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [super numberOfSectionsInTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [super tableView:tableView numberOfRowsInSection:section];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        //        return @"Update 2";
    }
    return @"";
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 2)
    {
        if (indexPath.row == 0) {
            
            offlineModeSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [offlineModeSwitch addTarget:self action:@selector(flipOnlineSwitch) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = offlineModeSwitch;
            [offlineModeSwitch setOn:[AuthenticationStation sharedHandler].isOnline];
            
        } else if (indexPath.row == 1)
        {
            holdTransactionsSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
            [holdTransactionsSwitch addTarget:self action:@selector(flipHoldTransactionsSwitch) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = holdTransactionsSwitch;
            [holdTransactionsSwitch setOn:[SettingsHandler sharedHandler].holdTransactions];
            
        }
    }
    return cell;
}
#pragma mark - Button Toggle

- (void) switchOnlineModeButtonOff
{
    [offlineModeSwitch setOn:NO animated:YES];
}


-(void)switchHoldTransactionsOn
{
    [holdTransactionsSwitch setOn:YES animated:YES];
    [[SettingsHandler sharedHandler] setHoldTransactions:YES];
}


-(void)flipOnlineSwitch
{
#ifdef DEBUG
    NSLog(@"flipOnlineSwitch");
#endif
    
    [self showUploadActivity];
    if ([AuthenticationStation sharedHandler].isOnline) {
        [self HUDshowMessage:@"Disconnecting.."];
        [ErrorAlert switchedToOfflineMode];
        [holdTransactionsSwitch setOn:true];
    } else {
        [self HUDshowMessage:@"Connecting.."];
        [[SettingsHandler sharedHandler] setHoldTransactions:true];
#ifdef DEBUG
        NSLog(@"test");
#endif
    }
    
    [[HUDsingleton sharedHUD] showWhileExecuting:@selector(doOnlineConnection) onTarget:self withObject:nil animated:YES];
    
}
-(void)doOnlineConnection
{
    BOOL statue = [AuthenticationStation sharedHandler].isOnline;
    [[AuthenticationStation sharedHandler] setIsOnline:!statue];
}

-(void)flipHoldTransactionsSwitch
{
    if ([AuthenticationStation sharedHandler].isOnline) {
        
        [[SettingsHandler sharedHandler] setHoldTransactions:holdTransactionsSwitch.on];
    } else {
        [[SettingsHandler sharedHandler] setHoldTransactions:true];
        [holdTransactionsSwitch setOn:true];
    }
}

-(void)refreshHoldTransactionSwitch
{
    [holdTransactionsSwitch setOn:[[SettingsHandler sharedHandler] holdTransactions]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //Hacky way of turning table rows into buttons (necessary to keep correct highlighting)
    
    if (indexPath.section == 1)
    {
        if (indexPath.row == 0)
            [self uploadTransactions];
        
        else if (indexPath.row == 1)
            [self reSync];
    }
    else if (indexPath.section == 2)
    {
        //[self flipSwitch];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
#pragma mark - Alert
-(void)showAlertViewToEnterUID
{
    
    //[self performSelectorOnMainThread:@selector(uidAlertView) withObject:nil waitUntilDone:YES];
    NSString *serial = [AuthenticationStation sharedHandler].serialNumber;
    NSString *message = [NSString stringWithFormat:@"Serial: %@",serial];
    UIAlertView *uidEntryAlert = [[UIAlertView alloc] initWithTitle:ERR_UNABLE_TO_FIND_UID
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Later"
                                                  otherButtonTitles:@"OK", nil];
    [uidEntryAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [uidEntryAlert textFieldAtIndex:0].placeholder = [SettingsHandler sharedHandler].uid;
    [uidEntryAlert show];
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    //u need to change 0 to other value(,1,2,3) if u have more buttons.then u can check which button was pressed.
#ifdef DEBUG
    NSLog(@"Management Alert Button Pressed");
#endif
    NSString* title = alertView.title;
    
    //Announce Alert View is Dismissed
    if ([title isEqualToString:@"Nothing to Upload"]) {
        if (buttonIndex == 0) {
            //Run verify past transaction
            [self performSelector:@selector(verifyUploadedTransaction) withObject:nil afterDelay:1.0];
            
        } else if (buttonIndex == 1)
        {
            [[HUDsingleton sharedHUD] hide:true afterDelay:1];
            //Do nothing
        }
    } else if ([title isEqualToString:ERR_UNABLE_TO_FIND_UID]) {
        if(buttonIndex == 1) {
            NSString *uidFromAlertView = [[alertView textFieldAtIndex:0] text];
            [[SettingsHandler sharedHandler] setUID:uidFromAlertView];
            [self performSelector:@selector(reSync) withObject:nil afterDelay:1];
            return;
        }
        [AuthenticationStation sharedHandler].isLoopingTimer = NO;
    } else if ([title isEqualToString:ERR_FAIL_TO_CONNECT_TO_SERVER] ||
               [title isEqualToString:ERR_FAIL_TO_DOWNLOAD_ITEM] ||
               [title isEqualToString:ERR_FAIL_TO_DOWNLOAD_STUDENT]) {
        if (buttonIndex == 1) { //Retry
            
            [self performSelector:@selector(doSync) withObject:nil afterDelay:1];
        } else if (buttonIndex == 2) { //Email
            
            // Email Subject
            NSString *emailTitle = @"Odin App Connection Error";
            // Email Content
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSDictionary* messages = @{@"Error Title":title,
                                       @"Error Message":alertView.message,
                                       @"base url":[defaults valueForKey:@"portablePath"],
                                       @"isMSSQL":[defaults valueForKey:@"isMSSQL"],
                                       @"serverHost":[defaults valueForKey:@"serverHost"],
                                       @"port":[defaults valueForKey:@"serverPort"],
                                       @"schema":[defaults valueForKey:@"serverSchema"],
                                       @"school":[defaults valueForKey:@"school"],
                                       @"uid":[defaults valueForKey:@"uid"],
                                       @"registerCode":[defaults valueForKey:@"registerCode"],
                                       @"iosVersion":[[UIDevice currentDevice] systemVersion],
                                       @"OdinVersion":[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                                       @"scanner":[SettingsHandler sharedHandler].serialNumber};
            NSString *messageBody = [messages description];
            // To address
#ifdef DEBUG
            NSArray *toRecipents = [NSArray arrayWithObject:@"alvin@odin-inc.com"];
#else
            NSArray *toRecipents = [NSArray arrayWithObject:@"support@odin-inc.com"];
#endif
            
            MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
            mc.mailComposeDelegate = self;
            [mc setSubject:emailTitle];
            [mc setMessageBody:messageBody isHTML:NO];
            [mc setToRecipients:toRecipents];
            
            // Present mail view controller on screen
            [self presentViewController:mc animated:YES completion:NULL];
            [self finishReSync];
        } else {
            [self finishReSync];
        }
    }
    
}


#pragma mark - Mail Service

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
