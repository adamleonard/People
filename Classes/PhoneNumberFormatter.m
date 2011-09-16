//
//  PhoneNumberFormatter.m
//  People
//
//  Created by Adam Leonard on 7/3/08.
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


#import "PhoneNumberFormatter.h"


@implementation PhoneNumberFormatter

static PhoneNumberFormatter *CCSharedPhoneNumberFormatter;

+ (PhoneNumberFormatter *)sharedFormatter;
{
	@synchronized(self) 
	{
        if (CCSharedPhoneNumberFormatter == nil)
		{
            CCSharedPhoneNumberFormatter = [[self alloc] init];
		}
    }
    return CCSharedPhoneNumberFormatter;
}

- (NSString *)formatPhoneNumber:(NSString *)phone;
{
	//start with a clean slate: remove any existing formattinng
	phone = [self unformatPhoneNumber:phone];
	
	NSMutableString *formattedPhone = [NSMutableString stringWithCapacity:20];
	
	//look at each digit individually 
	int indexOfFirstDigitOfAreaCode = 0;
	for(NSUInteger i = 0; i < [phone length] && i < (indexOfFirstDigitOfAreaCode + 10); i++) //do not add any numbers after the 10th digit (or the 11th digit if the optional 1 at the begining is there), as the API won't accept it
	{
		NSString *digitAsString = [phone substringWithRange:NSMakeRange(i, 1)];
		
		if([digitAsString isEqualToString:@"+"] || [digitAsString isEqualToString:@"*"] || [digitAsString isEqualToString:@"#"])
			continue; //these are characters that appear on the iPhone phone number keyboard, but the WhitePages API can't handle them, so just leave them out of the string
		
		NSInteger digit = [digitAsString integerValue];
		
		if(i == 0 && digit == 1)
		{
			[formattedPhone appendString:@"1"]; //if the user included the optional 1 (country code, right?), leave it out front with a space
			indexOfFirstDigitOfAreaCode = 1; //that means the area code begins in the second digit
			continue;
		}
		
		if(i == indexOfFirstDigitOfAreaCode)
		{
			if(indexOfFirstDigitOfAreaCode == 1)
				[formattedPhone appendString:@" "]; //the user put a "1" at the beginning. Add a space after it.
			 
			[formattedPhone appendFormat:@"(%i",digit]; //start of area code
			continue;
		}
		
		if(i == indexOfFirstDigitOfAreaCode + 3)
		{
			[formattedPhone appendFormat:@") %i",digit]; //start of 3 digit part of number
			continue;
		}
		
		if(i == indexOfFirstDigitOfAreaCode + 6)
		{
			[formattedPhone appendFormat:@"-%i",digit]; //start of 4 digit part of the number
			continue;
		}
		
		
		[formattedPhone appendFormat:@"%i",digit]; //if it is not a special formatting case, just add the digit
	}
	
	return formattedPhone;
}
		
- (NSString *)unformatPhoneNumber:(NSString *)phone;
{
	phone = [phone stringByReplacingOccurrencesOfString:@"(" withString:@""];
	phone = [phone stringByReplacingOccurrencesOfString:@")" withString:@""];
	phone = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
	phone = [phone stringByReplacingOccurrencesOfString:@"+" withString:@""];
	phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];

	return phone;
}
			
@end
