//
//  UIAlertController+modified.m
//  OdinScanner
//
//  Created by KenThomsen on 12/10/14.
//
//

#import "UIAlertController+modified.h"

@implementation UIAlertController (modified)

+ (UIAlertController*)noItemConnection
{
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Test" message:@"Hello World" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
													 style:UIAlertActionStyleCancel handler:^(UIAlertAction *action)
							 {
								 NSLog(@"Cancel Action");
							 }];
	
	UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action")
												 style:UIAlertActionStyleCancel handler:^(UIAlertAction *action)
						 {
							 NSLog(@"OK Action");
						 }];
	[alertController addAction:cancel];
	[alertController addAction:ok];
	return alertController;
}


+ (UIAlertController*)noServerConnection
{
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Test" message:@"Hello World" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
													 style:UIAlertActionStyleCancel handler:^(UIAlertAction *action)
							 {
								 NSLog(@"Cancel Action");
							 }];
	
	UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK action")
												 style:UIAlertActionStyleCancel handler:^(UIAlertAction *action)
						 {
							 NSLog(@"OK Action");
						 }];
	[alertController addAction:cancel];
	[alertController addAction:ok];
	return alertController;
}
@end
