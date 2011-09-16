//
//  EnterLocationViewController.m
//  WikiPhone
//
//  Created by Adam Leonard on 6/24/08.
//  Copyright 2008 Caffeinated Cocoa. All rights reserved.
//

#import "EnterLocationViewController.h"
#import "CCLocation.h"
#import "LocationController.h"

@implementation EnterLocationViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */


- (void)viewDidLoad
{
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}
 

- (IBAction)continue:(id)sender;
{
	CCLocation *newLocation = [[[CCLocation alloc]initWithNaturalLanguageLocation:locationField.text]autorelease];
	
	if(delegate && [delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)])
	{
		[delegate locationManager:nil didUpdateToLocation:newLocation fromLocation:nil];
	}
	
	[self dismissModalViewControllerAnimated:YES];
	
}
- (IBAction)cancel:(id)sender;
{
	//now we are really giving up getting the user's location
	
	[[NSNotificationCenter defaultCenter]postNotificationName:CCLocationUpdateFailedNotificationName object:nil];
	
	[self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc {
	[super dealloc];
}


@end
