//
//  UploadToServerOperation.m
//  OdinScanner
//
//  Created by Ben McCloskey on 2/8/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "UploadToServerOperation.h"
#import "MysqlServer.h"
#import "MysqlConnection.h"
#import "MysqlUpdate.h"
#import "MysqlInsert.h"
#import "MysqlException.h"
#import "MysqlFetch+FrequentFetches.h"
#import "Temptran.h"

@interface UploadToServerOperation ()

@property (nonatomic, strong) OdinTransaction *aTransaction;

@end

@implementation UploadToServerOperation

@synthesize aTransaction;

	
	//repeats for each row			


@end
