
/******************************************************************
   E-Payment Integrator V6 for Mac OS X and iOS
   Copyright (c) 2015 /n software inc. - All rights reserved.
*******************************************************************/

#import "InPayRetail.h"
#ifndef __has_feature
#define __has_feature(x) 0
#endif

#define ENCODING_CONVERSION_ERROR @"Cannot convert string using specified encoding."

@interface InPayRetail()
- (NSStringEncoding)innerGetCodePage;
- (const char*)nsstringToCString:(NSString*)str;
@end

#if __cplusplus
#define Retail_EXTERN extern "C"
#else
#define Retail_EXTERN extern
#endif

Retail_EXTERN void* InPay_Retail_Create(void* lpSink, void* lpContext, char* lpOemKey);
Retail_EXTERN int   InPay_Retail_Destroy(void* lpObj);
Retail_EXTERN int   InPay_Retail_CheckIndex(void* lpObj, int propid, int arridx);
Retail_EXTERN void* InPay_Retail_Get(void* lpObj, int propid, int arridx, int* lpcbVal);
Retail_EXTERN int   InPay_Retail_Set(void* lpObj, int propid, int arridx, void* val, int cbVal);
Retail_EXTERN int   InPay_Retail_Do(void* lpObj, int methid, int cparam, void* param[], int cbparam[]);
Retail_EXTERN char* InPay_Retail_GetLastError(void* lpObj);
Retail_EXTERN int   InPay_Retail_GetLastErrorCode(void* lpObj);

static void Retail_cCallBack(CFSocketRef s, CFSocketCallBackType ct, CFDataRef addr, const void *data, void *info) {
  void* param[1] = {(void*)(long)CFSocketGetNative(s)};
  InPay_Retail_Do(info, 2002/*MID_DOSOCKETEVENTS*/, 1, param, 0);
}

#if !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#endif

static int Retail_cSink(id lpObj, int event_id, int cparam, void* param[], int cbparam[]) {
  
  InPayRetail* ctl = (InPayRetail*)lpObj;
  void **param_orig = param;
  switch (event_id) {
  
    case 2000 /*EID_IDLE*/: {
#if TARGET_OS_IPHONE
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true);
#else
      double timeout = ((double)((long)param[0]) / 1000.0) / 100.0;
      NSEvent *theEvent;          
      while ((theEvent = [NSApp nextEventMatchingMask:NSAnyEventMask
                                            untilDate:[NSDate dateWithTimeIntervalSinceNow:timeout]
                                               inMode:NSDefaultRunLoopMode
                                              dequeue:YES])) {
        [NSApp sendEvent:theEvent];
      }
#endif
      break;
    }

    case 2001 /*EID_ASYNCSELECT*/: {
      CFSocketContext ctx;
      ctx.version = 0;
      ctx.info = (void*)(ctl->m_pObj);
      ctx.retain = NULL;
      ctx.release = NULL;
      ctx.copyDescription = NULL;
      
      CFOptionFlags evtflags = 0;
      if ((int)((unsigned long)param[1]) & 0x01) evtflags |= kCFSocketReadCallBack;
      if ((int)((unsigned long)param[1]) & 0x02) evtflags |= kCFSocketWriteCallBack;
      if ((int)((unsigned long)param[1]) & 0x08) evtflags |= kCFSocketReadCallBack;
      if ((int)((unsigned long)param[1]) & 0x10) evtflags |= kCFSocketConnectCallBack;

      if (!param[2]) {
        void* notifier = (void*)CFSocketCreateWithNative(NULL, (CFSocketNativeHandle)((unsigned long)param[0]), evtflags, Retail_cCallBack, &ctx);
        
        CFArrayAppendValue(ctl->m_rNotifiers, notifier);
        CFRelease((CFSocketRef)notifier);
        param[2] = notifier;
        
        CFSocketSetSocketFlags((CFSocketRef)(notifier), kCFSocketAutomaticallyReenableReadCallBack | kCFSocketAutomaticallyReenableAcceptCallBack);
        
        CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(NULL, (CFSocketRef)(notifier), 0);
        if (rls != nil) {
          CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
          CFRelease(rls);
        }
      } else {
        if (param[2]) CFSocketEnableCallBacks((CFSocketRef)(param[2]), evtflags);
      }
      break;
    }
    
    case 2002 /*EID_DELETENOTIFYOBJECT*/: {
      if (param[0]) {
        CFSocketInvalidate((CFSocketRef)(param[0]));
        while(CFArrayContainsValue(ctl->m_rNotifiers, CFRangeMake(0, CFArrayGetCount(ctl->m_rNotifiers)), param[0]))
          CFArrayRemoveValueAtIndex(ctl->m_rNotifiers, CFArrayGetFirstIndexOfValue(ctl->m_rNotifiers, CFRangeMake(0, CFArrayGetCount(ctl->m_rNotifiers)), param[0]));
      }
      break;
    }

    case 1: {
      int errorCode = (int)(long)(*param++); cbparam++;
      NSString* descriptionT = [NSString stringWithCString:(const char*)(*param++) encoding:[ctl innerGetCodePage]]; cbparam++;
      NSString* description = descriptionT;

      [ctl onError :errorCode :description];



      break;
    }
    case 2: {
      NSData* certEncoded = [NSData dataWithBytesNoCopy:(*param++) length:(*cbparam++) freeWhenDone:NO];
      NSString* certSubjectT = [NSString stringWithCString:(const char*)(*param++) encoding:[ctl innerGetCodePage]]; cbparam++;
      NSString* certSubject = certSubjectT;
      NSString* certIssuerT = [NSString stringWithCString:(const char*)(*param++) encoding:[ctl innerGetCodePage]]; cbparam++;
      NSString* certIssuer = certIssuerT;
      NSString* statusT = [NSString stringWithCString:(const char*)(*param++) encoding:[ctl innerGetCodePage]]; cbparam++;
      NSString* status = statusT;
      int* accept = (int*)(param++); cbparam++;


      [ctl onSSLServerAuthentication :certEncoded :certSubject :certIssuer :status :accept];






      break;
    }
    case 3: {
      NSString* messageT = [NSString stringWithCString:(const char*)(*param++) encoding:[ctl innerGetCodePage]]; cbparam++;
      NSString* message = messageT;

      [ctl onSSLStatus :message];


      break;
    }

  }
  param_orig = NULL;
  return 0;
}

