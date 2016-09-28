
/******************************************************************
   E-Payment Integrator V6 for Mac OS X and iOS
   Copyright (c) 2015 /n software inc. - All rights reserved.
*******************************************************************/

#import <Foundation/Foundation.h>

//CVVPRESENCES
#define CVP_NOT_PROVIDED                                   0
#define CVP_PROVIDED                                       1
#define CVP_ILLEGIBLE                                      2
#define CVP_NOT_ON_CARD                                    3

//ENTRYDATASOURCES
#define EDS_TRACK_1                                        0
#define EDS_TRACK_2                                        1
#define EDS_MANUAL_ENTRY_TRACK_1CAPABLE                    2
#define EDS_MANUAL_ENTRY_TRACK_2CAPABLE                    3
#define EDS_MANUAL_ENTRY_NO_CARD_READER                    4
#define EDS_TRACK_1CONTACTLESS                             5
#define EDS_TRACK_2CONTACTLESS                             6
#define EDS_MANUAL_ENTRY_CONTACTLESS_CAPABLE               7
#define EDS_IVR                                            8
#define EDS_KIOSK                                          9

//TGATEWAY
#define GW_NO_GATEWAY                                      0
#define GW_AUTHORIZE_NET                                   1
#define GW_EPROCESSING                                     2
#define GW_ITRANSACT                                       4
#define GW_NET_BILLING                                     5
#define GW_PAY_FLOW_PRO                                    6
#define GW_USAE_PAY                                        7
#define GW_PLUG_NPAY                                       8
#define GW_PLANET_PAYMENT                                  9
#define GW_MPCS                                            10
#define GW_RTWARE                                          11
#define GW_ECX                                             12
#define GW_BANK_OF_AMERICA                                 13
#define GW_MERCHANT_ANYWHERE                               15
#define GW_SKIPJACK                                        16
#define GW_INTUIT_PAYMENT_SOLUTIONS                        17
#define GW_TRUST_COMMERCE                                  19
#define GW_PAY_FUSE                                        21
#define GW_LINK_POINT                                      24
#define GW_FAST_TRANSACT                                   27
#define GW_NETWORK_MERCHANTS                               28
#define GW_PRIGATE                                         30
#define GW_MERCHANT_PARTNERS                               31
#define GW_FIRST_DATA                                      33
#define GW_YOUR_PAY                                        34
#define GW_ACHPAYMENTS                                     35
#define GW_PAYMENTS_GATEWAY                                36
#define GW_CYBER_SOURCE                                    37
#define GW_GO_EMERCHANT                                    39
#define GW_CHASE                                           41
#define GW_NEX_COMMERCE                                    42
#define GW_TRANSACTION_CENTRAL                             44
#define GW_STERLING                                        45
#define GW_PAY_JUNCTION                                    46
#define GW_MY_VIRTUAL_MERCHANT                             49
#define GW_VERIFI                                          54
#define GW_MERCHANT_ESOLUTIONS                             56
#define GW_PAY_LEAP                                        57
#define GW_WORLD_PAY_XML                                   59
#define GW_PRO_PAY                                         60
#define GW_QBMS                                            61
#define GW_HEARTLAND                                       62
#define GW_LITLE                                           63
#define GW_BRAIN_TREE                                      64
#define GW_JET_PAY                                         65
#define GW_HSBC                                            66
#define GW_BLUE_PAY                                        67
#define GW_PAY_TRACE                                       70
#define GW_TRANS_NATIONAL_BANKCARD                         74
#define GW_FIRST_DATA_E4                                   80
#define GW_BLUEFIN                                         82
#define GW_PAYSCAPE                                        83
#define GW_PAY_DIRECT                                      84
#define GW_WORLD_PAY_LINK                                  87
#define GW_PAYMENT_WORK_SUITE                              88
#define GW_FIRST_DATA_PAY_POINT                            90

//AUTHSCHEMES
#define AUTH_BASIC                                         0
#define AUTH_DIGEST                                        1
#define AUTH_PROPRIETARY                                   2
#define AUTH_NONE                                          3
#define AUTH_NTLM                                          4
#define AUTH_NEGOTIATE                                     5

