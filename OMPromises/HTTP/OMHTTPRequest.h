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

/** Perform an HTTP request.

 The central method to create an HTTP request, start it and create a promise
 which represents the outcome of the respective request.

 There are convenience methods for the most common verbs to simplify the process even
 further, like get:paramaters:options: or post:parameters:options:. These methods may
 apply additional logic to provide sane defaults, have a look at the corresponding
 documentation.
 All covenience methods share the automated URL string interpolation in addition to
 the final parameter serializtion: Each occurence of a string wrapped in curly braces
 is replaced by the value found in the parameters dictionary identified by the wrapped
 string. The pair is removed from the dictionary afterwards.

 @param method The HTTP method to use. E.g. GET, POST, etc.
 @param url The URL of the resource to request.
 @param parameters Optional set of parameters. How these parameters are serialized into
                   the body depends on the OMHTTPSerialization key.
 @param options An optional set of HTTP headers including values and method specific
                options like OMHTTPSerialization. Each non method specific option is
                automatically treated as an HTTP header and added to the request.
 @return A promise that yields an OMHTTPResponse instance if successful.
 @see OMHTTPResponse
 @see get:parameters:options:
 @see post:parameters:options:
 @see put:parameters:options:
 @see head:parameters:options:
 @see delete:parameters:options:
 */
+ (OMPromise *)requestWithMethod:(NSString *)method
                             url:(NSURL *)url
                      parameters:(NSDictionary *)parameters
                         options:(NSDictionary *)options;

///---------------------------------------------------------------------------------------
/// @name Convenience Methods
///---------------------------------------------------------------------------------------

/** Convenience method to perform an HTTP GET request.
 
 Uses OMHTTPSerializationQueryString for OMHTTPSerialization if not specified otherwise.
 
 @see requestWithMethod:url:parameters:options:
 */
+ (OMPromise *)get:(NSString *)urlString
        parameters:(NSDictionary *)parameters
           options:(NSDictionary *)options;

/** Convenience method to perform an HTTP POST request.
 
 @see requestWithMethod:url:parameters:options:
 */
+ (OMPromise *)post:(NSString *)urlString
         parameters:(NSDictionary *)parameters
            options:(NSDictionary *)options;

/** Convenience method to perform an HTTP PUT request.
 
 @see requestWithMethod:url:parameters:options:
 */
+ (OMPromise *)put:(NSString *)urlString
        parameters:(NSDictionary *)parameters
           options:(NSDictionary *)options;

/** Convenience method to perform an HTTP HEAD request.
 
 @see requestWithMethod:url:parameters:options:
 */
+ (OMPromise *)head:(NSString *)urlString
         parameters:(NSDictionary *)parameters
            options:(NSDictionary *)options;

/** Convenience method to perform an HTTP DELETE request.
 
 @see requestWithMethod:url:parameters:options:
 */
+ (OMPromise *)delete:(NSString *)urlString
           parameters:(NSDictionary *)parameters
              options:(NSDictionary *)options;

@end
