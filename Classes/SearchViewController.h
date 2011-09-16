//
//  NameSearchViewController.h
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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "ReverseGeocodingRequestController.h"
#import "ReverseGeocodingRequestDelegateProtocol.h"
#import "WhitePagesRequestDelegateProtocol.h"

@class LoadingViewController, SearchResultsViewController, WhitePagesRequestController;

@interface SearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, ReverseGeocodingRequestDelegate, WhitePagesRequestDelegate, UISearchBarDelegate>
{
	UITableView *tableView;
	
	LoadingViewController *loadingViewController;
	
	UIBarButtonItem *searchBarButtonItem;
	UIBarButtonItem *cancelBarButtonItem;
	UIBarButtonItem *clearBarButtonItem;
	
	UISearchBar *searchBar;
	
	int whitePagesSearchType; //one of the constants in WhitePageConstants.h
	
	UISegmentedControl *searchTypeSelector;
	
	//search by name fields
	NSIndexPath *_firstNameCellIndexPath;
	NSIndexPath *_lastNameCellIndexPath;
	NSIndexPath *_locationFieldCellIndexPath;
	NSMutableDictionary *_savedNameSearchFieldsContents;
	
	//search by address fields
	NSIndexPath *_streetAddressCellIndexPath;
	NSIndexPath *_cityStateAndZipCellIndexPath;
	NSMutableDictionary *_savedAddressSearchFieldsContents;
	
	//search by phone fields
	NSIndexPath *_phoneNumberCellIndexPath;
	NSMutableDictionary *_savedPhoneSearchFieldsContents;
	NSString *_oldFormattedNumber;
	
	SearchResultsViewController *resultsViewController;
	
	UIAlertView *_whitePagesErrorAlert;
	
	int oldWhitePagesSearchType;
	
	BOOL performingWhitePagesSearch;
	BOOL showingSearchFields;
}
- (void)reverseGeocodingRequestController:(ReverseGeocodingRequestController *)controller retrievedAddress:(NSString *)address addressComponents:(NSDictionary *)addressComponents;
- (void)reverseGeocodingRequestController:(ReverseGeocodingRequestController *)controller failedWithError:(NSError *)error;

- (void)whitePagesRequestController:(WhitePagesRequestController *)controller retrievedResults:(NSArray *)results metadata:(NSDictionary *)metadata;
- (void)whitePagesRequestController:(WhitePagesRequestController *)controller failedWithError:(NSError *)error;

- (void)showSearchFieldsTableWithAnimation:(BOOL)animate;


- (WhitePagesRequestController *)beginWhitePagesSearchWithSearchType:(NSInteger)searchType
											searchDisplayDescription:(NSString *)displayDescription
														  APICallURL:(NSURL *)URL
													   withAnimation:(BOOL)animate; //returns the WhitePagesRequestController that is running the search. Used by SearchHistoryTableViewController

@property (readonly) UITableView *tableView;
@property (assign) int whitePagesSearchType;

@end