//PROXYSSLTYPES
#define PS_AUTOMATIC                                       0
#define PS_ALWAYS                                          1
#define PS_NEVER                                           2
#define PS_TUNNEL                                          3

//CERTSTORETYPES
#define CST_USER                                           0
#define CST_MACHINE                                        1
#define CST_PFXFILE                                        2
#define CST_PFXBLOB                                        3
#define CST_JKSFILE                                        4
#define CST_JKSBLOB                                        5
#define CST_PEMKEY_FILE                                    6
#define CST_PEMKEY_BLOB                                    7
#define CST_PUBLIC_KEY_FILE                                8
#define CST_PUBLIC_KEY_BLOB                                9
#define CST_SSHPUBLIC_KEY_BLOB                             10
#define CST_P7BFILE                                        11
#define CST_P7BBLOB                                        12
#define CST_SSHPUBLIC_KEY_FILE                             13
#define CST_PPKFILE                                        14
#define CST_PPKBLOB                                        15
#define CST_XMLFILE                                        16
#define CST_XMLBLOB                                        17



@protocol InPayRetailDelegate <NSObject>
@optional
- (void)onError:(int)errorCode :(NSString*)description;
- (void)onSSLServerAuthentication:(NSData*)certEncoded :(NSString*)certSubject :(NSString*)certIssuer :(NSString*)status :(int*)accept;
- (void)onSSLStatus:(NSString*)message;

@end

@interface InPayRetail : NSObject {
  @public void* m_pObj;
  @public CFMutableArrayRef m_rNotifiers;
  id <InPayRetailDelegate> m_delegate;
  BOOL m_delegateHasError;
  BOOL m_delegateHasSSLServerAuthentication;
  BOOL m_delegateHasSSLStatus;

}

+ (InPayRetail*)retail;

- (id)init;
- (void)dealloc;
 
- (NSString*)lastError;
- (int)lastErrorCode;

@property (nonatomic,readwrite,assign,getter=delegate,setter=setDelegate:) id <InPayRetailDelegate> delegate;

- (id <InPayRetailDelegate>)delegate;
- (void) setDelegate:(id <InPayRetailDelegate>)anObject;

  /* events */

- (void)onError:(int)errorCode :(NSString*)description;
- (void)onSSLServerAuthentication:(NSData*)certEncoded :(NSString*)certSubject :(NSString*)certIssuer :(NSString*)status :(int*)accept;
- (void)onSSLStatus:(NSString*)message;

  /* properties */

@property (nonatomic,readwrite,assign,getter=authCode,setter=setAuthCode:) NSString* authCode;

- (NSString*)authCode;

- (void)setAuthCode:(NSString*)newAuthCode;



@property (nonatomic,readwrite,assign,getter=cardCVVData,setter=setCardCVVData:) NSString* cardCVVData;

- (NSString*)cardCVVData;

- (void)setCardCVVData:(NSString*)newCardCVVData;



@property (nonatomic,readwrite,assign,getter=cardCVVPresence,setter=setCardCVVPresence:) int cardCVVPresence;

- (int)cardCVVPresence;

- (void)setCardCVVPresence:(int)newCardCVVPresence;



@property (nonatomic,readwrite,assign,getter=cardEntryDataSource,setter=setCardEntryDataSource:) int cardEntryDataSource;

- (int)cardEntryDataSource;

- (void)setCardEntryDataSource:(int)newCardEntryDataSource;



@property (nonatomic,readwrite,assign,getter=cardExpMonth,setter=setCardExpMonth:) int cardExpMonth;

- (int)cardExpMonth;

- (void)setCardExpMonth:(int)newCardExpMonth;



@property (nonatomic,readwrite,assign,getter=cardExpYear,setter=setCardExpYear:) int cardExpYear;

- (int)cardExpYear;

- (void)setCardExpYear:(int)newCardExpYear;



@property (nonatomic,readwrite,assign,getter=cardMagneticStripe,setter=setCardMagneticStripe:) NSString* cardMagneticStripe;

