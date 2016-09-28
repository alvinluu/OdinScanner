//
//  UploadToServerOperation.h
//  OdinScanner
//
//  Created by Ben McCloskey on 2/8/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OdinTransaction.h"

@interface UploadToServerOperation : NSOperation

-(id)initWithTransaction:(OdinTransaction *)transaction;
-(void)main;

@end
