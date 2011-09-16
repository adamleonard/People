//
//  TextFieldTableViewCell.m
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

#import "TextFieldTableViewCell.h"
#import "CCTextField.h"

@implementation TextFieldTableViewCell

@synthesize textField;
@synthesize label, longestLabelInTable;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier 
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
		self.selectionStyle = UITableViewCellSelectionStyleNone; //cannot select this cell
		
		
		CGRect frame = CGRectMake(0.0, 9.0, 100.0, 22.0);
		textField = [[CCTextField alloc] initWithFrame:frame];
		
		textField.borderStyle = UITextBorderStyleNone;
		textField.textColor = [UIColor blackColor];
		textField.font = [UIFont systemFontOfSize:17.0];
		textField.backgroundColor = [UIColor clearColor];
		textField.returnKeyType = UIReturnKeyDone;
		textField.autocorrectionType = UITextAutocorrectionTypeNo;
		textField.clearButtonMode = UITextFieldViewModeAlways;
		
		[[NSNotificationCenter defaultCenter]addObserver:self
												selector:@selector(stopEditingTextField)
													name:@"CCStopEditingSearchTextFields"
												  object:nil];
		
		
		self.accessoryView = textField;
		
	}
	return self;
}

- (void)stopEditingTextField
{
	if(self.textField.editing)
	{
		[self.textField resignFirstResponder];
	}
}

- (void)setLabel:(NSString *)theLabel
{
	[theLabel retain];
	[label release];
	label = theLabel;
	
	self.textLabel.text = label;
}
- (void)setLongestLabelInTable:(NSString *)theLongestLabel;
{
	[theLongestLabel retain];
	[longestLabelInTable release];
	longestLabelInTable = theLongestLabel;
	
	CGSize neededLabelSize = [longestLabelInTable sizeWithFont:self.font];
		
	
	CGRect newTextFieldFrame = [textField frame];
	newTextFieldFrame.size.width = self.frame.size.width - neededLabelSize.width - 48.0 - 3.0;
	
	[textField setFrame:newTextFieldFrame];
	
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	//[self.accessoryView becomeFirstResponder];
}

- (void)dealloc 
{
	[textField release];
	[label release];
	[longestLabelInTable release];
	[[NSNotificationCenter defaultCenter]removeObserver:self];
	[super dealloc];
}


@end
