//
// OMPromise+HTTP.m
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

#import "OMPromise+HTTP.h"

#import "OMResources.h"
#import "OMHTTPRequest.h"
#import "OMHTTPResponse.h"

@implementation OMPromise (HTTP)

- (OMPromise *)httpParseJSON {
    return [self then:^id(OMHTTPResponse *response) {
        // check content type
        if (![response.headers[@"Content-Type"] hasPrefix:@"application/json"]) {
            return [NSError errorWithDomain:OMPromisesHTTPErrorDomain
                                       code:OMPromisesHTTPContentTypeError
                                   userInfo:@{
                                       NSLocalizedDescriptionKey: OMLocalizedString(@"error_http_content_type_%@%@",
                                           response.headers[@"Content-Type"], @"application/json")
                                   }];
        }

        NSError *error = nil;
        id data = [NSJSONSerialization JSONObjectWithData:response.body options:0 error:&error];

        if (error) {
            return [NSError errorWithDomain:OMPromisesHTTPErrorDomain
                                       code:OMPromisesHTTPSerializationError
                                   userInfo:@{
                                       NSLocalizedDescriptionKey: OMLocalizedString(@"error_http_deserialization_%@%@",
                                           @"JSON", error),
                                       NSUnderlyingErrorKey: error
                                   }];
        }

        return data;
    }];
}

@end
