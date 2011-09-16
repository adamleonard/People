//
//  ViewTableViewCell.m
//  People
//
//  Created by Adam Leonard on 6/29/08.
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

#import "ViewTableViewCell.h"


@implementation ViewTableViewCell

@synthesize view;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier])
	{
		/*
		self.backgroundColor = [UIColor clearColor];
		self.backgroundView = nil;
		self.selectedBackgroundView = nil;
		self.contentView.backgroundColor = [UIColor clearColor];
		 */
	}
	return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	return;
}


- (void)setView:(UIView *)aView
{
	if (self.view)
		[self.view removeFromSuperview];
	
	view = [aView retain];

	[self.contentView addSubview:self.view];
	
	[self layoutSubviews];
}

- (void)layoutSubviews
{	
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
	
	//FIXME: arghh, I can't get the white rounded background to stop displaying in a grouped table view
	//it may have something to do with this: http://discussions.apple.com/thread.jspa?threadID=1573153&tstart=105
	//also, the background appears to draw outside its bounds by one pixel on each side
	//as a temporary fix, draw the view one pixel larger than the background on each side to cover it completely
	CGRect frame = CGRectMake(contentRect.origin.x - 1.0, contentRect.origin.y - 1.0, contentRect.size.width + 2.0, contentRect.size.height + 2.0);
	self.view.frame = frame;
}



- (void)dealloc 
{
	[self.view release];
	[super dealloc];
}


@end
