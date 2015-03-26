//
//  ALAlertView.m
//  ALAlert
//
//  Created by Alvin on 2/27/15.
//  Copyright (c) 2015 Alvin. All rights reserved.
//

#import "ALAlertView.h"


@interface ALAlertView ()
@end


@implementation ALAlertView

@synthesize headerLabel, bodyLabel;
@synthesize headerView, bodyView, footerView;
@synthesize popView;
@synthesize btnTwo, btnThree, btnOne;

-(id)init
{
	NSLog(@"test");
    self = [super initWithNibName:@"ALAlertView" bundle:nil];
    
    if (self) {
        //do something
	}
    return self;
}
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        //do something
    }
    return self;
}
-(void)showInView:(UIView *)sourceView title:(NSString *)title message:(NSString *)message
{
    [self showInView:sourceView title:title message:message buttons:nil];
}

-(void)showInView:(UIView *)sourceView title:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttonNames
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [sourceView addSubview:self.view];
        self.view.frame = sourceView.frame;
        headerLabel.text = title;
        bodyLabel.text = message;
        
        if (buttonNames && buttonNames.count > 0) {
            switch (buttonNames.count) {
                case 3:
                    [btnOne setTitle:buttonNames[0] forState:UIControlStateNormal];
                    [btnTwo setTitle:buttonNames[1] forState:UIControlStateNormal];
                    [btnThree setTitle:buttonNames[2] forState:UIControlStateNormal];
                    [btnOne setHidden:false];
                    [btnTwo setHidden:false];
                    [btnThree setHidden:false];
                    [self shrinkButtons];
                    break;
                case 2:
                    [btnOne setTitle:buttonNames[0] forState:UIControlStateNormal];
                    [btnThree setTitle:buttonNames[1] forState:UIControlStateNormal];
                    [btnOne setHidden:false];
                    [btnThree setHidden:false];
                    break;
                case 1:
                    [btnTwo setTitle:buttonNames[0] forState:UIControlStateNormal];
                    [btnTwo setHidden:false];
                    break;
                default:
                    [btnTwo setTitle:@"OK" forState:UIControlStateNormal];
                    [btnTwo setHidden:false];
                    break;
            }
        } else {
            [btnTwo setTitle:@"OK" forState:UIControlStateNormal];
            [btnTwo setHidden:false];
        }
        
        
        
        
        [self showSelfAnimate];

    });
}

- (IBAction)buttonAction:(id)sender {
    

    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton* btn = (UIButton*)sender;
        [UIView animateWithDuration:.25 animations:^{
            btn.alpha = 0;
        } completion:^(BOOL finished) {
            btn.alpha = 1;
            id<ALAlertDelegate> strongDelegate = self.delegate;
            [strongDelegate buttonClicked:sender title:headerLabel.text];
            [self removeSelfAnimate];
        }];
    }
}
- (void) showSelfAnimate {
    self.view.transform = CGAffineTransformMakeScale(1.3, 1.3);
    self.view.alpha = 0;
    
    
    [UIView animateWithDuration:.25 animations:^{
        self.view.alpha = 1;
        self.view.transform = CGAffineTransformMakeScale(1, 1);
    }];
}
- (void) removeSelfAnimate
{
    [UIView animateWithDuration:.25 animations:^{
        self.view.transform = CGAffineTransformMakeScale(1.3, 1.3);
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        if (finished) {
            self.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
            [self hideAllButtons];
            [self resetButtons];
            [self.view removeFromSuperview];
        }
    }];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    popView.layer.cornerRadius = 20;
    popView.layer.borderWidth = 4;
    popView.layer.shadowOpacity = 0.8;
    popView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    popView.layer.borderColor = [UIColor grayColor].CGColor;
    
    
    [self hideAllButtons];
    
    //make round buttons
    btnOne.layer.cornerRadius = 20;
    btnThree.layer.cornerRadius = 20;
    btnTwo.layer.cornerRadius = 20;
    
    //shrink font to fit button width
    btnOne.titleLabel.adjustsFontSizeToFitWidth = true;
    btnTwo.titleLabel.adjustsFontSizeToFitWidth = true;
    btnThree.titleLabel.adjustsFontSizeToFitWidth = true;
    
    //prevent label touching button edge
    btnOne.titleEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
    btnTwo.titleEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
    btnThree.titleEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4);
    
    
    // Do any additional setup after loading the view from its nib.
}
- (void)shrinkButtons {
    
    btnOne.transform = CGAffineTransformMakeScale(0.8, 0.8);
    btnTwo.transform = CGAffineTransformMakeScale(0.8, 0.8);
    btnThree.transform = CGAffineTransformMakeScale(0.8, 0.8);
}
- (void)resetButtons {
    
    btnOne.transform = CGAffineTransformMakeScale(1.0, 1.0);
    btnTwo.transform = CGAffineTransformMakeScale(1.0, 1.0);
    btnThree.transform = CGAffineTransformMakeScale(1.0, 1.0);
}
- (void)hideAllButtons {
    
    //hide all buttons
    [btnOne setHidden:true];
    [btnTwo setHidden:true];
    [btnThree setHidden:true];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
