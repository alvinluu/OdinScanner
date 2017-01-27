//
//  OdinStudent+Methods.m
//  OdinScanner
//
//  Created by Ben McCloskey on 10/19/12.
//
//

#import "OdinStudent+Methods.h"
#import "NetworkConnection.h"

@implementation OdinStudent (Methods)

+(NSString *) getStudentSecondaryEmailForID:(NSString *)idNumber
{
    NSLog(@"getStudentSecondaryEmail");
    OdinStudent  *studentCoreData = nil;
    NSDictionary *studentData = nil;
    //get student data
    //if online, check SQL server, if not, check core data
    if ([[AuthenticationStation sharedHandler] isOnline] == TRUE)
    {
        //--if we're authenticated, fetch student info from web
        studentData = [WebService fetchStudentWithID:idNumber];
        //--webService will show potential error messages when it handles http error codes
        if (!studentData) {
            NSLog(@"no student data");
            return @"";
        } else {
            return [studentData objectForKey:@"s_email"] == nil ? @"" : [studentData objectForKey:@"s_email"];
        }
    }
    else
    {
        
        //get managedObjectContext from AppDelegate
        NSManagedObjectContext* managedObjectContext = [CoreDataService getMainMOC];
        
        NSArray *arrayOfStudents = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                                             withPredicate:[NSPredicate predicateWithFormat:@"id_number = %@",idNumber]
                                                                andSortKey:nil
                                                          andSortAscending:NO
                                                                andContext:managedObjectContext];
        //assert that there should be 0 or 1 values returned
#ifdef DEBUG
        NSAssert(([arrayOfStudents count] <= 1), @"multiple accounts with same ID");
#endif
        
        if ([arrayOfStudents count] > 0) {
#ifdef DEBUG
            NSLog(@"getStudentSecondaryEmailForID: found %@",idNumber);
#endif
            studentCoreData = [arrayOfStudents objectAtIndex:0];
            return studentCoreData.s_email == nil ? @"" : studentCoreData.s_email;
            
        } else
        {
#ifdef DEBUG
            NSLog(@"getStudentSecondaryEmailForID: not found %@",idNumber);
#endif
            //[ErrorAlert studentNotFound:idNumber];
            //alert post in subclass
            return @"";
        }
    }
    //    return [studentData objectForKey:@"s_email"];
}
+(NSString *) getStudentIDForBarcode:(NSString *)barcode
{
    NSLog(@"getStudentID");
    OdinStudent  *studentCoreData = nil;
    NSDictionary *studentData = nil;
    //get student data
    //if online, check SQL server, if not, check core data
    if ([[AuthenticationStation sharedHandler] isOnline] == TRUE)
    {
        //--if we're authenticated, fetch student info from web
        studentData = [WebService fetchStudentWithID:barcode];
        //--webService will show potential error messages when it handles http error codes
        if (!studentData) {
            NSLog(@"no student data");
            return @"";
        } else {
            return [studentData objectForKey:@"s_email"] == nil ? @"" : [studentData objectForKey:@"s_email"];
        }
    }
    else
    {
        
        //get managedObjectContext from AppDelegate
        NSManagedObjectContext* managedObjectContext = [CoreDataService getMainMOC];
        
        NSArray *arrayOfStudents = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                                             withPredicate:[NSPredicate predicateWithFormat:@"barcode = %@",barcode]
                                                                andSortKey:nil
                                                          andSortAscending:NO
                                                                andContext:managedObjectContext];
        //assert that there should be 0 or 1 values returned
#ifdef DEBUG
        NSAssert(([arrayOfStudents count] <= 1), @"multiple accounts with same ID");
#endif
        
        if ([arrayOfStudents count] > 0) {
#ifdef DEBUG
            NSLog(@"getStudentSecondaryEmailForID: found %@",barcode);
#endif
            studentCoreData = [arrayOfStudents objectAtIndex:0];
            return studentCoreData.id_number == nil ? @"" : studentCoreData.id_number;
            
        } else
        {
#ifdef DEBUG
            NSLog(@"getStudentSecondaryEmailForID: not found %@",barcode);
#endif
            //[ErrorAlert studentNotFound:idNumber];
            //alert post in subclass
            return @"";
        }
    }
    //    return [studentData objectForKey:@"s_email"];
}
+(NSDictionary *) getStudentInfoForID:(NSString *)idNumber andMOC:(NSManagedObjectContext *)managedObjectContext
{
    NSLog(@"getStudentInfo %@",idNumber);
    OdinStudent  *studentCoreData = nil;
    NSDictionary *studentData = nil;
    
    if ([[AuthenticationStation sharedHandler] isOnline] == TRUE && [NetworkConnection isInternetOnline])
    {
        //if we're authenticated, fetch student info from web
        studentData = [WebService fetchStudentWithID:idNumber];
    }
    
#ifdef DEBUG
				
    NSLog(@"getStudentInfo %@ has data %@",idNumber,studentData);
    
#endif
    
    if (!studentData)
    {
#ifdef DEBUG
        NSLog(@"no student found with id %@. use offline student data",idNumber);
#endif
        
        NSArray *arrayOfStudents = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                                             withPredicate:[NSPredicate predicateWithFormat:@"id_number = %@",idNumber]
                                                                andSortKey:nil
                                                          andSortAscending:NO
                                                                andContext:managedObjectContext];
        //assert that there should be 0 or 1 values returned
#ifdef DEBUG
        NSAssert(([arrayOfStudents count] <= 1), @"multiple accounts with same ID");
#endif
        
        if ([arrayOfStudents count] > 0)
            studentCoreData = [arrayOfStudents objectAtIndex:0];
        
        
        //if we have data, turn it into a dictionary to be returned, if not, show an error message
        if (studentCoreData){
            studentData = [self getStudentOfflineInfoForID:idNumber andMOC:managedObjectContext];
        }
    }
    
