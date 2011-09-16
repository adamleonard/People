//
//  CCApplication.m
//  People
//
//  Created by Adam Leonard on 7/3/08.
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

#import "CCApplication.h"


@implementation CCApplication

@synthesize contactLinksDelegate;

- (BOOL)openURL:(NSURL *)url
{
	
	if(contactLinksDelegate)
	{
		//when a White Pages record is tapped in SearchResultsTableViewController, it shows a ABUnknownPersonViewController that displays, among other things, the phone number and address
		//The problem is that, since the people it shows are not in the Address Book, there is a bug in which the links it generates when the address or phone are tapped are wrong and do not work).
		//(Specifically, it attaches "&abPersonID=-1&abAddressID=0" to the URL, which Maps cannot handle)
		//Also, unlike ABPersonViewController, the delegate does not have a personViewController:shouldPerformDefaultActionForPerson:property:identifier: that would allow us to change the URL in a more sane way
		//so, we intercept it here, and ask the SearchResultsTableViewController for the correct URL, which we then load
		//Bug #6054635
	
		NSString *urlAsString = [url absoluteString];
		if([urlAsString hasPrefix:@"maps:"] || [urlAsString hasPrefix:@"http://maps.google"] || [urlAsString hasPrefix:@"http://www.maps.google"])
			url = [contactLinksDelegate urlForAddressOfCurrentContact:url];
		/*else if([urlAsString hasPrefix:@"tel:"])
			url = [contactLinksDelegate urlForPhoneOfCurrentContact:url];*/
	}

	return [super openURL:url];
}
@end
