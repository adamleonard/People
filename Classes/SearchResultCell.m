//
//  SearchResultCell.m
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

#import "SearchResultCell.h"
#import "SearchResultCellView.h"
#import "CCLocation.h"

@implementation SearchResultCell

@synthesize name, streetAddress;
@synthesize location;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
		resultView = [[SearchResultCellView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height)];
		resultView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		[self.contentView addSubview:resultView];
	}
	return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
}

- (void)setName:(NSString *)aName
{
	[aName retain];
	[self.name release];
	name = aName;
	
	resultView.name = self.name;
	[resultView setNeedsDisplay];
}
- (void)setStreetAddress:(NSString *)anAddress
{
	[anAddress retain];
	[self.streetAddress release];
	streetAddress = anAddress;
	
	resultView.streetAddress = self.streetAddress;
	[resultView setNeedsDisplay];
}
- (void)setLocation:(CCLocation *)aLocation
{
	[aLocation retain];
	[self.location release];
	location = aLocation;
	
	resultView.location = self.location;
	[resultView setNeedsDisplay];
}

- (void)dealloc
{
	[resultView release];
	[self.name release];
	[self.streetAddress release];
	[self.location release];
	[super dealloc];
}


@end
