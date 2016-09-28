//
//  HUDsingleton.h
//  OdinScanner
//
//  Created by Ben McCloskey on 10/31/12.
//
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

@interface HUDsingleton : MBProgressHUD

//@property (nonatomic, strong) HUDsingleton *HUD;

+(HUDsingleton *)sharedHUD;
//-(MBProgressHUD *)HUD;

@end