#ifdef DEBUG
				NSLog(@"exit getStudentInfo %@ with student %@",idNumber,studentData);
#endif
    NSDecimalNumber* balance = [[NSDecimalNumber alloc] initWithDouble:[TestIf studentOfflineBalanceWithID:idNumber]];
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithDictionary:studentData];
    [dict setObject:balance forKey:@"present"];
    return [[NSDictionary alloc] initWithDictionary:dict];
}
+(NSDictionary *) getStudentOfflineInfoForID:(NSString *)idNumber andMOC:(NSManagedObjectContext *)managedObjectContext
{
    NSLog(@"getStudentOfflineInfoForID %@",idNumber);
    OdinStudent  *studentCoreData = nil;
    NSDictionary *studentData = nil;
    //get student data
    NSArray *arrayOfStudents = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                                         withPredicate:[NSPredicate predicateWithFormat:@"id_number = %@",idNumber]
                                                            andSortKey:nil
                                                      andSortAscending:NO
                                                            andContext:managedObjectContext];
    //assert that there should be 0 or 1 values returned
#ifdef DEBUG
    NSAssert(([arrayOfStudents count] <= 1), @"multiple accounts with same ID");
#endif
    
    if ([arrayOfStudents count] > 0){
        
#ifdef DEBUG
        NSLog(@"getStudentOfflineInfoForID %@ found",idNumber);
#endif
        
        studentCoreData = [arrayOfStudents objectAtIndex:0];
    }
    else
    {
#ifdef DEBUG
        NSLog(@"getStudentOfflineInfoForID %@ not found",idNumber);
#endif
        
        //[ErrorAlert studentNotFound:idNumber];
        //alert post in subclass
        return nil;
    }
    
    //if we have data, turn it into a dictionary to be returned, if not, show an error message
    if (studentCoreData){
        //replacing
        //studentData = [studentCoreData asDictionary];
        NSMutableDictionary *studentAsDictionary = [[NSMutableDictionary alloc] init];
        //[self dictionaryWithValuesForKeys:self.entity.attributesByName.allKeys];
        //[results setObject:propertyType forKey:propertyName]
        if(studentCoreData.accnt_type != nil)
            [studentAsDictionary setObject:studentCoreData.accnt_type forKey:@"accnt_type"];
        
        if(studentCoreData.exportid != nil)
            [studentAsDictionary setObject:studentCoreData.exportid forKey:@"exportid"];
        
        if(studentCoreData.id_number != nil)
            [studentAsDictionary setObject:studentCoreData.id_number forKey:@"id_number"];
        
        if(studentCoreData.last_name != nil)
            [studentAsDictionary setObject:studentCoreData.last_name forKey:@"last_name"];
        
        if(studentCoreData.student != nil)
            [studentAsDictionary setObject:studentCoreData.student forKey:@"student"];
        
        if(studentCoreData.studentuid != nil)
            [studentAsDictionary setObject:studentCoreData.studentuid forKey:@"studentuid"];
        
        if(studentCoreData.time_1 != nil)
            [studentAsDictionary setObject:studentCoreData.time_1 forKey:@"time_1"];
        
        if(studentCoreData.time_2 != nil)
            [studentAsDictionary setObject:studentCoreData.time_2 forKey:@"time_2"];
        
        if(studentCoreData.time_3 != nil)
            [studentAsDictionary setObject:studentCoreData.time_3 forKey:@"time_3"];
        
        if(studentCoreData.time_4 != nil)
            [studentAsDictionary setObject:studentCoreData.time_4 forKey:@"time_4"];
        
        if(studentCoreData.time_5 != nil)
            [studentAsDictionary setObject:studentCoreData.time_5 forKey:@"time_5"];
        
        if(studentCoreData.time_6 != nil)
            [studentAsDictionary setObject:studentCoreData.time_6 forKey:@"time_6"];
        
        if(studentCoreData.time_7 != nil)
            [studentAsDictionary setObject:studentCoreData.time_7 forKey:@"time_7"];
        
        if(studentCoreData.time_8 != nil)
            [studentAsDictionary setObject:studentCoreData.time_8 forKey:@"time_8"];
        
        if(studentCoreData.time_9 != nil)
            [studentAsDictionary setObject:studentCoreData.time_9 forKey:@"time_9"];
        
        if(studentCoreData.present != nil) {
            NSDecimalNumber* present = [[NSDecimalNumber alloc] initWithDouble: [TestIf studentOfflineBalanceWithID:idNumber]];
            //[studentAsDictionary setObject:studentCoreData.present forKey:@"present"];
            [studentAsDictionary setObject:present forKey:@"present"];
        }
        
        if(studentCoreData.area_1 != nil)
            [studentAsDictionary setObject:studentCoreData.area_1 forKey:@"area_1"];
        
        if(studentCoreData.area_2 != nil)
            [studentAsDictionary setObject:studentCoreData.area_2 forKey:@"area_2"];
        
        if(studentCoreData.area_3 != nil)
            [studentAsDictionary setObject:studentCoreData.area_3 forKey:@"area_3"];
        
        if(studentCoreData.area_4 != nil)
            [studentAsDictionary setObject:studentCoreData.area_4 forKey:@"area_4"];
        
        if(studentCoreData.area_5 != nil)
            [studentAsDictionary setObject:studentCoreData.area_5 forKey:@"area_5"];
        
        if(studentCoreData.area_6 != nil)
            [studentAsDictionary setObject:studentCoreData.area_6 forKey:@"area_6"];
        
        if(studentCoreData.area_7 != nil)
            [studentAsDictionary setObject:studentCoreData.area_7 forKey:@"area_7"];
        
        if(studentCoreData.area_8 != nil)
            [studentAsDictionary setObject:studentCoreData.area_8 forKey:@"area_8"];
        
        if(studentCoreData.area_9 != nil)
            [studentAsDictionary setObject:studentCoreData.area_9 forKey:@"area_9"];
        
        if(studentCoreData.last_update != nil)
            [studentAsDictionary setObject:studentCoreData.last_update forKey:@"last_update"];
#ifdef DEBUG
        NSLog(@"%@ As Dictionary:%@",[[self class] description],[studentAsDictionary description]);
#endif
        
        return [NSDictionary dictionaryWithDictionary:studentAsDictionary];
        //        return studentAsDictionary;
        
    }
    else
    {
        return nil;
    }
    return studentData;
    
    //    return studentData;
}
+ (void) updateThisStudentWith:(NSDictionary *)studentInfoFromWeb andMOC:(NSManagedObjectContext *)moc sync:(BOOL)sync
{
#ifdef DEBUG
    NSLog([studentInfoFromWeb description]);
#endif
    
    if ([AuthenticationStation sharedHandler].isSyncing && !sync) {
        return;
    }
    //check if the student being loaded already exists in Core Data. If so, update them, if not, create a new one.
    OdinStudent *studentToAdd;
    BOOL foundStudent = false;
    
    if (sync) {
        
        studentToAdd = [CoreDataService insertObjectForEntity:@"OdinStudent"  andContext:moc];
    } else {
        NSArray *arrayOfStudentsInCoreData;
        if ([studentInfoFromWeb objectForKey:@"id_number"])
        {
            NSString *id_number = [studentInfoFromWeb objectForKey:@"id_number"];
            arrayOfStudentsInCoreData = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                                                  withPredicate:[NSPredicate predicateWithFormat:@"id_number == %@",id_number]
                                                                     andSortKey:nil
                                                               andSortAscending:NO
                                                                     andContext:moc];
#ifdef DEBUG
            int countForArray = [arrayOfStudentsInCoreData count];
            NSString *assertFailed = [NSString stringWithFormat:@"should never be two entries with the same ID. total of %i students with ID:%@.",countForArray, id_number];
            if (countForArray >= 2)
                NSLog(assertFailed);
            //        NSAssert((countForArray < 2), assertFailed);
#endif
        }
        if ([arrayOfStudentsInCoreData count] > 0) {
            studentToAdd = [arrayOfStudentsInCoreData objectAtIndex:0];
            foundStudent = true;
        }
        else {
            studentToAdd = [CoreDataService insertObjectForEntity:@"OdinStudent"  andContext:moc];
        }
    }
    studentToAdd.last_update = [NSDate localDate];
    //now that we have a handle on the core data entry, loop through each element of the dictionary and enter it into the student obejct in Core Data
    NSEnumerator *enumerator = [studentInfoFromWeb keyEnumerator];
    id key;
    while (key = [enumerator nextObject])
    {
        //loops through all properties of student, setting properties according to query data
        //note that class ivars are exact same names as query fields returned in data
        NSString *keyName = (NSString *)key;
        //create selectors based on keyName (i.e. setStudent)
        SEL selector = NSSelectorFromString(keyName);
        SEL setSelector = NSSelectorFromString([NSString stringWithFormat:@"set%@:",keyName]);
        
#ifdef DEBUG
        //		NSAssert([studentToAdd respondsToSelector:setSelector], @"called bad setSelector");
        //		NSAssert([studentToAdd respondsToSelector:selector], @"called bad selector");
#endif
        //we must be sure that we can respond to the dynamically created selectors, and that the object exists and is not a NULL
        if (([studentToAdd respondsToSelector:setSelector])
            && ([studentToAdd respondsToSelector:selector])
            && ([studentInfoFromWeb objectForKey:keyName])
            && ([[studentInfoFromWeb objectForKey:keyName] isEqual:[NSNull null]] == FALSE))
        {
            id theWebObject = [studentInfoFromWeb objectForKey:keyName];
            id theObjectToAdd;
            
            theObjectToAdd = theWebObject;
            //catches values passed into number fields that are strings but should be doubles
            if ([theWebObject isKindOfClass:[NSString class]])
            {
                NSString *partialKey = [keyName substringWithRange:NSMakeRange(0, 4)];
                if (([keyName isEqualToString:@"present"])
                    || ([partialKey isEqualToString:@"area"]))
                {
                    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
                    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                    NSString *numberAsString = theWebObject;
                    theObjectToAdd = [formatter numberFromString:numberAsString];
                }
            }
            @try
            {
                [studentToAdd performSelector:setSelector withObject:theObjectToAdd];
            }
            @catch (NSException *error)
            {
                if ([[error name] isEqualToString:@"NSInvalidArgumentException"])
                {
                    NSLog(@"%@",[error description]);
                }
                else
                {
                    [error raise];
                }
            }
        }
        
    }
