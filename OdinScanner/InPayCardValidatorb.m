
/******************************************************************
   E-Payment Integrator V6 for Mac OS X and iOS
   Copyright (c) 2015 /n software inc. - All rights reserved.
*******************************************************************/

#import "InPayCardValidator.h"
#ifndef __has_feature
#define __has_feature(x) 0
#endif

#define ENCODING_CONVERSION_ERROR @"Cannot convert string using specified encoding."

@interface InPayCardValidator()
- (NSStringEncoding)innerGetCodePage;
- (const char*)nsstringToCString:(NSString*)str;
@end

#if __cplusplus
#define CardValidator_EXTERN extern "C"
#else
#define CardValidator_EXTERN extern
#endif

CardValidator_EXTERN void* InPay_CardValidator_Create(void* lpSink, void* lpContext, char* lpOemKey);
CardValidator_EXTERN int   InPay_CardValidator_Destroy(void* lpObj);
CardValidator_EXTERN int   InPay_CardValidator_CheckIndex(void* lpObj, int propid, int arridx);
CardValidator_EXTERN void* InPay_CardValidator_Get(void* lpObj, int propid, int arridx, int* lpcbVal);
CardValidator_EXTERN int   InPay_CardValidator_Set(void* lpObj, int propid, int arridx, void* val, int cbVal);
CardValidator_EXTERN int   InPay_CardValidator_Do(void* lpObj, int methid, int cparam, void* param[], int cbparam[]);
CardValidator_EXTERN char* InPay_CardValidator_GetLastError(void* lpObj);
CardValidator_EXTERN int   InPay_CardValidator_GetLastErrorCode(void* lpObj);

static void CardValidator_cCallBack(CFSocketRef s, CFSocketCallBackType ct, CFDataRef addr, const void *data, void *info) {
  void* param[1] = {(void*)(long)CFSocketGetNative(s)};
  InPay_CardValidator_Do(info, 2002/*MID_DOSOCKETEVENTS*/, 1, param, 0);
}

#if !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#endif

static int CardValidator_cSink(id lpObj, int event_id, int cparam, void* param[], int cbparam[]) {
  
  InPayCardValidator* ctl = (InPayCardValidator*)lpObj;
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
        void* notifier = (void*)CFSocketCreateWithNative(NULL, (CFSocketNativeHandle)((unsigned long)param[0]), evtflags, CardValidator_cCallBack, &ctx);
        
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

  }
  param_orig = NULL;
  return 0;
}

@implementation InPayCardValidator

+ (InPayCardValidator*)cardvalidator
{
#if __has_feature(objc_arc)
  return [[InPayCardValidator alloc] init];
#else
  return [[[InPayCardValidator alloc] init] autorelease];
#endif
}

- (id)init
{
  self = [super init];
  if (!self) return nil;

  m_rNotifiers = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
#if __has_feature(objc_arc)
  m_pObj = InPay_CardValidator_Create((void*)CardValidator_cSink, (__bridge void*)self, "\1\1\1MAC\1\1\1");
#else
  m_pObj = InPay_CardValidator_Create((void*)CardValidator_cSink, self, "\1\1\1MAC\1\1\1");
#endif
  if (m_pObj) InPay_CardValidator_Do(m_pObj, 2001/*MID_ENABLEASYNCEVENTS*/, 0, 0, 0);

  return self;
}

