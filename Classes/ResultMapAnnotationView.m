//
//  ResultMapAnnotationView.m
//  People
//
//  Created by Adam Leonard on 6/3/09.
//  Copyright 2009 Caffeinated Cocoa. All rights reserved.
//

#import "ResultMapAnnotationView.h"


@implementation ResultMapAnnotationView
- (UIView *)viewForCalloutPosition:(MKAnnotationCalloutAccessoryPosition)position
{
	NSLog(@"1");
	if (position == MKAnnotationCalloutAccessoryPositionRight)
	{
		NSLog(@"2");
		//show a blue arrow button that, when clicked will display all the information about the result
		return [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
	}
	
	return nil;
}
@end
