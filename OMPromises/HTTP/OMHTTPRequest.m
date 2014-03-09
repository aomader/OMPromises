//
// OMHTTPRequest.m
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

#import "OMHTTPRequest.h"

#import "OMHTTPResponse.h"

static const NSTimeInterval kDefaultTimeoutInterval = 20.;
static const float kDefaultLookupProgress = .05f;

NSString *const OMHTTPTimeout = @"OMHTTPTimeout";
NSString *const OMHTTPLookupProgress = @"OMHTTPLookupProgress";
NSString *const OMHTTPSerialization = @"OMHTTPSerialization";
NSString *const OMHTTPSerializationQueryString = @"querystring";
NSString *const OMHTTPSerializationJSON = @"json";
NSString *const OMHTTPSerializationURLEncoded = @"urlencoded";

@interface OMHTTPRequest () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property(assign, nonatomic) float lookup;
@property(nonatomic) NSURLConnection *connection;
@property(nonatomic) NSHTTPURLResponse *response;
@property(nonatomic) NSMutableData *data;

@end

@implementation OMHTTPRequest

#pragma mark - Init

- (id)initWithURL:(NSURL *)url
           method:(NSString *)method
       parameters:(NSDictionary *)parameters
          options:(NSDictionary *)options
{
    self = [super init];
    if (self) {
        NSAssert([url.scheme.lowercaseString hasPrefix:@"http"], @"Only HTTP(S) requests are supported.");
        
        _lookup = options[OMHTTPLookupProgress] ? [options[OMHTTPLookupProgress] floatValue] : kDefaultLookupProgress;
        _data = [NSMutableData data];
        _connection = [[NSURLConnection alloc]
                       initWithRequest:[self requestForURL:url method:method parameters:parameters options:options]
                       delegate:self
                       startImmediately:YES];
    }
    return self;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self fail:error];
}

#pragma mark - NSURLConnectionDataDelegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
    
    if (self.response.expectedContentLength > 0) {
        [self progress:self.lookup + (1 - self.lookup) *
                (float)self.data.length / self.response.expectedContentLength];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    NSAssert([response isKindOfClass:NSHTTPURLResponse.class], @"An NSHTTPURLResponse was expected!");
    
    if (response.statusCode >= 400) {
        [connection cancel];

            #warning proper error
        NSError *error = [NSError errorWithDomain:OMPromisesErrorDomain
                                             code:0
                                         userInfo:@{@"statusCode": @(response.statusCode)}];
        [self connection:connection didFailWithError:error];
    } else {
        self.response = response;
        [self progress:self.lookup];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self fulfil:[[OMHTTPResponse alloc] initWithCode:(NSUInteger)self.response.statusCode
                                              headers:self.response.allHeaderFields
                                                 body:self.data]];
}

#pragma mark - Private Helper Methods

- (NSURLRequest *)requestForURL:(NSURL *)url
                         method:(NSString *)method
                     parameters:(NSDictionary *)parameters
                        options:(NSDictionary *)options
{
    // add query string to URL
    if (parameters && [options[OMHTTPSerialization] isEqualToString:OMHTTPSerializationQueryString]) {
        NSString *queryString = [OMHTTPRequest buildQueryString:parameters];
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%c%@", url.absoluteString,
                                    url.query.length ? '&' : '?', queryString]];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
            initWithURL:url
            cachePolicy:NSURLRequestReloadIgnoringCacheData
        timeoutInterval:options[OMHTTPTimeout] ? [options[OMHTTPTimeout] doubleValue] : kDefaultTimeoutInterval];
    request.HTTPMethod = method;
    
    // generate body
    if (parameters) {
        NSString *contentType;
        
        if ([options[OMHTTPSerialization] isEqualToString:OMHTTPSerializationJSON]) {
            contentType = @"application/json";
#warning handle error
            request.HTTPBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
        } else if ([options[OMHTTPSerialization] isEqualToString:OMHTTPSerializationURLEncoded]) {
            contentType = @"application/x-www-form-urlencoded";
            request.HTTPBody = [OMHTTPRequest buildURLEncodedData:parameters];
        }
        
        if (request.HTTPBody) {
            [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
            [request setValue:[@(request.HTTPBody.length) stringValue] forHTTPHeaderField:@"Content-Length"];
        }
    }
    
    // add http headers
    NSArray *ownOptions = @[OMHTTPTimeout, OMHTTPLookupProgress, OMHTTPSerialization];
    for (NSString *key in options.keyEnumerator) {
        if (![ownOptions containsObject:key]) {
            [request setValue:options[key] forHTTPHeaderField:key];
        }
    }
    
    return request;
}

+ (NSData *)buildURLEncodedData:(NSDictionary *)parameters {
#warning add implementation
    return nil;
}

+ (NSString *)buildQueryString:(NSDictionary *)parameters {
    NSMutableArray *pairs = [NSMutableArray arrayWithCapacity:parameters.count];
    for (NSString *key in parameters.keyEnumerator) {
        [pairs addObject:[NSString stringWithFormat:@"%@=%@",
                          [OMHTTPRequest escapeString:key], [OMHTTPRequest escapeString:parameters[key]]]];
    }
    return [pairs componentsJoinedByString:@"&"];
}

+ (NSString *)escapeString:(NSString *)string {
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
        NULL, (CFStringRef)string, NULL, CFSTR("/%&=?$#+-~@<>|\\*,.()[]{}^!"), kCFStringEncodingUTF8);
}

#pragma mark - Public Static Methods

+ (OMPromise *)requestWithMethod:(NSString *)method
                             url:(NSURL *)url
                      parameters:(NSDictionary *)parameters
                         options:(NSDictionary *)options
{
    return [[OMHTTPRequest alloc] initWithURL:url
                                       method:method
                                   parameters:parameters
                                      options:options].promise;
}

+ (OMPromise *)get:(NSString *)urlString
        parameters:(NSDictionary *)parameters
           options:(NSDictionary *)options
{
    return [OMHTTPRequest requestWithMethod:@"GET"
                                        url:[NSURL URLWithString:urlString]
                                 parameters:parameters
                                    options:options];
}

+ (OMPromise *)post:(NSString *)urlString
         parameters:(NSDictionary *)parameters
            options:(NSDictionary *)options
{
    return [OMHTTPRequest requestWithMethod:@"POST"
                                        url:[NSURL URLWithString:urlString]
                                 parameters:parameters
                                    options:options];
}

+ (OMPromise *)put:(NSString *)urlString
        parameters:(NSDictionary *)parameters
           options:(NSDictionary *)options
{
    return [OMHTTPRequest requestWithMethod:@"PUT"
                                        url:[NSURL URLWithString:urlString]
                                 parameters:parameters
                                    options:options];
}

+ (OMPromise *)head:(NSString *)urlString
         parameters:(NSDictionary *)parameters
            options:(NSDictionary *)options
{
    return [OMHTTPRequest requestWithMethod:@"HEAD"
                                        url:[NSURL URLWithString:urlString]
                                 parameters:parameters
                                    options:options];
}

+ (OMPromise *)delete:(NSString *)urlString
           parameters:(NSDictionary *)parameters
              options:(NSDictionary *)options
{
    return [OMHTTPRequest requestWithMethod:@"DELETE"
                                        url:[NSURL URLWithString:urlString]
                                 parameters:parameters
                                    options:options];
}

@end