@implementation InPayRetail

+ (InPayRetail*)retail
{
#if __has_feature(objc_arc)
  return [[InPayRetail alloc] init];
#else
  return [[[InPayRetail alloc] init] autorelease];
#endif
}

- (id)init
{
  self = [super init];
  if (!self) return nil;

  m_rNotifiers = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
#if __has_feature(objc_arc)
  m_pObj = InPay_Retail_Create((void*)Retail_cSink, (__bridge void*)self, "\1\1\1MAC\1\1\1");
#else
  m_pObj = InPay_Retail_Create((void*)Retail_cSink, self, "\1\1\1MAC\1\1\1");
#endif
  if (m_pObj) InPay_Retail_Do(m_pObj, 2001/*MID_ENABLEASYNCEVENTS*/, 0, 0, 0);

  return self;
}

- (void)dealloc
{
  if (m_pObj) {
    InPay_Retail_Destroy(m_pObj);
    m_pObj = NULL;
  }
  if (m_rNotifiers) {
    for (int i = 0; i < CFArrayGetCount(m_rNotifiers); i++) {
      const void* notifier = CFArrayGetValueAtIndex(m_rNotifiers, i);
      CFSocketInvalidate((CFSocketRef)notifier);
    }
    CFArrayRemoveAllValues(m_rNotifiers);
    CFRelease(m_rNotifiers);
  }
#if __has_feature(objc_arc)
#else
  [super dealloc];
#endif
}

- (NSString*)lastError
{
    return [NSString stringWithCString:(const char*)InPay_Retail_GetLastError(m_pObj) encoding:[self innerGetCodePage]];
}

- (int)lastErrorCode
{
  return InPay_Retail_GetLastErrorCode(m_pObj);
}

- (id <InPayRetailDelegate>)delegate
{
  return m_delegate;
}

