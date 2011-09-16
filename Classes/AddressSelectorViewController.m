//
//  AddressSelectorViewController.m
//  People
//
//  Created by Adam Leonard on 6/3/09.
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

#import "AddressSelectorViewController.h"
#import "TextFieldTableViewCell.h"
#import "CCTextField.h"

@implementation AddressSelectorViewController
@synthesize delegate;
@synthesize streetAddress;
@synthesize location;


- (id)initWithStyle:(UITableViewStyle)style {
	if (self = [super initWithStyle:style]) 
	{
		self.title = @"Edit Address";
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)]autorelease];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)]autorelease];
		
		self.streetAddress = @"";
		self.location = @"";
	}
	return self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	TextFieldTableViewCell *cell = [[[TextFieldTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:nil] autorelease];
	
	cell.textField.keyboardType = UIKeyboardTypeDefault;
	cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
	
	cell.label = @"";
	cell.textField.text = @"";
	cell.longestLabelInTable = @"";
		
	if (indexPath.row == 0)
	{
		cell.textField.placeholder = @"Street Address";
		cell.textField.text = streetAddress;
		cell.textField.returnKeyType = UIReturnKeyDefault;
	}
	else if (indexPath.row == 1)
	{
		cell.textField.placeholder = @"City, State & Zip";
		cell.textField.text = location;
		cell.textField.returnKeyType = UIReturnKeyDone; //this is the last field
		[cell.textField addTarget:self action:@selector(done:) forControlEvents:UIControlEventEditingDidEndOnExit];
	}
		


	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES]; //do not maintain selection
	
}
- (NSString *)streetAddress
{
	return ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).textField.text;
}
- (void)setStreetAddress:(NSString *)newAddress
{
	[newAddress retain];
	[streetAddress release];
	streetAddress = newAddress;
	((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).textField.text = newAddress;
}

- (NSString *)location
{
	return ((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]]).textField.text;
}

- (void)setLocation:(NSString *)newLocation
{
	[newLocation retain];
	[location release];
	location = newLocation;
	((TextFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]]).textField.text = newLocation;
}


- (void)done:(id)sender
{
	if(self.delegate)
		[delegate addressSelectorDidEnd:self];
}

- (void)cancel:(id)sender
{
	if(self.delegate)
		[delegate addressSelectorDidCancel:self];
}



- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc 
{
	[streetAddress release];
	[location release];
    [super dealloc];
}


@end
