//
//  ReceiptViewController.h
//  OdinScanner
//
//  Created by KenThomsen on 8/1/14.
//
//

#import <UIKit/UIKit.h>
#import "OdinViewController.h"


@interface ReceiptVC : OdinViewController <
NSXMLParserDelegate,
UIPrintInteractionControllerDelegate>
@property (nonatomic, strong) NSArray* transArray;
@property (nonatomic, strong) NSString* type;

//connection
@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, strong) NSMutableString *soapResults;
@property (nonatomic) BOOL recordResults;

//Interface
@property (nonatomic, strong) IBOutlet UITextField *emailAddress;
@property (nonatomic, strong) IBOutlet UIButton *emailBut;
@property (nonatomic, strong) IBOutlet UIButton *airPrintBut;
@property (nonatomic, strong) IBOutlet UIButton *cancelBut;
@property (strong, nonatomic) IBOutlet UILabel *chargeStatus;

//Variables
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDecimalNumber *totalAmount;
@property (nonatomic, strong) NSString *approval;
@property (nonatomic, strong) NSString *school;
@property (nonatomic, strong) NSString *tranid;
@end