- (void) setDelegate:(id <InPayRetailDelegate>)anObject
{
  m_delegateHasError = NO;
  m_delegateHasSSLServerAuthentication = NO;
  m_delegateHasSSLStatus = NO;

  m_delegate = anObject;
  if (m_delegate != nil)
  {
    if ([m_delegate respondsToSelector:@selector(onError::)])
    {
      m_delegateHasError = YES;
    }
    if ([m_delegate respondsToSelector:@selector(onSSLServerAuthentication:::::)])
    {
      m_delegateHasSSLServerAuthentication = YES;
    }
    if ([m_delegate respondsToSelector:@selector(onSSLStatus:)])
    {
      m_delegateHasSSLStatus = YES;
    }

  }
}

  /* events */

- (void)onError:(int)errorCode :(NSString*)description
{
  if (m_delegate != nil && m_delegateHasError) 
  {
    [m_delegate onError:errorCode :description];
  }
}
- (void)onSSLServerAuthentication:(NSData*)certEncoded :(NSString*)certSubject :(NSString*)certIssuer :(NSString*)status :(int*)accept
{
  if (m_delegate != nil && m_delegateHasSSLServerAuthentication) 
  {
    [m_delegate onSSLServerAuthentication:certEncoded :certSubject :certIssuer :status :accept];
  }
}
- (void)onSSLStatus:(NSString*)message
{
  if (m_delegate != nil && m_delegateHasSSLStatus) 
  {
    [m_delegate onSSLStatus:message];
  }
}

  /* properties */

