//
//  NameSearchViewController.m
//  People
//
//  Created by Adam Leonard on 6/27/08.
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

#import "SearchViewController.h"
#import "TextFieldTableViewCell.h"
#import "LocationController.h"
#import "ReverseGeocodingRequestController.h"
#import "GeonamesRequestDelegate.h"
#import "AddressParser.h"
#import "CCLocation.h"
#import "WhitePagesRequestController.h"
#import "LoadingViewController.h"
#import "SearchResultsViewController.h"
#import "ViewTableViewCell.h"
#import "WhitePagesConstants.h"
#import "PhoneNumberFormatter.h"
#import "CCTextField.h"

#define SEARCH_TYPE_CONTROL_TABLE_SECTION 0
#define SEARCH_FIELDS_TABLE_SECTION 1

@interface SearchViewController (PRIVATE)
- (void)beginWhitePagesSearch;
- (void)setUpViewsForWhitePagesSearchWithAnimation:(BOOL)animate;
- (BOOL)beginWhitePagesNameSearch;
- (BOOL)beginWhitePagesAddressSearch;
- (BOOL)beginWhitePagesPhoneSearch;
- (void)autofillLocationFieldWithCurrentLocation;
- (void)saveSearchCellFieldsContent;
- (void)finishShowSearchFieldsAnimation:(NSString *)animationID context:(void *)context;
@end

@implementation SearchViewController

@synthesize tableView;
@synthesize whitePagesSearchType;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
	{
		self.title = @"Name Search";
		self.tabBarItem = [[[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemSearch tag:0]autorelease];
		
		_savedNameSearchFieldsContents = [[NSMutableDictionary alloc]initWithCapacity:3];
		_savedAddressSearchFieldsContents = [[NSMutableDictionary alloc]initWithCapacity:2];
		_savedPhoneSearchFieldsContents = [[NSMutableDictionary alloc]initWithCapacity:1];
	}
	return self;
}


- (void)loadView
{
	[super loadView];
	

	//create a containing generic view that can hold both our search fields table and later the UISearchBar and results table
	UIView *containerView = [[UIView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame];
	[containerView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
	self.view = containerView;
	[containerView release];
	
	tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	[tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin];
	[self.view addSubview:self.tableView];
}
 
- (void)viewDidLoad 
{			
	searchBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0.0, 0.0, [UIScreen mainScreen].applicationFrame.size.width, 44.0)];
	searchBar.opaque = NO;
	searchBar.alpha = 0.0;
	searchBar.delegate = self;
	[self.view addSubview:searchBar];
	
	searchTypeSelector = [[UISegmentedControl alloc]initWithItems:[NSArray arrayWithObjects:@"Name",@"Address",@"Phone",nil]];
	searchTypeSelector.selectedSegmentIndex = 0; //Name Search is the default
	[searchTypeSelector addTarget:self action:@selector(changeSearchType:) forControlEvents:UIControlEventValueChanged];
	
	self.whitePagesSearchType = CCWhitePagesSearchTypeName; 

	
	loadingViewController = [[LoadingViewController alloc]initWithNibName:@"LoadingViewController" bundle:nil];

	searchBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Search" style:UIBarButtonItemStyleDone target:self action:@selector(beginWhitePagesSearch)];
	self.navigationItem.rightBarButtonItem = searchBarButtonItem;

	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	cancelBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(stopEditingAllSearchFields)];
	clearBarButtonItem =  [[UIBarButtonItem alloc]initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clearSearchFields:)];
		
	[super viewDidLoad];
}

- (void)keyboardWillShow:(NSNotification *)sender
{
	//show the cancel button so the user can easily hide the keyboard
	self.navigationItem.leftBarButtonItem = cancelBarButtonItem;
}
- (void)keyboardWillHide:(NSNotification *)sender
{
	//if no text is entered, show nothing as the left item
	self.navigationItem.leftBarButtonItem = nil;

	//otherwise, show a clear button
	for (UITableViewCell *aCell in [self.tableView visibleCells])
	{
		if([aCell isKindOfClass:NSClassFromString(@"TextFieldTableViewCell")] && ((TextFieldTableViewCell *)aCell).textField.text && ![((TextFieldTableViewCell *)aCell).textField.text isEqualToString:@""])
		{
			self.navigationItem.leftBarButtonItem = clearBarButtonItem;
			break;
		}
	}

	
}


- (void)stopEditingAllSearchFields
{
	[[NSNotificationCenter defaultCenter]postNotificationName:@"CCStopEditingSearchTextFields"
													   object:self];
	
}

