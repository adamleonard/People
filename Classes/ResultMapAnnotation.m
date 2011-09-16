//
//  ResultMapAnnotation.m
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

#import "ResultMapAnnotation.h"

@implementation ResultMapAnnotation

@synthesize result;

- (id)initWithResult:(NSDictionary *)aResult
{
	self = [super init];
	if (self != nil) 
	{
		self.result = aResult;
		
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@: Title: %@ Subtitle: %@ Lat:%f Lon:%f",[super description],self.title,self.subtitle,self.coordinate.latitude,self.coordinate.longitude];
}

- (void)setResult:(NSDictionary *)aResult
{
	[aResult retain];
	[self.result release];
	result = aResult;
		
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
	
	[title release];
	title = [cellDisplayName retain];
	
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
	
	[subtitle release];
	subtitle = [displayAddress retain];
	
	NSString *latitude = [[result objectForKey:@"geodata"]objectForKey:@"latitude"];
	NSString *longitude = [[result objectForKey:@"geodata"]objectForKey:@"longitude"];
	
	
	coordinate = (CLLocationCoordinate2D) { [latitude floatValue], [longitude floatValue] };
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

- (NSString *)title
{
	return title;
}
- (NSString *)subtitle
{
	return subtitle;
}


- (CLLocationCoordinate2D)coordinate
{
	return coordinate;
}

- (void) dealloc
{
	[title release];
	[subtitle release];
	[result release];
	[super dealloc];
}


@end
