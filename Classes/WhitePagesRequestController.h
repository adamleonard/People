//
//  WhitePagesRequestController.h
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
//#import <JSON/JSON.h>
#import "WhitePagesRequestDelegateProtocol.h"
#import "PicklistTableViewController.h"

@interface WhitePagesRequestController : NSObject <PicklistDelegate>
{
	BOOL savesSearchesToSearchHistory;
	UIViewController *viewControllerForPicklist;
	
	NSObject <WhitePagesRequestDelegate> *delegate;
	int searchType;
	NSString *searchDisplayDescription;
	
	NSURL *_requestURL;
	NSMutableData *_currentDownloadData;

}

+ (id)beginSearchWithType:(NSInteger)searchType
			   APICallURL:(NSURL *)URL
 searchDisplayDescription:(NSString *)searchDescription
				 delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;

+ (id)beginNameSearchWithFirstName:(NSString *)firstName
						  lastName:(NSString *)lastName
							  city:(NSString *)city
							 state:(NSString *)state
							   zip:(NSString *)zip
		  searchDisplayDescription:(NSString *)searchDescription
						  delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;

+ (id)beginReverseAddressSearchWithHouse:(NSString *)house
								  street:(NSString *)street
									city:(NSString *)city
								   state:(NSString *)state
									 zip:(NSString *)zip
				searchDisplayDescription:(NSString *)searchDescription
								delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;

+ (id)beginReversePhoneSearchWithPhoneNumber:(NSString *)phoneNumber
					searchDisplayDescription:(NSString *)searchDescription
									delegate:(NSObject <WhitePagesRequestDelegate> *)aDelegate;

@property (assign) BOOL savesSearchesToSearchHistory;
@property (assign) NSObject <WhitePagesRequestDelegate> *delegate;
@property (nonatomic, retain) NSString *searchDisplayDescription;
@property (nonatomic, retain) UIViewController *viewControllerForPicklist;



@end