- (void)changeSearchType:(id)sender;
{
	if(sender != searchTypeSelector)
		return;
	
	if(self.whitePagesSearchType == [searchTypeSelector selectedSegmentIndex])
		return; //no change
	
	
	//when we change the search type, the old cells containing the search fields will be dealloc'd and therefore will lose their contents
	//so, save the old search type cells' contents now.
	[self saveSearchCellFieldsContent];
	
	
	
	NSUInteger numberOfNeededRowsInSearchFieldsSection = 0; //see animation note below
	
	int newWhitePagesSearchType = [searchTypeSelector selectedSegmentIndex]; //the segment indexes correspond directly to the enum int constants
	
	UITableViewRowAnimation animation;
	if(newWhitePagesSearchType > self.whitePagesSearchType)
		animation = UITableViewRowAnimationLeft;
	else
		animation = UITableViewRowAnimationRight;
	
	//change the title to reflect the type of search
	if(newWhitePagesSearchType == CCWhitePagesSearchTypeName)
	{
		numberOfNeededRowsInSearchFieldsSection = 3;
		self.title = @"Name Search";
	}
	else if(newWhitePagesSearchType == CCWhitePagesSearchTypeReverseAddress)
	{
		numberOfNeededRowsInSearchFieldsSection = 2;
		self.title = @"Address Search";
	}
	else if(newWhitePagesSearchType == CCWhitePagesSearchTypeReversePhone)
	{
		numberOfNeededRowsInSearchFieldsSection = 1;
		self.title = @"Phone Search";
	}
	
	
	//This is some animation code to animate the insertion and removal of rows
	//It is not used because:
	//- It seems to only animate correctly when removing one row- not adding rows or removing 2 rows
	//- the textView has the nasty habbit of selecting cells when the animation is complete without calling the appropriate delegate messages
	
	NSInteger currentNumberOfRowsInSearchFieldsSection = [self.tableView numberOfRowsInSection:SEARCH_FIELDS_TABLE_SECTION];

	/*
	if(numberOfNeededRowsInSearchFieldsSection > currentNumberOfRowsInSearchFieldsSection)
	{
		//we need to add rows
		NSMutableArray *rowIndexPathsToInsert = [NSMutableArray arrayWithCapacity:2];
		for(NSUInteger i = numberOfNeededRowsInSearchFieldsSection; i > currentNumberOfRowsInSearchFieldsSection; i--) //start adding rows at the bottom
			[rowIndexPathsToInsert addObject:[NSIndexPath indexPathForRow:i-1 inSection:SEARCH_FIELDS_TABLE_SECTION]];
		
		[self.tableView beginUpdates];
		[self.tableView insertRowsAtIndexPaths:rowIndexPathsToInsert withRowAnimation:UITableViewRowAnimationFade]; //rows get inserted from the left
		[self.tableView endUpdates];

	}
	else if(numberOfNeededRowsInSearchFieldsSection < currentNumberOfRowsInSearchFieldsSection)
	{
		//we need to delete rows
		NSMutableArray *rowIndexPathsToDelete = [NSMutableArray arrayWithCapacity:2];
		for(NSUInteger i = currentNumberOfRowsInSearchFieldsSection; i > numberOfNeededRowsInSearchFieldsSection; i--) //start deleting rows at the bottom
			[rowIndexPathsToDelete addObject:[NSIndexPath indexPathForRow:i-1 inSection:SEARCH_FIELDS_TABLE_SECTION]];
		
		[self.tableView beginUpdates];
		[self.tableView deleteRowsAtIndexPaths:rowIndexPathsToDelete withRowAnimation:UITableViewRowAnimationFade]; //rows get deleted to the right
		[self.tableView endUpdates];
	}
	*/
	
	NSMutableArray *rowIndexPathsToRemove = [NSMutableArray arrayWithCapacity:3];
	for(NSUInteger i = 0; i < currentNumberOfRowsInSearchFieldsSection; i++)
		[rowIndexPathsToRemove addObject:[NSIndexPath indexPathForRow:i inSection:SEARCH_FIELDS_TABLE_SECTION]];
	
	[self.tableView reloadRowsAtIndexPaths:rowIndexPathsToRemove withRowAnimation:animation];
	
	
	self.whitePagesSearchType = newWhitePagesSearchType;
	
	[self.tableView reloadData];
	
	NSMutableArray *rowIndexPathsToInsert = [NSMutableArray arrayWithCapacity:3];
	for(NSUInteger i = 0; i < numberOfNeededRowsInSearchFieldsSection; i++)
		[rowIndexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:SEARCH_FIELDS_TABLE_SECTION]];
	
	[self.tableView reloadRowsAtIndexPaths:rowIndexPathsToInsert withRowAnimation:animation];
	
	
	/*
	NSMutableArray *rowIndexPathsToDelete = [NSMutableArray arrayWithCapacity:2];
	for(NSUInteger i = 0; i < currentNumberOfRowsInSearchFieldsSection; i++)
		[rowIndexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:SEARCH_FIELDS_TABLE_SECTION]];
	NSMutableArray *rowIndexPathsToInsert = [NSMutableArray arrayWithCapacity:2];
	for(NSUInteger i = 0; i < numberOfNeededRowsInSearchFieldsSection; i++)
		[rowIndexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:SEARCH_FIELDS_TABLE_SECTION]];
	

	
	[self.tableView beginUpdates];
	[self.tableView insertRowsAtIndexPaths:rowIndexPathsToInsert withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView deleteRowsAtIndexPaths:rowIndexPathsToDelete withRowAnimation:UITableViewRowAnimationNone];
	[self.tableView endUpdates];
*/
	//[self.tableView deleteRowsAtIndexPaths:rowIndexPathsToInsert withRowAnimation:UITableViewRowAnimationLeft];
	 
	
	//So, instead of animation, we just reload the table
	//but the textView also has the nasty habbit of not displaying correctly when a cell is selected (textField is editing) and cells are added/removed
	//but that we can fix.
	/*
	[self stopEditingAllSearchFields];
	[self.tableView reloadData];
	[self stopEditingAllSearchFields];
	 */
	
	/*
	NSMutableArray *rowIndexPathsToInsert = [NSMutableArray arrayWithCapacity:3];
	for(NSUInteger i = 0; i < currentNumberOfRowsInSearchFieldsSection; i++)
		[rowIndexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:SEARCH_FIELDS_TABLE_SECTION]];
	
	
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:rowIndexPathsToInsert withRowAnimation:UITableViewRowAnimationLeft];
	[self.tableView reloadRowsAtIndexPaths:rowIndexPathsToInsert withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView endUpdates];
	 */

	
}
- (void)saveSearchCellFieldsContent
{
	//these will be restored when the cells are created again in tableView:cellForRowAtIndexPath:
	if(self.whitePagesSearchType == CCWhitePagesSearchTypeName)
	{
		NSString *firstName = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_firstNameCellIndexPath]).textField.text;
		NSString *lastName = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_lastNameCellIndexPath]).textField.text;
		NSString *location = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_locationFieldCellIndexPath]).textField.text;
		
		if(firstName)
			[_savedNameSearchFieldsContents setObject:firstName forKey:@"firstName"];
		if(lastName)
			[_savedNameSearchFieldsContents setObject:lastName forKey:@"lastName"];
		if(location)
			[_savedNameSearchFieldsContents setObject:location forKey:@"location"];
		
	}
	else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReverseAddress)
	{
		NSString *streetAddress = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_streetAddressCellIndexPath]).textField.text;
		NSString *cityStateAndZip = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_cityStateAndZipCellIndexPath]).textField.text;
		
		if(streetAddress)
			[_savedAddressSearchFieldsContents setObject:streetAddress forKey:@"streetAddress"];
		if(cityStateAndZip)
			[_savedAddressSearchFieldsContents setObject:cityStateAndZip forKey:@"cityStateAndZip"];
		
	}
	else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReversePhone)
	{
		NSString *phone = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_phoneNumberCellIndexPath]).textField.text;
		
		if(phone)
			[_savedPhoneSearchFieldsContents setObject:phone forKey:@"phone"];
	}

}
- (void)clearSearchFields:(id)sender
{
	for (UITableViewCell *aCell in [self.tableView visibleCells])
	{
		if ([aCell isKindOfClass:NSClassFromString(@"TextFieldTableViewCell")])
			((TextFieldTableViewCell *)aCell).textField.text = @"";
	}
}

