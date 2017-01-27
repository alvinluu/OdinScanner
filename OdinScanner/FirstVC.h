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
#import "Patron.h"

@interface FirstVC : OdinViewController
<UITextFieldDelegate, 
UIScrollViewDelegate, 
UIPickerViewDelegate,
UIPickerViewDataSource,
NSXMLParserDelegate,
MBProgressHUDDelegate,
PatronDelegate

> {
    
}


@end
