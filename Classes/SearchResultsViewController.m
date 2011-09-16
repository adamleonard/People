//
//  SearchResultsViewController.m
//  People
//
//  Created by Adam Leonard on 5/25/09.
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

#import "SearchResultsViewController.h"
#import "SearchResultsListViewController.h"
#import "MapViewController.h"
#import "WhitePagesLogoImageView.h"
#import "CCHidingBarUnknownPersonViewController.h"

@implementation SearchResultsViewController

@synthesize searchResults;
@synthesize metadata;
@synthesize parentViewController;

- (id)initWithSearchResults:(NSArray *)theSearchResults;
{
	self = [super init];
	if (self != nil) 
	{
		self.searchResults = theSearchResults;
		((CCApplication *)[UIApplication sharedApplication]).contactLinksDelegate = self;
	}
	return self;
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
	UIView *containerView = [[UIView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame];
	[containerView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
	self.view = containerView;
	[containerView release];
	
	UISegmentedControl *mapOrListSelector = [[UISegmentedControl alloc]initWithItems:[NSArray arrayWithObjects:@"List",@"Map",nil]];
	mapOrListSelector.segmentedControlStyle = UISegmentedControlStyleBar;
	mapOrListSelector.selectedSegmentIndex = 0; //List view is the default
	[mapOrListSelector addTarget:self action:@selector(changeResultsView:) forControlEvents:UIControlEventValueChanged];
	mapOrListSelector.bounds = CGRectMake(mapOrListSelector.bounds.origin.x, mapOrListSelector.bounds.origin.y, containerView.bounds.size.width - 25.0, mapOrListSelector.bounds.size.height);
	
	toolbar = [[UIToolbar alloc]init];
	toolbar.barStyle = UIBarStyleDefault;
	[toolbar sizeToFit];
	CGFloat toolbarHeight = [toolbar frame].size.height;
	CGRect toolbarFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.size.height - toolbarHeight, self.view.frame.size.width,toolbarHeight);
	[toolbar setFrame:toolbarFrame];
	[toolbar setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
	
	[self.view addSubview:toolbar];
	UIBarButtonItem *mapOrListSelectorBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:mapOrListSelector];
	[toolbar setItems:[NSArray arrayWithObject:mapOrListSelectorBarButtonItem] animated:NO];
	[mapOrListSelectorBarButtonItem release];
	[toolbar release];
	
	currentResultsView = CCSearchResultsViewTypeNone;
	[self switchToResultsView:CCSearchResultsViewTypeList];
}

- (void)switchToResultsView:(CCSearchResultsViewType)viewType;
{
	if(currentResultsView == viewType)
		return;
	
	CGRect resultsViewFrame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height - [toolbar frame].size.height);
	
	if(viewType == CCSearchResultsViewTypeList)
	{
		if (!listViewController)
		{
			listViewController = [[SearchResultsListViewController alloc]initWithSearchResults:self.searchResults];
			listViewController.metadata = self.metadata;
			listViewController.view.frame = resultsViewFrame;
			listViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
			listViewController.resultsController = self;
		}
		
		if(currentResultsView == CCSearchResultsViewTypeMap)
			[mapViewController.view removeFromSuperview];
		
		[self.view insertSubview:listViewController.view belowSubview:toolbar];
		[listViewController.tableView reloadData];
	}
	
	else if(viewType == CCSearchResultsViewTypeMap)
	{
		if (!mapViewController)
		{
			mapViewController = [[MapViewController alloc]initWithSearchResults:self.searchResults resultsController:self];
			mapViewController.view.frame = resultsViewFrame;
			mapViewController.view.autoresizingMask =  UIViewAutoresizingFlexibleHeight;
			mapViewController.showsMoreInfoButton = YES;
			mapViewController.showsOpenInMapsButton = NO;
		}
		
		if(currentResultsView == CCSearchResultsViewTypeList)
			[listViewController.view removeFromSuperview];
		
		[self.view insertSubview:mapViewController.view belowSubview:toolbar];
	}
}

- (void)changeResultsView:(id)sender
{
	if ([(UISegmentedControl *)sender selectedSegmentIndex] == 0)
		[self switchToResultsView:CCSearchResultsViewTypeList];
	else if ([(UISegmentedControl *)sender selectedSegmentIndex] == 1)
		[self switchToResultsView:CCSearchResultsViewTypeMap];
}

