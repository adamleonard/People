//
//  ResultMapAnnotationView.h
//  People
//
//  Created by Adam Leonard on 6/3/09.
//  Copyright 2009 Caffeinated Cocoa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface ResultMapAnnotationView : MKPinAnnotationView 
{

}

//FIXME: Somehow, this got removed from MKAnnotationView's header in beta 5. It is still documented, so it was probably an oversight. Remove this when it reappears.
enum {
	MKAnnotationCalloutAccessoryPositionLeft = 0,
	MKAnnotationCalloutAccessoryPositionRight
};
typedef NSUInteger MKAnnotationCalloutAccessoryPosition;

@end
