//
//  WhitePagesRequestController.m
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

#import "WhitePagesRequestController.h"
#import "NSString+SBJSON.h"
#import "WhitePagesConstants.h"
#import "SearchHistoryController.h"

@interface WhitePagesRequestController (PRIVATE)
- (id)initWithDelegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate
			searchType:(int)aSearchType
searchDisplayDescription:(NSString *)aSearchDescription;

- (id)initWithSearchType:(int)aSearchType
			  APICallURL:(NSURL *)URL
searchDisplayDescription:(NSString *)aSearchDescription
				delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;

- (id)initForNameSearchWithFirstName:(NSString *)firstName
							lastName:(NSString *)lastName
								city:(NSString *)city
							   state:(NSString *)state
								 zip:(NSString *)zip
			searchDisplayDescription:(NSString *)aSearchDescription
							delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;

- (id)initForReverseAddressSearchWithHouse:(NSString *)house
									street:(NSString *)street
									  city:(NSString *)city
									 state:(NSString *)state
									   zip:(NSString *)zip
				  searchDisplayDescription:(NSString *)aSearchDescription
								  delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;

- (id)initForReversePhoneSearchWithPhoneNumber:(NSString *)phoneNumber
					  searchDisplayDescription:(NSString *)aSearchDescription
									  delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;

@end

@implementation WhitePagesRequestController

@synthesize delegate;
@synthesize searchDisplayDescription;
@synthesize savesSearchesToSearchHistory;
@synthesize viewControllerForPicklist;

+ (id)beginSearchWithType:(NSInteger)searchType
			   APICallURL:(NSURL *)URL
 searchDisplayDescription:(NSString *)searchDescription
				 delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;
{
	
	WhitePagesRequestController *controller = [[self alloc]initWithSearchType:searchType
																   APICallURL:URL
													 searchDisplayDescription:searchDescription
																	 delegate:aDelegate];
	
	return controller;
}

+ (id)beginNameSearchWithFirstName:(NSString *)firstName
						  lastName:(NSString *)lastName
							  city:(NSString *)city
							 state:(NSString *)state
							   zip:(NSString *)zip
		  searchDisplayDescription:(NSString *)searchDescription
						  delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;
{
	WhitePagesRequestController *controller = [[self alloc]initForNameSearchWithFirstName:firstName
																				 lastName:lastName
																					 city:city
																					state:state
																					  zip:zip
																 searchDisplayDescription:searchDescription
																				 delegate:aDelegate];
	
	return controller;
}

+ (id)beginReverseAddressSearchWithHouse:(NSString *)house
								  street:(NSString *)street
									city:(NSString *)city
								   state:(NSString *)state
									 zip:(NSString *)zip
				searchDisplayDescription:(NSString *)searchDescription
								delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;
{
	WhitePagesRequestController *controller = [[self alloc]initForReverseAddressSearchWithHouse:house
																						 street:street
																						   city:city
																						  state:state
																							zip:zip
																	   searchDisplayDescription:searchDescription
																					   delegate:aDelegate];

	return controller;
}
+ (id)beginReversePhoneSearchWithPhoneNumber:(NSString *)phoneNumber
					searchDisplayDescription:(NSString *)searchDescription
									delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;
{
	WhitePagesRequestController *controller = [[self alloc]initForReversePhoneSearchWithPhoneNumber:phoneNumber
																		   searchDisplayDescription:searchDescription
																						   delegate:aDelegate];
	
	return controller;
}
- (id)initWithDelegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate
			searchType:(int)aSearchType
searchDisplayDescription:(NSString *)aSearchDescription;
{
	self = [super init];
	if (self != nil)
	{
		self.delegate = aDelegate;
		searchType = aSearchType;
		self.searchDisplayDescription = aSearchDescription;
		self.savesSearchesToSearchHistory = YES;
	}
	return self;
}
- (id)initWithSearchType:(int)aSearchType
			  APICallURL:(NSURL *)URL