- (void)displayResult:(NSDictionary *)selectedResult withAnimation:(BOOL)animate
{	
	
	_displayedResult = [selectedResult retain];
	
	//construct an ABPerson that will be displayed in an ABPersonViewController
	_displayedPerson = [self ABRecordFromWhitePagesSearchResult:_displayedResult];
	
	//yay. Now show the record using a ABPersonViewController
	CCHidingBarUnknownPersonViewController *personViewController = [[CCHidingBarUnknownPersonViewController alloc]init];
	personViewController.displayedPerson = _displayedPerson;
	personViewController.allowsActions = YES;
	personViewController.allowsAddingToAddressBook = YES;
	
	
	if(parentViewController)
	{
		personViewController.hidesNavigationBarWhenHidden = self.parentViewController.navigationController.navigationBarHidden;
		personViewController.parentNavigationController = self.parentViewController.navigationController;
		[self.parentViewController.navigationController pushViewController:personViewController animated:animate];
		[self.parentViewController.navigationController setNavigationBarHidden:NO animated:YES];
	}
	else
	{
		personViewController.hidesNavigationBarWhenHidden = self.navigationController.navigationBarHidden;
		personViewController.parentNavigationController = self.navigationController;
		[self.navigationController pushViewController:personViewController animated:animate];
		[self.navigationController setNavigationBarHidden:NO animated:YES];
	}
	
	//we need to add the WhitePages logo to the bottom of the view, but since we just created it, the height is not finalized
	//wait until the next run loop when all the person data is loaded and displayed to add the logo
	[self performSelector:@selector(addWhitePagesLogoToUnknownPersonViewController:) withObject:personViewController afterDelay:0.0];
	
	[_displayedResult release];	
}

- (ABRecordRef)ABRecordFromWhitePagesSearchResult:(NSDictionary *)result;
{
	ABRecordRef person = ABPersonCreate();
	
	//name properties
	NSDictionary *personName = [[result objectForKey:@"people"]objectAtIndex:0];
	if([personName objectForKey:@"firstname"])
		ABRecordSetValue(person, kABPersonFirstNameProperty, (CFStringRef)[personName objectForKey:@"firstname"], NULL);
	if([personName objectForKey:@"middlename"])
		ABRecordSetValue(person, kABPersonMiddleNameProperty, (CFStringRef)[personName objectForKey:@"middlename"], NULL);
	if([personName objectForKey:@"lastname"])
		ABRecordSetValue(person, kABPersonLastNameProperty, (CFStringRef)[personName objectForKey:@"lastname"], NULL);

	
	//address properties
	NSDictionary *address = [result objectForKey:@"address"];
	if(address)
	{
		ABMutableMultiValueRef addressesMultiValue = ABMultiValueCreateMutable(kABDictionaryPropertyType); //since there can be multiple addresses, this is basically an array of dictionaries
		NSMutableDictionary *addressDictionaryForAB = [NSMutableDictionary dictionaryWithCapacity:5];
		
		if([address objectForKey:@"fullstreet"])
			[addressDictionaryForAB setObject:[address objectForKey:@"fullstreet"] forKey:(NSString *)kABPersonAddressStreetKey];
		if([address objectForKey:@"city"])
			[addressDictionaryForAB setObject:[address objectForKey:@"city"] forKey:(NSString *)kABPersonAddressCityKey];
		if([address objectForKey:@"state"])
			[addressDictionaryForAB setObject:[address objectForKey:@"state"] forKey:(NSString *)kABPersonAddressStateKey];
		if([address objectForKey:@"zip"])
			[addressDictionaryForAB setObject:[address objectForKey:@"zip"] forKey:(NSString *)kABPersonAddressZIPKey];
		
		ABMultiValueAddValueAndLabel(addressesMultiValue, (CFDictionaryRef)addressDictionaryForAB, (CFStringRef) @"Address", NULL); //add our single address to the array of addresses
		
		ABRecordSetValue(person, kABPersonAddressProperty, addressesMultiValue, NULL);
	}
	
	
	//phone properties
	NSArray *phoneNumbers = [result objectForKey:@"phonenumbers"];
	ABMutableMultiValueRef phoneMultiValue = ABMultiValueCreateMutable(kABStringPropertyType);
	for(NSDictionary *aPhone in phoneNumbers)
	{
		if([aPhone objectForKey:@"fullphone"])
		{
			//get the type of phone number (home, mobile, etc)
			CFStringRef phoneNumberType = kABPersonPhoneMainLabel;
			if([[aPhone objectForKey:@"type"]isEqualToString:@"work"])
				phoneNumberType = kABWorkLabel;
			else if([[aPhone objectForKey:@"type"]isEqualToString:@"home"])
				phoneNumberType = kABHomeLabel;
			else if([[aPhone objectForKey:@"type"]isEqualToString:@"mobile"])
				phoneNumberType = kABPersonPhoneMobileLabel;
			
			ABMultiValueAddValueAndLabel(phoneMultiValue, (CFStringRef)[aPhone objectForKey:@"fullphone"], phoneNumberType, NULL);
		}
		
	}
	ABRecordSetValue(person, kABPersonPhoneProperty, phoneMultiValue, NULL);
	
	
	//More info link
	NSString *moreInfoURLAsString = [[[[result objectForKey:@"listingmeta"]objectForKey:@"moreinfolinks"]objectForKey:@"viewdetails"]objectForKey:@"url"];
	if(moreInfoURLAsString)
	{
		ABMutableMultiValueRef URLMultiValue = ABMultiValueCreateMutable(kABStringPropertyType);
		ABMultiValueAddValueAndLabel(URLMultiValue, moreInfoURLAsString, (CFStringRef)@"More Info", NULL);
		ABRecordSetValue(person, kABPersonURLProperty, (CFStringRef)URLMultiValue, NULL);
	}
	
	return person;
}	
- (void)addWhitePagesLogoToUnknownPersonViewController:(ABUnknownPersonViewController *)personViewController
{
	WhitePagesLogoImageView *whitePagesLogoImageView = [[WhitePagesLogoImageView alloc]initAndLoadWhitePagesLogo];
	whitePagesLogoImageView.userInteractionEnabled = YES; //clicking the logo will launch whitepages.com
	
	CGFloat oldScrollViewContentHeight = personViewController.view.bounds.size.height;
	
	if([personViewController.view respondsToSelector:@selector(contentSize:)])
		oldScrollViewContentHeight = ((UIScrollView *)personViewController.view).contentSize.height;
	
	//add it right below the current height of the view
	whitePagesLogoImageView.frame = CGRectMake(floor((personViewController.view.bounds.size.width - whitePagesLogoImageView.bounds.size.width) / 2.0),
											   oldScrollViewContentHeight + 80.0,
											   whitePagesLogoImageView.bounds.size.width,
											   whitePagesLogoImageView.bounds.size.height);
	
	//increase the content size of the scroll view so that the logo can be scrolled down to.
	//Note: this assumes personViewController.view is a subclass of UIScrollView. This is an undocumented assumption- it is just that the AB framework is so limiting, I don't know another way.
	if([personViewController.view respondsToSelector:@selector(setContentSize:)])
		((UIScrollView *)personViewController.view).contentSize = CGSizeMake(((UIScrollView *)personViewController.view).contentSize.width, ((UIScrollView *)personViewController.view).contentSize.height + whitePagesLogoImageView.frame.size.height + 80.0);
	
	[personViewController.view addSubview:whitePagesLogoImageView];
	
	[whitePagesLogoImageView release]; 
}

