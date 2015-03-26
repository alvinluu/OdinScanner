//
//  PSTAlertController+method.h
//  OdinScanner
//
//  Created by KenThomsen on 1/7/15.
//
//

#import "PSTAlertController.h"

@interface PSTAlertController (method)

#pragma mark - Invalid Input
+(void) emptyField:(UIViewController*)vc;
+(void) invalidQuantity:(UIViewController*)vc;
+(void) invalidTax:(UIViewController*)vc;
+(void) invalidRetail:(UIViewController*)vc;
+(void) noItemSelected:(UIViewController*)vc;
+(void) cardPresentAlert:(UIViewController*)vc;
+(void) noCost:(UIViewController*)vc;
+(void) studentCantAfford:(NSString *)studentID controller:(UIViewController*)vc;

#pragma mark - Data / Connection
+(void) switchedToOfflineMode:(UIViewController*)vc;
+(void) cannotEditItem:(UIViewController*)vc;
+(void) cannotEditItem:(NSString *)specifier controller:(UIViewController*)vc;
+(void) cannotUpdateInOffline:(UIViewController*)vc;
+(void) cannotSwitchToOnline:(UIViewController*)vc;
+(void) noSchoolServer:(UIViewController*)vc;
+(void) noStudentConnection:(NSString*)id_number controller:(UIViewController*)vc;
+(void) synchedAlert:(UIViewController*)vc;
+(void) noScannerToOfflineMode:(UIViewController*)vc;
+(void) noInternetConnection:(UIViewController*)vc;


#pragma mark - Credit Card
+(void) chargeDeclined:(UIViewController*)vc;
+(void) failToPostToWebservice:(UIViewController*)vc;
+(void) failToPostToEmailService:(UIViewController*)vc;

#pragma mark - Custom Alert
+(void) customSimpleAlertWithTitle:(NSString*)title message:(NSString*)message controller:(UIViewController*)vc;
@end
