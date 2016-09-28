//
//  OdinTransaction+Methods.m
//  OdinScanner
//
//  Created by Ben McCloskey on 10/19/12.
//
//

#import "OdinTransaction.h"
#import "OdinTransaction+Methods.h"
#import "OdinEvent+Methods.h"
#import "NSString+hackXML.h"
//#import "Temptran.h"

@implementation OdinTransaction (Methods)

+(NSDecimalNumber *)getTotalAmountFromQtyEntered:(NSNumber *)qty andAmountEntered:(NSDecimalNumber *)amount forItem:(OdinEvent *)selectedItem
{
    NSDecimalNumber *amountPerItem = amount;
    //if item is taxable, then add tax amount to the "per item" amount
    if ([selectedItem.taxable boolValue] == TRUE)
    {
#ifdef DEBUG
        NSLog(@"isTaxable");
        NSLog(@"qyt %@",qty);
        NSLog(@"amount entered %2.2f",amount.floatValue);
        NSLog(@"tax rate %@",selectedItem.tax);
#endif
        //get the % value
        //		NSDecimalNumber *taxPercent = selectedItem.tax;
        //divide by 100
        //		NSDecimalNumber *taxDecimal = [taxPercent decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithMantissa:100 exponent:0 isNegative:NO]];
        //then multiply by the retail amount for 1 item
        //		NSDecimalNumber *taxAmountPerItem = [amount decimalNumberByMultiplyingBy:taxDecimal];
        //add tax total to retail amount
        //		amountPerItem = [amount decimalNumberByAdding:taxAmountPerItem];
        amountPerItem = [amount addTax:selectedItem.tax];
#ifdef DEBUG
        NSLog(@"item included tax %2.f",amountPerItem.floatValue);
#endif
    }
    //multiply "per item" amount by # of items
    NSDecimalNumber *totalAmount = [amountPerItem decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithNumber:qty]];
    
    return totalAmount;
}
-(NSDictionary *)preppedForWeb
{
    //must send it to web as a dictionary, must organize elements to be validly transformable to dictionary
    
    NSMutableDictionary *tAsDictionary = [[NSMutableDictionary alloc] init];
    
    //[self dictionaryWithValuesForKeys:self.entity.attributesByName.allKeys];
    //[results setObject:propertyType forKey:propertyName];
    
    if([[SettingsHandler sharedHandler] school] != nil)
        [tAsDictionary setObject:[[SettingsHandler sharedHandler] school] forKey:@"school"];
    
    if (self.id_number != nil)
        [tAsDictionary setObject:self.id_number forKey:@"id_number"];
    
    if (self.location != nil)
        [tAsDictionary setObject:self.location forKey:@"location"];
    
    if (self.item != nil)
        [tAsDictionary setObject:self.item forKey:@"item"];
    
    if (self.qty != nil)
        [tAsDictionary setObject:self.qty forKey:@"qty"];
    
    if(self.amount != nil)
        [tAsDictionary setObject:self.amount forKey:@"amount"];
    
    if (self.payment != nil)
        [tAsDictionary setObject:self.payment forKey:@"payment"];
    
    if (self.reference != nil)
        [tAsDictionary setObject:self.reference forKey:@"reference"];
    
    if (self.operator != nil)
        [tAsDictionary setObject:self.operator forKey:@"operator"];
    
    if (self.tax_amount != nil)
        [tAsDictionary setObject:self.tax_amount forKey:@"tax_amount"];
    
    if (self.glcode != nil)
        [tAsDictionary setObject:self.glcode forKey:@"glcode"];
    
    if (self.dept_code != nil)
        [tAsDictionary setObject:self.dept_code forKey:@"dept_code"];
    
    if (self.plu != nil)
        [tAsDictionary setObject:self.plu forKey:@"plu"];
    
    if (self.sync != nil)
        [tAsDictionary setObject:self.sync forKey:@"sync"];
    
    if (self.process_on_sync != nil)
        [tAsDictionary setObject:self.process_on_sync forKey:@"process_on_sync"];
    
    if (self.cc_digit != nil)
        [tAsDictionary setObject:self.cc_digit forKey:@"cc_digit"];
    
    if (self.cc_tranid != nil)
        [tAsDictionary setObject:self.cc_tranid forKey:@"cc_tranid"];
    
    if (self.cc_approval != nil)
        [tAsDictionary setObject:self.cc_approval forKey:@"cc_approval"];
    
    if (self.first != nil)
        [tAsDictionary setObject:self.first forKey:@"first"];
    
    if (self.last != nil)
        [tAsDictionary setObject:self.last forKey:@"last"];
    
    if (self.cc_responsetext != nil)
        [tAsDictionary setObject:self.cc_responsetext forKey:@"cc_responsetext"];
    if (self.type != nil)
        [tAsDictionary setObject:self.type forKey:@"type"];
    
    //sort out time
    if(self.timeStamp != nil){
//        NSDate* localDate = [NSDate localDate];
//        self.timeStamp = localDate;
//        self.qdate = [self.timeStamp asStringWithFormat:@"@YYYY-@MM-@DD"];
//        self.time = [self.timeStamp asStringWithFormat:@"@hh:@mm:@ss"];
        
    }
    
    if (self.qdate != nil) {
        [tAsDictionary setObject:self.qdate forKey:@"qdate"];
    }
    
    if (self.time != nil) {
        [tAsDictionary setObject:self.time forKey:@"time"];
    }
    
    if (self.timeStamp != nil && self.cc_digit != 0)
        [tAsDictionary setObject:[self.timeStamp convertDataToTimestamp] forKey:@"cc_timeStamp"];
    
#ifdef DEBUG
    NSLog(@"%@ As Dictionary:%@",[[self class] description],[tAsDictionary description]);
#endif
    
    return [NSDictionary dictionaryWithDictionary:tAsDictionary];
}


