//
//  TransactionUpdateObserver.m
//  OdinScanner
//
//  Created by Ken Thomsen on 3/14/13.
//
//

#import "TransactionUpdateObserver.h"
#import "TransactionUpdate.h"

@implementation TransactionUpdateObserver

@synthesize TransactionUpdateQueue;

-(id) initWithQueue:(NSOperationQueue *)newQueue
{
	if (self = [super init])
	{
		self.TransactionUpdateQueue = newQueue;
		return self;
	}
	return nil;
}

- (void) startTransactionUpdates
{

#ifdef DEBUG
//    NSLog(@"start transaction update");
#endif
    TransactionUpdate *nextUpdate = [[TransactionUpdate alloc] initWithDelay:2];
	//re-queue the Transaction update upon completion
	[nextUpdate setCompletionBlock:^(void){
		[self startTransactionUpdates];
//        [AuthenticationStation sharedHandler].isTransactionChecking = false;
	}];
	[TransactionUpdateQueue addOperation:nextUpdate];
}

@end
