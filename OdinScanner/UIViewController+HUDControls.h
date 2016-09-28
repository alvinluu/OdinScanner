//
//  UIViewController+HUDControls.h
//  OdinScanner
//
//  Created by Ben McCloskey on 10/31/12.
//
//

#import <UIKit/UIKit.h>
//#import "MBProgressHUD.h"
#import "HUDsingleton.h"

@interface UIViewController (HUDControls)
<MBProgressHUDDelegate>

//-(void) updateActivity:(NSNotification *)updateNote;
-(void) showCacheActivity;
-(void) hideActivity;
-(void) initializeAuth;
-(void) switchedToOfflineMode;
-(void) failedSwitchToOnlineMode;
//-(void) showAlertViewToEnterUID;

@end
