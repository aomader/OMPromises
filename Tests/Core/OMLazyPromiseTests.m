//
// OMLazyPromiseTests.m
// OMPromisesTests
//
// Copyright (C) 2016 Oliver Mader
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

#import "OMTests.h"

#import "OMLazyPromise.h"

@interface OMLazyPromiseTests : XCTestCase
@end

@implementation OMLazyPromiseTests

- (void)testTaskPromise {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    XCTAssertNotEqual(queue, dispatch_get_current_queue(), @"Current queue shouldnt be dispatch queue");
    
    __block int called = 0;
    OMLazyPromise *promise = [OMLazyPromise promiseWithTask:^id{
        XCTAssertEqual(queue, dispatch_get_current_queue(), @"Should run on specified queue");
        called += 1;
        return @1337;
    } on:queue];
    
    WAIT_FOR(.1);
    
    XCTAssertFalse(promise.started);
    XCTAssertEqual(called, 0);
    
    __block BOOL fulfilled = NO;
    [promise fulfilled:^(id  _Nullable result) {
        fulfilled = YES;
    }];
    
    WAIT_UNTIL(fulfilled, 1, @"Fulfilled should have been called");
    
    XCTAssertTrue(promise.started);
    XCTAssertEqual(called, 1);
    XCTAssertEqual(promise.state, OMPromiseStateFulfilled, @"Promise should be fulfilled");
    XCTAssertEqualObjects(promise.result, @1337, @"Promise should have the supplied result");
}

- (void)testForcedStart {
    __block BOOL ran = NO;

    OMLazyPromise *promise = [OMLazyPromise promiseWithTask:^id {
        ran = YES;
        return nil;
    }];

    WAIT_FOR(.1);

    XCTAssertFalse(promise.started);
    XCTAssertFalse(ran);

    [promise start];

    XCTAssertTrue(promise.started);
    WAIT_UNTIL(ran, 1, @"task should have been run");
}

- (void)testThenChaining {
    __block BOOL ran1 = NO;
    __block BOOL ran2 = NO;

    OMLazyPromise *origin = [OMLazyPromise promiseWithTask:^id {
        XCTAssertFalse(ran2);
        ran1 = YES;
        return @21;
    }];

    OMDeferred *deferred = [OMDeferred deferred];

    OMLazyPromise *chained = [origin then:^id(id result) {
        ran2 = YES;
        return deferred.promise;
    }];

    XCTAssertFalse(origin.started);
    XCTAssertFalse(chained.started);
    XCTAssertFalse(ran1);
    XCTAssertFalse(ran2);
    XCTAssertEqualWithAccuracy(chained.progress, 0.f, 0.001f);

    [chained fulfilled:^(id result) {
        // no-op
    }];

    WAIT_UNTIL(ran1, 1.0, @"Initial promise didn't run");

    XCTAssertTrue(origin.started);
    XCTAssertTrue(chained.started);
    XCTAssertTrue(ran1);
    XCTAssertTrue(ran2);
    XCTAssertEqualWithAccuracy(origin.progress, 1.f, 0.001f);
    XCTAssertEqualWithAccuracy(chained.progress, .5f, 0.001f);
    XCTAssertEqual(chained.state, OMPromiseStateUnfulfilled);

    [deferred progress:0.5f];

    XCTAssertEqualWithAccuracy(chained.progress, .75f, 0.001f);

    [deferred fulfil:@42];

    XCTAssertEqual(chained.state, OMPromiseStateFulfilled);
    XCTAssertEqualObjects(chained.result, @42);
}

- (void)testRescueChaining {
    __block BOOL ran1 = NO;
    __block BOOL ran2 = NO;

    OMLazyPromise *origin = [OMLazyPromise promiseWithDetailedTask:^(OMDeferred *deferred) {
        XCTAssertFalse(ran2);

        [deferred progress:.2f];
        [deferred fail:nil];

        ran1 = YES;
    }];

    OMDeferred *deferred = [OMDeferred deferred];

    OMLazyPromise *chained = [origin rescue:^id(NSError *error) {
        ran2 = YES;
        return deferred.promise;
    }];

    XCTAssertFalse(origin.started);
    XCTAssertFalse(chained.started);
    XCTAssertFalse(ran1);
    XCTAssertFalse(ran2);
    XCTAssertEqualWithAccuracy(chained.progress, 0.f, 0.001f);

    [chained progressed:^(float progress) {
        // no-op
    }];

    WAIT_UNTIL(ran1, 1.0, @"Initial promise didn't run");

    XCTAssertTrue(origin.started);
    XCTAssertTrue(chained.started);
    XCTAssertTrue(ran1);
    XCTAssertTrue(ran2);

    XCTAssertEqual(origin.state, OMPromiseStateFailed);
    XCTAssertEqualWithAccuracy(origin.progress, .2f, 0.001f);
    XCTAssertEqualWithAccuracy(chained.progress, .2f, 0.001f);
    XCTAssertEqual(chained.state, OMPromiseStateUnfulfilled);

    [deferred progress:0.5f];

    XCTAssertEqualWithAccuracy(chained.progress, .6f, 0.001f);

    [deferred fulfil:@42];

    XCTAssertEqual(chained.state, OMPromiseStateFulfilled);
    XCTAssertEqualObjects(chained.result, @42);
}

@end
