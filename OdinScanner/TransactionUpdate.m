//
//  TransactionUpdate.m
//  OdinScanner
//
//  Created by Ben McCloskey on 9/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TransactionUpdate.h"
#import "OdinTransaction.h"
#import "AppDelegate.h"
//#import "SynchronizationOperation.h"

@implementation TransactionUpdate
{
    NSDate* startDate;
    NSDate* endDate;
}
@synthesize sleepyTime;

-(TransactionUpdate *) initWithDelay:(NSTimeInterval)sleepDelay
{
    sleepyTime = sleepDelay;
    self = [super init];
    return self;
}
-(void) main
{
    //This is a scheduler for checking Transaction balance
    //if (TransactionListSize == 0) {return;}
    
    
    //wait for the alloted time between each Transaction update
    sleep(sleepyTime);
    AuthenticationStation* auth = [AuthenticationStation sharedHandler];
    SettingsHandler* sett = [SettingsHandler sharedHandler];
#ifdef DEBUG
    //	return;
    //	NSLog(@"checking Transaction isTransactionChecking:%i isProcessing:%i isPosting:%i",
    //          auth.isTransactionChecking,
    //          sett.isProcessingSale,
    //          auth.isPosting);
#endif
    
    //don't check on Transaction during Re-Sync
    if (auth.isTransactionChecking ||
        auth.isPosting ||
        sett.holdTransactions)
    {
#ifdef DEBUG
        NSLog(@"cancel Transaction update: isHolding:%i isTranChecking:%i isPost:%i",sett.holdTransactions,auth.isTransactionChecking,auth.isPosting);
#endif
        return;
    }
    
    //if we're in offline mode, skip this process
    if ([auth isOnline] == TRUE)
    {
        auth.isTransactionChecking = true;
#ifdef DEBUG
        //get start time
        startDate = [NSDate localDate];
        //sleep(rand()%10+1);
#endif
        
        //find most out-of-date Transaction record
        NSManagedObjectContext* moc = [CoreDataHelper getCoordinatorMOC];
        [moc performBlock:^{
            
            NSArray *arrayOfTransactions = [OdinTransaction reloadUnSyncedArrayWithMoc:moc];
            
            OdinTransaction *transactionToUpdate;
            if ([arrayOfTransactions count] > 0)
            {
                transactionToUpdate = [arrayOfTransactions objectAtIndex:0];
            }
            //check "isCancelled" on either end of the fetch from webservice, as that's what takes the time
            if ([self isCancelled] == TRUE
                || transactionToUpdate == nil
                || auth.isPosting
                ) {
#ifdef DEBUG
                NSLog(@"cancel Transaction: nothing to upload");
#endif
                auth.isTransactionChecking = false;
                
                return;
            }
            
            //fetch info from webservice
            
            
            //        NSDictionary *TransactionToUpdateAsDictionary = [WebService fetchTransactionWithID:[TransactionToUpdate id_number]];
            
            sett.numberOfUploadTransaction = 0;
            [WebService postTransactionAFNWithRecall:[transactionToUpdate preppedForWeb] isBatch:false];
            //get end time
#ifdef DEBUG
            endDate = [NSDate localDate];
            NSTimeInterval durationOfUpdate = [endDate timeIntervalSinceDate:startDate];
            //		NSLog(@"update transaction took:%.2f seconds",durationOfUpdate);
#endif
            
        }];
    }
}


@end
