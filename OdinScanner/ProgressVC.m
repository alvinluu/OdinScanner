#import "ProgressVC.h"

@implementation ProgressVC

- (void)viewWillAppear:(BOOL)animated
{
    [infoText setText:@"Operation in progress, please wait..."];
    //[phaseLabel setHidden:TRUE];
    //[progressProgress setHidden:TRUE];
	[activityIndicator startAnimating];
#ifdef DEBUG
	NSLog(@"show progress view");
#endif
}
- (void)viewWillDisappear: (BOOL)animated
{
	[activityIndicator stopAnimating];
}

- (void)updateText:(NSString *)text
{
#ifdef DEBUG
	NSLog(@"update text %@",text);
#endif
	infoText.text = text;
    //[infoText setText:text];
}

- (void)updateProgress:(NSString *)phase progress:(int)progress
{
#ifdef DEBUG
	NSLog(@"update progress");
#endif
    [phaseLabel setText:phase];
    [progressProgress setProgress:(float)progress/100];
    
    [phaseLabel setHidden:FALSE];
    [progressProgress setHidden:FALSE];
}

@end