searchDisplayDescription:(NSString *)aSearchDescription
				delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;
{
	self = [self initWithDelegate:aDelegate searchType:aSearchType searchDisplayDescription:aSearchDescription];
	if (self != nil)
	{
		if(!URL)
		{
			NSException *exception = [NSException exceptionWithName:@"CCWhitePagesMissingRequiredParameter"
															 reason:@"WhitePagesRequestController requires that URL not be nil to perform search"
														   userInfo:nil];
			[exception raise];
			
			return nil;
		}
		
		_requestURL = [URL retain];

		_currentDownloadData = [[NSMutableData alloc]init];
		
		NSURLRequest *request = [NSURLRequest requestWithURL:_requestURL
												 cachePolicy:NSURLRequestUseProtocolCachePolicy
											 timeoutInterval:60.0];
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES; //show the progress indicator-like view in the status bar to indicate the network is being used
		
		[NSURLConnection connectionWithRequest:request delegate:self];
		
	}
	
	return self;
}
- (id)initForNameSearchWithFirstName:(NSString *)firstName
							lastName:(NSString *)lastName
								city:(NSString *)city
							   state:(NSString *)state
								 zip:(NSString *)zip
			searchDisplayDescription:(NSString *)aSearchDescription
							delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;
{
	self = [self initWithDelegate:aDelegate searchType:CCWhitePagesSearchTypeName searchDisplayDescription:aSearchDescription];
	if (self != nil)
	{
		
		if(!lastName || [lastName isEqualToString:@""])
		{
			NSException *exception = [NSException exceptionWithName:@"CCWhitePagesMissingRequiredParameter"
															 reason:@"WhitePagesRequestController requires that lastName not be nil or empty to perform search"
														   userInfo:nil];
			[exception raise];
			
			return nil;
		}
		
		NSMutableString *requestURLAsMutableString = [NSMutableString stringWithString:WHITE_PAGES_FIND_PERSON_BASE_URL];
		
		[requestURLAsMutableString appendFormat:@"api_key=%@;",WHITE_PAGES_API_KEY];
		
		[requestURLAsMutableString appendString:@"outputtype=JSON;"];
		
		if(firstName && ![firstName isEqualToString:@""])
			[requestURLAsMutableString appendFormat:@"firstname=%@;",firstName];
		
		if(lastName && ![lastName isEqualToString:@""])
			[requestURLAsMutableString appendFormat:@"lastname=%@;",lastName];
		
		if(city && ![city isEqualToString:@""])
			[requestURLAsMutableString appendFormat:@"city=%@;",city];
		
		if(state && ![state isEqualToString:@""])
			[requestURLAsMutableString appendFormat:@"state=%@;",state];
		
		if(zip && ![zip isEqualToString:@""])
			[requestURLAsMutableString appendFormat:@"zip=%@;",zip];
		
		_requestURL = [[NSURL URLWithString:[requestURLAsMutableString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]retain];

		_currentDownloadData = [[NSMutableData alloc]init];
		
		NSURLRequest *request = [NSURLRequest requestWithURL:_requestURL
												 cachePolicy:NSURLRequestUseProtocolCachePolicy
											 timeoutInterval:60.0];
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES; //show the progress indicator-like view in the status bar to indicate the network is being used
		
		[NSURLConnection connectionWithRequest:request delegate:self];
		
		
		
	}
	return self;
}

- (id)initForReverseAddressSearchWithHouse:(NSString *)house
									street:(NSString *)street
									  city:(NSString *)city
									 state:(NSString *)state
									   zip:(NSString *)zip
				  searchDisplayDescription:(NSString *)aSearchDescription
								  delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;
{
	self = [self initWithDelegate:aDelegate searchType:CCWhitePagesSearchTypeReverseAddress searchDisplayDescription:aSearchDescription];
	if (self != nil)
	{
		if((!street || [street isEqualToString:@""]) ||
			((!state || [state isEqualToString:@""]) && (!zip || [zip isEqualToString:@""])))
		{
			NSException *exception = [NSException exceptionWithName:@"CCWhitePagesMissingRequiredParameter"
															 reason:@"WhitePagesRequestController requires that street not be nil or empty, and that either a state or zip is provided to perform search"
														   userInfo:nil];
			[exception raise];
			
			return nil;
		}
		
		NSMutableString *requestURLAsMutableString = [NSMutableString stringWithString:WHITE_PAGES_REVERSE_ADDRESS_BASE_URL];
		
		[requestURLAsMutableString appendFormat:@"api_key=%@;",WHITE_PAGES_API_KEY];
		
		[requestURLAsMutableString appendString:@"outputtype=JSON;"];
		
		if(house && ![house isEqualToString:@""])
			[requestURLAsMutableString appendFormat:@"house=%@;",house];
		
		if(street && ![street isEqualToString:@""])
			[requestURLAsMutableString appendFormat:@"street=%@;",street];
		
		if(city && ![city isEqualToString:@""])
			[requestURLAsMutableString appendFormat:@"city=%@;",city];
		
		if(state && ![state isEqualToString:@""])
			[requestURLAsMutableString appendFormat:@"state=%@;",state];
		
		if(zip && ![zip isEqualToString:@""])
			[requestURLAsMutableString appendFormat:@"zip=%@;",zip];
		
		_requestURL = [[NSURL URLWithString:[requestURLAsMutableString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]retain];

		_currentDownloadData = [[NSMutableData alloc]init];
		
		NSURLRequest *request = [NSURLRequest requestWithURL:_requestURL
												 cachePolicy:NSURLRequestUseProtocolCachePolicy
											 timeoutInterval:60.0];
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES; //show the progress indicator-like view in the status bar to indicate the network is being used
		
		[NSURLConnection connectionWithRequest:request delegate:self];
		
		
	}
	return self;
}
- (id)initForReversePhoneSearchWithPhoneNumber:(NSString *)phoneNumber
					  searchDisplayDescription:(NSString *)aSearchDescription
									  delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;
{
	self = [self initWithDelegate:aDelegate searchType:CCWhitePagesSearchTypeReverseAddress searchDisplayDescription:aSearchDescription];
	if (self != nil)
	{
		if(!phoneNumber || [phoneNumber isEqualToString:@""])
		{
			NSException *exception = [NSException exceptionWithName:@"CCWhitePagesMissingRequiredParameter"
															 reason:@"WhitePagesRequestController requires that phoneNumber not be nil or empty to perform search"
														   userInfo:nil];
			[exception raise];
			
			return nil;
		}
		
		NSMutableString *requestURLAsMutableString = [NSMutableString stringWithString:WHITE_PAGES_REVERSE_PHONE_BASE_URL];
		
		[requestURLAsMutableString appendFormat:@"api_key=%@;",WHITE_PAGES_API_KEY];
		
		[requestURLAsMutableString appendString:@"outputtype=JSON;"];
		
		[requestURLAsMutableString appendFormat:@"phone=%@;",phoneNumber];
		
		_requestURL = [[NSURL URLWithString:[requestURLAsMutableString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]retain];
				
		_currentDownloadData = [[NSMutableData alloc]init];

		NSURLRequest *request = [NSURLRequest requestWithURL:_requestURL
												 cachePolicy:NSURLRequestUseProtocolCachePolicy
											 timeoutInterval:60.0];
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES; //show the progress indicator-like view in the status bar to indicate the network is being used
		
		[NSURLConnection connectionWithRequest:request delegate:self];
		
		
		
	}
	return self;
	
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
	
	
	//_currentDownloadData = [[NSData alloc]initWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"TestData" ofType:@"txt"]];
	
	NSString *JSONDataAsString = [[[NSString alloc]initWithData:_currentDownloadData encoding:NSUTF8StringEncoding]autorelease];
	
	[_currentDownloadData release];
	_currentDownloadData = nil;
	
	NSDictionary *response = [JSONDataAsString JSONValue];
	
	//the root structure of the returned dictionary should have a @"message" dictionary, and if there are results and no errors, a @"businesses" array with the results
	
	if(!response)
	{
		if(self.delegate && [self.delegate respondsToSelector:@selector(whitePagesRequestController:failedWithError:)]) //tell the delegate about the error
		{
			NSError *error = [NSError errorWithDomain:@"CCWhitePagesErrorDomain" 
												 code:-4
											 userInfo:[NSDictionary dictionaryWithObject:@"API Query Limit Exceeded. Try again tomorrow." forKey:NSLocalizedDescriptionKey]];
			
			
			[delegate whitePagesRequestController:self failedWithError:error];
			
			return;
		}
	}		
	
	
	NSDictionary *resultInfo = [response objectForKey:@"result"];
	if([[resultInfo objectForKey:@"type"]isEqualToString:@"error"]) //it returned an error
	{
		if([response objectForKey:@"options"] && self.viewControllerForPicklist)
		{
			//this is a picklist error (http://developer.whitepages.com/docs/Responses/Picklist_Response)
			//We will handle it by presenting a list of possible cities. When the user selects one, we run the new search without getting the delegate involved
			
			PicklistTableViewController *picklistController = [[PicklistTableViewController alloc]initWithStyle:UITableViewStylePlain];
			picklistController.picklist = [response objectForKey:@"options"];
			picklistController.delegate = self;
			UINavigationController *picklistNavigationController = [[UINavigationController alloc]initWithRootViewController:picklistController];
			
			[self.viewControllerForPicklist presentModalViewController:picklistNavigationController animated:YES];
			
			[picklistNavigationController release];
			[picklistController release];
			
			return; //wait for the picklist delegate method
		}
		
		NSString *errorUserInfo = @"An unknown error occured.";
		if([[response objectForKey:@"errors"]objectAtIndex:0])
			errorUserInfo = [[response objectForKey:@"errors"]objectAtIndex:0]; //this is the most user friendly and descriptive error
		else if([resultInfo objectForKey:@"message"])
			errorUserInfo = [resultInfo objectForKey:@"message"];
		else if([resultInfo objectForKey:@"code"])
			errorUserInfo = [resultInfo objectForKey:@"code"]; //if it does not have a message, maybe it has a (less infomrmative, but still English) code
		
		NSLog(@"***Error from White Pages api retrieving results: %@ code: %i ***",errorUserInfo, [resultInfo objectForKey:@"code"]);
		
		if(self.delegate && [self.delegate respondsToSelector:@selector(whitePagesRequestController:failedWithError:)]) //tell the delegate about the error
		{
			NSError *error = [NSError errorWithDomain:@"CCWhitePagesErrorDomain" 
												 code:-1
											 userInfo:[NSDictionary dictionaryWithObject:errorUserInfo forKey:NSLocalizedDescriptionKey]];
			
			
			[delegate whitePagesRequestController:self failedWithError:error];
		}
	}
	else
	{
		//no error, we're good
		NSMutableArray *results = [response objectForKey:@"listings"];
		NSDictionary *metadata = [response objectForKey:@"meta"];
		
		if(self.savesSearchesToSearchHistory)
		{
			[[SearchHistoryController sharedController]addItemWithSearchType:searchType
																	   title:self.searchDisplayDescription
																  APICallURL:_requestURL];
		}
		
		[delegate whitePagesRequestController:self retrievedResults:results metadata:metadata];
	}
	
	
	[self autorelease];
	
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{	
	NSLog(@"*** Download failed with error: %@ ***",error);
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if(self.delegate && [self.delegate respondsToSelector:@selector(whitePagesRequestController:failedWithError:)]) //tell the delegate about the error
	{
		[delegate whitePagesRequestController:self failedWithError:error];
	}
	
	[self autorelease];
	
}

- (void)picklistTableViewController:(PicklistTableViewController *)picklist didResolveToAPIRequestURL:(NSURL *)aRequestURL;
{
	[picklist.navigationController dismissModalViewControllerAnimated:YES];
	
	if(!aRequestURL)
	{
		//the user probably canceled or something. Nothing more we can do, return an error.
		
		if(self.delegate && [self.delegate respondsToSelector:@selector(whitePagesRequestController:failedWithError:)]) //tell the delegate about the error
		{
			NSError *error = [NSError errorWithDomain:@"CCWhitePagesErrorDomain" 
												 code:-2
											 userInfo:[NSDictionary dictionaryWithObject:@"Multiple cities found for location" forKey:NSLocalizedDescriptionKey]];
			
			
			[delegate whitePagesRequestController:self failedWithError:error];
			
			return;
		}
		
	}
	
	//otherwise, start the download with the new call URL
	_currentDownloadData = [[NSMutableData alloc]init];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:aRequestURL
											 cachePolicy:NSURLRequestUseProtocolCachePolicy
										 timeoutInterval:60.0];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES; //show the progress indicator-like view in the status bar to indicate the network is being used
	
	[NSURLConnection connectionWithRequest:request delegate:self];
}

- (void) dealloc
{
	[_currentDownloadData release];
	[self.searchDisplayDescription release];
	[_requestURL release];
	[super dealloc];
}



@end