#ifdef DEBUG
    NSString* function = foundStudent ? @"Auto Update" : @"Added";
    NSLog(@"%@ %@ %@ with ID:%@ and present:$%@ %@",function, studentToAdd.student, studentToAdd.last_name, studentToAdd.id_number, studentToAdd.present, studentToAdd.last_update);
#endif
}

+(OdinStudent *) getStudentObjectForID:(NSString *)idNumber andMOC:(NSManagedObjectContext *)managedObjectContext
{
    NSArray *arrayOfStudentToUpdate = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                                                withPredicate:[NSPredicate predicateWithFormat:@"id_number = %@",idNumber]
                                                                   andSortKey:nil
                                                             andSortAscending:NO
                                                                   andContext:managedObjectContext];
    if ([arrayOfStudentToUpdate count] <= 0)
    {
        return nil;
    }
    else
    {
        return [arrayOfStudentToUpdate objectAtIndex:0];
    }
}

+(NSArray*)getAllStudent
{
    NSManagedObjectContext* moc = [CoreDataService getMainMOC];
    //    [CoreDataService saveObjectsInContext:self.moc];
    NSArray *arrayOfTransaction = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                                            withPredicate:nil
                                                               andSortKey:nil
                                                         andSortAscending:NO
                                                               andContext:moc];
    
    if (@(arrayOfTransaction.count) > 0) {
        return arrayOfTransaction;
    }
    return nil;
    
}