- (NSString*)cardMagneticStripe;

- (void)setCardMagneticStripe:(NSString*)newCardMagneticStripe;



@property (nonatomic,readwrite,assign,getter=cardNumber,setter=setCardNumber:) NSString* cardNumber;

- (NSString*)cardNumber;

- (void)setCardNumber:(NSString*)newCardNumber;



@property (nonatomic,readwrite,assign,getter=customerAddress,setter=setCustomerAddress:) NSString* customerAddress;

- (NSString*)customerAddress;

- (void)setCustomerAddress:(NSString*)newCustomerAddress;



@property (nonatomic,readwrite,assign,getter=customerAddress2,setter=setCustomerAddress2:) NSString* customerAddress2;

- (NSString*)customerAddress2;

- (void)setCustomerAddress2:(NSString*)newCustomerAddress2;



@property (nonatomic,readwrite,assign,getter=customerAggregate,setter=setCustomerAggregate:) NSString* customerAggregate;

- (NSString*)customerAggregate;

- (void)setCustomerAggregate:(NSString*)newCustomerAggregate;



@property (nonatomic,readwrite,assign,getter=customerCity,setter=setCustomerCity:) NSString* customerCity;

- (NSString*)customerCity;

- (void)setCustomerCity:(NSString*)newCustomerCity;



@property (nonatomic,readwrite,assign,getter=customerCountry,setter=setCustomerCountry:) NSString* customerCountry;

- (NSString*)customerCountry;

- (void)setCustomerCountry:(NSString*)newCustomerCountry;



@property (nonatomic,readwrite,assign,getter=customerEmail,setter=setCustomerEmail:) NSString* customerEmail;

- (NSString*)customerEmail;

- (void)setCustomerEmail:(NSString*)newCustomerEmail;



@property (nonatomic,readwrite,assign,getter=customerFax,setter=setCustomerFax:) NSString* customerFax;

- (NSString*)customerFax;

- (void)setCustomerFax:(NSString*)newCustomerFax;



@property (nonatomic,readwrite,assign,getter=customerFirstName,setter=setCustomerFirstName:) NSString* customerFirstName;

- (NSString*)customerFirstName;

- (void)setCustomerFirstName:(NSString*)newCustomerFirstName;



@property (nonatomic,readwrite,assign,getter=customerFullName,setter=setCustomerFullName:) NSString* customerFullName;

- (NSString*)customerFullName;

- (void)setCustomerFullName:(NSString*)newCustomerFullName;



@property (nonatomic,readwrite,assign,getter=customerId,setter=setCustomerId:) NSString* customerId;

- (NSString*)customerId;

- (void)setCustomerId:(NSString*)newCustomerId;



@property (nonatomic,readwrite,assign,getter=customerLastName,setter=setCustomerLastName:) NSString* customerLastName;

- (NSString*)customerLastName;

- (void)setCustomerLastName:(NSString*)newCustomerLastName;



@property (nonatomic,readwrite,assign,getter=customerPhone,setter=setCustomerPhone:) NSString* customerPhone;

- (NSString*)customerPhone;

- (void)setCustomerPhone:(NSString*)newCustomerPhone;



@property (nonatomic,readwrite,assign,getter=customerState,setter=setCustomerState:) NSString* customerState;

- (NSString*)customerState;

- (void)setCustomerState:(NSString*)newCustomerState;



@property (nonatomic,readwrite,assign,getter=customerZip,setter=setCustomerZip:) NSString* customerZip;

- (NSString*)customerZip;

- (void)setCustomerZip:(NSString*)newCustomerZip;



@property (nonatomic,readwrite,assign,getter=gateway,setter=setGateway:) int gateway;

- (int)gateway;

- (void)setGateway:(int)newGateway;



@property (nonatomic,readwrite,assign,getter=gatewayURL,setter=setGatewayURL:) NSString* gatewayURL;

- (NSString*)gatewayURL;

- (void)setGatewayURL:(NSString*)newGatewayURL;



@property (nonatomic,readwrite,assign,getter=invoiceNumber,setter=setInvoiceNumber:) NSString* invoiceNumber;

