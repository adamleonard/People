//
//  PeopleAppDelegate.m
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

#import "PeopleAppDelegate.h"
#import "SearchViewController.h"
#import "NearbyViewController.h"
#import "SearchHistoryTableViewController.h"

@implementation PeopleAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize searchViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{			
	searchViewController = [[[SearchViewController alloc]initWithNibName:nil bundle:nil]autorelease];
	UINavigationController *searchNavigationController = [[[UINavigationController alloc]initWithRootViewController:searchViewController]autorelease];
	
	NearbyViewController *nearbyViewController = [[[NearbyViewController alloc]initWithNibName:nil bundle:nil]autorelease];
	UINavigationController *nearbyNavigationController = [[[UINavigationController alloc]initWithRootViewController:nearbyViewController]autorelease];
	
	SearchHistoryTableViewController *searchHistoryTableViewController = [[[SearchHistoryTableViewController alloc]initWithStyle:UITableViewStylePlain]autorelease];
	UINavigationController *searchHistoryNavigationController = [[[UINavigationController alloc]initWithRootViewController:searchHistoryTableViewController]autorelease];

	tabBarController.viewControllers = [NSArray arrayWithObjects:searchNavigationController,nearbyNavigationController,searchHistoryNavigationController,nil];
	
	//the default selected tab is the search tab
	[[NSUserDefaults standardUserDefaults]registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:0] forKey:@"selectedTabIndex"]];
	
	//restore the state from the last session by loading the last shown tab
	tabBarController.selectedIndex = [[[NSUserDefaults standardUserDefaults]objectForKey:@"selectedTabIndex"]integerValue];
	tabBarController.delegate = self;
	
	[window addSubview:tabBarController.view];
	[window makeKeyAndVisible];
}


- (void)tabBarController:(UITabBarController *)aTabBarController didSelectViewController:(UIViewController *)viewController 
{
	[[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithInteger:tabBarController.selectedIndex] forKey:@"selectedTabIndex"];
}


/*
 Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/


- (void)dealloc {
	[tabBarController release];
	[window release];
	[super dealloc];
}

@end