- (void)autofillLocationFieldWithCurrentLocation;
{
	
	UITextField *textField = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_locationFieldCellIndexPath]).textField;
	textField.placeholder = @"Loading location";
	textField.text = @"";
	textField.enabled = NO; //do not let the user edit the field while we are loading the location
	textField.rightView.hidden = YES;
	((UIButton *)textField.rightView).enabled = NO;
	
	//get the user's current location to autofill the "Location" field
	[[NSNotificationCenter defaultCenter]addObserver:self 
											selector:@selector(foundLocation:)
												name:CCLocationChangedNotificationName 
											  object:nil];
	
	[[NSNotificationCenter defaultCenter]addObserver:self 
											selector:@selector(locationUpdateFailed:)
												name:CCLocationUpdateFailedNotificationName 
											  object:nil];
	
	//for this, we are just getting the user's city. It really can be very inacurate
	[[LocationController sharedController]startUpdatingLocationWithDesiredAccuracy:kCLLocationAccuracyThreeKilometers];
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
	[geonamesController findCityStateAndZip];
	
}
- (void)locationUpdateFailed:(NSNotification *)sender
{
	UITextField *textField = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_locationFieldCellIndexPath]).textField;
	textField.placeholder = @"City, State or Zip"; //get rid of the "Loading..." placeholder
	textField.enabled = YES;
	textField.rightView.hidden = NO;
	((UIButton *)textField.rightView).enabled = YES;
	
	
	UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Could not determine your current location"
													   message:@"You can fill in your location manually in the \"Location\" field."							
													  delegate:nil
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil];
	[alertView show];
}	
- (void)reverseGeocodingRequestController:(ReverseGeocodingRequestController *)controller retrievedAddress:(NSString *)address addressComponents:(NSDictionary *)addressComponents;
{
	UITextField *textField = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_locationFieldCellIndexPath]).textField;
	textField.placeholder = @"City, State or Zip"; //get rid of the "Loading..." placeholder
	textField.enabled = YES;
	textField.rightView.hidden = NO;
	((UIButton *)textField.rightView).enabled = YES;
	
	if(!address)
		return; //hmmm, could not get a city near the users location. Oh well, no autofill for you!
	
	if(!_locationFieldCellIndexPath)
		return; //but no where to put it. Strange....
	
	NSMutableString *location = [NSMutableString string];
	
	NSString *city = [addressComponents objectForKey:@"city"];	
	if(city && ![city isEqualToString:@""])
		[location appendString:city];
	
	NSString *state = [addressComponents objectForKey:@"state"];
	if(state && ![state isEqualToString:@""])
	{
		if([location length] > 0)
			[location appendString:@" "]; //add a space between the city and state
		
		[location appendString:state];
	}
	
	if([location length] > 0)
		textField.text = location;


}
- (void)reverseGeocodingRequestController:(ReverseGeocodingRequestController *)controller failedWithError:(NSError *)error;
{
	UITextField *textField = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_locationFieldCellIndexPath]).textField;
	textField.placeholder = @"City, State or Zip"; //get rid of the "Loading..." placeholder
	textField.enabled = YES;

	UIAlertView *alert = [[[UIAlertView alloc]initWithTitle:@"Could not determine your current location."
													message:[NSString stringWithFormat:@"You can fill in your location manually in the \"Location\" field. The error was: %@",[error localizedDescription]]
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil]autorelease];
	[alert show];
}

 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
	return 2;
}


- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section 
{
	if(section == SEARCH_TYPE_CONTROL_TABLE_SECTION && self.whitePagesSearchType != CCWhitePagesSearchTypeNone)
		return 1;
	else if(section == SEARCH_FIELDS_TABLE_SECTION)
	{
		if(self.whitePagesSearchType == CCWhitePagesSearchTypeName)
			return 3; //first name, last name, location
		else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReverseAddress)
			return 2; //address, (city+state+zip)
		else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReversePhone)
			return 1; //phone number
	}
	
	return 0;
}


- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section
{
	//if(section == SEARCH_FIELDS_TABLE_SECTION && self.whitePagesSearchType == CCWhitePagesSearchTypeReverseAddress)
	//	return @"Address"; //we put no labels on the text fields for the first and second lines of the address, so put a permanent visible clue of what should go in those fields
	//else
		return @""; //otherwise, no titles
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//ok, so we are really crammed for space, especially with the name search.
	//We need to fit the navigation bar, all the search fields, and a huge keyboard on the screen, and it is really confusing if the user needs to scroll
	//so, some compromises. The full normal height for a table row is 44.0
	
	if(indexPath.section == SEARCH_TYPE_CONTROL_TABLE_SECTION)
		return 36.0; //this is the segmented control. In my opinion, it's normal size looks too big. There are only 3 segments, and it feels totally usuable even with a big finger. Plus there is padding beneath it between the table sections
	
	else
		return	42.0; //and like 2 pixels off. Who will notice?
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{	
	if(indexPath.section == SEARCH_TYPE_CONTROL_TABLE_SECTION) //the segmented control allowing the user to select a name, address, or phone search
	{
				
		ViewTableViewCell *cell = [[[ViewTableViewCell alloc]initWithFrame:CGRectZero reuseIdentifier:nil]autorelease];
		
		cell.view = searchTypeSelector;
		
		return cell;
	}
		
	if(indexPath.section == SEARCH_FIELDS_TABLE_SECTION && indexPath.row != 3) //first name, last name, location, etc.
	{
		//reusing cells causes all sorts of display bugs when we change search type and have to add/remove rows and change labels.
		//So, just create a new one every time. This really should not matter at all, since at most we have 3 cells.
		TextFieldTableViewCell *cell = [[[TextFieldTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil] autorelease];
		
		cell.textField.returnKeyType = UIReturnKeyDefault;
		cell.textField.keyboardType = UIKeyboardTypeDefault;
		cell.textField.autocorrectionType = UITextAutocorrectionTypeYes;
		
		cell.label = @"";
		cell.textField.text = @"";
		cell.textField.placeholder = @"";

		if(self.whitePagesSearchType == CCWhitePagesSearchTypeName)
			cell.longestLabelInTable = @"First Name";
		else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReverseAddress)
			cell.longestLabelInTable = @"";
		else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReversePhone)
			cell.longestLabelInTable = @"Number";

		
		[cell.textField addTarget:self action:@selector(beginEditingNextFieldAfterField:) forControlEvents:UIControlEventEditingDidEndOnExit];
				
		switch (indexPath.row)
		{
			case 0:
				if(self.whitePagesSearchType == CCWhitePagesSearchTypeName)
				{
					cell.label = @"First Name";
					[_firstNameCellIndexPath release];
					_firstNameCellIndexPath = [indexPath retain];
					
					NSString *savedContents = [_savedNameSearchFieldsContents objectForKey:@"firstName"];
					if(savedContents)
						cell.textField.text = savedContents;
				}
				else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReverseAddress)
				{
					cell.textField.placeholder = @"Street Address";
					cell.textField.autocorrectionType = UITextAutocorrectionTypeNo; //does not work very well with this
					[_streetAddressCellIndexPath release];
					_streetAddressCellIndexPath = [indexPath retain];
					
					NSString *savedContents = [_savedAddressSearchFieldsContents objectForKey:@"streetAddress"];
					if(savedContents)
						cell.textField.text = savedContents;
				}
				else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReversePhone)
				{
					cell.label = @"Number";
					cell.textField.placeholder = @"";
					cell.textField.keyboardType = UIKeyboardTypePhonePad;
					[_phoneNumberCellIndexPath release];
					_phoneNumberCellIndexPath = [indexPath retain];
					cell.textField.returnKeyType = UIReturnKeySearch; //this is the last field, so make clicking the return key start the search
					[cell.textField addTarget:self action:@selector(beginWhitePagesSearch) forControlEvents:UIControlEventEditingDidEndOnExit];
					[cell.textField addTarget:self action:@selector(formatPhoneNumber:) forControlEvents:UIControlEventEditingChanged];
					
					NSString *savedContents = [_savedPhoneSearchFieldsContents objectForKey:@"phone"];
					if(savedContents)
						cell.textField.text = savedContents;
				}
				else
					return nil;
				
				break;
			case 1:
				if(self.whitePagesSearchType == CCWhitePagesSearchTypeName)
				{
					cell.label = @"Last Name";
					cell.textField.placeholder = @"Required";
					[_lastNameCellIndexPath release];
					_lastNameCellIndexPath = [indexPath retain];
					
					NSString *savedContents = [_savedNameSearchFieldsContents objectForKey:@"lastName"];
					if(savedContents)
						cell.textField.text = savedContents;
				}
				else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReverseAddress)
				{
					cell.textField.placeholder = @"City, State & Zip";
					[_cityStateAndZipCellIndexPath release];
					_cityStateAndZipCellIndexPath = [indexPath retain];
					cell.textField.returnKeyType = UIReturnKeySearch; //this is the last field, so make clicking the return key start the search
					[cell.textField addTarget:self action:@selector(beginWhitePagesSearch) forControlEvents:UIControlEventEditingDidEndOnExit];
					
					NSString *savedContents = [_savedAddressSearchFieldsContents objectForKey:@"cityStateAndZip"];
					if(savedContents)
						cell.textField.text = savedContents;
				}
				else
					return nil;
				break;
			case 2:
				if(self.whitePagesSearchType == CCWhitePagesSearchTypeName)
				{
					cell.label = @"Location";
					cell.textField.placeholder = @"City, State or Zip";
				
					[_locationFieldCellIndexPath release];
					_locationFieldCellIndexPath = [indexPath retain]; //so we can autofill it later if we get the user's location
					cell.textField.returnKeyType = UIReturnKeySearch; //this is the last field, so make clicking the return key start the search
					[cell.textField addTarget:self action:@selector(beginWhitePagesSearch) forControlEvents:UIControlEventEditingDidEndOnExit];
					
					UIButton *locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
					UIImage *locationButtonImage = [UIImage imageNamed:@"locationButton.png"];
					[locationButton setImage:locationButtonImage forState:UIControlStateNormal];
					[locationButton addTarget:self action:@selector(autofillLocationFieldWithCurrentLocation) forControlEvents:UIControlEventTouchDown];
					locationButton.showsTouchWhenHighlighted = YES;
					
					cell.textField.rightView = locationButton;
					cell.textField.rightViewMode = UITextFieldViewModeAlways;
					
					NSString *savedContents = [_savedNameSearchFieldsContents objectForKey:@"location"];
					if(savedContents)
						cell.textField.text = savedContents;

				}
				else
					return nil;
				
				break;

		}
		
		return cell;
	}
	
	return nil;
}
- (void)formatPhoneNumber:(UITextField *)textField
{
	if(_oldFormattedNumber && [_oldFormattedNumber length] > [textField.text length])
	{
		//if the length of the number string decreased, the user probably hit the backspace key. If this is the case, let the user delete formatting characters by just not formatting the string this time
		[_oldFormattedNumber release];
		_oldFormattedNumber = [textField.text retain];
		return;
	}
	
	//since we will be modifying the text field in respose to a notification that the textField was modified, we must temporarily remove ourselves as a target to avoid infinite recursion
	[textField removeTarget:self action:@selector(formatPhoneNumber:) forControlEvents:UIControlEventEditingChanged];
	textField.text = [[PhoneNumberFormatter sharedFormatter]formatPhoneNumber:textField.text];
	[textField addTarget:self action:@selector(formatPhoneNumber:) forControlEvents:UIControlEventEditingChanged];
}
- (void)beginWhitePagesSearch;
{
	//the user clicked the search button, so lets do a search

	BOOL searchDidStartSuccessfully = NO;
	
	if(self.whitePagesSearchType == CCWhitePagesSearchTypeName)
		searchDidStartSuccessfully = [self beginWhitePagesNameSearch];
	else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReverseAddress)
		searchDidStartSuccessfully = [self beginWhitePagesAddressSearch];
	else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReversePhone)
		searchDidStartSuccessfully = [self beginWhitePagesPhoneSearch];
	
	if(!searchDidStartSuccessfully) //there was some error (which another call handled)
		return;
	
	[self setUpViewsForWhitePagesSearchWithAnimation:YES];
}
- (void)setUpViewsForWhitePagesSearchWithAnimation:(BOOL)animate;
{
	showingSearchFields = NO;
	//if the search started successfully, show the loading screen, optionally with all the exciting animations
	
	//since we will be getting rid of the search fields table view, first make sure to save all the contents inside so it can be restored if the user wants to modify the search
	[self saveSearchCellFieldsContent];
	
	resultsViewController = nil;
	
	//from this point on, we are assuming we are going from the search fields to the loading view to the results (the only path that really makes sense)
	//however, if a search is started in the search history view controller (another tab) we could be anywhere in the interface right now.
	//so ensure we are at the right place
	//[self showSearchFieldsTableWithAnimation:NO];
	
	self.navigationItem.rightBarButtonItem = nil; //hide the search button
	
	CGRect originalTableViewBounds = self.tableView.bounds;
	
	UIView *loadingView = loadingViewController.view;
	loadingView.frame = originalTableViewBounds;
	[self.view insertSubview:loadingView belowSubview:self.tableView]; //put it right below the table view. It will be visible after the animations
	[loadingView setNeedsLayout]; //make sure the subviews autoresize properly so they are placed in the center
	
	[self.navigationController setNavigationBarHidden:YES animated:animate];
			
	[self.view insertSubview:searchBar aboveSubview:self.tableView]; //make sure the search bar is visible (it may not be if we moved the search fields table view up on the reverse animation)
	[self.view setNeedsDisplay];

	//and now that we have started the request, start our animations:
	//simultaniously fade in the search field to the top of the window; and flip and fade out the search fields table to the top of the window
	//this will reveal the loadingView underneath
	//once we get the White Pages results, we move up a new table with the results to cover the loading view
	
	if(animate)
	{
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.25];
		//[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.tableView cache:NO];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
		
		NSInteger currentNumberOfRowsInSearchFieldsSection = [self.tableView numberOfRowsInSection:SEARCH_FIELDS_TABLE_SECTION];		
		NSMutableArray *rowIndexPathsToRemove = [NSMutableArray arrayWithCapacity:3];
		for(NSUInteger i = 0; i < currentNumberOfRowsInSearchFieldsSection; i++)
			[rowIndexPathsToRemove addObject:[NSIndexPath indexPathForRow:i inSection:SEARCH_FIELDS_TABLE_SECTION]];
		
		[rowIndexPathsToRemove addObject:[NSIndexPath indexPathForRow:0 inSection:SEARCH_TYPE_CONTROL_TABLE_SECTION]];
		
		oldWhitePagesSearchType = self.whitePagesSearchType;
		self.whitePagesSearchType = CCWhitePagesSearchTypeNone;

		[self.tableView deleteRowsAtIndexPaths:rowIndexPathsToRemove withRowAnimation:UITableViewRowAnimationTop];
		
		
	}
	//self.tableView.frame = CGRectMake(originalTableViewBounds.origin.x, originalTableViewBounds.origin.y, originalTableViewBounds.size.width, searchBar.frame.size.height);
	self.tableView.alpha = 0.0;
	searchBar.alpha = 1.0; //fade in the search bar (had alpha of 0.0)
	
	if(animate)
	{
		[UIView commitAnimations];
	}
	
}
- (WhitePagesRequestController *)beginWhitePagesSearchWithSearchType:(NSInteger)searchType
											searchDisplayDescription:(NSString *)displayDescription
														  APICallURL:(NSURL *)URL
													   withAnimation:(BOOL)animate;
{
	if(!displayDescription || !URL)
		return nil;
	
	searchBar.text = displayDescription;
	
	performingWhitePagesSearch = YES;
	
	WhitePagesRequestController *requestController =  [WhitePagesRequestController beginSearchWithType:searchType
																							APICallURL:URL
																			  searchDisplayDescription:displayDescription
																							  delegate:self];
	requestController.viewControllerForPicklist = self;
	[self setUpViewsForWhitePagesSearchWithAnimation:animate];
	
	return requestController;
}
- (BOOL)beginWhitePagesNameSearch
{	
	UITextField *firstNameTextField = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_firstNameCellIndexPath]).textField;
	UITextField *lastNameTextField = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_lastNameCellIndexPath]).textField;
	UITextField *locationTextField = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_locationFieldCellIndexPath]).textField;
	
	//make sure to stop editing any of the fields so the keyboard hides
	[firstNameTextField resignFirstResponder];
	[lastNameTextField resignFirstResponder];
	[locationTextField resignFirstResponder];
	
	NSString *firstName = firstNameTextField.text;
	NSString *lastName = lastNameTextField.text;
	NSString *location = locationTextField.text;
	
	NSDictionary *locationComponents = [[AddressParser sharedParser]parseCombinedCityStateAndZipString:location];
	
	if(!lastName || [lastName isEqualToString:@""])
	{
		//the API requires that the user enters at least a last name
		UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Not enough information"
														   message:@"To perform a search, you must at least provide the person's last name."	
														  delegate:nil
												 cancelButtonTitle:@"OK"
												 otherButtonTitles:nil];
		[alertView show];
		
		[((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_lastNameCellIndexPath]).textField becomeFirstResponder]; //automatically start editing the missing field
		
		return NO;
	}
	
	
	//construct the string that will represent the search in the search bar and in the search history
	//note that it does not really mean anything. When the user clicks it to edit the search, the bar goes away and we display the full interface (first name, last name, location, etc) 
	NSMutableString *searchStringForSearch = [NSMutableString stringWithCapacity:100];
	
	if(firstName && ![firstName isEqualToString:@""])
		[searchStringForSearch appendFormat:@"%@ ",firstName];
	if(lastName && ![lastName isEqualToString:@""])
		[searchStringForSearch appendFormat:@"%@ ",lastName];
	
	//use one of the location components. Preferences are in this order: city, zip, state
	if([locationComponents objectForKey:@"city"] && ![[locationComponents objectForKey:@"city"] isEqualToString:@""])
		[searchStringForSearch appendFormat:@"in %@",[locationComponents objectForKey:@"city"]];
	else if([locationComponents objectForKey:@"zip"] && ![[locationComponents objectForKey:@"zip"] isEqualToString:@""])
		[searchStringForSearch appendFormat:@"in %@",[locationComponents objectForKey:@"zip"]];
	else if([locationComponents objectForKey:@"state"] && ![[locationComponents objectForKey:@"state"] isEqualToString:@""])
		[searchStringForSearch appendFormat:@"in %@",[locationComponents objectForKey:@"state"]]; 
	
	searchBar.text = searchStringForSearch;
	
	
	//ok, now we are ready to begin the search
	WhitePagesRequestController *requestController = [WhitePagesRequestController beginNameSearchWithFirstName:firstName
																									  lastName:lastName
																										  city:[locationComponents objectForKey:@"city"]
																										 state:[locationComponents objectForKey:@"state"]
																										   zip:[locationComponents objectForKey:@"zip"]
																					  searchDisplayDescription:searchStringForSearch
																									  delegate:self];
	
	requestController.viewControllerForPicklist = self;
	
	return YES;
}
- (BOOL)beginWhitePagesAddressSearch
{	
	UITextField *streetAddressField = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_streetAddressCellIndexPath]).textField;
	UITextField *cityStateAndZipField = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_cityStateAndZipCellIndexPath]).textField;
	
	//make sure to stop editing any of the fields so the keyboard hides
	[streetAddressField resignFirstResponder];
	[cityStateAndZipField resignFirstResponder];
	
	NSString *streetAddress = streetAddressField.text;
	NSString *cityStateAndZip = cityStateAndZipField.text;
	
	NSDictionary *houseAddressComponents = [[AddressParser sharedParser]parseStreetAddress:streetAddress];
	NSDictionary *cityStateAndZipComponents = [[AddressParser sharedParser]parseCombinedCityStateAndZipString:cityStateAndZip];
	
	if((![houseAddressComponents objectForKey:@"street"] || [[houseAddressComponents objectForKey:@"street"] isEqualToString:@""]) ||
	   (![cityStateAndZipComponents objectForKey:@"state"] && ![cityStateAndZipComponents objectForKey:@"zip"]))
	{
		//the API requires a street and either a state or a zip.
		UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Not enough information"
														   message:@"To perform a search, you must provide a street name and either a state or a zip code."
														  delegate:nil
												 cancelButtonTitle:@"OK"
												 otherButtonTitles:nil];
		[alertView show];
		
		[streetAddressField becomeFirstResponder]; //automatically start editing the missing field
		
		return NO;
	}
	
	//construct the string that will represent the search in the search bar and in the search history
	//note that it does not really mean anything. When the user clicks it to edit the search, the bar goes away and we display the full search fields interface
	NSMutableString *searchStringForSearch = [NSMutableString stringWithCapacity:100];
	[searchStringForSearch appendFormat:@"%@ / %@",streetAddress,cityStateAndZip];
	searchBar.text = searchStringForSearch;
	
	//ok, now we are ready to begin the search
	WhitePagesRequestController *requestController = [WhitePagesRequestController beginReverseAddressSearchWithHouse:[houseAddressComponents objectForKey:@"house"]
																											  street:[houseAddressComponents objectForKey:@"street"]
																												city:[cityStateAndZipComponents objectForKey:@"city"]
																											   state:[cityStateAndZipComponents objectForKey:@"state"]
																												 zip:[cityStateAndZipComponents objectForKey:@"zip"]
																							searchDisplayDescription:searchStringForSearch
																											delegate:self];
	requestController.viewControllerForPicklist = self;

	return YES;
}

