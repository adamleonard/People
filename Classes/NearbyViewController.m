//
//  NearbyViewController.m
//  People
//
//  Created by Adam Leonard on 6/30/08.
//
//Copyright (c) 2011, Adam Leonard
//All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//* Redistributions of source code must retain the above copyright
//notice, this list of conditions and the following disclaimer.
//* Redistributions in binary form must reproduce the above copyright
//notice, this list of conditions and the following disclaimer in the
//documentation and/or other materials provided with the distribution.
//* Neither the name of Adam Leonard nor Caffeinated Cocoa nor the
//names of its contributors may be used to endorse or promote products
//derived from this software without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
//DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "NearbyViewController.h"
#import "LocationController.h"
#import "ReverseGeocodingRequestController.h"
#import "SearchResultsViewController.h"
#import "LoadingViewController.h"
#import "WhitePagesRequestController.h"
#import "AddressParser.h"

@interface NearbyViewController (PRIVATE)
- (void)updateLastRefreshDate;
@end

@implementation NearbyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
	{
		self.title = @"Nearby";
		self.tabBarItem = [[[UITabBarItem alloc]initWithTitle:@"Nearby" image:[UIImage imageNamed:@"nearby.png"] tag:1]autorelease];
	}
	return self;
}


- (void)loadView 
{
	UIView *containerView = [[UIView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame];
	[containerView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
	self.view = containerView;
	[containerView release];
}
 

- (void)viewDidLoad 
{
	refreshBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
	self.navigationItem.rightBarButtonItem = refreshBarButtonItem;
	
	loadingViewController = [[LoadingViewController alloc]initWithNibName:@"LoadingViewController" bundle:nil];

	UIView *loadingView = loadingViewController.view;
	loadingView.frame = self.view.bounds;
	[self.view addSubview:loadingView];
	
	resultsViewController.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - [toolbar frame].size.height); //full width, 0 height at bottom of view (invisible)
	[self.view addSubview:resultsViewController.view];
	
	_displayingResultsTable = NO;
	
	lastRefreshDate = [[NSDate distantPast]retain]; //force a refresh when we are first loaded in viewWillAppear
}
- (void)viewWillAppear:(BOOL)animated
{
	//check if we should refresh the nearby list
	
	NSDate *currentDate = [NSDate date];
	if([currentDate timeIntervalSinceDate:lastRefreshDate] > (60 * 5)) //if more than 5 minutes have passed since the last refresh
		[self refresh];
	
	
}
- (void)refresh
{	
	refreshBarButtonItem.enabled = NO; //do not allow another refresh while one is going on
	
	if(_displayingResultsTable)
	{
		//if we are showing the results table, we first need to slide it down to reveal the loadingView underneath
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.5];
		//full width, 0 height at bottom of view (invisible)
		resultsViewController.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - [toolbar frame].size.height); //full width, 0 height at bottom of view (invisible)
		toolbar.alpha = 0.0;
		[UIView commitAnimations];
		
		_displayingResultsTable = NO;
	}
	
	[[NSNotificationCenter defaultCenter]addObserver:self 
											selector:@selector(foundLocation:)
												name:CCLocationChangedNotificationName 
											  object:nil];
	
	[[NSNotificationCenter defaultCenter]addObserver:self 
											selector:@selector(locationUpdateFailed:)
												name:CCLocationUpdateFailedNotificationName 
											  object:nil];
	
	[[LocationController sharedController]startUpdatingLocationWithDesiredAccuracy:kCLLocationAccuracyHundredMeters];
}