- (NSString*)invoiceNumber;

- (void)setInvoiceNumber:(NSString*)newInvoiceNumber;



@property (nonatomic,readwrite,assign,getter=level2Aggregate,setter=setLevel2Aggregate:) NSString* level2Aggregate;

- (NSString*)level2Aggregate;

- (void)setLevel2Aggregate:(NSString*)newLevel2Aggregate;



@property (nonatomic,readwrite,assign,getter=level3Aggregate,setter=setLevel3Aggregate:) NSString* level3Aggregate;

- (NSString*)level3Aggregate;

- (void)setLevel3Aggregate:(NSString*)newLevel3Aggregate;



@property (nonatomic,readwrite,assign,getter=merchantLogin,setter=setMerchantLogin:) NSString* merchantLogin;

- (NSString*)merchantLogin;

- (void)setMerchantLogin:(NSString*)newMerchantLogin;



@property (nonatomic,readwrite,assign,getter=merchantPassword,setter=setMerchantPassword:) NSString* merchantPassword;

- (NSString*)merchantPassword;

- (void)setMerchantPassword:(NSString*)newMerchantPassword;



@property (nonatomic,readwrite,assign,getter=proxyAuthScheme,setter=setProxyAuthScheme:) int proxyAuthScheme;

- (int)proxyAuthScheme;

- (void)setProxyAuthScheme:(int)newProxyAuthScheme;



@property (nonatomic,readwrite,assign,getter=proxyAutoDetect,setter=setProxyAutoDetect:) BOOL proxyAutoDetect;

- (BOOL)proxyAutoDetect;

- (void)setProxyAutoDetect:(BOOL)newProxyAutoDetect;



@property (nonatomic,readwrite,assign,getter=proxyPassword,setter=setProxyPassword:) NSString* proxyPassword;

- (NSString*)proxyPassword;

- (void)setProxyPassword:(NSString*)newProxyPassword;



@property (nonatomic,readwrite,assign,getter=proxyPort,setter=setProxyPort:) int proxyPort;

- (int)proxyPort;

- (void)setProxyPort:(int)newProxyPort;



@property (nonatomic,readwrite,assign,getter=proxyServer,setter=setProxyServer:) NSString* proxyServer;

- (NSString*)proxyServer;

- (void)setProxyServer:(NSString*)newProxyServer;



@property (nonatomic,readwrite,assign,getter=proxySSL,setter=setProxySSL:) int proxySSL;

- (int)proxySSL;

- (void)setProxySSL:(int)newProxySSL;



@property (nonatomic,readwrite,assign,getter=proxyUser,setter=setProxyUser:) NSString* proxyUser;

- (NSString*)proxyUser;

- (void)setProxyUser:(NSString*)newProxyUser;



@property (nonatomic,readonly,assign,getter=responseApprovalCode) NSString* responseApprovalCode;


- (NSString*)responseApprovalCode;




@property (nonatomic,readonly,assign,getter=responseApproved) BOOL responseApproved;


- (BOOL)responseApproved;




@property (nonatomic,readonly,assign,getter=responseApprovedAmount) NSString* responseApprovedAmount;


- (NSString*)responseApprovedAmount;




@property (nonatomic,readonly,assign,getter=responseAVSResult) NSString* responseAVSResult;


- (NSString*)responseAVSResult;




@property (nonatomic,readonly,assign,getter=responseCode) NSString* responseCode;


- (NSString*)responseCode;




@property (nonatomic,readonly,assign,getter=responseCVVResult) NSString* responseCVVResult;


- (NSString*)responseCVVResult;




@property (nonatomic,readonly,assign,getter=responseData) NSString* responseData;


- (NSString*)responseData;




@property (nonatomic,readonly,assign,getter=responseErrorCode) NSString* responseErrorCode;


- (NSString*)responseErrorCode;




@property (nonatomic,readonly,assign,getter=responseErrorText) NSString* responseErrorText;


- (NSString*)responseErrorText;




