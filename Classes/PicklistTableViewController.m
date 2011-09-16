//
//  PicklistTableViewController.m
//  People
//
//  Created by Adam Leonard on 7/4/08.
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

#import "PicklistTableViewController.h"


@implementation PicklistTableViewController

@synthesize picklist;
@synthesize delegate;

- (id)initWithStyle:(UITableViewStyle)style {
	if (self = [super initWithStyle:style]) 
	{
		self.title = @"Select City";
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]autorelease];
	}
	return self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.picklist count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *PicklistCellIdentifier = @"PicklistCellIdentifier";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PicklistCellIdentifier];
	if (cell == nil) 
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:PicklistCellIdentifier] autorelease];
	}
	
	NSDictionary *picklistElement = [self.picklist objectAtIndex:indexPath.row];
	
	NSMutableString *title = [NSMutableString string];
	if([picklistElement objectForKey:@"city"])
	{
		[title appendString:[picklistElement objectForKey:@"city"]];
		[title appendString:@" "];
	}
	if([picklistElement objectForKey:@"state"])
	{
		[title appendString:[picklistElement objectForKey:@"state"]];
	}
	
	cell.text = title;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES]; //do not maintain selection
	
	if(self.delegate)
		[delegate picklistTableViewController:self didResolveToAPIRequestURL:[NSURL URLWithString:[[self.picklist objectAtIndex:indexPath.row]objectForKey:@"uri"]]];
}

- (void)cancel:(id)sender
{
	if(self.delegate)
		[delegate picklistTableViewController:self didResolveToAPIRequestURL:nil];
}

- (void)dealloc 
{
	[picklist release];
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


@end

