//
// OMHTTPResponse.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Represents the outcome of a successful HTTP request operation.
 */
@interface OMHTTPResponse : NSObject

/** Use this method to set the properties.
 Once initialized, the object is sealed.
 */
- (instancetype)initWithCode:(NSUInteger)statusCode
                     headers:(NSDictionary *)headers
                        body:(NSData *)body;

/** The HTTP status code of the response.
 */
@property(assign, readonly, nonatomic) NSUInteger statusCode;

/** The headers including the value of the response.
 */
@property(readonly, nonatomic) NSDictionary *headers;

/** The body of the response.
 */
@property(readonly, nonatomic, nullable) NSData *body;

@end

NS_ASSUME_NONNULL_END