@property (nonatomic,readonly,assign,getter=responseInvoiceNumber) NSString* responseInvoiceNumber;


- (NSString*)responseInvoiceNumber;




@property (nonatomic,readonly,assign,getter=responseProcessorCode) NSString* responseProcessorCode;


- (NSString*)responseProcessorCode;




@property (nonatomic,readonly,assign,getter=responseText) NSString* responseText;


- (NSString*)responseText;




@property (nonatomic,readonly,assign,getter=responseTransactionId) NSString* responseTransactionId;


- (NSString*)responseTransactionId;




@property (nonatomic,readwrite,assign,getter=shippingAddress,setter=setShippingAddress:) NSString* shippingAddress;

- (NSString*)shippingAddress;

- (void)setShippingAddress:(NSString*)newShippingAddress;



@property (nonatomic,readwrite,assign,getter=shippingAddress2,setter=setShippingAddress2:) NSString* shippingAddress2;

- (NSString*)shippingAddress2;

- (void)setShippingAddress2:(NSString*)newShippingAddress2;



@property (nonatomic,readwrite,assign,getter=shippingCity,setter=setShippingCity:) NSString* shippingCity;

- (NSString*)shippingCity;

- (void)setShippingCity:(NSString*)newShippingCity;



@property (nonatomic,readwrite,assign,getter=shippingCountry,setter=setShippingCountry:) NSString* shippingCountry;

- (NSString*)shippingCountry;

- (void)setShippingCountry:(NSString*)newShippingCountry;



@property (nonatomic,readwrite,assign,getter=shippingEmail,setter=setShippingEmail:) NSString* shippingEmail;

- (NSString*)shippingEmail;

- (void)setShippingEmail:(NSString*)newShippingEmail;



@property (nonatomic,readwrite,assign,getter=shippingFirstName,setter=setShippingFirstName:) NSString* shippingFirstName;

- (NSString*)shippingFirstName;

- (void)setShippingFirstName:(NSString*)newShippingFirstName;



@property (nonatomic,readwrite,assign,getter=shippingLastName,setter=setShippingLastName:) NSString* shippingLastName;

- (NSString*)shippingLastName;

- (void)setShippingLastName:(NSString*)newShippingLastName;



@property (nonatomic,readwrite,assign,getter=shippingPhone,setter=setShippingPhone:) NSString* shippingPhone;

- (NSString*)shippingPhone;

- (void)setShippingPhone:(NSString*)newShippingPhone;



@property (nonatomic,readwrite,assign,getter=shippingState,setter=setShippingState:) NSString* shippingState;

- (NSString*)shippingState;

- (void)setShippingState:(NSString*)newShippingState;



@property (nonatomic,readwrite,assign,getter=shippingZip,setter=setShippingZip:) NSString* shippingZip;

- (NSString*)shippingZip;

- (void)setShippingZip:(NSString*)newShippingZip;



@property (nonatomic,readwrite,assign,getter=specialFieldCount,setter=setSpecialFieldCount:) int specialFieldCount;

- (int)specialFieldCount;

- (void)setSpecialFieldCount:(int)newSpecialFieldCount;





- (NSString*)specialFieldName:(int)fieldIndex ;

- (void)setSpecialFieldName:(int)fieldIndex :(NSString*)newSpecialFieldName;





- (NSString*)specialFieldValue:(int)fieldIndex ;

- (void)setSpecialFieldValue:(int)fieldIndex :(NSString*)newSpecialFieldValue;



@property (nonatomic,readwrite,assign,getter=SSLAcceptServerCertEncoded,setter=setSSLAcceptServerCertEncoded:) NSString* SSLAcceptServerCertEncoded;

- (NSString*)SSLAcceptServerCertEncoded;

- (void)setSSLAcceptServerCertEncoded:(NSString*)newSSLAcceptServerCertEncoded;


@property (nonatomic,readwrite,assign,getter=SSLAcceptServerCertEncodedB,setter=setSSLAcceptServerCertEncodedB:) NSData* SSLAcceptServerCertEncodedB;
- (NSData*)SSLAcceptServerCertEncodedB;
- (void)setSSLAcceptServerCertEncodedB :(NSData*)newSSLAcceptServerCertEncoded;
@property (nonatomic,readwrite,assign,getter=SSLCertEncoded,setter=setSSLCertEncoded:) NSString* SSLCertEncoded;

