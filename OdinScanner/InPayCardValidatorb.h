
/******************************************************************
   E-Payment Integrator V6 for Mac OS X and iOS
   Copyright (c) 2015 /n software inc. - All rights reserved.
*******************************************************************/

#import <Foundation/Foundation.h>

//TCCCARDTYPE
#define VCT_UNKNOWN                                        0
#define VCT_VISA                                           1
#define VCT_MASTER_CARD                                    2
#define VCT_AMEX                                           3
#define VCT_DISCOVER                                       4
#define VCT_DINERS                                         5
#define VCT_JCB                                            6
#define VCT_VISA_ELECTRON                                  7
#define VCT_MAESTRO                                        8
#define VCT_CUP                                            9
#define VCT_LASER                                          10

//TTRACKTYPE
#define TT_UNKNOWN                                         0
#define TT_TRACK_1                                         1
#define TT_TRACK_2                                         2



@protocol InPayCardValidatorDelegate <NSObject>
@optional
- (void)onError:(int)errorCode :(NSString*)description;

@end

@interface InPayCardValidator : NSObject {
  @public void* m_pObj;
  @public CFMutableArrayRef m_rNotifiers;
  id <InPayCardValidatorDelegate> m_delegate;
  BOOL m_delegateHasError;

}

+ (InPayCardValidator*)cardvalidator;

- (id)init;
- (void)dealloc;
 
- (NSString*)lastError;
- (int)lastErrorCode;

@property (nonatomic,readwrite,assign,getter=delegate,setter=setDelegate:) id <InPayCardValidatorDelegate> delegate;

- (id <InPayCardValidatorDelegate>)delegate;
- (void) setDelegate:(id <InPayCardValidatorDelegate>)anObject;

  /* events */

- (void)onError:(int)errorCode :(NSString*)description;

  /* properties */

@property (nonatomic,readwrite,assign,getter=cardExpMonth,setter=setCardExpMonth:) int cardExpMonth;

- (int)cardExpMonth;

- (void)setCardExpMonth:(int)newCardExpMonth;



@property (nonatomic,readwrite,assign,getter=cardExpYear,setter=setCardExpYear:) int cardExpYear;

- (int)cardExpYear;

- (void)setCardExpYear:(int)newCardExpYear;



@property (nonatomic,readwrite,assign,getter=cardNumber,setter=setCardNumber:) NSString* cardNumber;

- (NSString*)cardNumber;

- (void)setCardNumber:(NSString*)newCardNumber;



@property (nonatomic,readonly,assign,getter=cardType) int cardType;


- (int)cardType;




@property (nonatomic,readonly,assign,getter=cardTypeDescription) NSString* cardTypeDescription;


- (NSString*)cardTypeDescription;




@property (nonatomic,readonly,assign,getter=dateCheckPassed) BOOL dateCheckPassed;


- (BOOL)dateCheckPassed;




@property (nonatomic,readonly,assign,getter=digitCheckPassed) BOOL digitCheckPassed;


- (BOOL)digitCheckPassed;




@property (nonatomic,readwrite,assign,getter=trackData,setter=setTrackData:) NSString* trackData;

- (NSString*)trackData;

- (void)setTrackData:(NSString*)newTrackData;



@property (nonatomic,readonly,assign,getter=trackType) int trackType;


- (int)trackType;





  /* methods */

- (NSString*)config:(NSString*)configurationString;
- (void)reset;
- (void)validateCard;

@end


