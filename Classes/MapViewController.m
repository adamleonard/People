//
//  MapViewController.m
//  People
//
//  Created by Adam Leonard on 5/25/09.
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

#import "MapViewController.h"
#import "ResultMapAnnotation.h"
#import "SearchResultsViewController.h"


@implementation MapViewController

@synthesize results;
@synthesize resultsController;
@synthesize showsMoreInfoButton, showsOpenInMapsButton;


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (id)initWithSearchResults:(NSArray *)theSearchResults resultsController:(SearchResultsViewController *)aResultsController;
{
	self = [super init];
	if (self != nil) 
	{
		self.results = theSearchResults;
		self.resultsController = aResultsController;
		
		self.showsMoreInfoButton = YES;
		self.showsOpenInMapsButton = NO;
		
	}
	return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
	[super loadView];
	
	MKMapView *mapView = [[MKMapView alloc]initWithFrame:[UIScreen mainScreen].applicationFrame];
	[mapView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
	mapView.delegate = self;
	self.view = mapView;
	[mapView release];
	

}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	
	MKMapView *mapView = (MKMapView *)self.view;
	
	if(results && [results count] > 0)
	{
		//2 things: compute the zoom level of the map by finding the result that is the maximum distance away from the first result, and create the annotations
		CGFloat minLatitude = CGFLOAT_MAX;
		CGFloat maxLatitude = CGFLOAT_MAX * -1.0;
		CGFloat minLongitude = CGFLOAT_MAX;
		CGFloat maxLongitude = CGFLOAT_MAX * -1.0;
		NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:[results count]];
		for (NSDictionary *result in self.results)
		{
			float latitude = [[[result objectForKey:@"geodata"]objectForKey:@"latitude"] floatValue];
			if (latitude < minLatitude)
				minLatitude = latitude;
			if (latitude > maxLatitude)
				maxLatitude = latitude;
			
			float longitude = [[[result objectForKey:@"geodata"]objectForKey:@"longitude"] floatValue];
			if (longitude < minLongitude)
				minLongitude = longitude;
			if (longitude > maxLongitude)
				maxLongitude = longitude;
			
			[annotations addObject:[[[ResultMapAnnotation alloc]initWithResult:result]autorelease]];
		}
		
		//compute the place to center the map by finding the center of the bounding box we just created
		CLLocationCoordinate2D centerCoordinate = {(minLatitude + maxLatitude) / 2.0, (minLongitude + maxLongitude) / 2.0};
		
		CGFloat latitudeDelta = fabs(maxLatitude - minLatitude);
		CGFloat longitudeDelta = fabs(maxLongitude - minLongitude);
		
		[mapView addAnnotations:annotations];
		annotationToSelctWhenShown = [annotations objectAtIndex:0]; //show the popup bubble for the first (best) result when it appears onscreen
		
		//add some padding to the zoom level so there is room around the result pins
		latitudeDelta += latitudeDelta * 0.15;
		longitudeDelta += longitudeDelta * 0.15;
				
		[mapView setRegion:MKCoordinateRegionMake(centerCoordinate, MKCoordinateSpanMake(latitudeDelta, longitudeDelta)) animated:YES];
		
		if(self.showsOpenInMapsButton)
		{
			self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Open In Maps" style:UIBarButtonItemStyleDone target:self action:@selector(openInMaps:)]autorelease];
		}
	}
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)setResults:(NSArray *)theResults;
{
	[theResults retain];
	[results release];
	results = theResults;
}
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
	if (!annotationToSelctWhenShown)
		return;
	
	for (MKPinAnnotationView *aView in views)
	{
		if ([aView.annotation isEqual:annotationToSelctWhenShown])
		{
			[mapView selectAnnotation:annotationToSelctWhenShown animated:YES];
			annotationToSelctWhenShown = nil;
			break;
		}
	}
		
}
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKPinAnnotationView *annotationView = [[[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:nil]autorelease];
	annotationView.canShowCallout = YES;
	annotationView.animatesDrop = YES;
	
	if (self.showsMoreInfoButton)
	{
		UIButton *moreInfoButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[moreInfoButton addTarget:self action:@selector(displaySelectedResult:) forControlEvents:UIControlEventTouchDown];
		annotationView.rightCalloutAccessoryView = moreInfoButton;
	}
	
	return annotationView;
	
}

- (void)displaySelectedResult:(id)sender
{
	MKMapView *mapView = (MKMapView *)self.view;
	NSDictionary *selectedResult = ((ResultMapAnnotation *)((MKAnnotationView *)[[mapView selectedAnnotations]objectAtIndex:0]).annotation).result;
	[self.resultsController displayResult:selectedResult withAnimation:YES];
	
}

- (void)openInMaps:(id)sender
{
	MKMapView *mapView = (MKMapView *)self.view;
	NSDictionary *selectedResult = ((ResultMapAnnotation *)((MKAnnotationView *)[[mapView selectedAnnotations]objectAtIndex:0]).annotation).result;
	
	if(!selectedResult)
		selectedResult = [self.results objectAtIndex:0]; //if no result is selected, open the top result
	
	if(!selectedResult)
		return;
	
	ABRecordRef selectedResultAsPerson = [self.resultsController ABRecordFromWhitePagesSearchResult:selectedResult];
	NSDictionary *addressDictionary = (NSDictionary *)ABMultiValueCopyValueAtIndex(ABRecordCopyValue(selectedResultAsPerson,kABPersonAddressProperty), 0);
	
	NSMutableString *formattedAddress = [NSMutableString string];
	NSString *streetAddress = [addressDictionary objectForKey:(NSString *)kABPersonAddressStreetKey];
	NSString *city = [addressDictionary objectForKey:(NSString *)kABPersonAddressCityKey];
	NSString *state = [addressDictionary objectForKey:(NSString *)kABPersonAddressStateKey];
	NSString *zip = [addressDictionary objectForKey:(NSString *)kABPersonAddressZIPKey];
	
	if(streetAddress)
		[formattedAddress appendFormat:@"%@ ",streetAddress];
	if(city)
		[formattedAddress appendFormat:@"%@ ",city];
	if(state)
		[formattedAddress appendFormat:@"%@ ",state];
	if(zip)
		[formattedAddress appendFormat:@"%@ ",zip];
	
	NSString *formattedName = (NSString *)ABRecordCopyCompositeName(selectedResultAsPerson);
	
	NSString *urlAsString = [NSString stringWithFormat:@"maps:q=%@ (%@)",formattedAddress,formattedName];
	
	[[UIApplication sharedApplication]openURL:[NSURL URLWithString:[urlAsString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
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
	[results release];
    [super dealloc];
}


@end
