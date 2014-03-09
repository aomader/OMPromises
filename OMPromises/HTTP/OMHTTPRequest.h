//
// OMHTTPRequest.h
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

#import "OMDeferred.h"

extern NSString *const OMHTTPTimeout;

extern NSString *const OMHTTPLookupProgress;

// Serialization Option
extern NSString *const OMHTTPSerialization;
extern NSString *const OMHTTPSerializationQueryString;
extern NSString *const OMHTTPSerializationJSON;
extern NSString *const OMHTTPSerializationURLEncoded;

/** Provides methods to create an OMPromise representing an HTTP request.
 
 
 */
@interface OMHTTPRequest : OMDeferred

///---------------------------------------------------------------------------------------
/// @name Universal HTTP Request
///---------------------------------------------------------------------------------------

/** Perform a HTTP request.

 The central method to create a HTTP request, start it and create a promise
 which represents the outcome of the HTTP request.

 There are convenience methods to simplify the process even further,
 like get: or post:.

 @param method The HTTP method to use. E.g. GET, POST, etc.
 @param url The URL of the resource to request.
 @param parameters Optional set of parameters. How these parameters are serialized into
                   the body depends on the OMHTTPSerialization key.
 @param options An optional set of HTTP headers including values and method specific
                options like OMHTTPSerialization. Each non method specific option is
                automatically treated as HTTP header and added to the request.
 @return A promise that yields an OMHTTPResponse instance if successful.
 @see OMHTTPResponse
 @see get:parameters:options:
 @see post:parameters:options:
 */
+ (OMPromise *)requestWithMethod:(NSString *)method
                             url:(NSURL *)url
                      parameters:(NSDictionary *)parameters
                         options:(NSDictionary *)options;

///---------------------------------------------------------------------------------------
/// @name Convenience Methods
///---------------------------------------------------------------------------------------

+ (OMPromise *)get:(NSString *)urlString
        parameters:(NSDictionary *)parameters
           options:(NSDictionary *)options;

+ (OMPromise *)post:(NSString *)urlString
         parameters:(NSDictionary *)parameters
            options:(NSDictionary *)options;

+ (OMPromise *)put:(NSString *)urlString
        parameters:(NSDictionary *)parameters
           options:(NSDictionary *)options;

+ (OMPromise *)head:(NSString *)urlString
         parameters:(NSDictionary *)parameters
            options:(NSDictionary *)options;

+ (OMPromise *)delete:(NSString *)urlString
           parameters:(NSDictionary *)parameters
              options:(NSDictionary *)options;

@end