//See note in CCApplication.m for reasons behind these delegate messages
- (NSURL *)urlForAddressOfCurrentContact:(NSURL *)oldURL;
{

	if(self.parentViewController.navigationController.topViewController == singleResultMapViewController || 
		self.navigationController.topViewController == singleResultMapViewController)
	{
		return oldURL; //if the user hit the "Open in Maps" button in the map view, MapViewController already constructed a good URL, so use that
	}
	
	//otherwise, instead of opening the Maps app to show this URL, show it in a MapViewController ourselves
	
	if(!_displayedResult || !_displayedPerson)
		return nil;
	
	singleResultMapViewController = [[MapViewController alloc]initWithSearchResults:[NSArray arrayWithObject:_displayedResult] resultsController:self];
	singleResultMapViewController.showsMoreInfoButton = NO;
	singleResultMapViewController.showsOpenInMapsButton = YES;
	
	
	if(parentViewController)
	{
		[self.parentViewController.navigationController pushViewController:singleResultMapViewController animated:YES];
		[self.parentViewController.navigationController setNavigationBarHidden:NO animated:NO];

	}
	else
	{
		[self.navigationController pushViewController:singleResultMapViewController animated:YES];
		[self.navigationController setNavigationBarHidden:NO animated:NO];

	}
	

	
	[singleResultMapViewController release];
	
	return nil;
	
}
- (NSURL *)urlForPhoneOfCurrentContact:(NSURL *)oldURL;
{
	//I don't have an iPhone, so I cannot test if these links are wrong, but just to be safe make our own link
	if(!_displayedPerson)
		return nil;
	
	//FIXME: Athough the API currently only returns one phone number, we should modify this to support multiple numbers and use the one the user actually tapped
	NSString *phoneNumber = (NSString *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(_displayedPerson,kABPersonPhoneProperty), 0); //do these need to be released? Well, whatever, the application quits as soon as the URL is loaded
	
	NSString *urlAsString = [NSString stringWithFormat:@"tel:%@",phoneNumber];
	
	return [NSURL URLWithString:[urlAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}



/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	
	//release the results view that is not being shown
	if (currentResultsView == CCSearchResultsViewTypeList)
		[mapViewController release];
	else if (currentResultsView == CCSearchResultsViewTypeMap)
		[listViewController release];
		
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc 
{
	[_displayedResult release];
	[searchResults release];
	[metadata release];
	((CCApplication *)[UIApplication sharedApplication]).contactLinksDelegate = nil;
    [super dealloc];
}


@end
