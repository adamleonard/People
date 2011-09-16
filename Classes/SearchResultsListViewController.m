//
//  SearchResultsTableDataSource.m
//  WikiPhone
//
//  Created by Adam Leonard on 6/26/08.
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

#import "SearchResultsListViewController.h"
#import "SearchResultCell.h"
#import "CCLocation.h"
#import "ViewTableViewCell.h"
#import "MapViewController.h"
#import "SearchResultsViewController.h"
#import "WhitePagesLogoImageView.h"


@implementation SearchResultsListViewController

@synthesize searchResults;
@synthesize metadata;
@synthesize resultsController;

- (id)initWithSearchResults:(NSArray *)theSearchResults;
{
	self = [super initWithStyle:UITableViewStylePlain];
	if (self != nil) 
	{
		self.searchResults = theSearchResults;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if([self.searchResults count] == 1)
	{
		
		//if there is exactly one result, do not make the user select it in the results table; just show it immediately
		[self.resultsController displayResult:[self.searchResults objectAtIndex:0] withAnimation:NO];
	}

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// Only one section
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if([self.searchResults count] == 0)
		return 2; //If there are no results, we match the behavior of the YouTube app and display 1 blank cell followed by 1 "No Results" cell
		
	return [self.searchResults count] + 1; //we will also display one extra cell with some form of required WhitePages attribution
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 60.0;
}


- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([self.searchResults count] == 0)
	{
		//display a "No Results" cell
		
		static NSString *NoResultsCellIdentifier = @"NoResultsCellIdentifier";
		
		UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:NoResultsCellIdentifier];
		
		if(!cell)
			cell = [[[UITableViewCell alloc]initWithFrame:CGRectZero reuseIdentifier:NoResultsCellIdentifier]autorelease];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		//to match the behavior of the YouTube App, we have 1 blank cell, followed by 1 "No Results" cell
		if(indexPath.row == 1)
		{
			NSString *noResultsText = @"No Results";
			
			cell.textLabel.text = noResultsText;
			cell.textLabel.textColor = [UIColor colorWithWhite:0.66 alpha:1.0];
			cell.textLabel.font = [UIFont boldSystemFontOfSize:18.0];
						
			//As of Beta 8 cell.textAlignment = UITextAlignmentCenter does not work. 
			//Also, I don't know how to get a frame size change to stick as the tableView automatically changes it later
			//And, indentionWidth seems use magic units that are not pixels...
			//cell.indentationLevel = 1;
			//cell.indentationWidth = 50.0; //but 50 seems really close to center, for like, whatever 50 means
			/*
			CGFloat leftOffset = [UIScreen mainScreen].applicationFrame.size.width - floor(([noResultsText sizeWithFont:cell.font].width) / 2.0);
			cell.frame = CGRectMake(leftOffset, cell.frame.origin.y, cell.frame.size.width - leftOffset, cell.frame.size.height);
			cell.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			 */
			
			//fixed in 3.0
			cell.textLabel.textAlignment = UITextAlignmentCenter;
		}
		
		return cell;
	}
	
	if(indexPath.row == [self.searchResults count])
	{
		//this is the last cell- one after the last result
		//display white pages attribution info in it.
		
		static NSString *WhitePagesAttributionCellIdentifier = @"WhitePagesAttributionCellIdentifier";
		
		UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:WhitePagesAttributionCellIdentifier];
		
		if(!cell)
			cell = [[[UITableViewCell alloc]initWithFrame:CGRectZero reuseIdentifier:WhitePagesAttributionCellIdentifier]autorelease];
		
		WhitePagesLogoImageView *whitePagesLogoImageView = [[WhitePagesLogoImageView alloc]initAndLoadWhitePagesLogo];
		cell.accessoryView = whitePagesLogoImageView;
		[whitePagesLogoImageView release];
		
		NSString *attributionText = nil;
		//see if there are more results availiable on whitepages.com than were returned by the API. If so, show a "View x more results on [white pages image]" cell
		if([self.metadata objectForKey:@"recordrange"])
		{
			NSInteger totalResultsAvailable = [[[self.metadata objectForKey:@"recordrange"]objectForKey:@"totalavailable"]integerValue];
			
			if([self.searchResults count] < totalResultsAvailable)
			{
				attributionText = [NSString stringWithFormat:@"%i More %@",(totalResultsAvailable - [self.searchResults count]),((totalResultsAvailable - [self.searchResults count]) > 1) ? @"Results" : @"Result"];
			}
		}
		if(!attributionText)
		{
			//otherwise, just offer to go to whitepages.com
			attributionText = @"Visit WhitePages";
		}
		
		cell.textLabel.text = attributionText;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
		
		return cell;
	}
	
	
	static NSString *SearchResultsCellIdentifier = @"SearchResultsCellIdentifier";
	
	SearchResultCell *cell = (SearchResultCell *)[aTableView dequeueReusableCellWithIdentifier:SearchResultsCellIdentifier];
	
	if(!cell)
		cell = [[[SearchResultCell alloc]initWithFrame:CGRectZero reuseIdentifier:SearchResultsCellIdentifier]autorelease];
	
	NSDictionary *result = [self.searchResults objectAtIndex:indexPath.row] ;
	
	//a single result has an array of people for that address. Each person has a dictionary with keys @"firstname", @"lastname", @"middlename", and @"rank"
	NSArray *peopleDictionries = [result objectForKey:@"people"];
	NSString *cellDisplayName = [self displayNameForPeopleDictionaries:peopleDictionries];
	if(!cellDisplayName || [cellDisplayName isEqualToString:@""])
	{
		//if there is no name, look to see if there is a buisiness name insted
		cellDisplayName = [[result objectForKey:@"business"]objectForKey:@"businessname"];
		
		if(!cellDisplayName || [cellDisplayName isEqualToString:@""])
		{
			//still nothing? Try the phone number.
			cellDisplayName = [[[result objectForKey:@"phonenumbers"]objectAtIndex:0]objectForKey:@"fullphone"];
			
			if(!cellDisplayName || [cellDisplayName isEqualToString:@""])
			{
				//um, well it is a pretty worthless result, but by this point it is too late to get rid of it. Display a generic name
				cellDisplayName = @"Unknown Name";
			}
		}
	}
	
	cell.name = cellDisplayName;
	
	NSString *displayAddress = [[result objectForKey:@"address"]objectForKey:@"fullstreet"];
	if(!displayAddress || [displayAddress isEqualToString:@""])
	{
		//no street address? Try the city
		displayAddress = [[result objectForKey:@"address"]objectForKey:@"city"];
		
		if(!displayAddress || [displayAddress isEqualToString:@""])
		{
			//oh well
			displayAddress = @"";
		}
	}

	cell.streetAddress = displayAddress;
	
	NSString *latitude = [[result objectForKey:@"geodata"]objectForKey:@"latitude"];
	NSString *longitude = [[result objectForKey:@"geodata"]objectForKey:@"longitude"];
	NSInteger geoprecision = [[[result objectForKey:@"geodata"]objectForKey:@"geoprecision"]integerValue]; //the accuracy of the returned lat lon. Greater than 2 is 200-500 houses, and therefore useless for displaying the distance
	if(latitude && longitude && geoprecision <= 2)
	{
		cell.location = [[[CCLocation alloc]initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]]autorelease];
	}
	
	
	return cell;
}
- (NSString *)displayNameForPeopleDictionaries:(NSArray *)people;
{
	NSMutableString *peopleDisplayName = [NSMutableString string];
	
	if([people count] == 0)
		return nil; //no people? this should not happen. FIXME: check for this and get rid of the result in  WhitePagesRequestController
	
	NSDictionary *person = [people objectAtIndex:0];
	
	NSString *firstName = [person objectForKey:@"firstname"];
	NSString *middleName = [person objectForKey:@"middlename"];
	NSString *lastName = [person objectForKey:@"lastname"];
	if(firstName && ![firstName isEqualToString:@""])
		[peopleDisplayName appendFormat:@"%@ ",firstName];
	
	if(middleName && ![middleName isEqualToString:@""])
		[peopleDisplayName appendFormat:@"%@ ",middleName];
	
	if(lastName && ![lastName isEqualToString:@""])
		[peopleDisplayName appendFormat:@"%@ ",lastName];	
	
	
	/*
	if([people count] == 2)//if there are two people, we will display both names (without their middle name to save space)
	{
		NSDictionary *firstPerson = [people objectAtIndex:0];
		NSDictionary *secondPerson = [people objectAtIndex:1];
		
		if([[firstPerson objectForKey:@"lastname"]isEqualToString:[secondPerson objectForKey:@"lastname"]] && //last names match
		   [firstPerson objectForKey:@"lastname"] && ![[firstPerson objectForKey:@"lastname"] isEqualToString:@""] && //but they didnt match because they were both nil or empty
		   [firstPerson objectForKey:@"firstname"] && ![[firstPerson objectForKey:@"firstname"] isEqualToString:@""] && //and the first person has a first name
		   [secondPerson objectForKey:@"firstname"] && ![[secondPerson objectForKey:@"firstname"] isEqualToString:@""]) //and the second person has a first name
		{
			//if the two people have matching last names (as should be fairly common for many resident addresses), and both have first names availiable
			//display the name as "FirstPersonFirstName & SecondPersonFirstName SharedLastName"
			[peopleDisplayName appendFormat:@"%@ & %@ %@",[firstPerson objectForKey:@"firstname"], [secondPerson objectForKey:@"firstname"], [firstPerson objectForKey:@"lastname"]];
		}
		else
		{
			//otherwise, just display the names as: "FirstPersonFirstName FirstPersonLastName & SecondPersonFirstName SecondPersonLastName
			if([firstPerson objectForKey:@"firstname"] && ![[firstPerson objectForKey:@"firstname"] isEqualToString:@""])
				[peopleDisplayName appendFormat:@"%@ ",[firstPerson objectForKey:@"firstname"]];
			
			if([firstPerson objectForKey:@"lastname"] && ![[firstPerson objectForKey:@"lastname"] isEqualToString:@""])
				[peopleDisplayName appendFormat:@"%@ & ",[firstPerson objectForKey:@"lastname"]];
			
			if([secondPerson objectForKey:@"firstname"] && ![[secondPerson objectForKey:@"firstname"] isEqualToString:@""])
				[peopleDisplayName appendFormat:@"%@ ",[secondPerson objectForKey:@"firstname"]];
			
			if([secondPerson objectForKey:@"lastname"] && ![[secondPerson objectForKey:@"lastname"] isEqualToString:@""])
				[peopleDisplayName appendFormat:@"%@",[secondPerson objectForKey:@"lastname"]];
		}
	}
	
	else //if there is one or more than 2 people, we only display one full name. If there are more than 2, we will also add "and n more"
	{
		NSDictionary *person = [people objectAtIndex:0];
		
		NSString *firstName = [person objectForKey:@"firstname"];
		NSString *middleName = [person objectForKey:@"middlename"];
		NSString *lastName = [person objectForKey:@"lastname"];
		if(firstName && ![firstName isEqualToString:@""])
			[peopleDisplayName appendFormat:@"%@ ",firstName];
		
		if(middleName && ![middleName isEqualToString:@""])
			[peopleDisplayName appendFormat:@"%@ ",middleName];
		
		if(lastName && ![lastName isEqualToString:@""])
			[peopleDisplayName appendFormat:@"%@ ",lastName];
		
		if([people count] > 2)
			[peopleDisplayName appendFormat:@"and %i more", [people count] - 1];
	}
	*/
	return peopleDisplayName;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[aTableView deselectRowAtIndexPath:indexPath animated:YES]; //do not maintain selection
	
	if([self.searchResults count] == 0)
		return; //user probably selected a "No Results" cell. Just ignore it.
	
	if(indexPath.row == [self.searchResults count])
	{
		//user clicked on the WhitePage attribution cell
		//if there are more results, open the results page
		//otherwise, open the home page (which has a special URL)
		
		NSString *moreResultsURLAsString = [[[self.metadata objectForKey:@"searchlinks"]objectForKey:@"allresults"]objectForKey:@"url"];
		NSString *homePageURLAsString = [[[self.metadata objectForKey:@"searchlinks"]objectForKey:@"homepage"]objectForKey:@"url"];
		if(moreResultsURLAsString)
		{
			[[UIApplication sharedApplication]openURL:[NSURL URLWithString:moreResultsURLAsString]];
		}
		else if(homePageURLAsString)
		{
			[[UIApplication sharedApplication]openURL:[NSURL URLWithString:homePageURLAsString]];
		}
		return;
	}
	NSDictionary *selectedResult = [self.searchResults objectAtIndex:indexPath.row];
	
	[self.resultsController displayResult:selectedResult withAnimation:YES];
	
}

- (void)setSearchResults:(NSArray *)theSearchResults
{
	//create this setter ourselves (don't use the property) so we can reload the table when the categories change
	[searchResults release];
	searchResults = [theSearchResults retain];
}

- (void) dealloc
{
	[searchResults release];
	[super dealloc];
}


@end
