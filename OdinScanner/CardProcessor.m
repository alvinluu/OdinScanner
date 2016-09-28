//
//  CardValidator.m
//  OdinScanner
//
//  Created by KenThomsen on 7/9/14.
//
//

#import "CardProcessor.h"


@implementation CardProcessor

@synthesize stripData;



+(CardProcessor*)initialize:(NSString *)magnetic
{
    SettingsHandler* set = [SettingsHandler sharedHandler];
    if ([set.merchantName.lowercaseString isEqualToString:@"odintest"]) {
        
    } else if ([set.merchantLogin isEqual:@""] ||
               [set.merchantName isEqual:@""] ||
               [set.merchantPassword isEqual:@""] ) {
        [ErrorAlert simpleAlertTitle:@"Credit Card Error!" message:@"Please set up merchant account."];
        return nil;
    }
    CardProcessor* cv = [[CardProcessor alloc]init];
    cv.stripData = magnetic;
    [cv setCardMagneticStripe:magnetic];
    return cv;
}
-(BOOL)makePurchase
{
    //[self sale];
    
#ifdef DEBUG
    NSLog(@"make purchase");
#endif
    if (![self setTerminal]) {
        [ErrorAlert simpleAlertTitle:@"Unknown merchant" message:@""];
        return false;
    }
    
    
    //your code here
    MBProgressHUD *HUD = [HUDsingleton sharedHUD];
    HUD.detailsLabelText = @"";
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.labelText = @"Processing Card";
    [[UIApplication sharedApplication].keyWindow addSubview:HUD];
    [HUD show:YES];
    
    //[HUD showWhileExecuting:@selector(authOnly) onTarget:SELF withObject:nil animated:YES];
    
    //[self authOnly];
    
    [self sale];
#ifdef DEBUG
    NSLog(@"\nCC process avs result %@", [self responseAVSResult]);
    NSLog(@"CC process error %@", [self responseErrorText]);
    NSLog(@"CC process text %@", [self responseText]);
    NSLog(@"CC process amount %@", [self responseApprovedAmount]);
    NSLog(@"CC process code %@", [self responseApprovalCode]); //store this
    NSLog(@"CC process bool %i", [self responseApproved]); //tell success or fail
    NSLog(@"CC process invoice %@", [self responseInvoiceNumber]);
    NSLog(@"CC process tranid %@", [self responseTransactionId]);
    NSLog(@"CC process proc code %@", [self responseProcessorCode]);
    NSLog(@"CC process cvv %@", [self responseCVVResult]);
    NSLog(@"CC process approval %i", [self responseApproved]);
    NSLog(@"CC process merchant %@", [self gatewayURL]);
    NSLog(@"CC process login %@", [self merchantLogin]);
    NSLog(@"CC process pass %@", [self merchantPassword]);
#endif
    
    [HUD hide:YES];
    
    
    if ([self responseApproved]) return TRUE;
    
    
    //alert user credit card failed
    [ErrorAlert simpleAlertTitle:@"Charge Declined" message:@""];
    return FALSE;
}
-(NSNumber*)getCardLast4Digits
{
    NSString *data = stripData;
    NSRange range = [data rangeOfString:@"="];
    if (range.location == NSNotFound) {
        return nil;
    }
    NSString *digit = [data substringWithRange:NSMakeRange(range.location-4, 4)];
    
    
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterNoStyle];
    if (f) return [f numberFromString:digit];
    
    return nil;
}
-(NSDate*)getCardExpDate
{
    NSString *data = stripData;
    NSRange range = [data rangeOfString:@"="];
    if (range.location == NSNotFound) {
        return nil;
    }
    NSString *dateString = [data substringWithRange:NSMakeRange(range.location+1, 4)];
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"yyMM"];
    NSDate *date = [df dateFromString:dateString];
    
    if (date) return date;
    
    return nil;
}
-(NSString*)getCardName
{
    NSString *data = stripData;
    
    //get last name
    NSRange range = [data rangeOfString:@"^"];
    NSRange range2 = [data rangeOfString:@"/"];
    if (range.location == NSNotFound || range2.location == NSNotFound) {
        return @"";
    }
    int length = range2.location - range.location - 1;
    NSString *lastname = [data substringWithRange:NSMakeRange(range.location+1, length)];
    lastname = [lastname stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    //get first name
    NSString *data2 = [data substringFromIndex:range2.location];
    range = [data2 rangeOfString:@"^"];
    NSString* firstname = [data2 substringWithRange:NSMakeRange(1, range.location-1)];
    firstname = [firstname stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (firstname && lastname) return [NSString stringWithFormat:@"%@ %@",firstname,lastname];
    return @"";
}
-(NSString*)getCardLastName
{
    NSString *data = stripData;
    
    //get last name
    NSRange range = [data rangeOfString:@"^"];
    NSRange range2 = [data rangeOfString:@"/"];
    if (range.location == NSNotFound || range2.location == NSNotFound) {
        return @"";
    }
    int length = range2.location - range.location - 1;
    NSString *lastname = [data substringWithRange:NSMakeRange(range.location+1, length)];
    lastname = [lastname stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (lastname) return lastname;
    return @"";
    
}
-(NSString*)getCardFirstName
{
    NSString *data = stripData;
    
    //get last name
    NSRange range2 = [data rangeOfString:@"/"];
    if (range2.location == NSNotFound) {
        return @"";
    }
    //get first name
    NSString *data2 = [data substringFromIndex:range2.location];
    NSRange range = [data2 rangeOfString:@"^"];
    NSString* firstname = [data2 substringWithRange:NSMakeRange(1, range.location-1)];
    firstname = [firstname stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (firstname) return firstname;
    
    return @"";
}
-(BOOL)isValidCardExpDate
{
    NSDate *date = [self getCardExpDate];
    NSDate* today = [[NSDate alloc]init];
    NSComparisonResult result = [today compare:date];
    
    return (result == NSOrderedDescending) ? NO : YES;
    
}
-(BOOL)setTerminal
{
    SettingsHandler* setting = [SettingsHandler sharedHandler];
    [self setMerchantLogin:setting.merchantLogin];
    [self setMerchantPassword:setting.merchantPassword];
    NSString* merchantName = setting.merchantName.lowercaseString;
    if ([merchantName isEqualToString:@"authorize"] || [merchantName isEqualToString:@"authorize.net"])
    {
        [self setGateway:GW_AUTHORIZE_NET];
    } else if ([merchantName isEqualToString:@"eprocessing"]) {
        [self setGateway:GW_EPROCESSING];
    } else if ([merchantName isEqualToString:@"itransact"]) {
        [self setGateway:GW_ITRANSACT];
    } else if ([merchantName isEqualToString:@"netbilling"]) {
        [self setGateway:GW_NET_BILLING];
    } else if ([merchantName isEqualToString:@"payflowpro"]) {
        [self setGateway:GW_PAY_FLOW_PRO];
    } else if ([merchantName isEqualToString:@"usaepay"]) {
        [self setGateway:GW_USAE_PAY];
    } else if ([merchantName isEqualToString:@"plugnpay"]) {
        [self setGateway:GW_PLUG_NPAY];
    } else if ([merchantName isEqualToString:@"planetpayment"]) {
        [self setGateway:GW_PLANET_PAYMENT];
    } else if ([merchantName isEqualToString:@"mpcs"]) {
        [self setGateway:GW_MPCS];
    } else if ([merchantName isEqualToString:@"rtware"]) {
        [self setGateway:GW_RTWARE];
    } else if ([merchantName isEqualToString:@"ecx"]) {
        [self setGateway:GW_ECX];
    } else if ([merchantName isEqualToString:@"boa"]) {
        [self setGateway:GW_BANK_OF_AMERICA];
    } else if ([merchantName isEqualToString:@"ma"]) {
        [self setGateway:GW_MERCHANT_ANYWHERE];
    } else if ([merchantName isEqualToString:@"skipjack"]) {
        [self setGateway:GW_SKIPJACK];
    } else if ([merchantName isEqualToString:@"ips"]) {
        [self setGateway:GW_INTUIT_PAYMENT_SOLUTIONS];
    } else if ([merchantName isEqualToString:@"tc"]) {
        [self setGateway:GW_TRUST_COMMERCE];
    } else if ([merchantName isEqualToString:@"pf"]) {
        [self setGateway:GW_PAY_FUSE];
    } else if ([merchantName isEqualToString:@"payfuse"]) {
        [self setGateway:GW_LINK_POINT];
    } else if ([merchantName isEqualToString:@"ft"]) {
        [self setGateway:GW_FAST_TRANSACT];
    } else if ([merchantName isEqualToString:@"nm"]) {
        [self setGateway:GW_NETWORK_MERCHANTS];
    } else if ([merchantName isEqualToString:@"prigate"]) {
        [self setGateway:GW_PRIGATE];
    } else if ([merchantName isEqualToString:@"mp"]) {
        [self setGateway:GW_MERCHANT_PARTNERS];
    } else if ([merchantName isEqualToString:@"yourpay"]) {
        [self setGateway:GW_YOUR_PAY];
    } else if ([merchantName isEqualToString:@"ap"]) {
        [self setGateway:GW_ACHPAYMENTS];
    } else if ([merchantName isEqualToString:@"pg"]) {
        [self setGateway:GW_PAYMENTS_GATEWAY];
    } else if ([merchantName isEqualToString:@"cs"]) {
        [self setGateway:GW_CYBER_SOURCE];
    } else if ([merchantName isEqualToString:@"ge"]) {
        [self setGateway:GW_GO_EMERCHANT];
    } else if ([merchantName isEqualToString:@"chase"]) {
        [self setGateway:GW_CHASE];
    } else if ([merchantName isEqualToString:@"nc"]) {
        [self setGateway:GW_NEX_COMMERCE];
    } else if ([merchantName isEqualToString:@"tc"]) {
        [self setGateway:GW_TRANSACTION_CENTRAL];
    } else if ([merchantName isEqualToString:@"sterling"]) {
        [self setGateway:GW_STERLING];
    } else if ([merchantName isEqualToString:@"payjunction"]) {
        [self setGateway:GW_PAY_JUNCTION];
    } else if ([merchantName isEqualToString:@"mvm"]) {
        [self setGateway:GW_MY_VIRTUAL_MERCHANT];
    } else if ([merchantName isEqualToString:@"verifi"]) {
        [self setGateway:GW_VERIFI];
    } else if ([merchantName isEqualToString:@"me"]) {
        [self setGateway:GW_MERCHANT_ESOLUTIONS];
    } else if ([merchantName isEqualToString:@"pl"]) {
        [self setGateway:GW_PAY_LEAP];
    } else if ([merchantName isEqualToString:@"wpx"]) {
        [self setGateway:GW_WORLD_PAY_XML];
    } else if ([merchantName isEqualToString:@"propay"]) {
        [self setGateway:GW_PRO_PAY];
    } else if ([merchantName isEqualToString:@"qbms"]) {
        [self setGateway:GW_QBMS];
    } else if ([merchantName isEqualToString:@"heartland"]) {
        [self setGateway:GW_HEARTLAND];
    } else if ([merchantName isEqualToString:@"little"]) {
        [self setGateway:GW_LITLE];
    } else if ([merchantName isEqualToString:@"braintree"]) {
        [self setGateway:GW_BRAIN_TREE];
    } else if ([merchantName isEqualToString:@"jetpay"]) {
        [self setGateway:GW_JET_PAY];
    } else if ([merchantName isEqualToString:@"hsbc"]) {
        [self setGateway:GW_HSBC];
    } else if ([merchantName isEqualToString:@"bluepay"]) {
        [self setGateway:GW_BLUE_PAY];
    } else if ([merchantName isEqualToString:@"paytrace"]) {
        [self setGateway:GW_PAY_TRACE];
    } else if ([merchantName isEqualToString:@"tnb"]) {
        [self setGateway:GW_TRANS_NATIONAL_BANKCARD];
    } else if ([merchantName isEqualToString:@"firstdata"]) {
        [self setGateway:GW_FIRST_DATA];
    } else if ([merchantName isEqualToString:@"bluefin"]) {
        [self setGateway:GW_BLUEFIN];
    } else if ([merchantName isEqualToString:@"payscape"]) {
        [self setGateway:GW_PAYSCAPE];
    } else if ([merchantName isEqualToString:@"paydirect"]) {
        [self setGateway:GW_PAY_DIRECT];
    } else if ([merchantName isEqualToString:@"wpl"]) {
        [self setGateway:GW_WORLD_PAY_LINK];
    } else if ([merchantName isEqualToString:@"pws"]) {
        [self setGateway:GW_PAYMENT_WORK_SUITE];
    } else if ([merchantName isEqualToString:@"fdpp"]) {
        [self setGateway:GW_FIRST_DATA_PAY_POINT];
    } else if ([merchantName isEqualToString:@"odintest"]) {
        [self setMerchantLogin:@"kladdtest"];
        [self setMerchantPassword:@"n1d01ct0"];
        [self setGateway:GW_NETWORK_MERCHANTS];
    } else {
        return false;
    }
    return true;
}
@end
