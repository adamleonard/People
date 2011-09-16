//
//  GeonamesRequestController.m
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

#import "ReverseGeocodingRequestController.h"
#import "CCLocation.h"
#import "NSString+SBJSON.h"
#import "ReverseGeocodingRequestDelegateProtocol.h"
#import "AddressParser.h"

#define GOOGLE_MAPS_API_KEY @"ABQIAAAA6WiYMG4IKEK_67fS_OU0GRRsTXvIk3L6zr-eJi1Qkz35vhLuixSJlWG6HNYc3Tx3L4A1H5gddf7YZQ"

@implementation ReverseGeocodingRequestController

@synthesize location;
@synthesize delegate;

- (id)initWithLocation:(CCLocation *)aLocation delegate:(NSObject <ReverseGeocodingRequestDelegate> *)aDelegate;
{
	self = [super init];
	if (self != nil) 
	{
		if(!aLocation || !aLocation.coordinate.latitude || !aLocation.coordinate.longitude)
		{
			NSException *exception = [NSException exceptionWithName:@"CCReverseGeocodingRequestNoLocationException"
															 reason:@"ReverseGeocodingRequestController requires that aLocation not be nil or empty to perform search"
														   userInfo:nil];
			[exception raise];
			
			return nil;

		}
		
		self.delegate = aDelegate;
		self.location = aLocation;
	}
	return self;
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark
{
	NSLog(@"Placemark: %@",[placemark addressDictionary]);
}

- (void)findCityStateAndZip;
{
	[self retain];
	/*
	MKReverseGeocoder *geocoder = [[MKReverseGeocoder alloc]initWithCoordinate:self.location.coordinate];
	[geocoder setDelegate:self];
	
	NSLog(@"START");
	[geocoder start];
	 */
	
	
	NSMutableString *requestURLAsString = [NSMutableString stringWithString:@"http://maps.google.com/maps/geo"];
	[requestURLAsString appendFormat:@"?q=%f,%f",self.location.coordinate.latitude,self.location.coordinate.longitude];
	[requestURLAsString appendString:@"&sensor=true"]; //used the GPS sensor to get lat lon for this request
	[requestURLAsString appendString:@"&output=json"];
	[requestURLAsString appendString:@"&oe=utf8"];
	[requestURLAsString appendFormat:@"&key=%@",GOOGLE_MAPS_API_KEY];
	
	
	NSURL *requestURL = [NSURL URLWithString:[requestURLAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
	_currentDownloadData = [[NSMutableData alloc]init];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:requestURL
											 cachePolicy:NSURLRequestUseProtocolCachePolicy
										 timeoutInterval:60.0];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES; //show the progress indicator-like view in the status bar to indicate the network is being used
	
	[NSURLConnection connectionWithRequest:request delegate:self];
	 
}

- (void)findNearestAddress;
{
	[self findCityStateAndZip];
}	


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	[_currentDownloadData appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{		
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO; 
	
	if(!delegate) //hmm, well no one seems to care we are done. Don't do any work
		return;
	
	
	NSString *JSONDataAsString = [[[NSString alloc]initWithData:_currentDownloadData encoding:NSUTF8StringEncoding]autorelease];
	
	NSDictionary *response = [JSONDataAsString JSONValue];
	
	
	//the root structure of the returned dictionary should have a @"message" dictionary, and if there are results and no errors, a @"businesses" array with the results
	
	//NSLog(@"Results: %@",results);
	
	NSDictionary *status = [response objectForKey:@"Status"];
	if([[status objectForKey:@"code"]integerValue] != 200) //it returned an error
	{
		NSString *errorUserInfo = @"Unknown Error";
		if([status objectForKey:@"message"])
			errorUserInfo = [status objectForKey:@"message"];
		
		NSLog(@"***Error from Google Maps api retrieving results: %@ code: %i ***",errorUserInfo, [[status objectForKey:@"code"]integerValue]);
		
		if(self.delegate && [self.delegate respondsToSelector:@selector(geonamesRequestController:failedWithError:)]) //tell the delegate about the error
		{
			NSError *error = [NSError errorWithDomain:@"CCGoogleMapsErrorDomain" 
												 code:[[status objectForKey:@"code"]integerValue] 
											 userInfo:[NSDictionary dictionaryWithObject:errorUserInfo forKey:NSLocalizedDescriptionKey]];
			
			
			[delegate reverseGeocodingRequestController:self failedWithError:error];
		}
	}
	else
	{
		//We are only interested in the best reverse geocode, so only look at the first result
		NSString *fullAddressString = [[[response objectForKey:@"Placemark"]objectAtIndex:0]objectForKey:@"address"];
		NSDictionary *untamedAddressDictionary = [[[[[response objectForKey:@"Placemark"]objectAtIndex:0]objectForKey:@"AddressDetails"]objectForKey:@"Country"]objectForKey:@"AdministrativeArea"];
		
		NSDictionary *locality = [untamedAddressDictionary objectForKey:@"Locality"];
		if(!locality)
			locality = [[untamedAddressDictionary objectForKey:@"SubAdministrativeArea"]objectForKey:@"Locality"];
		
		NSString *state = [untamedAddressDictionary objectForKey:@"AdministrativeAreaName"];
		NSString *city = [locality objectForKey:@"LocalityName"];
		if(!city)
			city = [untamedAddressDictionary objectForKey:@"LocalityName"];
		NSString *zip = [[locality objectForKey:@"PostalCode"] objectForKey:@"PostalCodeNumber"];
		if(!zip)
			zip = [[untamedAddressDictionary objectForKey:@"PostalCode"] objectForKey:@"PostalCodeNumber"];
		
		NSString *unparsedStreetAddress = [[locality objectForKey:@"Thoroughfare"] objectForKey:@"ThoroughfareName"];
		NSDictionary *parsedAddressDictionary = [[AddressParser sharedParser]parseStreetAddress:unparsedStreetAddress];
		
		NSString *street = [parsedAddressDictionary objectForKey:@"street"];
		
		NSString *house = [parsedAddressDictionary objectForKey:@"house"];
		//Google will sometimes give us a range of house numbers in the form "xxx-xxx" to indicate the margin of error.
		//If that happens, take a good guess and select the house number in the middle (average)
		NSArray *houseRangeBounds = [house componentsSeparatedByString:@"-"];
		if([houseRangeBounds count] == 2)
		{
			NSInteger lowerBound = [[houseRangeBounds objectAtIndex:0]integerValue];
			NSInteger upperBound = [[houseRangeBounds objectAtIndex:1]integerValue];
			house = [[NSNumber numberWithInteger:((lowerBound + upperBound) / (NSInteger)2)]stringValue];
		}
		
				
		NSMutableDictionary *addressDictionary = [NSMutableDictionary dictionaryWithCapacity:10];
		
		if(state)
			[addressDictionary setObject:state forKey:@"state"];
		if(city)
			[addressDictionary setObject:city forKey:@"city"];
		if(zip)
			[addressDictionary setObject:zip forKey:@"zip"];
		if(street)
			[addressDictionary setObject:street forKey:@"street"];
		if(house)
			[addressDictionary setObject:house forKey:@"house"];
		
		
		[delegate reverseGeocodingRequestController:self retrievedAddress:fullAddressString addressComponents:addressDictionary];
		
	}
	
	
	[self autorelease];
	
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	NSLog(@"*** Download failed with error: %@ ***",error);
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if(self.delegate && [self.delegate respondsToSelector:@selector(reverseGeocodingRequestController:failedWithError:)]) //tell the delegate about the error
	{
		[delegate reverseGeocodingRequestController:self failedWithError:error];
	}
	
	[self autorelease];
	
}

- (void) dealloc
{
	[self.location release];
	[_currentDownloadData release];
	[super dealloc];
}



@end
