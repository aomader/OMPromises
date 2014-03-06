//
// OMHTTPPromise.m
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

#import "OMHTTPPromise.h"

#import "OMHTTPResponse.h"

static const NSTimeInterval kTimeoutInterval = 20;
static const float kLookupProgress = .05f;

NSString *const OMHTTPSerialization = @"OMHTTPSerialization";
NSString *const OMHTTPSerializationJSON = @"json";
NSString *const OMHTTPSerializationURLEncoded = @"urlencoded";

@interface OMHTTPPromise () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property(nonatomic) NSHTTPURLResponse *response;
@property(nonatomic) NSMutableData *data;

@end

@implementation OMHTTPPromise

#pragma mark - Init

- (id)initWithURL:(NSURL *)url method:(NSString *)method parameters:(NSDictionary *)parameters options:(NSDictionary *)options {
    self = [super init];
    if (self) {
        _data = [NSMutableData data];

        NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                initWithURL:url
                cachePolicy:NSURLRequestReloadIgnoringCacheData
            timeoutInterval:kTimeoutInterval];
        request.HTTPMethod = method;

        if (parameters) {
            if ([options[OMHTTPSerialization] isEqualToString:OMHTTPSerializationJSON]) {
                [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                request.HTTPBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
            } else {
#warning generate form data
                [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                request.HTTPBody = nil;
            }

            [request setValue:[NSString stringWithFormat:@"%i", request.HTTPBody.length]
           forHTTPHeaderField:@"Content-Length"];
        }

        [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    }
    return self;
}

#pragma mark - Public Static Methods

+ (OMPromise *)requestWithMethod:(NSString *)method
                             url:(NSURL *)url
                      parameters:(NSDictionary *)parameters
                         options:(NSDictionary *)options
{
    return [[OMHTTPPromise alloc] initWithURL:url
                                       method:method
                                   parameters:parameters
                                      options:options].promise;
}

+ (OMPromise *)get:(NSString *)urlString parameters:(NSDictionary *)parameters options:(NSDictionary *)options {
    return [OMHTTPPromise requestWithMethod:@"GET"
                                        url:[NSURL URLWithString:urlString]
                                 parameters:parameters
                                    options:options];
}

+ (OMPromise *)get:(NSString *)urlString options:(NSDictionary *)options {
    return [OMHTTPPromise get:urlString parameters:nil options:options];
}

+ (OMPromise *)get:(NSString *)urlString {
    return [OMHTTPPromise get:urlString parameters:nil options:nil];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self fail:error];
}

#pragma mark - NSURLConnectionDataDelegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
    if (self.response.expectedContentLength > 0) {
        [self progress:kLookupProgress + (1 - kLookupProgress) *
                (float)self.data.length / self.response.expectedContentLength];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    if ([response isKindOfClass:NSHTTPURLResponse.class]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode >= 400) {
            [connection cancel];

            #warning proper error
            NSError *error = [NSError errorWithDomain:OMPromisesErrorDomain
                                code:0
                            userInfo:@{@"statusCode": @(httpResponse.statusCode)}];
            [self connection:connection didFailWithError:error];
        }

        self.response = (NSHTTPURLResponse *)response;
    }

    if (self.state == OMPromiseStateUnfulfilled) {
        [self progress:kLookupProgress];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self fulfil:[[OMHTTPResponse alloc] initWithCode:(NSUInteger)self.response.statusCode
                                              headers:self.response.allHeaderFields
                                                 body:self.data]];
}

@end