#pragma mark - Conversion

-(NSString*) prepForWebservice {
    NSArray* tranArray = [[NSArray alloc] initWithObjects:self, nil];
    return [tranArray prepForWebservice];
    /*
     NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
     NSString* school = [SettingsHandler sharedHandler].school;
     NSString* source = (self.process_on_sync.intValue == 1) ? @"2" : @"1";
     
     NSArray* array = [NSArray arrayWithObjects:
     [NSString addData:self.id_number Tag:@"id_number"],
     [NSString addData:school Tag:@"school"],
     //[self addData:[NSString stringWithFormat:@"%@ %@",tran.qdate, tran.time] Tag:@"orderdate"],
     [NSString addData:self.item Tag:NAME],
     [NSString addData:self.plu Tag:PLU],
     [NSString addData:self.qty Tag:QUANTITY],
     [NSString addData:self.amount Tag:RETAIL],
     [NSString addData:self.dept_code Tag:DEPARTMENT],
     [NSString addData:self.amount Tag:TOTAL],
     [NSString addData:self.glcode Tag:GLCODE],
     [NSString addData:self.reference Tag:@"reference"],
     [NSString addData:self.qdate Tag:@"qdate"],
     [NSString addData:self.time Tag:@"time"],
     [NSString addData:self.first Tag:@"first"],
     [NSString addData:self.last Tag:@"last"],
     [NSString addData:self.location Tag:@"location"],
     [NSString addData:source Tag:@"source"],
     [NSString addData:@"Sale" Tag:@"type"],
     [NSString addData:self.payment Tag:@"payment"],
     [NSString addData:self.tax_amount Tag:@"tax_amount"],
     [NSString addData:self.operator Tag:@"operator"],
     [NSString addData:self.process_on_sync Tag:@"process_on_sync"],
     [NSString addData:[NSString stringWithFormat:@"%f",date] Tag:@"orderDate"],
     [NSString addData:[[[UIDevice currentDevice] identifierForVendor] UUIDString] Tag:@"deviceID"],
     [NSString addData:[[UIDevice currentDevice] systemVersion] Tag:@"iosVersion"],
     nil];
     
     
     return [array componentsJoinedByString:@""];
     */
}
-(NSString*)JSON
{
    NSError* error;
    NSDictionary* dict = [self preppedForWeb];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONReadingAllowFragments
                                                         error:&error];
    
    NSString* xmlString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (! jsonData) {
        NSLog(@"bv_jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
        return @"[]";
    }
    
    return [xmlString stringByAppendingString:@"\n"];
}

