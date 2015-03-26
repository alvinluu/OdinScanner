//
//  ALAlertView+methods.h
//  OdinScanner
//
//  Created by KenThomsen on 3/2/15.
//
//

#import "ALAlertView.h"

@interface ALAlertView (methods)


#pragma mark - Invalid Input
-(void) emptyField:(UIView*)vc;
-(void) invalidQuantity:(UIView*)vc;
-(void) invalidTax:(UIView*)vc;
-(void) invalidRetail:(UIView*)vc;
-(void) noItemSelected:(UIView*)vc;
-(void) cardPresentAlert:(UIView*)vc;
-(void) noCost:(UIView*)vc;
-(void) studentCantAfford:(NSString *)studentID sourceView:(UIView*)vc;

#pragma mark - Data / Connection
-(void) switchedToOfflineMode:(UIView*)vc;
-(void) cannotEditItem:(UIView*)vc;
-(void) cannotEditItem:(NSString *)specifier sourceView:(UIView*)vc;
-(void) cannotUpdateInOffline:(UIView*)vc;
-(void) cannotSwitchToOnline:(UIView*)vc;
-(void) noSchoolServer:(UIView*)vc;
-(void) noStudentConnection:(NSString*)id_number sourceView:(UIView*)vc;
-(void) synchedAlert:(UIView*)vc;
-(void) noScannerToOfflineMode:(UIView*)vc;
-(void) noInternetConnection:(UIView*)vc;


#pragma mark - Credit Card
-(void) chargeDeclined:(UIView*)vc;
-(void) failToPostToWebservice:(UIView*)vc;
-(void) failToPostToEmailService:(UIView*)vc;

#pragma mark - Custom Alert
-(void) simpleAlertInView:(NSString *)title message:(NSString *)message sourceView:(UIView*)vc;

@end
