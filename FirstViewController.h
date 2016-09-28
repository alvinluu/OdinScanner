//
//  FirstViewController.h
//  Scanner
//
//  Created by Ben McCloskey on 12/2/11.
//  Copyright (c) 2011 Odin Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "OdinViewController.h"
#import "Linea.h"
#import "CardProcessor.h"
#import "ReceiptVC.h"

@interface FirstViewController : OdinViewController
<UITextFieldDelegate, 
UIScrollViewDelegate, 
UIPickerViewDelegate,
UIPickerViewDataSource,
NSXMLParserDelegate,
MBProgressHUDDelegate,
DTDeviceDelegate> {
	
}


@end