-(NSString* )getCreditCardData
{
    
    //email, name, school, approval, tranid, amount, TranData: string
    
    //NSString* name = [NSString stringWithFormat:@"%@ %@", self.first, self.last];
    //NSString* argument = [NSString stringWithFormat:@"&name=%@&school=%@&approval=%@&tranid=%@", name, self.school, self.cc_approval, self.cc_tranid];
    NSMutableArray* arguments = [[NSMutableArray alloc]  init];
    [arguments addObjectsFromArray:@[[NSString addData:self.first Tag:@"first"],
                                     [NSString addData:self.last Tag:@"last"],
                                     [NSString addData:self.school Tag:@"school"],
                                     [NSString addData:self.cc_approval Tag:@"approval"],
                                     [NSString addData:self.cc_tranid Tag:@"tranid"],
                                     [NSString addData:self.cc_responsetext Tag:@"responsetext"],
                                     [NSString addData:self.cc_digit Tag:@"cc"],
                                     ]];
    return [arguments componentsJoinedByString:@""];
}
-(NSString*)XML
{
    NSString *xmlString = [NSString stringWithFormat:@"<transaction><cc_digit>%@</cc_digit><cc_tranid>%@</cc_tranid><cc_approval>%@</cc_approval><item>%@</item><qty>%@</qty><plu>%@</plu><timestamp>%@</timestamp><glcode>%@</glcode><dept_code>%@</dept_code><operator>%@</operator><location>%@</location><reference>%@</reference><amount>%@</amount><school>%@</school><qdate>%@</qdate><time>%@</time></transaction>\n", self.cc_digit, self.cc_tranid, self.cc_approval, self.item, self.qty, self.plu, [self.timeStamp convertDataToTimestamp], self.glcode, self.dept_code, self.operator, self.location, self.reference, self.amount, self.school, self.qdate, self.time];
    return xmlString;
}
-(BOOL)existIn:(NSManagedObjectContext *)moc
{
#ifdef DEBUG
    NSLog(@"check trans reference %@", self.reference);
#endif
    //    NSManagedObjectContext* moc = [CoreDataService getMainMOC];    [CoreDataService saveObjectsInContext:self.moc];
    NSArray *arrayOfTransaction = [CoreDataService searchObjectsForEntity:@"OdinTransaction"
                                                            withPredicate:[NSPredicate predicateWithFormat:@"reference = %@",self.reference]
                                                               andSortKey:nil
                                                         andSortAscending:NO
                                                               andContext:moc];
    //assert that there should be 0 or 1 values returned
    
#ifdef DEBUG
    NSLog(@"check reference %@ found %@", self.reference, @(arrayOfTransaction.count));
#endif
    
    if (@(arrayOfTransaction.count) > 0) {
        return true;
    }
    
    return false;
    
}

+(NSArray*) reloadUnSyncedArray
{
    
    NSArray* unSyncedArray = [CoreDataService searchObjectsForEntity:@"OdinTransaction"
                                                       withPredicate:[NSPredicate predicateWithFormat:@"sync == FALSE"]
                                                          andSortKey:@"timeStamp"
                                                    andSortAscending:YES
                                                          andContext:[CoreDataService getMainMOC]];
    return unSyncedArray;
}

+(NSArray*) reloadUnSyncedArrayWithMoc:(NSManagedObjectContext*)moc
{
    
    NSArray* unSyncedArray = [CoreDataService searchObjectsForEntity:@"OdinTransaction"
                                                       withPredicate:[NSPredicate predicateWithFormat:@"sync == FALSE"]
                                                          andSortKey:@"timeStamp"
                                                    andSortAscending:YES
                                                          andContext:moc];
    return unSyncedArray;
}
//loads the array of all transactions that have been synced
+(NSArray*) reloadSyncedArray
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:[[NSDate alloc] init]];
    
    [components setHour:-[components hour]];
    [components setMinute:-[components minute]];
    [components setSecond:-[components second]];
    NSDate *today = [cal dateByAddingComponents:components toDate:[[NSDate alloc] init] options:0]; //This variable should now be pointing at a date object that is the start of today (midnight);
    
    //change to 30days after 2.6.0 previously 60days
    [components setDay:-30];
    NSDate *sixtyDaysAgo = [cal dateByAddingComponents:components toDate: today options:0];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sync == TRUE && qdate > %@", sixtyDaysAgo];
    NSArray* syncedArray = [CoreDataService searchObjectsForEntity:@"OdinTransaction"
                                                     withPredicate:predicate
                                                        andSortKey:nil
                                                  andSortAscending:NO
                                                        andContext:[CoreDataService getMainMOC]];
    return syncedArray;
    
}

+(BOOL) deleteCurrentTransaction:(NSString*)reference
{
    NSString* currentRef = reference;
    return[self deleteTransactionByReference:currentRef];
    
}

