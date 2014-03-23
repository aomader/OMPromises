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

//#import <UIKit/UIKit.h>

#import "OMHTTPResponse.h"

static const char *supportedImages[] = {
    "image/gif",
    "image/jpeg",
    "image/png",
    "image/tiff",
    "image/x-xbitmap",
    "image/x-icon"
};

@implementation OMPromise (HTTP)

- (OMPromise *)httpParseText {
#warning Check content-type as well as a charset and transform body to string.
    return nil;
}

- (OMPromise *)httpParseImage {
    /*
    return [self then:^id(OMHTTPResponse *response) {
        BOOL supported = NO;
        const char *contentType = [response.headers[@"Content-Type"] cStringUsingEncoding:NSUTF8StringEncoding];
        for (NSUInteger i = 0; i < 6; ++i) {
            if (strcasecmp(contentType, supportedImages[i]) == 0) {
                supported = YES;
                break;
            }
        }
        
        if (!supported) {
#warning Check content-type as well as a charset and transform body to string.
            return [NSError errorWithDomain:OMPromisesErrorDomain code:0 userInfo:nil];
        }
        
        return [[UIImage alloc] initWithData:response.body];
    }];
    */
    
#warning Check content-type for UIImage readable and transform to UIImage.
    return  nil;
}

- (OMPromise *)httpParseJSON {
#warning Check for content-type, also account for possible versioned content types.
    return [self then:^id(OMHTTPResponse *response) {
        NSError *error = nil;
        id data = [NSJSONSerialization JSONObjectWithData:response.body options:0 error:&error];
        return error ?: data;
    }];
}

@end