- (void)foundLocation:(NSNotification *)sender
{
	CCLocation *location = [sender object];
	
	
	[[NSNotificationCenter defaultCenter]removeObserver:self
												   name:CCLocationChangedNotificationName
												 object:nil];
	[[NSNotificationCenter defaultCenter]removeObserver:self
												   name:CCLocationUpdateFailedNotificationName
												 object:nil];
	
	//now find the nearest city using Geonames
	ReverseGeocodingRequestController *geonamesController= [[[ReverseGeocodingRequestController alloc]initWithLocation:location delegate:self]autorelease];
	[geonamesController findNearestAddress];
	
}
- (void)locationUpdateFailed:(NSNotification *)sender
{
	[self updateLastRefreshDate];

	UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Could not determine your current location"
													   message:@"Please ensure you are connected to a cellular or wifi network and try again."					
													  delegate:self
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil];
	[alertView show];
	
}	
- (void)reverseGeocodingRequestController:(ReverseGeocodingRequestController *)controller retrievedAddress:(NSString *)address addressComponents:(NSDictionary *)addressComponents;
{
	if(!address)
	{
		[self reverseGeocodingRequestController:controller
								failedWithError:[NSError errorWithDomain:@"CCGoogleMapsErrorDomain" 
																	code:-3
																userInfo:[NSDictionary dictionaryWithObject:@"Could not find nearby addresses" forKey:NSLocalizedDescriptionKey]]];
		return;
	}
	
	//the API can take a range of house numbers that allows us to find nearby houses. To do this, we use numbers around the number returned from Geonames. The range cannot be too large, as only 5 results can be returned
	NSInteger houseNumberAsInteger = [[addressComponents objectForKey:@"house"]integerValue];
	NSString *houseRange = nil; 
	NSInteger lowerSearchBound = houseNumberAsInteger - 10;
	if (lowerSearchBound < 0)
		lowerSearchBound = 0;
	NSInteger upperSearchBound = houseNumberAsInteger + 10;
	if(houseNumberAsInteger)
		houseRange = [NSString stringWithFormat:@"[%i-%i]",lowerSearchBound, upperSearchBound];
		
	NSString *street = [addressComponents objectForKey:@"street"];
	if(!street)
	{
		NSLog(@"Geonames did not give us a street. Cannot perform nearby search");
		[self reverseGeocodingRequestController:controller
								failedWithError:[NSError errorWithDomain:@"CCGoogleMapsErrorDomain" 
																	code:-4
																userInfo:[NSDictionary dictionaryWithObject:@"Could not find nearby addresses" forKey:NSLocalizedDescriptionKey]]];
		return;
	}
	
	NSString *city = [addressComponents objectForKey:@"city"];
	NSString *state = [addressComponents objectForKey:@"state"];
	NSString *zip = [addressComponents objectForKey:@"zip"];
	
	if([zip integerValue] == 0) //for some reason, Geonames sometimes returns "00" as the zip code. That is of course not valid and screws up WhitePages.
		zip = nil;
	
	//FIXME: more error checking
	
	[nearbyAddressComponents release];
	nearbyAddressComponents = [addressComponents retain];
	
	WhitePagesRequestController *requestController = [WhitePagesRequestController beginReverseAddressSearchWithHouse:houseRange
																											  street:street
																												city:city
																											   state:state
																												 zip:zip
																							searchDisplayDescription:@""
																											delegate:self];
	requestController.savesSearchesToSearchHistory = NO;
	requestController.viewControllerForPicklist = self;
	
	
}
- (void)reverseGeocodingRequestController:(ReverseGeocodingRequestController *)controller failedWithError:(NSError *)error;
{
	[self updateLastRefreshDate];
	
	NSString *message = nil;
	
	if([[error domain]isEqualToString:NSURLErrorDomain])
		message = [NSString stringWithFormat:@"Please make sure you are online and try again later. The error was: %@",[error localizedDescription]];
	else if([[error domain]isEqualToString:@"CCGoogleMapsErrorDomain"])
		message = [NSString stringWithFormat:@"No nearby addresses could be found. The error was: %@", [error localizedDescription]];
	else
		message = [NSString stringWithFormat:@"The error was: %@",[error localizedDescription]];
	
	UIAlertView *alert = [[[UIAlertView alloc]initWithTitle:@"Could not determine your location."
													message:message
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil]autorelease];
	[alert show];

}
 
