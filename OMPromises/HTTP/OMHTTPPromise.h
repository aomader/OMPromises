//
// OMHTTPPromise.h
// OMPromises
//
// Copyright (C) 2013,2014 Oliver Mader
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "OMPromises.h"

// Serialization Option
extern NSString *const OMHTTPSerialization;
extern NSString *const OMHTTPSerializationJSON;
extern NSString *const OMHTTPSerializationURLEncoded;

@interface OMHTTPPromise : OMDeferred

+ (OMPromise *)get:(NSString *)urlString parameters:(NSDictionary *)parameters options:(NSDictionary *)options;
+ (OMPromise *)get:(NSString *)urlString options:(NSDictionary *)options;
+ (OMPromise *)get:(NSString *)urlString;

/** Perform a HTTP request.

 @param method The HTTP method to use.
 @param url The URL of the resource to request.
 @param parameters Optional set of parameters.
 @param options ...
 @return A promise that yields a OMHTTPResponse.
 @see OMHTTPResponse
 */
+ (OMPromise *)requestWithMethod:(NSString *)method
                             url:(NSURL *)url
                      parameters:(NSDictionary *)parameters
                         options:(NSDictionary *)options;

@end