- (void)dealloc
{
  if (m_pObj) {
    InPay_CardValidator_Destroy(m_pObj);
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
    return [NSString stringWithCString:(const char*)InPay_CardValidator_GetLastError(m_pObj) encoding:[self innerGetCodePage]];
}

- (int)lastErrorCode
{
  return InPay_CardValidator_GetLastErrorCode(m_pObj);
}

- (id <InPayCardValidatorDelegate>)delegate
{
  return m_delegate;
}

- (void) setDelegate:(id <InPayCardValidatorDelegate>)anObject
{
  m_delegateHasError = NO;

  m_delegate = anObject;
  if (m_delegate != nil)
  {
    if ([m_delegate respondsToSelector:@selector(onError::)])
    {
      m_delegateHasError = YES;
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

  /* properties */

- (int)cardExpMonth
{
  int len = 0;
  void* val = InPay_CardValidator_Get(m_pObj, 1, 0, &len);
  if (InPay_CardValidator_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setCardExpMonth:(int)newCardExpMonth
{
  int len = 0;
  void *val = (void*)(long)newCardExpMonth;
  int ret_code = InPay_CardValidator_Set(m_pObj, 1, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)cardExpYear
{
  int len = 0;
  void* val = InPay_CardValidator_Get(m_pObj, 2, 0, &len);
  if (InPay_CardValidator_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}

- (void)setCardExpYear:(int)newCardExpYear
{
  int len = 0;
  void *val = (void*)(long)newCardExpYear;
  int ret_code = InPay_CardValidator_Set(m_pObj, 2, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (NSString*)cardNumber
{
  int len = 0;
  void* val = InPay_CardValidator_Get(m_pObj, 3, 0, &len);
  if (InPay_CardValidator_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setCardNumber:(NSString*)newCardNumber
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newCardNumber];
  int ret_code = InPay_CardValidator_Set(m_pObj, 3, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)cardType
{
  int len = 0;
  void* val = InPay_CardValidator_Get(m_pObj, 4, 0, &len);
  if (InPay_CardValidator_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}



- (NSString*)cardTypeDescription
{
  int len = 0;
  void* val = InPay_CardValidator_Get(m_pObj, 5, 0, &len);
  if (InPay_CardValidator_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}



- (BOOL)dateCheckPassed
{
  int len = 0;
  void* val = InPay_CardValidator_Get(m_pObj, 6, 0, &len);
  if (InPay_CardValidator_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return val ? YES : NO;
}



- (BOOL)digitCheckPassed
{
  int len = 0;
  void* val = InPay_CardValidator_Get(m_pObj, 7, 0, &len);
  if (InPay_CardValidator_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return val ? YES : NO;
}



- (NSString*)trackData
{
  int len = 0;
  void* val = InPay_CardValidator_Get(m_pObj, 8, 0, &len);
  if (InPay_CardValidator_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)val encoding:[self innerGetCodePage]];
}

- (void)setTrackData:(NSString*)newTrackData
{
  int len = 0;
  void *val = (void*)[self nsstringToCString:newTrackData];
  int ret_code = InPay_CardValidator_Set(m_pObj, 8, 0, val, len);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
}


- (int)trackType
{
  int len = 0;
  void* val = InPay_CardValidator_Get(m_pObj, 9, 0, &len);
  if (InPay_CardValidator_GetLastErrorCode(m_pObj)) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return (int)(long)val;
}




  /* methods */

- (NSString*)config:(NSString*)configurationString
{
  void *param[1+1] = {(void*)[self nsstringToCString:configurationString], NULL};
  int cbparam[1+1] = {0, 0};
  int ret_code = InPay_CardValidator_Do(m_pObj, 2, 1, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];
  return [NSString stringWithCString:(const char*)param[1] encoding:[self innerGetCodePage]];
}
- (void)reset
{
  void *param[0+1] = {NULL};
  int cbparam[0+1] = {0};
  int ret_code = InPay_CardValidator_Do(m_pObj, 3, 0, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}
- (void)validateCard
{
  void *param[0+1] = {NULL};
  int cbparam[0+1] = {0};
  int ret_code = InPay_CardValidator_Do(m_pObj, 4, 0, param, cbparam);
  if (ret_code) [NSException raise:[self lastError] format:@"%@", [self lastError]];

}


- (const char*)nsstringToCString:(NSString*)str {
   const char* cstr = [str cStringUsingEncoding:[self innerGetCodePage]];
   if ( cstr == NULL ) [NSException raise:ENCODING_CONVERSION_ERROR format:@"%@", ENCODING_CONVERSION_ERROR];
   return cstr;
}
- (NSStringEncoding)innerGetCodePage {
  int len = 0;
  int codePage = (int)(long)InPay_CardValidator_Get(m_pObj, 2010, 0, &len);
  if ( codePage == 0 ) return NSASCIIStringEncoding;
  return (NSStringEncoding)codePage;
}
@end