- (NSString*)SSLCertEncoded;

- (void)setSSLCertEncoded:(NSString*)newSSLCertEncoded;


@property (nonatomic,readwrite,assign,getter=SSLCertEncodedB,setter=setSSLCertEncodedB:) NSData* SSLCertEncodedB;
- (NSData*)SSLCertEncodedB;
- (void)setSSLCertEncodedB :(NSData*)newSSLCertEncoded;
@property (nonatomic,readwrite,assign,getter=SSLCertStore,setter=setSSLCertStore:) NSString* SSLCertStore;

- (NSString*)SSLCertStore;

- (void)setSSLCertStore:(NSString*)newSSLCertStore;


@property (nonatomic,readwrite,assign,getter=SSLCertStoreB,setter=setSSLCertStoreB:) NSData* SSLCertStoreB;
- (NSData*)SSLCertStoreB;
- (void)setSSLCertStoreB :(NSData*)newSSLCertStore;
@property (nonatomic,readwrite,assign,getter=SSLCertStorePassword,setter=setSSLCertStorePassword:) NSString* SSLCertStorePassword;

- (NSString*)SSLCertStorePassword;

- (void)setSSLCertStorePassword:(NSString*)newSSLCertStorePassword;



@property (nonatomic,readwrite,assign,getter=SSLCertStoreType,setter=setSSLCertStoreType:) int SSLCertStoreType;

- (int)SSLCertStoreType;

- (void)setSSLCertStoreType:(int)newSSLCertStoreType;



@property (nonatomic,readwrite,assign,getter=SSLCertSubject,setter=setSSLCertSubject:) NSString* SSLCertSubject;

- (NSString*)SSLCertSubject;

- (void)setSSLCertSubject:(NSString*)newSSLCertSubject;



@property (nonatomic,readonly,assign,getter=SSLServerCertEncoded) NSString* SSLServerCertEncoded;


- (NSString*)SSLServerCertEncoded;



@property (nonatomic,readonly,assign,getter=SSLServerCertEncodedB) NSData* SSLServerCertEncodedB;

- (NSData*)SSLServerCertEncodedB;

@property (nonatomic,readwrite,assign,getter=testMode,setter=setTestMode:) BOOL testMode;

- (BOOL)testMode;

- (void)setTestMode:(BOOL)newTestMode;



@property (nonatomic,readwrite,assign,getter=timeout,setter=setTimeout:) int timeout;

- (int)timeout;

- (void)setTimeout:(int)newTimeout;



@property (nonatomic,readwrite,assign,getter=transactionAmount,setter=setTransactionAmount:) NSString* transactionAmount;

- (NSString*)transactionAmount;

- (void)setTransactionAmount:(NSString*)newTransactionAmount;



@property (nonatomic,readwrite,assign,getter=transactionDesc,setter=setTransactionDesc:) NSString* transactionDesc;

- (NSString*)transactionDesc;

- (void)setTransactionDesc:(NSString*)newTransactionDesc;



@property (nonatomic,readwrite,assign,getter=transactionId,setter=setTransactionId:) NSString* transactionId;

- (NSString*)transactionId;

- (void)setTransactionId:(NSString*)newTransactionId;




  /* methods */

- (void)addSpecialField:(NSString*)name :(NSString*)val;
- (void)authOnly;
- (void)AVSOnly;
- (void)capture:(NSString*)transactionId :(NSString*)captureAmount;
- (NSString*)config:(NSString*)configurationString;
- (void)credit;
- (void)force:(NSString*)voiceAuthCode;
- (NSString*)getResponseVar:(NSString*)name;
- (void)interrupt;
- (void)refund:(NSString*)transactionId :(NSString*)refundAmount;
- (void)resetSpecialFields;
- (void)sale;
- (void)voidTransaction:(NSString*)transactionId;

@end


