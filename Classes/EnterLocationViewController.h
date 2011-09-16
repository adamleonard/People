//
//  EnterLocationViewController.h
//  WikiPhone
//
//  Created by Adam Leonard on 6/24/08.
//  Copyright 2008 Caffeinated Cocoa. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface EnterLocationViewController : UIViewController
{
	id <CLLocationManagerDelegate> delegate;
	
	IBOutlet UITextField *locationField;

}

- (IBAction)continue:(id)sender;
- (IBAction)cancel:(id)sender;

@property(nonatomic, assign) id<CLLocationManagerDelegate> delegate;

@end