- (NSString*)authCode
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 1, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setAuthCode:(NSString*)newAuthCode
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newAuthCode];
  int ret_code = InPay_Retail_Set(m_pObj, 1, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)cardCVVData
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 2, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCardCVVData:(NSString*)newCardCVVData
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCardCVVData];
  int ret_code = InPay_Retail_Set(m_pObj, 2, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)cardCVVPresence
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 3, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setCardCVVPresence:(int)newCardCVVPresence
{
  int len = 0;
  void *val = (void*)(long)newCardCVVPresence;
  int ret_code = InPay_Retail_Set(m_pObj, 3, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)cardEntryDataSource
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 4, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setCardEntryDataSource:(int)newCardEntryDataSource
{
  int len = 0;
  void *val = (void*)(long)newCardEntryDataSource;
  int ret_code = InPay_Retail_Set(m_pObj, 4, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)cardExpMonth
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 5, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setCardExpMonth:(int)newCardExpMonth
{
  int len = 0;
  void *val = (void*)(long)newCardExpMonth;
  int ret_code = InPay_Retail_Set(m_pObj, 5, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)cardExpYear
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 6, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setCardExpYear:(int)newCardExpYear
{
  int len = 0;
  void *val = (void*)(long)newCardExpYear;
  int ret_code = InPay_Retail_Set(m_pObj, 6, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)cardMagneticStripe
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 7, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCardMagneticStripe:(NSString*)newCardMagneticStripe
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCardMagneticStripe];
  int ret_code = InPay_Retail_Set(m_pObj, 7, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)cardNumber
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 8, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCardNumber:(NSString*)newCardNumber
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCardNumber];
  int ret_code = InPay_Retail_Set(m_pObj, 8, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerAddress
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 9, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerAddress:(NSString*)newCustomerAddress
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerAddress];
  int ret_code = InPay_Retail_Set(m_pObj, 9, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerAddress2
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 10, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerAddress2:(NSString*)newCustomerAddress2
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerAddress2];
  int ret_code = InPay_Retail_Set(m_pObj, 10, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerAggregate
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 11, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerAggregate:(NSString*)newCustomerAggregate
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerAggregate];
  int ret_code = InPay_Retail_Set(m_pObj, 11, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerCity
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 12, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerCity:(NSString*)newCustomerCity
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerCity];
  int ret_code = InPay_Retail_Set(m_pObj, 12, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerCountry
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 13, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerCountry:(NSString*)newCustomerCountry
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerCountry];
  int ret_code = InPay_Retail_Set(m_pObj, 13, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerEmail
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 14, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerEmail:(NSString*)newCustomerEmail
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerEmail];
  int ret_code = InPay_Retail_Set(m_pObj, 14, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerFax
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 15, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerFax:(NSString*)newCustomerFax
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerFax];
  int ret_code = InPay_Retail_Set(m_pObj, 15, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerFirstName
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 16, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerFirstName:(NSString*)newCustomerFirstName
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerFirstName];
  int ret_code = InPay_Retail_Set(m_pObj, 16, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerFullName
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 17, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerFullName:(NSString*)newCustomerFullName
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerFullName];
  int ret_code = InPay_Retail_Set(m_pObj, 17, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerId
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 18, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerId:(NSString*)newCustomerId
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerId];
  int ret_code = InPay_Retail_Set(m_pObj, 18, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerLastName
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 19, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerLastName:(NSString*)newCustomerLastName
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerLastName];
  int ret_code = InPay_Retail_Set(m_pObj, 19, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerPhone
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 20, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerPhone:(NSString*)newCustomerPhone
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerPhone];
  int ret_code = InPay_Retail_Set(m_pObj, 20, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerState
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 21, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerState:(NSString*)newCustomerState
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerState];
  int ret_code = InPay_Retail_Set(m_pObj, 21, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)customerZip
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 22, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCustomerZip:(NSString*)newCustomerZip
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCustomerZip];
  int ret_code = InPay_Retail_Set(m_pObj, 22, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)gateway
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 23, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setGateway:(int)newGateway
{
  int len = 0;
  void *val = (void*)(long)newGateway;
  int ret_code = InPay_Retail_Set(m_pObj, 23, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)gatewayURL
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 24, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setGatewayURL:(NSString*)newGatewayURL
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newGatewayURL];
  int ret_code = InPay_Retail_Set(m_pObj, 24, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)invoiceNumber
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 25, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setInvoiceNumber:(NSString*)newInvoiceNumber
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newInvoiceNumber];
  int ret_code = InPay_Retail_Set(m_pObj, 25, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)level2Aggregate
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 26, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setLevel2Aggregate:(NSString*)newLevel2Aggregate
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newLevel2Aggregate];
  int ret_code = InPay_Retail_Set(m_pObj, 26, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)level3Aggregate
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 27, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setLevel3Aggregate:(NSString*)newLevel3Aggregate
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newLevel3Aggregate];
  int ret_code = InPay_Retail_Set(m_pObj, 27, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)merchantLogin
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 28, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setMerchantLogin:(NSString*)newMerchantLogin
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newMerchantLogin];
  int ret_code = InPay_Retail_Set(m_pObj, 28, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)merchantPassword
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 29, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setMerchantPassword:(NSString*)newMerchantPassword
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newMerchantPassword];
  int ret_code = InPay_Retail_Set(m_pObj, 29, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)proxyAuthScheme
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 30, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setProxyAuthScheme:(int)newProxyAuthScheme
{
  int len = 0;
  void *val = (void*)(long)newProxyAuthScheme;
  int ret_code = InPay_Retail_Set(m_pObj, 30, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (BOOL)proxyAutoDetect
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 31, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return val ? YES : NO;
}

- (void)setProxyAutoDetect:(BOOL)newProxyAutoDetect
{
  int len = 0;
  void *val = (void*)(long)(newProxyAutoDetect ? 1 : 0);
  int ret_code = InPay_Retail_Set(m_pObj, 31, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)proxyPassword
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 32, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setProxyPassword:(NSString*)newProxyPassword
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newProxyPassword];
  int ret_code = InPay_Retail_Set(m_pObj, 32, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)proxyPort
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 33, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setProxyPort:(int)newProxyPort
{
  int len = 0;
  void *val = (void*)(long)newProxyPort;
  int ret_code = InPay_Retail_Set(m_pObj, 33, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)proxyServer
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 34, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setProxyServer:(NSString*)newProxyServer
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newProxyServer];
  int ret_code = InPay_Retail_Set(m_pObj, 34, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)proxySSL
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 35, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setProxySSL:(int)newProxySSL
{
  int len = 0;
  void *val = (void*)(long)newProxySSL;
  int ret_code = InPay_Retail_Set(m_pObj, 35, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)proxyUser
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 36, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setProxyUser:(NSString*)newProxyUser
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newProxyUser];
  int ret_code = InPay_Retail_Set(m_pObj, 36, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)responseApprovalCode
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 37, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (BOOL)responseApproved
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 38, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return val ? YES : NO;
}