- (BOOL)beginWhitePagesPhoneSearch
{	
	UITextField *phoneNumberField = ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:_phoneNumberCellIndexPath]).textField;
	
	//make sure to stop editing any of the fields so the keyboard hides
	[phoneNumberField resignFirstResponder];

	NSString *formattedPhoneNumber = phoneNumberField.text; //it was formatted live as it was typed in
	
	//remove all formatting so the API can handle the number
	NSString *unformattedPhoneNumber = [[PhoneNumberFormatter sharedFormatter]unformatPhoneNumber:formattedPhoneNumber];
	
	if([unformattedPhoneNumber length] > 0 && [[unformattedPhoneNumber substringWithRange:NSMakeRange(0, 1)]integerValue] == 1)
		unformattedPhoneNumber = [unformattedPhoneNumber substringFromIndex:1]; //the API wants exactly 10 digits, so if the number has the optional "1" country code at the begining, remove it.
	
	if([unformattedPhoneNumber length] != 10)
	{
		//the API requires a full phone number with area code (10 digits)
		UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Not enough information"
														   message:@"To perform a search, you must provide a full phone number, including the area code."
														  delegate:nil
												 cancelButtonTitle:@"OK"
												 otherButtonTitles:nil];
		[alertView show];
		
		[phoneNumberField becomeFirstResponder]; //automatically start editing the missing field
		
		return NO;
	}
	
	
	//ok, now we are ready to begin the search
	WhitePagesRequestController *requestController = [WhitePagesRequestController beginReversePhoneSearchWithPhoneNumber:unformattedPhoneNumber
																								searchDisplayDescription:formattedPhoneNumber
																												delegate:self];
	requestController.viewControllerForPicklist = self;

	
	//construct the string that will represent the search in the search bar
	//note that it does not really mean anything. When the user clicks it to edit the search, the bar goes away and we display the full search fields interface
	searchBar.text = formattedPhoneNumber;
	
	return YES;
}


