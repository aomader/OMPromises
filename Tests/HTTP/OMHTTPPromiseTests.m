//
// OMHTTPPromiseTests.h
// OMPromisesTests
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

#import <XCTest/XCTest.h>

#import "OMPromises.h"

#define WAIT_UNTIL(condition, timeout, msg, ...) \
    { \
        NSDate *date = [NSDate date]; \
        while (!(condition)) { \
            if ([date timeIntervalSinceNow] < -timeout) { \
                XCTFail(msg); \
                break;\
            } \
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.]]; \
        } \
    }

@interface OMHTTPPromiseTests : XCTestCase
@end

@implementation OMHTTPPromiseTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGet {
        /*
    OMPromise *get = [OMHTTPPromise get:@"http://headers.jsontest.com/"
                             parameters:@{@"test": @"asdf"}
                                options:nil];
    */
    OMPromise *get = [OMHTTPRequest get:@"http://reaktor42.de/images/robot.png?foo={bar}&newbar={bar}&test={nich1da}"
                             parameters:@{@"bar": @"asdf=?"}
                                options:@{OMHTTPTimeout: @3., OMHTTPSerialization: OMHTTPSerializationQueryString}];
    //[get cancel];
    
    get = [get httpParseImage];

    __block int called = 0;
    [[get fulfilled:^(id data) {

        called += 1;
    }] failed:^(NSError *error) {
        called += 1;
    }];

    WAIT_UNTIL(called == 1, 10, @"should have been called");
    
    get = nil;
}

- (void)testCustomHeaders {
    OMPromise *request = [OMHTTPRequest get:@"http://headers.jsontest.com"
                                 parameters:nil
                                    options:@{
                                        @"X-Custom-Header": @"arr1",
                                        @"Y-Custom-Header": @"arr2"
                                    }].httpParseJSON;
    
    __block int called = 0;
    [request fulfilled:^(NSDictionary *headers) {
        XCTAssert([headers[@"X-Custom-Header"] isEqualToString:@"arr1"], @"We should have sent custom headers");
        XCTAssert([headers[@"Y-Custom-Header"] isEqualToString:@"arr2"], @"We should have sent custom headers");
        called += 1;
    }];
    
    WAIT_UNTIL(called == 1, 10, @"should have finished successfully");
}

- (void)testUrlInterpolation {
    OMPromise *request = [OMHTTPRequest get:@"http://echo.jsontest.com/{key}/{value}"
                                 parameters:@{
                                     @"key": @"arr",
                                     @"value": @"hey"
                                 } options:nil].httpParseJSON;
    
    __block int called = 0;
    [request fulfilled:^(NSDictionary *data) {
        XCTAssert([data[@"arr"] isEqualToString:@"hey"], @"We should have requested an interpolated url");
        called += 1;
    }];
    
    WAIT_UNTIL(called == 1, 10, @"should have finished successfully");
}

@end