- (NSString*)responseApprovedAmount
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 39, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (NSString*)responseAVSResult
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 40, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (NSString*)responseCode
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 41, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (NSString*)responseCVVResult
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 42, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (NSString*)responseData
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 43, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (NSString*)responseErrorCode
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 44, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (NSString*)responseErrorText
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 45, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (NSString*)responseInvoiceNumber
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 46, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (NSString*)responseProcessorCode
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 47, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (NSString*)responseText
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 48, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (NSString*)responseTransactionId
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 49, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (NSString*)shippingAddress
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 50, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setShippingAddress:(NSString*)newShippingAddress
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newShippingAddress];
  int ret_code = InPay_Retail_Set(m_pObj, 50, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)shippingAddress2
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 51, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setShippingAddress2:(NSString*)newShippingAddress2
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newShippingAddress2];
  int ret_code = InPay_Retail_Set(m_pObj, 51, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)shippingCity
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 52, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setShippingCity:(NSString*)newShippingCity
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newShippingCity];
  int ret_code = InPay_Retail_Set(m_pObj, 52, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)shippingCountry
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 53, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setShippingCountry:(NSString*)newShippingCountry
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newShippingCountry];
  int ret_code = InPay_Retail_Set(m_pObj, 53, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)shippingEmail
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 54, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setShippingEmail:(NSString*)newShippingEmail
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newShippingEmail];
  int ret_code = InPay_Retail_Set(m_pObj, 54, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)shippingFirstName
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 55, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setShippingFirstName:(NSString*)newShippingFirstName
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newShippingFirstName];
  int ret_code = InPay_Retail_Set(m_pObj, 55, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)shippingLastName
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 56, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setShippingLastName:(NSString*)newShippingLastName
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newShippingLastName];
  int ret_code = InPay_Retail_Set(m_pObj, 56, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)shippingPhone
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 57, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setShippingPhone:(NSString*)newShippingPhone
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newShippingPhone];
  int ret_code = InPay_Retail_Set(m_pObj, 57, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)shippingState
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 58, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setShippingState:(NSString*)newShippingState
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newShippingState];
  int ret_code = InPay_Retail_Set(m_pObj, 58, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)shippingZip
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 59, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setShippingZip:(NSString*)newShippingZip
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newShippingZip];
  int ret_code = InPay_Retail_Set(m_pObj, 59, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)specialFieldCount
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 60, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setSpecialFieldCount:(int)newSpecialFieldCount
{
  int len = 0;
  void *val = (void*)(long)newSpecialFieldCount;
  int ret_code = InPay_Retail_Set(m_pObj, 60, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)specialFieldName:(int)fieldIndex 
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 61, fieldIndex, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setSpecialFieldName:(int)fieldIndex :(NSString*)newSpecialFieldName
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newSpecialFieldName];
  int ret_code = InPay_Retail_Set(m_pObj, 61, fieldIndex, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)specialFieldValue:(int)fieldIndex 
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 62, fieldIndex, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setSpecialFieldValue:(int)fieldIndex :(NSString*)newSpecialFieldValue
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newSpecialFieldValue];
  int ret_code = InPay_Retail_Set(m_pObj, 62, fieldIndex, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)SSLAcceptServerCertEncoded
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 63, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
    return [[NSString alloc] initWithBytes:val length:len encoding:[self innerGetCodePage]];
}

- (void)setSSLAcceptServerCertEncoded:(NSString*)newSSLAcceptServerCertEncoded
{
  int len = (int)[newSSLAcceptServerCertEncoded lengthOfBytesUsingEncoding:[self innerGetCodePage]];
  void *val = (void*)[self nsstringToCString:newSSLAcceptServerCertEncoded];
  int ret_code = InPay_Retail_Set(m_pObj, 63, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSData*)SSLAcceptServerCertEncodedB
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 63, 0, &len);
  return [NSData dataWithBytesNoCopy:val length:len freeWhenDone:NO];
}
- (void)setSSLAcceptServerCertEncodedB :(NSData*)newSSLAcceptServerCertEncoded
{
  int len = (int)[newSSLAcceptServerCertEncoded length];
  void *val = (void*)[newSSLAcceptServerCertEncoded bytes];
  int ret_code = InPay_Retail_Set(m_pObj, 63, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}
- (NSString*)SSLCertEncoded
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 64, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
    return [[NSString alloc] initWithBytes:val length:len encoding:[self innerGetCodePage]];
}

