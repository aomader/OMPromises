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
#import "OMResources.h"

static const NSTimeInterval kDefaultTimeoutInterval = 20.;
static const float kDefaultLookupProgress = .05f;

NSString *const OMPromisesHTTPErrorDomain = @"de.reaktor42.OMPromises.HTTP";
NSString *const OMHTTPResponseKey = @"response";
NSString *const OMHTTPTimeout = @"OMHTTPTimeout";
NSString *const OMHTTPLookupProgress = @"OMHTTPLookupProgress";
NSString *const OMHTTPSerialization = @"OMHTTPSerialization";
NSString *const OMHTTPSerializationQueryString = @"querystring";
NSString *const OMHTTPSerializationJSON = @"json";
NSString *const OMHTTPSerializationURLEncoded = @"urlencoded";
NSString *const OMHTTPAllowInvalidCertificates = @"allowinvalidcertificates";

@interface OMHTTPRequest () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property(assign, nonatomic) float lookup;
@property(nonatomic) NSURLConnection *connection;
@property(nonatomic) OMHTTPResponse *response;
@property(nonatomic) NSMutableData *data;
@property(assign, nonatomic) NSUInteger expectedContentLength;
@property(nonatomic) BOOL allowInvalidCertificates;

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
        NSAssert(url, @"URL is required.");
        NSAssert(method, @"Method is required.");
        NSAssert([url.scheme.lowercaseString hasPrefix:@"http"], @"Only HTTP(S) requests are supported.");
        
        _lookup = options[OMHTTPLookupProgress] ? [options[OMHTTPLookupProgress] floatValue] : kDefaultLookupProgress;
        _allowInvalidCertificates = [(options[OMHTTPAllowInvalidCertificates] ?: @NO) boolValue];
        _connection = [[NSURLConnection alloc]
                       initWithRequest:[self requestForURL:url method:method parameters:parameters options:options]
                       delegate:self
                       startImmediately:YES];
        
        // cancellation support
        __weak OMHTTPRequest *weakSelf = self;
        [self cancelled:^(OMDeferred *_) {
            [weakSelf.connection cancel];
        }];
    }
    return self;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection
        willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (self.allowInvalidCertificates &&
            [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        NSLog(@"Ignoring SSL");

        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
             forAuthenticationChallenge:challenge];

        return;
    }

    [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSMutableDictionary *userInfo = @{
        NSLocalizedDescriptionKey: OMLocalizedString(@"error_http_request_%@", error),
        NSUnderlyingErrorKey: error
    }.mutableCopy;

    if (self.response) {
        userInfo[OMHTTPResponseKey] = self.response;
    }

    [self fail:[NSError errorWithDomain:OMPromisesHTTPErrorDomain
                                   code:OMPromisesHTTPRequestError
                               userInfo:userInfo]];
}

#pragma mark - NSURLConnectionDataDelegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
    
    if (self.expectedContentLength > 0) {
        [self progress:MIN(1.0f, self.lookup + (1 - self.lookup) *
                (float)self.data.length / self.expectedContentLength)];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    NSAssert([response isKindOfClass:NSHTTPURLResponse.class], @"An NSHTTPURLResponse was expected!");
    
    self.expectedContentLength = (NSUInteger)(response.expectedContentLength > 0 ? response.expectedContentLength : 0);
    self.data = [NSMutableData dataWithCapacity:self.expectedContentLength > 0 ? self.expectedContentLength : 16];
    self.response = [[OMHTTPResponse alloc] initWithCode:(NSUInteger)response.statusCode
                                                 headers:response.allHeaderFields
                                                    body:self.data];
    
    if (response.statusCode >= 400) {
        [connection cancel];

        [self fail:[NSError errorWithDomain:OMPromisesHTTPErrorDomain
                                       code:OMPromisesHTTPStatusError
                                   userInfo:@{
                                       NSLocalizedDescriptionKey: OMLocalizedString(@"error_http_status_%i%@",
                                           response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]),
                                       OMHTTPResponseKey: self.response
                                   }]];
    } else {
        [self progress:self.lookup];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self fulfil:self.response];
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
                                  urlString:urlString
                                 parameters:parameters
                                    options:options
                             defaultOptions:@{OMHTTPSerialization: OMHTTPSerializationQueryString}];
}

+ (OMPromise *)post:(NSString *)urlString
         parameters:(NSDictionary *)parameters
            options:(NSDictionary *)options
{
    return [OMHTTPRequest requestWithMethod:@"POST"
                                  urlString:urlString
                                 parameters:parameters
                                    options:options
                             defaultOptions:nil];
}

+ (OMPromise *)put:(NSString *)urlString
        parameters:(NSDictionary *)parameters
           options:(NSDictionary *)options
{
    return [OMHTTPRequest requestWithMethod:@"PUT"
                                  urlString:urlString
                                 parameters:parameters
                                    options:options
                             defaultOptions:nil];
}

