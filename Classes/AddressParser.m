//
//  AddressParser.m
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

#import "AddressParser.h"


@implementation AddressParser

static AddressParser *CCSharedAddressParser;

+ (AddressParser *)sharedParser;
{
	@synchronized(self) 
	{
        if (CCSharedAddressParser == nil)
		{
            CCSharedAddressParser = [[self alloc] init];
		}
    }
    return CCSharedAddressParser;
}
- (NSDictionary *)parseStreetAddress:(NSString *)inputString;
{
	//again, no online c implementation, very US specific.
	//We will extract the house number and street. The house number is always first for a correct address, although it can be complicated
	//For example in "123 82nd st." "123 is the house number, "82nd st." is the street
	//Or "123 1/2 82nd st." "123 1/2" is the house number "82nd st." is the street
	//Luckily the API does not require to extract parts of the street ("82nd" "st"). It will parse that for us.
	
	NSString *house = nil;
	NSString *street = nil;

	// break the string up into components separated by spaces and inspect them one by one
	NSArray *components = [inputString componentsSeparatedByString:@" "];
	
	BOOL foundFirstNonEmptyComponent = NO;
	NSInteger indexOfFirstHouseComponent = NSNotFound;
	NSInteger i = 0;
	for(NSString *aComponent in components)
	{
		if([aComponent length] == 0)
		{
			i++;
			continue; //extra space, ignore this component
		}
		
		if(!foundFirstNonEmptyComponent || i == indexOfFirstHouseComponent + 1) //if we are at the first component, or the first component that is not just a space, or this component is right after the first house component
		{
			foundFirstNonEmptyComponent = YES;
			
			//this should be part of the house number for any valid US address
			//However, the string may not have a house number and instead only have a street
			//So, check if every character is not a letter. This will prevent us from thinking "Main" or "82nd" is a house number. 
			//Note that some house numbers have punctuation, like "123.5"
			//Note also that some house numbers can have spaces, like "123 1/2". that is what the indexOfFirstHouseComponent + 1 is for; to check the next component. I don't think any house number should be more than 2 words
			//FIXME: this will still cause the "82" in an input string like "82 nd st." or just "82 st." to be thought to be the house number
		
			NSCharacterSet *houseNumberCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"1234567890-+/."];
			
			BOOL foundNonMatchingCharacter = NO;
			for(NSUInteger i = 0; i < [aComponent length]; i++)
			{
				if(![houseNumberCharacterSet characterIsMember:[aComponent characterAtIndex:i]])
				{
					//there is a character that should not be in a house number. It is probably not part of the house number
					foundNonMatchingCharacter = YES;
					break;
				}
			}
			
			if(!foundNonMatchingCharacter) //if every character was in the set, it is probably a good house number
			{
				if(house)
				{
					house = [house stringByAppendingFormat:@" %@",aComponent]; //the 2nd part of the house number
				}
				else
				{
					house = aComponent;
					indexOfFirstHouseComponent = i;
				}
				i++;
				continue; //and we are done with this component
			}
		}
		
		//if we are here, this component is not part of the house number
		//We just have to assume it is part of the street
		
		if(street)
			street = [street stringByAppendingFormat:@" %@",aComponent];
		
		else
			street = aComponent;
		
		i++;
	}
	
	//NSLog(@"Parsed string: \"%@\" and found house number: \"%@\" street: \"%@\"",inputString,house,street);
	
	NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionaryWithCapacity:2];
	
	if(house)
		[resultDictionary setObject:house forKey:@"house"];
	
	if(street)
		[resultDictionary setObject:street forKey:@"street"];
	
	
	return resultDictionary;
}
	
		
	
- (NSDictionary *)parseCombinedCityStateAndZipString:(NSString *)inputString;
{
	//my own parser implememtaion because I could not find one online
	//this is very specific to US addresses (but whatever, that is all the White Pages API supports)
	
	NSString *city = nil;
	NSString *state = nil;
	NSString *zip = nil;
	
	//first get rid of all commas and replace them with spaces (in case the user did not enter a space after a comma)
	inputString = [inputString stringByReplacingOccurrencesOfString:@"," withString:@" "];
	
	//next, break the string up into components separated by spaces and inspect them one by one
	NSArray *components = [inputString componentsSeparatedByString:@" "];
	
	 
	NSArray *states = [@"AL AK AS AZ AR CA CO CT DE DC FM FL GA GU HI ID IL IN IA KS KY LA ME MH MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND MP OH OK OR PW PA PR RI SC SD TN TX UT VT VI VA WA WV WI WY AE AA AE AE AE AP" componentsSeparatedByString:@" "];
	
	for(NSString *aComponent in components)
	{
		if([aComponent length] == 0)
			continue; //extra space, probably from replacing a comma with another space
		
		if([aComponent length] == 2)
		{
			//this is likely to be a state abreviation. Check
			
			NSString *potentialStateAsUppercase =[aComponent uppercaseString];
			
			for(NSString *aState in states)
			{
				if([aState isEqualToString:potentialStateAsUppercase])
				{
					//yup, it is a state
					state = potentialStateAsUppercase;
					break;
				}
			}
			
			if(state)
				continue; //we are done with this component
		}
		
		if([aComponent length] == 5 || [aComponent length] == 9 || [aComponent length] == 10)
		{
			//likely to be a zip code. Either the short 5 digit version, the full 9 digit version, or the most correct 5-4 version
			NSCharacterSet *zipCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"1234567890-+/"];
			
			BOOL foundNonMatchingCharacter = NO;
			for(NSUInteger i = 0; i < [aComponent length]; i++)
			{
				if(![zipCharacterSet characterIsMember:[aComponent characterAtIndex:i]])
				{
					//there is a character that should not be in a zip code. It is probably not a zip code.
					foundNonMatchingCharacter = YES;
					break;
				}
			}
			
			if(!foundNonMatchingCharacter) //if every character was in the set, it is probably a good zip code
			{
				zip = aComponent;
				continue; //and we are done with this component
			}
		}
		
		//if we are here, the component is not a state or zip code. Let's assume it is a city
		
		//one thing to check though. I dont think any city has a number in its name. If a component has a number (and it was not a zip) just get rid of it
		NSCharacterSet *numberCharacterSet = [NSCharacterSet decimalDigitCharacterSet];
		
		BOOL foundNumberInCity = NO;
		for(NSUInteger i = 0; i < [aComponent length]; i++)
		{
			if([numberCharacterSet characterIsMember:[aComponent characterAtIndex:i]])
			{
				//there is a number in this component. It cannot be part of the city's name
				foundNumberInCity = YES;
				break;
			}
		}
		
		if(foundNumberInCity) 
			continue; //just throw this component out
		
		
		//otherwise, there is no other checking we can do easily. Assume it is part of a city name
		
		if(!city)
			city = aComponent;
		else 	//cities can of course be multiple words, so append it to our current city string
			city = [city stringByAppendingFormat:@" %@",aComponent]; //don't forget the space
	}
	
	//NSLog(@"Parsed string: \"%@\" and found city: \"%@\" state: \"%@\" zip:\"%@\"",inputString,city,state,zip);
	
	NSMutableDictionary *resultDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	
	if(city)
		[resultDictionary setObject:city forKey:@"city"];
	
	if(state)
		[resultDictionary setObject:state forKey:@"state"];
	
	if(zip)
		[resultDictionary setObject:zip forKey:@"zip"];
	
	return resultDictionary;
}

@end
