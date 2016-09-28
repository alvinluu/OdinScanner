//
//  TransactionUpdateObserver.h
//  OdinScanner
//
//  Created by Ken Thomsen on 3/14/13.
//
//

#import <Foundation/Foundation.h>

@interface TransactionUpdateObserver : NSObject

@property (nonatomic) NSOperationQueue *TransactionUpdateQueue;


-(id) initWithQueue:(NSOperationQueue *)newQueue;
- (void) startTransactionUpdates;

@end