- (void)setSSLCertEncoded:(NSString*)newSSLCertEncoded
{
  int len = (int)[newSSLCertEncoded lengthOfBytesUsingEncoding:[self innerGetCodePage]];
  void *val = (void*)[self nsstringToCString:newSSLCertEncoded];
  int ret_code = InPay_Retail_Set(m_pObj, 64, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSData*)SSLCertEncodedB
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 64, 0, &len);
  return [NSData dataWithBytesNoCopy:val length:len freeWhenDone:NO];
}
- (void)setSSLCertEncodedB :(NSData*)newSSLCertEncoded
{
  int len = (int)[newSSLCertEncoded length];
  void *val = (void*)[newSSLCertEncoded bytes];
  int ret_code = InPay_Retail_Set(m_pObj, 64, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}
- (NSString*)SSLCertStore
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 65, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
    return [[NSString alloc] initWithBytes:val length:len encoding:[self innerGetCodePage]];
}

- (void)setSSLCertStore:(NSString*)newSSLCertStore
{
  int len = (int)[newSSLCertStore lengthOfBytesUsingEncoding:[self innerGetCodePage]];
  void *val = (void*)[self nsstringToCString:newSSLCertStore];
  int ret_code = InPay_Retail_Set(m_pObj, 65, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSData*)SSLCertStoreB
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 65, 0, &len);
  return [NSData dataWithBytesNoCopy:val length:len freeWhenDone:NO];
}
- (void)setSSLCertStoreB :(NSData*)newSSLCertStore
{
  int len = (int)[newSSLCertStore length];
  void *val = (void*)[newSSLCertStore bytes];
  int ret_code = InPay_Retail_Set(m_pObj, 65, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}
- (NSString*)SSLCertStorePassword
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 66, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setSSLCertStorePassword:(NSString*)newSSLCertStorePassword
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newSSLCertStorePassword];
  int ret_code = InPay_Retail_Set(m_pObj, 66, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)SSLCertStoreType
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 67, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setSSLCertStoreType:(int)newSSLCertStoreType
{
  int len = 0;
  void *val = (void*)(long)newSSLCertStoreType;
  int ret_code = InPay_Retail_Set(m_pObj, 67, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)SSLCertSubject
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 68, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setSSLCertSubject:(NSString*)newSSLCertSubject
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newSSLCertSubject];
  int ret_code = InPay_Retail_Set(m_pObj, 68, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)SSLServerCertEncoded
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 69, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
    return [[NSString alloc] initWithBytes:val length:len encoding:[self innerGetCodePage]];
}



- (NSData*)SSLServerCertEncodedB
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 69, 0, &len);
  return [NSData dataWithBytesNoCopy:val length:len freeWhenDone:NO];
}

- (BOOL)testMode
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 70, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return val ? YES : NO;
}

