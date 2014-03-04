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
#import "OMHTTPPromise.h"
#import "OMHTTPResponse.h"
#import "OMPromise+HTTP.h"

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
    OMPromise *get = [OMHTTPPromise get:@"http://reaktor42.de/images/robot.png"
                             parameters:@{@"test": @"asdf"}
                                options:nil];

    __block int called = 0;
    [[get fulfilled:^(id data) {

        called += 1;
    }] failed:^(NSError *error) {
        called += 1;
    }];

    WAIT_UNTIL(called == 1, 10, @"should have been called");
}

@end