+(BOOL) deleteTransactionByReference:(NSString*)reference
{
#ifdef DEBUG
    NSLog(@"Delete trans %@", reference);
#endif
    NSManagedObjectContext* moc = [CoreDataService getMainMOC];
    NSArray *arrayOfTransaction = [CoreDataService searchObjectsForEntity:@"OdinTransaction"
                                                            withPredicate:[NSPredicate predicateWithFormat:@"reference = %@",reference]
                                                               andSortKey:nil
                                                         andSortAscending:NO
                                                               andContext:moc];
    //assert that there should be 0 or 1 values returned
    
#ifdef DEBUG
    NSLog(@"Delete trans %@ found %@", reference, @(arrayOfTransaction.count));
#endif
    
    if (@(arrayOfTransaction.count) > 0) {
#ifdef DEBUG
        //        [self HUDshowMessage:[NSString stringWithFormat:@"Delete trans %@", reference]];
#endif
        for (OdinTransaction* tran in arrayOfTransaction) {
            [moc deleteObject:tran];
        }
        
        [CoreDataService saveObjectsInContext:moc];
        return true;
    }
    
    return false;
}

-(BOOL) deleteCurrentTransaction
{
#ifdef DEBUG
    NSLog(@"Delete trans %@", self.reference);
#endif
    NSManagedObjectContext* moc = [CoreDataService getMainMOC];
    NSArray *arrayOfTransaction = [CoreDataService searchObjectsForEntity:@"OdinTransaction"
                                                            withPredicate:[NSPredicate predicateWithFormat:@"reference = %@",self.reference]
                                                               andSortKey:nil
                                                         andSortAscending:NO
                                                               andContext:moc];
    //assert that there should be 0 or 1 values returned
    
#ifdef DEBUG
    NSLog(@"Delete trans %@ found %@", self.reference, @(arrayOfTransaction.count));
#endif
    
    if (@(arrayOfTransaction.count) > 0) {
#ifdef DEBUG
        //        [self HUDshowMessage:[NSString stringWithFormat:@"Delete trans %@", reference]];
#endif
        for (OdinTransaction* tran in arrayOfTransaction) {
            [moc deleteObject:tran];
        }
        
        [CoreDataService saveObjectsInContext:moc];
        return true;
    }
    
    return false;
}

+(OdinTransaction *)getTransactionByReference:(NSString *)reference
{
    NSManagedObjectContext* moc = [CoreDataService getMainMOC];
    NSArray *arrayOfTransaction = [CoreDataService searchObjectsForEntity:@"OdinTransaction"
                                                            withPredicate:[NSPredicate predicateWithFormat:@"reference = %@",reference]
                                                               andSortKey:nil
                                                         andSortAscending:NO
                                                               andContext:moc];
    //assert that there should be 0 or 1 values returned
    
#ifdef DEBUG
    NSLog(@"Search trans %@ found %@", reference, @(arrayOfTransaction.count));
#endif
    
    if (@(arrayOfTransaction.count) > 0) {
        return [arrayOfTransaction objectAtIndex:0];
    }
    return nil;
    
}

+(OdinTransaction *)getTransactionByReference:(NSString *)reference andContext:(NSManagedObjectContext*)moc
{
    NSArray *arrayOfTransaction = [CoreDataService searchObjectsForEntity:@"OdinTransaction"
                                                            withPredicate:[NSPredicate predicateWithFormat:@"reference = %@",reference]
                                                               andSortKey:nil
                                                         andSortAscending:NO
                                                               andContext:moc];
    //assert that there should be 0 or 1 values returned
    
#ifdef DEBUG
    NSLog(@"Search trans %@ found %@", reference, @(arrayOfTransaction.count));
#endif
    
    if (@(arrayOfTransaction.count) > 0) {
        return [arrayOfTransaction objectAtIndex:0];
    }
    return nil;
    
}
+(OdinTransaction *)getTransaction:(NSDictionary*)transaction andContext:(NSManagedObjectContext*)moc
{
    NSString* reference = [transaction objectForKey:@"reference"];
    NSString* plu = [transaction objectForKey:@"plu"];
    NSString* item = [transaction objectForKey:@"item"];
    NSPredicate* refPre = [NSPredicate predicateWithFormat:@"reference = %@",reference];
    NSPredicate* pluPre = [NSPredicate predicateWithFormat:@"plu = %@",plu];
    NSPredicate* itemPre = [NSPredicate predicateWithFormat:@"item = %@",item];
    NSPredicate* predicates = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:refPre,pluPre,itemPre,nil]];
    NSArray *arrayOfTransaction = [CoreDataService searchObjectsForEntity:@"OdinTransaction"
                                                            withPredicate:predicates
                                                               andSortKey:nil
                                                         andSortAscending:NO
                                                               andContext:moc];
    //assert that there should be 0 or 1 values returned
    
#ifdef DEBUG
    NSLog(@"Search trans %@ found %@", reference, @(arrayOfTransaction.count));
#endif
    
    if (@(arrayOfTransaction.count) > 0) {
        return [arrayOfTransaction objectAtIndex:0];
    }
    return nil;
    
}

@end