- (void)whitePagesRequestController:(WhitePagesRequestController *)controller retrievedResults:(NSArray *)results metadata:(NSDictionary *)metadata;
{		
	//cool. Got the results
	
	self.title = @"Results";
	
	performingWhitePagesSearch = NO;
	
	if(showingSearchFields)
	{
		NSLog(@"Ignoring canceled white pages request");
		return;
	}
	
	resultsViewController = [[SearchResultsViewController alloc]initWithSearchResults:results];
	resultsViewController.parentViewController = self;
	resultsViewController.metadata = metadata;
	
	resultsViewController.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.size.height + searchBar.frame.size.height, self.view.frame.size.width,  self.view.frame.size.height - [searchBar frame].size.height); //full width, 0 height at bottom of view (invisible)
	
	[self.view insertSubview:resultsViewController.view belowSubview:searchBar];
	
	//now we animate it from the bottom to the top, covering the loading view
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	
	//full width, put right below search bar
	resultsViewController.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + searchBar.frame.size.height, self.view.frame.size.width,  self.view.frame.size.height - searchBar.frame.size.height);
	[UIView commitAnimations];
	 
	
}
- (void)whitePagesRequestController:(WhitePagesRequestController *)controller failedWithError:(NSError *)error;
{
	performingWhitePagesSearch = NO;
	
	if(showingSearchFields)
	{		return;
	}
	
	NSString *message = nil;
	
	if([[error domain]isEqualToString:NSURLErrorDomain])
		message = [NSString stringWithFormat:@"Please make sure you are online and try again later. The error was: %@",[error localizedDescription]];
	else if([[error domain]isEqualToString:@"CCWhitePagesErrorDomain"])
		message = [NSString stringWithFormat:@"Ensure the information you entered is correct and try again. The error was: %@", [error localizedDescription]];
	else
		message = [NSString stringWithFormat:@"The error was: %@",[error localizedDescription]];
	
	_whitePagesErrorAlert = [[[UIAlertView alloc]initWithTitle:@"Could not complete search."
													   message:message
													  delegate:self
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil]autorelease];
	[_whitePagesErrorAlert show];
	

}	
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(alertView == _whitePagesErrorAlert)
		[self showSearchFieldsTableWithAnimation:YES]; //we were showing the loading screen. Now go back to the search fields
}