- (void)whitePagesRequestController:(WhitePagesRequestController *)controller retrievedResults:(NSArray *)results metadata:(NSDictionary *)metadata;
{		
	//cool. Got the results
	//NSLog(@"NEARBY RESULTS: %@",results);
	
	[toolbar removeFromSuperview];
	[toolbar release];
	
	toolbar = [[UIToolbar alloc]init];
	toolbar.barStyle = UIBarStyleBlack;
	toolbar.translucent = YES;
	[toolbar sizeToFit];
	CGFloat toolbarHeight = [toolbar frame].size.height;
	CGRect toolbarFrame = CGRectMake(self.view.frame.origin.x,self.view.frame.origin.y, self.view.frame.size.width,toolbarHeight);
	[toolbar setFrame:toolbarFrame];
	[toolbar setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
	toolbar.alpha = 0.0;
	[self.view addSubview:toolbar];
	/*
	UILabel *addressLabel = [[[UILabel alloc]initWithFrame:toolbarFrame]autorelease];
	addressLabel.text = [NSString stringWithFormat:@"Near %@ %@",[nearbyAddressComponents objectForKey:@"house"],[nearbyAddressComponents objectForKey:@"street"]];
	addressLabel.textAlignment = UITextAlignmentCenter;
	addressLabel.textColor = [UIColor whiteColor];
	addressLabel.opaque = NO;
	addressLabel.backgroundColor = [UIColor clearColor];
	addressLabel.shadowColor = [UIColor lightGrayColor];
	 */
	NSMutableString *displayAddress = nil;
	
	if(![nearbyAddressComponents objectForKey:@"house"] || ![nearbyAddressComponents objectForKey:@"street"])
		displayAddress = [NSMutableString stringWithString:@"Unknown Address"];
	else
		displayAddress = [NSMutableString stringWithFormat:@"Near %@ %@",[nearbyAddressComponents objectForKey:@"house"],[nearbyAddressComponents objectForKey:@"street"]];
	
	if([displayAddress length] > 22)
	{
		[displayAddress deleteCharactersInRange:NSMakeRange(19, [displayAddress length] - 19)];
		[displayAddress appendString:@"..."];
	}
	
	UIBarButtonItem *addressBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:displayAddress style:UIBarButtonItemStylePlain target:self action:@selector(editAddress:)];
	UIBarButtonItem *spacingBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
	UIBarButtonItem *editBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAddress:)];
	
	[toolbar setItems:[NSArray arrayWithObjects:addressBarButtonItem,spacingBarButtonItem,editBarButtonItem,nil] animated:NO];
	[addressBarButtonItem release];
	

	
	//sort the results by distance from the current locaiton, in assending order
	results = [results sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc]initWithKey:@"geodata" 
																										ascending:YES
																										 selector:@selector(sortLatitudeLongitudeDictionaryByDistanceFromCurrentLocation:)]autorelease]]];
	[resultsViewController.view removeFromSuperview];
	[resultsViewController release];
	
	resultsViewController = [[SearchResultsViewController alloc]initWithSearchResults:results];
	resultsViewController.parentViewController = self;
	resultsViewController.metadata = metadata;
	
	resultsViewController.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - toolbarHeight); //full width, 0 height at bottom of view (invisible)
	[self.view addSubview:resultsViewController.view];
	
	
	//now we animate it from the bottom to the top, covering the loading view
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	resultsViewController.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + toolbarHeight, self.view.frame.size.width,  self.view.frame.size.height - toolbarHeight);
	toolbar.alpha = 1.0; //fade in address field
	[UIView commitAnimations];
	
	_displayingResultsTable = YES;
	
	[self updateLastRefreshDate];
}
- (void)whitePagesRequestController:(WhitePagesRequestController *)controller failedWithError:(NSError *)error;
{
	[self updateLastRefreshDate];
	
	NSString *message = nil;
	
	if([[error domain]isEqualToString:NSURLErrorDomain])
		message = [NSString stringWithFormat:@"Please make sure you are online and try again later. The error was: %@",[error localizedDescription]];
	else if([[error domain]isEqualToString:@"CCWhitePagesErrorDomain"])
		message = [NSString stringWithFormat:@"No nearby addresses could be found. The error was: %@", [error localizedDescription]];
	else
		message = [NSString stringWithFormat:@"The error was: %@",[error localizedDescription]];
	
	UIAlertView *alert = [[[UIAlertView alloc]initWithTitle:@"Could not find nearby addresses."
													   message:message
													  delegate:self
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil]autorelease];
	[alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	//we could not retrieve any nearby records, so we displayed an error
	//Now that it will dismiss, hide the loading view by showing the table with "No Results"
	[self whitePagesRequestController:nil retrievedResults:[NSArray array]metadata:[NSDictionary dictionary]];
}
- (void)updateLastRefreshDate;
{
	NSDate *currentDate = [[NSDate date] retain];
	[lastRefreshDate release];
	lastRefreshDate = currentDate;
	
	refreshBarButtonItem.enabled = YES;
}

- (void)editAddress:(id)sender
{
	AddressSelectorViewController *addressSelector = [[[AddressSelectorViewController alloc]initWithStyle:UITableViewStyleGrouped]autorelease];
	addressSelector.delegate = self;
	
	NSString *house = [nearbyAddressComponents objectForKey:@"house"];
	if(!house)
		house = @"";
	NSString *street = [nearbyAddressComponents objectForKey:@"street"];
	if(!street)
		street = @"";
	NSString *city = [nearbyAddressComponents objectForKey:@"city"];
	if(!city)
		city = @"";
	NSString *state = [nearbyAddressComponents objectForKey:@"state"];
	if(!state)
		state = @"";
	NSString *zip = [nearbyAddressComponents objectForKey:@"zip"];
	if(!zip)
		zip = @"";
	
	addressSelector.streetAddress = [NSString stringWithFormat:@"%@ %@",house,street];
	addressSelector.location = [NSString stringWithFormat:@"%@, %@ %@",city,state,zip];

	UINavigationController *addressSelectorNavigationController = [[[UINavigationController alloc]initWithRootViewController:addressSelector]autorelease];
	[self presentModalViewController:addressSelectorNavigationController animated:YES];
}
	


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)addressSelectorDidEnd:(AddressSelectorViewController *)addressSelector;
{	
	NSDictionary *houseAddressComponents = [[AddressParser sharedParser]parseStreetAddress:addressSelector.streetAddress];
	NSDictionary *cityStateAndZipComponents = [[AddressParser sharedParser]parseCombinedCityStateAndZipString:addressSelector.location];
	
	if((![houseAddressComponents objectForKey:@"street"] || [[houseAddressComponents objectForKey:@"street"] isEqualToString:@""]) ||
	   (![cityStateAndZipComponents objectForKey:@"state"] && ![cityStateAndZipComponents objectForKey:@"zip"]))
	{
		//the API requires a street and either a state or a zip.
		UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Not enough information"
														   message:@"To find nearby people, you must provide a street name and either a state or a zip code."
														  delegate:nil
												 cancelButtonTitle:@"OK"
												 otherButtonTitles:nil];
		[alertView show];
		
		return;
		
	}
	
	NSString *house = [houseAddressComponents objectForKey:@"house"];
	NSString *street = [houseAddressComponents objectForKey:@"street"];
	NSString *city = [cityStateAndZipComponents objectForKey:@"city"];
	NSString *state = [cityStateAndZipComponents objectForKey:@"state"];
	NSString *zip = [cityStateAndZipComponents objectForKey:@"zip"];
	
	if([house isEqualToString:[nearbyAddressComponents objectForKey:@"house"]] && [street isEqualToString:[nearbyAddressComponents objectForKey:@"street"]])
	{
		[self dismissModalViewControllerAnimated:YES];
		return; //if the user didn't change the address, don't do a new search
	}
	
	//otherwise, the user doesn't need to change any of the fields so we can hide the selector
	if(_displayingResultsTable)
	{
		//if we are showing the results table, we first need to slide it down to reveal the loadingView underneath
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.5];
		//full width, 0 height at bottom of view (invisible)
		resultsViewController.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - [toolbar frame].size.height); //full width, 0 height at bottom of view (invisible)
		toolbar.alpha = 0.0;
		[UIView commitAnimations];
		
		_displayingResultsTable = NO;
	}	
	[self dismissModalViewControllerAnimated:YES];

	NSInteger houseNumberAsInteger = [house integerValue];
	NSString *houseRange = nil; 
	NSInteger lowerSearchBound = houseNumberAsInteger - 10;
	if (lowerSearchBound < 0)
		lowerSearchBound = 0;
	NSInteger upperSearchBound = houseNumberAsInteger + 10;
	if(houseNumberAsInteger)
		houseRange = [NSString stringWithFormat:@"[%i-%i]",lowerSearchBound, upperSearchBound];
	
	[nearbyAddressComponents release];
	nearbyAddressComponents = [[NSDictionary alloc]initWithObjectsAndKeys:house,@"house",street,@"street",city,@"city",state,@"state",zip,@"zip",nil];
	
	WhitePagesRequestController *requestController = [WhitePagesRequestController beginReverseAddressSearchWithHouse:houseRange
																											  street:street
																												city:city
																											   state:state
																												 zip:zip
																							searchDisplayDescription:@""
																											delegate:self];
	requestController.savesSearchesToSearchHistory = NO;
	requestController.viewControllerForPicklist = self;
	

}
- (void)addressSelectorDidCancel:(AddressSelectorViewController *)addressSelector;
{
	[self dismissModalViewControllerAnimated:YES];
}


- (void)dealloc 
{
	[nearbyAddressComponents release];
	[refreshBarButtonItem release];
	[lastRefreshDate release];
	[loadingViewController release];
	[super dealloc];
}


@end