+ (OMPromise *)head:(NSString *)urlString
         parameters:(NSDictionary *)parameters
            options:(NSDictionary *)options
{
    return [OMHTTPRequest requestWithMethod:@"HEAD"
                                  urlString:urlString
                                 parameters:parameters
                                    options:options
                             defaultOptions:nil];
}

+ (OMPromise *)delete:(NSString *)urlString
           parameters:(NSDictionary *)parameters
              options:(NSDictionary *)options
{
    return [OMHTTPRequest requestWithMethod:@"DELETE"
                                  urlString:urlString
                                 parameters:parameters
                                    options:options
                             defaultOptions:nil];
}

#pragma mark - Private Helper Methods

+ (OMPromise *)requestWithMethod:(NSString *)method
                       urlString:(NSString *)urlString
                      parameters:(NSDictionary *)parameters
                         options:(NSDictionary *)options
                  defaultOptions:(NSDictionary *)defaultOptions
{
    // merge default options
    if (defaultOptions) {
        NSMutableDictionary *mutableOptions = defaultOptions.mutableCopy;
        [mutableOptions addEntriesFromDictionary:options];
        options = mutableOptions;
    }
    
    // interpolate url string
    if (parameters && parameters.count > 0) {
        NSMutableDictionary *mutableParameters = parameters.mutableCopy;
        NSMutableString *mutableUrlString = [NSMutableString stringWithCapacity:urlString.length];
        
        __block NSUInteger recentEnd = 0;
        [[NSRegularExpression regularExpressionWithPattern:@"\\{\\w+\\}" options:0 error:nil]
            enumerateMatchesInString:urlString options:0
            range:NSMakeRange(0, urlString.length)
            usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                [mutableUrlString appendString:[urlString substringWithRange:NSMakeRange(recentEnd, result.range.location - recentEnd)]];
                recentEnd = result.range.location + result.range.length;
                
                NSString *key = [urlString substringWithRange:NSMakeRange(result.range.location + 1, result.range.length - 2)];
                NSString *value = [OMHTTPRequest escapeString:parameters[key]];
                
                if (value) {
                    [mutableUrlString appendString:value];
                    [mutableParameters removeObjectForKey:key];
                }
            }];
        
        if (recentEnd > 0) {
            [mutableUrlString appendString:[urlString substringFromIndex:recentEnd]];
            urlString = mutableUrlString;
            parameters = mutableParameters;
        }
    }

    // trim leading/trailing whitespace
    urlString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return [OMHTTPRequest requestWithMethod:method
                                        url:[NSURL URLWithString:urlString]
                                 parameters:parameters
                                    options:options];
}

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
        
        if (!options[OMHTTPSerialization] ||
            [options[OMHTTPSerialization] isEqualToString:OMHTTPSerializationURLEncoded])
        {
            contentType = @"application/x-www-form-urlencoded";
            request.HTTPBody = [OMHTTPRequest buildURLEncodedData:parameters];
        } else if ([options[OMHTTPSerialization] isEqualToString:OMHTTPSerializationJSON]) {
            contentType = @"application/json";
            NSError *error = nil;
            request.HTTPBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
            NSAssert(!error, @"We should be able to serialize the JSON data but failed: %@", error);
        }
        
        if (request.HTTPBody) {
            [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
            [request setValue:[@(request.HTTPBody.length) stringValue] forHTTPHeaderField:@"Content-Length"];
        }
    }
    
    // add http headers
    NSSet *ownOptions = [NSSet setWithObjects:OMHTTPTimeout, OMHTTPLookupProgress, OMHTTPSerialization,
            OMHTTPAllowInvalidCertificates, nil];
    for (NSString *key in options.keyEnumerator) {
        if (![ownOptions containsObject:key]) {
            [request setValue:options[key] forHTTPHeaderField:key];
        }
    }
    
    return request;
}

+ (NSData *)buildURLEncodedData:(NSDictionary *)parameters {
    NSMutableArray *pairs = [NSMutableArray arrayWithCapacity:parameters.count];
    for (NSString *key in parameters.keyEnumerator) {
        [pairs addObject:[NSString stringWithFormat:@"%@=%@",
             [OMHTTPRequest escapeFormString:key], [OMHTTPRequest escapeFormString:parameters[key]]]];
    }
    return [[pairs componentsJoinedByString:@"&"] dataUsingEncoding:NSASCIIStringEncoding];
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
        NULL, (__bridge CFStringRef)string, NULL, CFSTR("/%&=?$#+-~@<>|\\*,.()[]{}^!"), kCFStringEncodingUTF8);
}

+ (NSString *)escapeFormString:(NSString *)string {
    NSString *str = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
        NULL, (__bridge CFStringRef)string, CFSTR(" "), CFSTR("/%&=?$#+-~@<>|\\*,.()[]{}^!\n\r"), kCFStringEncodingUTF8);
    return [str stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}

@end
