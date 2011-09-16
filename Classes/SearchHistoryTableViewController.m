//
//  SearchHistoryTableViewController.m
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

#import "SearchHistoryTableViewController.h"
#import "SearchHistoryController.h"
#import "WhitePagesRequestController.h"
#import "PeopleAppDelegate.h"
#import "SearchViewController.h"

@implementation SearchHistoryTableViewController


- (id)initWithStyle:(UITableViewStyle)style {
	if (self = [super initWithStyle:style]) 
	{
		searchHistoryController = [SearchHistoryController sharedController];
		
		self.title = @"Recent Searches";
		self.tabBarItem = [[[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemRecents tag:0]autorelease];
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(clear:)]autorelease];
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	//since other tabs add search history items, reload the data each time this tab is selected
	[self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [searchHistoryController.searchHistory count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *SearchHistoryCellIdentifer = @"SearchHistoryCellIdentifer";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SearchHistoryCellIdentifer];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:SearchHistoryCellIdentifer] autorelease];
	}
	
	cell.text = [[searchHistoryController.searchHistory objectAtIndex:indexPath.row]objectForKey:@"title"];
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES]; //do not maintain selection
	
	NSDictionary *selectedSearchHistoryItem = [searchHistoryController.searchHistory objectAtIndex:indexPath.row];
	
	//ask the searchViewController to begin the search with this URL and switch to that tab.
	
	PeopleAppDelegate *appDelegate = (PeopleAppDelegate *)[UIApplication sharedApplication].delegate;
	SearchViewController *searchViewController = appDelegate.searchViewController;

	[searchViewController showSearchFieldsTableWithAnimation:NO];
	
	[searchViewController beginWhitePagesSearchWithSearchType:[[selectedSearchHistoryItem objectForKey:@"searchType"]integerValue] 
									 searchDisplayDescription:[selectedSearchHistoryItem objectForKey:@"title"]
												   APICallURL:[NSURL URLWithString:[selectedSearchHistoryItem objectForKey:@"URL"]]
												withAnimation:NO];
	
	//note: the search will automatically be moved to the top of the search history list
	
	self.tabBarController.selectedViewController = searchViewController.navigationController;
	
}

- (void)clear:(id)sender
{
	UIActionSheet *confirmClearSheet = [[UIActionSheet alloc]initWithTitle:nil 
																  delegate:self
														 cancelButtonTitle:@"Cancel"
													destructiveButtonTitle:@"Clear Recent Searches"
														 otherButtonTitles:nil];
	[confirmClearSheet showInView:(UITabBar *)self.tabBarController.view];
	[confirmClearSheet release];
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == 0)
	{
		[searchHistoryController clearSearchHistory];
		[self.tableView reloadData];
	}
}

- (void)dealloc {
	[super dealloc];
}



@end

