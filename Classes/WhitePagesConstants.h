/*
 *  WhitePagesConstants.h
 *  People
 *
 *  Created by Adam Leonard on 6/29/08.
 */
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


//To test and run your own build of People, go to http://developer.whitepages.com/ and sign up for a Pro API Test Account. 
//Then, uncomment the line below and copy and paste your api key in.
//I can't provide the keys the release version of People uses publicly to prevent others from abusing them in other applications

//#define WHITE_PAGES_API_KEY @""

#ifndef WHITE_PAGES_API_KEY
#error Please get a WhitePages API Key and define it in WhitePagesConstants.h
#define WHITE_PAGES_API_KEY @"noAPIKeySet"
#endif

//the White Pages API uses a strange format for parameters. They begin with a single "?" and each parameter is separated with a ";"
#define WHITE_PAGES_FIND_PERSON_BASE_URL @"http://api.whitepages.com/find_person/1.0/?"
#define WHITE_PAGES_REVERSE_ADDRESS_BASE_URL @"http://api.whitepages.com/reverse_address/1.0/?"
#define WHITE_PAGES_REVERSE_PHONE_BASE_URL @"http://api.whitepages.com/reverse_phone/1.0/?"

enum CCWhitePagesSearchTypes
{
	CCWhitePagesSearchTypeNone = -1,
	CCWhitePagesSearchTypeName = 0,
	CCWhitePagesSearchTypeReverseAddress = 1,
	CCWhitePagesSearchTypeReversePhone = 2,
};
