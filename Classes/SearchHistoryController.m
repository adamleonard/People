//
//  SearchHistoryController.m
//  People
//
//  Created by Adam Leonard on 7/2/08.
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

#import "SearchHistoryController.h"


@implementation SearchHistoryController

static SearchHistoryController *CCSharedSearchHistoryController;

+(SearchHistoryController *)sharedController;
{
	@synchronized(self) 
	{
        if (CCSharedSearchHistoryController == nil)
		{
            CCSharedSearchHistoryController = [[self alloc] init];
		}
    }
    return CCSharedSearchHistoryController;
}

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		[[NSUserDefaults standardUserDefaults]registerDefaults:[NSDictionary dictionaryWithObject:[NSArray array] forKey:@"searchHistory"]];
	}
	return self;
}

- (NSArray *)searchHistory
{
	return [[NSUserDefaults standardUserDefaults]objectForKey:@"searchHistory"];
}

- (void)addItemWithSearchType:(NSInteger)whitePagesSearchType
						title:(NSString *)title
				   APICallURL:(NSURL *)URL;
{
	if(!title || !URL)
	{
		NSLog(@"Search History -addItemWithSearchType missing parameter. ignoring call.");
		return;
	}
	
	NSMutableArray *searchHistoryAsMutable = [[self.searchHistory mutableCopy]autorelease];
	
	//first see if there is another history item already in the array that is idenfical to the one we are adding.
	//If there is, remove it from its old index. It will then be added to the top of the list
	for(NSUInteger i = 0; i < [searchHistoryAsMutable count]; i++)
	{
		if([[[searchHistoryAsMutable objectAtIndex:i] objectForKey:@"URL"]isEqualToString:[URL absoluteString]]) //if the API calls are the same, they must be for the same search
		{
			[searchHistoryAsMutable removeObjectAtIndex:i];
			break;
		}
	}
	
	[searchHistoryAsMutable insertObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:whitePagesSearchType],@"searchType",title,@"title",[URL absoluteString],@"URL",nil]
								 atIndex:0]; //add it to the top of the list since it is the most recent (FIFO)
	
	if([searchHistoryAsMutable count] > 15)
		[searchHistoryAsMutable removeObjectAtIndex:15]; //delete the oldest one so there will never be more than 15 items
	
	[[NSUserDefaults standardUserDefaults]setObject:searchHistoryAsMutable forKey:@"searchHistory"];
}

- (void)clearSearchHistory;
{
	[[NSUserDefaults standardUserDefaults]setObject:[NSArray array] forKey:@"searchHistory"];
}
@end
