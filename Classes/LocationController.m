//
//  LocationController.m
//  WikiPhone
//
//  Created by Adam Leonard on 6/24/08.
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

#import "LocationController.h"
#import "CCLocation.h"

NSString *CCLocationChangedNotificationName = @"locationChanged";
NSString *CCLocationUpdateFailedNotificationName = @"locationUpdateFailed";

@interface LocationController (Private)
- (void)_stopUpdatingLocation;
@end;

@implementation LocationController

@synthesize location;

static LocationController *CCSharedLocationController;

+(LocationController *)sharedController;
{
	@synchronized(self) 
	{
        if (CCSharedLocationController == nil)
		{
            CCSharedLocationController = [[self alloc] init];
		}
    }
    return CCSharedLocationController;
}

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		locationManager = [[CLLocationManager alloc]init];
		locationManager.delegate = self;
		locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
	}
	return self;
}

- (void)startUpdatingLocationWithDesiredAccuracy:(CLLocationAccuracy)anAccuracy
{
	currentDesiredAccuracy = anAccuracy;
	locationManager.desiredAccuracy = anAccuracy;
	[locationManager startUpdatingLocation];
	
	[self performSelector:@selector(_stopUpdatingLocation) withObject:nil afterDelay:8.0]; //automatically stop updating reguardless after 8 seconds
}

- (void)_stopUpdatingLocation;
{
	[locationManager stopUpdatingLocation];
	
	if(self.location)
		[[NSNotificationCenter defaultCenter]postNotificationName:CCLocationChangedNotificationName object:self.location];

}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{	
	
	CCLocation *newLocationAsCCLocation = nil;
	
	if(![newLocation isKindOfClass:[CCLocation class]])
	{
		//create our CCLocation (which adds a natural language option) just by copying everything over
		newLocationAsCCLocation = [[[CCLocation alloc]initWithCoordinate:newLocation.coordinate
																			altitude:newLocation.altitude
																  horizontalAccuracy:newLocation.horizontalAccuracy
																	verticalAccuracy:newLocation.verticalAccuracy
																		   timestamp:newLocation.timestamp]autorelease];
		self.location = newLocationAsCCLocation;
		if(newLocation.horizontalAccuracy <= currentDesiredAccuracy && newLocation.verticalAccuracy <= currentDesiredAccuracy)
		{
			//if this location has an accuracy of currentDesiredAccuracy (m) or less, stop updates now. Otherwise, wait for the timeout to stop updates
			[self _stopUpdatingLocation];
		}
	}
	else
	{
		newLocationAsCCLocation = (CCLocation *)newLocation;
		self.location = newLocationAsCCLocation;
	}
	

	
	
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"Location update failed");
	
	[[NSNotificationCenter defaultCenter]postNotificationName:CCLocationUpdateFailedNotificationName object:nil];
}
	

- (void) dealloc
{
	[locationManager release];
	[super dealloc];
}



@end