- (void)beginEditingNextFieldAfterField:(UITextField *)textField
{
	//go through the visible cells and find the one that has this text field
	NSArray *visibleCells = [self.tableView visibleCells];
	BOOL foundTextFieldCell = NO;
	for(UITableViewCell *aCell in visibleCells)
	{
		if(![aCell isKindOfClass:[TextFieldTableViewCell class]]) //does not have a text field, can't be it
			continue;
		
		if(foundTextFieldCell)
		{
			//cool, we have found the edited cell on a previous iteration. Now, this cell is after the edited one in the table, so start editing this cell
			[((TextFieldTableViewCell *)aCell).textField becomeFirstResponder];
			return;
		}
		
		
		if(((TextFieldTableViewCell *)aCell).textField == textField)
		{
			//got it. Now, keep searching until we find the next TextFieldTableViewCell. That will be the one we want to start editing
			foundTextFieldCell = YES;
		}
	}
	
	//we can only get here if there is no text field in the table after the one that finished editing
	//that must mean the form is done. The keyboard should automatically disappear
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)aSearchBar
{
	//the search bar is just for a presentation to the user to represent the terms used to create the search results. It cannot be edited. Instead, we show the full editing interface

	[self showSearchFieldsTableWithAnimation:YES];
	
	return NO; //do not edit the search bar
}
- (void)showSearchFieldsTableWithAnimation:(BOOL)animate;
{
	showingSearchFields = YES;
	
	//make sure we are the only view controller on the stack (e.g., the ABUnknownPersonViewController is not being shown)
	[self.navigationController popToRootViewControllerAnimated:NO];
	
	//make the tableView again above the results table. The table view is invisible now, so it will allow us to slowly reveal it in the animation
	[self.view insertSubview:self.tableView belowSubview:searchBar];
	[self.view setNeedsDisplay];
	
	self.whitePagesSearchType = oldWhitePagesSearchType;
	
	[self.tableView reloadData];

	if(animate)
	{
		self.tableView.alpha = 0.0;
		
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.25];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(finishShowSearchFieldsAnimation:context:)];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];

		self.tableView.alpha = 1.0;
		
	}
	
	/*
	if(animate)
	{
		//these animations are just the reverse of the ones we did to hid the editing interface
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.25];
	
		//When the animation ends and the results table is completely covered up by the search fields table, we need to  remove the results view, and release its controller. 
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(finishShowSearchFieldsAnimation:context:)];
	
		//[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.tableView cache:YES];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
		
		NSInteger neededNumberOfRowsInSearchFieldsSection = [self tableView:self.tableView numberOfRowsInSection:SEARCH_FIELDS_TABLE_SECTION];		
		NSMutableArray *rowIndexPathsToAdd = [NSMutableArray arrayWithCapacity:3];
		for(NSUInteger i = 0; i < neededNumberOfRowsInSearchFieldsSection; i++)
			[rowIndexPathsToAdd addObject:[NSIndexPath indexPathForRow:i inSection:SEARCH_FIELDS_TABLE_SECTION]];
		
		[rowIndexPathsToAdd addObject:[NSIndexPath indexPathForRow:0 inSection:SEARCH_TYPE_CONTROL_TABLE_SECTION]];
		
		[self.tableView insertRowsAtIndexPaths:rowIndexPathsToAdd withRowAnimation:UITableViewRowAnimationFade];	
	}
	else
		[self.tableView reloadData];
	*/
	
	[self.navigationController setNavigationBarHidden:NO animated:animate];

	self.tableView.frame = self.view.frame;
	self.tableView.alpha = 1.0;
	searchBar.alpha = 0.0; //fade out the search bar (had alpha of 1.0)
	
	

	
	if(animate)
		[UIView commitAnimations];	
	else
		[self finishShowSearchFieldsAnimation:nil context:nil]; //no animation, so it ended immediately
}
- (void)finishShowSearchFieldsAnimation:(NSString *)animationID context:(void *)context
{
	if(resultsViewController)
	{
		[resultsViewController.view removeFromSuperview];
		[resultsViewController release];
		resultsViewController = nil;
	}
	
	if(self.whitePagesSearchType == CCWhitePagesSearchTypeName)
			self.title = @"Name Search";
	else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReverseAddress)
		self.title = @"Address Search";
	else if(self.whitePagesSearchType == CCWhitePagesSearchTypeReversePhone)
		self.title = @"Phone Search";
	
	self.navigationItem.rightBarButtonItem = searchBarButtonItem; //show the search button again now that we are showing the search fields

	[self.tableView reloadData];
	[self stopEditingAllSearchFields];
	
	//If the user hit the clear "x" button in the search field, clear all the search fields now that they are shown
	if([searchBar.text isEqualToString:@""])
		[self clearSearchFields:nil];
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[searchTypeSelector release];
	[resultsViewController release];
	[searchBar release];
	[searchBarButtonItem release];
	[cancelBarButtonItem release];
	[loadingViewController release];
	[_firstNameCellIndexPath release];
	[_lastNameCellIndexPath release];
	[_locationFieldCellIndexPath release];
	[_streetAddressCellIndexPath release];
	[_cityStateAndZipCellIndexPath release];
	[_phoneNumberCellIndexPath release];
	[_savedNameSearchFieldsContents release];
	[_savedAddressSearchFieldsContents release];
	[_savedPhoneSearchFieldsContents release];
	
	[[NSNotificationCenter defaultCenter]removeObserver:self];
	
	[super dealloc];
}


@end