- (void)setTestMode:(BOOL)newTestMode
{
  int len = 0;
  void *val = (void*)(long)(newTestMode ? 1 : 0);
  int ret_code = InPay_Retail_Set(m_pObj, 70, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)timeout
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 71, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setTimeout:(int)newTimeout
{
  int len = 0;
  void *val = (void*)(long)newTimeout;
  int ret_code = InPay_Retail_Set(m_pObj, 71, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)transactionAmount
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 72, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setTransactionAmount:(NSString*)newTransactionAmount
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newTransactionAmount];
  int ret_code = InPay_Retail_Set(m_pObj, 72, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)transactionDesc
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 73, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setTransactionDesc:(NSString*)newTransactionDesc
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newTransactionDesc];
  int ret_code = InPay_Retail_Set(m_pObj, 73, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)transactionId
{
  int len = 0;
  void* val = InPay_Retail_Get(m_pObj, 74, 0, &len);
  if (InPay_Retail_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setTransactionId:(NSString*)newTransactionId
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newTransactionId];
  int ret_code = InPay_Retail_Set(m_pObj, 74, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}



  /* methods */

- (void)addSpecialField:(NSString*)name :(NSString*)val
{
  void *param[2+1] = {(void*)[self nsstringToCString:name], (void*)[self nsstringToCString:val], NULL};
  int cbparam[2+1] = {0, 0, 0};
  int ret_code = InPay_Retail_Do(m_pObj, 2, 2, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}
- (void)authOnly
{
  void *param[0+1] = {NULL};
  int cbparam[0+1] = {0};
  int ret_code = InPay_Retail_Do(m_pObj, 3, 0, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}
- (void)AVSOnly
{
  void *param[0+1] = {NULL};
  int cbparam[0+1] = {0};
  int ret_code = InPay_Retail_Do(m_pObj, 4, 0, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}
- (void)capture:(NSString*)transactionId :(NSString*)captureAmount
{
  void *param[2+1] = {(void*)[self nsstringToCString:transactionId], (void*)[self nsstringToCString:captureAmount], NULL};
  int cbparam[2+1] = {0, 0, 0};
  int ret_code = InPay_Retail_Do(m_pObj, 5, 2, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}
- (NSString*)config:(NSString*)configurationString
{
  void *param[1+1] = {(void*)[self nsstringToCString:configurationString], NULL};
  int cbparam[1+1] = {0, 0};
  int ret_code = InPay_Retail_Do(m_pObj, 6, 1, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)param[1] encoding:[self innerGetCodePage]];
}
- (void)credit
{
  void *param[0+1] = {NULL};
  int cbparam[0+1] = {0};
  int ret_code = InPay_Retail_Do(m_pObj, 7, 0, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}
- (void)force:(NSString*)voiceAuthCode
{
  void *param[1+1] = {(void*)[self nsstringToCString:voiceAuthCode], NULL};
  int cbparam[1+1] = {0, 0};
  int ret_code = InPay_Retail_Do(m_pObj, 8, 1, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}
- (NSString*)getResponseVar:(NSString*)name
{
  void *param[1+1] = {(void*)[self nsstringToCString:name], NULL};
  int cbparam[1+1] = {0, 0};
  int ret_code = InPay_Retail_Do(m_pObj, 9, 1, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)param[1] encoding:[self innerGetCodePage]];
}
- (void)interrupt
{
  void *param[0+1] = {NULL};
  int cbparam[0+1] = {0};
  int ret_code = InPay_Retail_Do(m_pObj, 10, 0, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}
- (void)refund:(NSString*)transactionId :(NSString*)refundAmount
{
  void *param[2+1] = {(void*)[self nsstringToCString:transactionId], (void*)[self nsstringToCString:refundAmount], NULL};
  int cbparam[2+1] = {0, 0, 0};
  int ret_code = InPay_Retail_Do(m_pObj, 11, 2, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}
- (void)resetSpecialFields
{
  void *param[0+1] = {NULL};
  int cbparam[0+1] = {0};
  int ret_code = InPay_Retail_Do(m_pObj, 12, 0, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}
- (void)sale
{
  void *param[0+1] = {NULL};
  int cbparam[0+1] = {0};
  int ret_code = InPay_Retail_Do(m_pObj, 13, 0, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}
- (void)voidTransaction:(NSString*)transactionId
{
  void *param[1+1] = {(void*)[self nsstringToCString:transactionId], NULL};
  int cbparam[1+1] = {0, 0};
  int ret_code = InPay_Retail_Do(m_pObj, 14, 1, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}


- (const char*)nsstringToCString:(NSString*)str {
   const char* cstr = [str cStringUsingEncoding:[self innerGetCodePage]];
   if ( cstr == NULL ) [NSException raise:ENCODING_CONVERSION_ERROR format:@"%@", ENCODING_CONVERSION_ERROR];
   return cstr;
}
- (NSStringEncoding)innerGetCodePage {
  int len = 0;
  int codePage = (int)(long)InPay_Retail_Get(m_pObj, 2010, 0, &len);
  if ( codePage == 0 ) return NSASCIIStringEncoding;
  return (NSStringEncoding)codePage;
}
@end