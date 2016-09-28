//
//  AppDelegate.h
//  OdinScanner
//
//  Created by Ben McCloskey on 2/1/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "TransactionUpdateObserver.h"
//#import "MBProgressHUD.h"

@class StudentUpdateObserver;

@interface AppDelegate : UIResponder <UIApplicationDelegate>//, MBProgressHUDDelegate>

@property (nonatomic, retain) UIWindow *window;

@property (readonly, retain, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, retain, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, retain, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property StudentUpdateObserver *updateHandler;
@property TransactionUpdateObserver* transactUpdateHandler;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

typedef void(^myCompletion)(BOOL finished);
-(void)updateContext:(NSNotification*)notification andRun:(myCompletion)updateUIBlock;
@end
