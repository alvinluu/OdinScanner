//
//  AppDelegate.m
//  OdinScanner
//
//  Created by Ben McCloskey on 2/1/12.
//  Copyright (c) 2012 Odin Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "SynchronizationOperation.h"
#import "StudentUpdate.h"
#import "StudentUpdateObserver.h"
#import "AFNetworkActivityIndicatorManager.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize updateHandler;


-(void)contextChanged:(NSNotification*)notification
{
    if ([notification object] == self.managedObjectContext || [NSThread isMainThread]) {
#ifdef DEBUG
//        NSLog(@"OdinView contextchanged main");
#endif
        [self updateManageBadge:nil];
        
        return;
    }
    
#ifdef DEBUG
//    NSLog(@"OdinView contextchanged prepare");
#endif
    if (![NSThread isMainThread]) {
        //        [self performSelectorOnMainThread:@selector(contextChanged:) withObject:notification waitUntilDone:YES];
#ifdef DEBUG
//        NSLog(@"OdinView contextchanged update");
#endif
        //        [[self moc] mergeChangesFromContextDidSaveNotification:notification];
//        SEL selector = @selector(mergeChangesFromContextDidSaveNotification:);
//        [self.managedObjectContext performSelectorOnMainThread:selector withObject:notification waitUntilDone:YES];
        [self performSelectorOnMainThread:@selector(contextChanged:) withObject:notification waitUntilDone:YES];
//        [self updateManageBadge:nil];
    }
}
-(void)updateContext:(NSNotification *)notification andRun:(myCompletion)updateUIBlock
{
    
    SEL selector = @selector(mergeChangesFromContextDidSaveNotification:);
    [self.managedObjectContext performSelectorOnMainThread:selector withObject:notification waitUntilDone:YES];
}

#pragma mark - Tab Bar Items
-(void)updateManageBadge:(NSNotification*)notification
{
    [UIView animateWithDuration:0 animations:^{
        
        NSArray* unSyncedArray = [OdinTransaction reloadUnSyncedArray];
        int count = unSyncedArray.count;
#ifdef DEBUG
    NSLog(@"OdinView updateManageBadge %i",count);
#endif
        NSString* newLabel = [NSString stringWithFormat:@"%i",count];
        newLabel = [newLabel isEqualToString:@"0"] ? nil : newLabel;

        UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
        UITabBarItem* tabItem = [tabBarController.viewControllers objectAtIndex:2].tabBarItem;
        tabItem.badgeValue = newLabel;

    } completion:^(BOOL finished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_RELOAD_VIEW object:nil];
    }];
    
    
}
- (void) setVersion
{
    // this function detects what is the CFBundle version of this application and set it in the settings bundle
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // transfer the current version number into the defaults so that this correct value will be displayed when the user visit settings page later
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [defaults setObject:version forKey:@"version"];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //set default preferences
    [[SettingsHandler sharedHandler] setDefaults];
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    [self setVersion];
    //start async Student Update Operation Queue
    self.updateHandler = [[StudentUpdateObserver alloc] initWithQueue:[[NSOperationQueue alloc] init]];
    [self.updateHandler startStudentUpdates];
    self.transactUpdateHandler = [[TransactionUpdateObserver alloc] initWithQueue:[[NSOperationQueue alloc] init]];
    [self.transactUpdateHandler startTransactionUpdates];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextChanged:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    [self updateManageBadge:nil];
    
    
    return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    
    //App will exit on hitting the background. Just need to stop timers and save any Core Data changes
    //[self.updateHandler.studentUpdateQueue setSuspended:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"pausing App" object:nil];
    @synchronized(self)
    {
        [self saveContext];
    }
#ifdef DEBUG
    NSLog(@"Disconnecting Linea");
#endif
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"resuming App" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshLinea" object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
#ifdef DEBUG
    NSLog(@"did become active");
#endif
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshLinea" object:nil];
    [self updateManageBadge:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    /*
     NSArray *allStudents = [CoreDataService getObjectsForEntity:@"OdinStudent"
     withSortKey:nil
     andSortAscending:YES
     andContext:__managedObjectContext];
     for(OdinStudent *student in allStudents)
     {
     [student setPresent:0];
     #ifdef DEBUG NSLog(@"set %@ %@ to $0",[student student], [student last_name]);
     }
     */
    [self saveContext];
#ifdef DEBUG
    NSLog(@"terminated");
#endif
}



- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            [CoreDataService saveObjectsInContext:managedObjectContext];
        }
    }
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */

- (NSManagedObjectModel *)managedObjectModel {
    
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:@"OdinScanner" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:path];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    
//    if (__persistentStoreCoordinator != nil)
//    {
//        return __persistentStoreCoordinator;
//    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"OdinScanner.sqlite"];
    
    NSError *error = nil;
    NSPersistentStoreCoordinator* persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
//    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
//                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                    configuration:nil
                                                              URL:storeURL
                                                          options:options
                                                            error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
        abort();
    }    
    
    return persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
