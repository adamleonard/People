//
//  SearchResultCellView.m
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

#import "SearchResultCellView.h"
#import "LocationController.h"
#import "CCLocation.h"

@implementation SearchResultCellView

@synthesize name, streetAddress;
@synthesize location;
@synthesize highlighted;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame])
	{
		self.opaque = YES;
		self.backgroundColor = [UIColor whiteColor];
	}
	return self;
}


- (void)drawRect:(CGRect)rect 
{	
	//based on CustomTableViewCell example
#define LEFT_COLUMN_OFFSET 10
#define LEFT_COLUMN_WIDTH 240

#define RIGHT_COLUMN_OFFSET 260
#define RIGHT_COLUMN_WIDTH 60
	
#define UPPER_ROW_TOP 8
#define LOWER_ROW_TOP 34
	
#define MAIN_FONT_SIZE 18
#define MIN_MAIN_FONT_SIZE 16
#define SECONDARY_FONT_SIZE 15
#define MIN_SECONDARY_FONT_SIZE 12
	
	// Color and font for the main text items (name)
	UIColor *mainTextColor = nil;
	UIFont *mainFont = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	
	// Color and font for the secondary text items (street address)
	UIColor *secondaryTextColor = nil;
	UIFont *secondaryFont = [UIFont systemFontOfSize:SECONDARY_FONT_SIZE];
	
	// Choose font color based on highlighted state.
	if (self.highlighted) {
		mainTextColor = [UIColor whiteColor];
		secondaryTextColor = [UIColor whiteColor];
	}
	else {
		mainTextColor = [UIColor blackColor];
		secondaryTextColor = [UIColor darkGrayColor];
		self.backgroundColor = [UIColor whiteColor];
	}
	
	CGRect contentRect = self.bounds;
	
	// In this example we will never be editing, but this illustrates the appropriate pattern.
	
	
	CGFloat boundsX = contentRect.origin.x;
	CGPoint point;
	
	
	// Set the color for the main text items
	[mainTextColor set];
	
	/*
	 Draw the name top left; use the NSString UIKit method to scale the font size down if the text does not fit in the given area
	 */
	point = CGPointMake(boundsX + LEFT_COLUMN_OFFSET, UPPER_ROW_TOP);
	[self.name drawAtPoint:point forWidth:LEFT_COLUMN_WIDTH withFont:mainFont minFontSize:MIN_MAIN_FONT_SIZE actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
	
	
	// Set the color for the secondary text items
	[secondaryTextColor set];
	
	if(self.streetAddress)
	{
		
		// Draw the street address botton left; use the NSString UIKit method to scale the font size down if the text does not fit in the given area
		 
		point = CGPointMake(boundsX + LEFT_COLUMN_OFFSET, LOWER_ROW_TOP);
		[self.streetAddress drawAtPoint:point forWidth:LEFT_COLUMN_WIDTH withFont:secondaryFont minFontSize:MIN_SECONDARY_FONT_SIZE actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
	}
	
	CCLocation *currentLocation = [LocationController sharedController].location;
	if(self.location && self.location.coordinate.latitude && self.location.coordinate.longitude && currentLocation && currentLocation.coordinate.latitude && currentLocation.coordinate.longitude)
	{
		UIFont *distanceFont = [UIFont boldSystemFontOfSize:SECONDARY_FONT_SIZE];
		CGFloat distanceInFeetAsFloat = [currentLocation getDistanceFrom:self.location] * 3.2808399;
		NSString *distanceAsString = nil;
		
		if(distanceInFeetAsFloat < 999.5) //less than 1000ft
			distanceAsString = [NSString stringWithFormat:@"%i ft",(int)floor(distanceInFeetAsFloat)]; //display it as feet with no decimals
		else if(distanceInFeetAsFloat < 132000)//less than 25 miles
			distanceAsString = [NSString stringWithFormat:@"%.2f mi",(float)(floor(distanceInFeetAsFloat * 0.000189393939 * 100)) / 100.0]; //display it in miles with 2 decimal place accuracy
		else //if it is more than 25 miles, the user is probably not interested in the distance from the current location
			return;
		
		//draw a string representing the distance 
		CGFloat middleVerticleOffset = (contentRect.size.height - 15.0) / 2;
		point = CGPointMake(boundsX + RIGHT_COLUMN_OFFSET, middleVerticleOffset);
		[distanceAsString drawAtPoint:point forWidth:RIGHT_COLUMN_WIDTH withFont:distanceFont minFontSize:MIN_SECONDARY_FONT_SIZE actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
	}
	
}


- (void)dealloc
{
	[self.name release];
	[self.streetAddress release];
	[super dealloc];
}


@end
