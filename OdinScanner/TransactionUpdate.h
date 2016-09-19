//
//  TransactionUpdate.h
//  OdinScanner
//
//  Created by Ben McCloskey on 9/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransactionUpdateObserver.h"

@interface TransactionUpdate : NSOperation

@property unsigned int sleepyTime;
@property NSObject *delegate;
@property TransactionUpdateObserver *myObserver;


-(void) main;
-(TransactionUpdate *) initWithDelay:(NSTimeInterval)sleepDelay;

@end