+(NSArray*)getStudentsBySearch:(NSString *)searchString
{
    NSManagedObjectContext* moc = [CoreDataService getMainMOC];
    NSArray* allStudent;
    if ([searchString isEqualToString:@""] || searchString == nil) {
        allStudent = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                               withPredicate:nil
                                                  andSortKey:@"last_name"
                                            andSortAscending:YES
                                                  andContext:moc];
    } else {
        
        allStudent = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                               withPredicate:[NSPredicate predicateWithFormat:@"student contains[c] %@ or last_name contains[c] %@ or id_number beginswith[c] %@",searchString,searchString,searchString]
                                                  andSortKey:@"last_name"
                                            andSortAscending:YES
                                                  andContext:moc];
    }
    return allStudent;
}

+(NSArray*)getStudentsBySearch:(NSString *)searchString withMOC:(NSManagedObjectContext*)moc
{
    NSArray* allStudent;
    
        if ([searchString isEqualToString:@""] || searchString == nil) {
            allStudent = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                                   withPredicate:nil
                                                      andSortKey:@"last_name"
                                                andSortAscending:YES
                                                      andContext:moc];
        } else {
            
            allStudent = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                                   withPredicate:[NSPredicate predicateWithFormat:@"student contains[c] %@ or last_name contains[c] %@ or id_number beginswith[c] %@",searchString,searchString,searchString]
                                                      andSortKey:@"last_name"
                                                andSortAscending:YES
                                                      andContext:moc];
        }
    return allStudent;
}
+(OdinStudent *)getStudentByIDnumber:(NSString *)id_number
{
    NSManagedObjectContext* moc = [CoreDataService getMainMOC];
    NSArray *arrayOfTransaction = [CoreDataService searchObjectsForEntity:@"OdinStudent"
                                                            withPredicate:[NSPredicate predicateWithFormat:@"id_number = %@",id_number]
                                                               andSortKey:nil
                                                         andSortAscending:NO
                                                               andContext:moc];
    //assert that there should be 0 or 1 values returned
    
    int count = arrayOfTransaction.count;
    if (arrayOfTransaction && count > 0) {
#ifdef DEBUG
        NSLog(@"Search student %@ found %i", id_number, count);
#endif
        return [arrayOfTransaction objectAtIndex:0];
    }
    return nil;
    
}


+(int)count
{
    return [CoreDataHelper countForEntity:@"OdinStudent" andContext:[CoreDataHelper getMainMOC]];
}
@end
