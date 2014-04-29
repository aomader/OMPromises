//
// OMDeferredTests.m
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

#import "OMTests.h"

@interface OMDeferredTests : XCTestCase
@end

@implementation OMDeferredTests

- (void)testInitialValues {
    OMDeferred *deferred = [OMDeferred deferred];
    
    XCTAssertEqual(deferred.state, OMPromiseStateUnfulfilled, @"Should initially be Unfulfilled");
    XCTAssertNil(deferred.result, @"There shouldn't be a result yet");
    XCTAssertNil(deferred.error, @"There shouldn't be an error");
    XCTAssertEqualWithAccuracy(deferred.progress, 0.f, FLT_EPSILON, @"Progress should be 0");
    XCTAssertFalse(deferred.cancellable, @"Not cancellable by default");
}

- (void)testFulfil {
    OMDeferred *deferred = [OMDeferred deferred];
    
    id result = @.1337f;
    [deferred fulfil:result];
    
    XCTAssertEqual(deferred.state, OMPromiseStateFulfilled, @"Should be Fulfilled by now");
    XCTAssertEqual(deferred.result, result, @"There should be the supplied result by now");
    XCTAssertNil(deferred.error, @"There shouldn't be an error");
    XCTAssertEqualWithAccuracy(deferred.progress, 1.f, FLT_EPSILON, @"Progress should be 1");
    
    XCTAssertThrows([deferred fulfil:nil], @"Shouldn't be possible to do further state changes");
    XCTAssertThrows([deferred fail:nil], @"Shouldn't be possible to do further state changes");
    XCTAssertThrows([deferred progress:1.f], @"Shouldn't be possible to do further state changes");
}

- (void)testFail {
    OMDeferred *deferred = [OMDeferred deferred];
    
    NSError *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:nil];
    [deferred fail:error];
    
    XCTAssertEqual(deferred.state, OMPromiseStateFailed, @"Should be Failed by now");
    XCTAssertEqual(deferred.error, error, @"There should be the supplied error by now");
    XCTAssertNil(deferred.result, @"There shouldn't be an result");
    XCTAssertEqualWithAccuracy(deferred.progress, 0.f, FLT_EPSILON, @"Progress should be unchanged");
    
    XCTAssertThrows([deferred fulfil:nil], @"Shouldn't be possible to do further state changes");
    XCTAssertThrows([deferred fail:nil], @"Shouldn't be possible to do further state changes");
    XCTAssertThrows([deferred progress:1.f], @"Shouldn't be possible to do further state changes");
}

- (void)testProgress {
    OMDeferred *deferred = [OMDeferred deferred];
    
    [deferred progress:.1f];
    
    XCTAssertEqual(deferred.state, OMPromiseStateUnfulfilled, @"Should still be Unfulfilled");
    XCTAssertNil(deferred.error, @"There shouldn't be a result");
    XCTAssertNil(deferred.result, @"There shouldn't be an error");
    XCTAssertEqualWithAccuracy(deferred.progress, .1f, FLT_EPSILON, @"Progress should be .1");
    
    [deferred progress:.2f];
    XCTAssertEqualWithAccuracy(deferred.progress, .2f, FLT_EPSILON, @"Progress should be .2");
    
    XCTAssertNoThrow([deferred progress:.2f], @"Progress should ignore identical values");
    XCTAssertEqualWithAccuracy(deferred.progress, .2f, FLT_EPSILON, @"Progress should be .2");
    
    XCTAssertThrows([deferred progress:.1f], @"Must not decrease progress");
    XCTAssertEqualWithAccuracy(deferred.progress, .2f, FLT_EPSILON, @"Progress shouldn't have changed");
}

- (void)testProgressPrecision {
    OMDeferred *deferred = [OMDeferred deferred];
    
    __block int called = 0;
    [deferred.promise progressed:^(float progress) {
        float values[] = {.1f, .1 + 2.f*FLT_EPSILON};
        XCTAssertEqualWithAccuracy(values[called], progress, FLT_EPSILON, @"Unexpected progress");
        called += 1;
    }];
    
    [deferred progress:.1f];
    XCTAssertEqual(called, 1, @"Should have progressed once");
    
    
    XCTAssertNoThrow([deferred progress:.1f - FLT_EPSILON], @"We anticipate a certain error");
    
    [deferred progress:.1f + FLT_EPSILON];
    XCTAssertEqual(called, 1, @"We dont progress if change is too small");
    
    [deferred progress:.1f + 2.f*FLT_EPSILON];
    XCTAssertEqual(called, 2, @"Finally we progress if the change is large enough");
}

- (void)testTryFulfil {
    OMDeferred *deferred = [OMDeferred deferred];

    id result = @.1337f;
    XCTAssertTrue([deferred tryFulfil:result]);

    XCTAssertEqual(deferred.state, OMPromiseStateFulfilled, @"Should be Fulfilled by now");
    XCTAssertEqual(deferred.result, result, @"There should be the supplied result by now");
    XCTAssertNil(deferred.error, @"There shouldn't be an error");
    XCTAssertEqualWithAccuracy(deferred.progress, 1.f, FLT_EPSILON, @"Progress should be 1");

    id result2 = @.1338f;
    XCTAssertFalse([deferred tryFulfil:result2]);

    XCTAssertEqual(deferred.result, result, @"Result should be unchanged");
}

- (void)testTryFail {
    OMDeferred *deferred = [OMDeferred deferred];

    NSError *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:nil];
    XCTAssertTrue([deferred tryFail:error]);

    XCTAssertEqual(deferred.state, OMPromiseStateFailed, @"Should be Failed by now");
    XCTAssertEqual(deferred.error, error, @"There should be the supplied error by now");
    XCTAssertNil(deferred.result, @"There shouldn't be an result");
    XCTAssertEqualWithAccuracy(deferred.progress, 0.f, FLT_EPSILON, @"Progress should be unchanged");

    NSError *error2 = [NSError errorWithDomain:NSPOSIXErrorDomain code:1 userInfo:nil];
    XCTAssertFalse([deferred tryFail:error2]);

    XCTAssertEqual(deferred.error, error, @"Error should be unchanged");
}

- (void)testCancelled {
    OMDeferred *deferred = [OMDeferred deferred];
    OMPromise *promise = deferred.promise;
    
    __block int cancelled = 0;
    
    [deferred cancelled:^(OMDeferred *d) {
        XCTAssertEqual(deferred, d, @"Passed deferred should be equal to created one");
        XCTAssertEqual(promise.error.domain, OMPromisesErrorDomain, @"Error domain incorrect");
        XCTAssertEqual(promise.error.code, OMPromisesCancelledError, @"Error code should be cancelled");
        XCTAssertNil(promise.result, @"There shouldn't be an result");
        cancelled += 1;
    }];
    
    XCTAssertTrue(promise.cancellable, @"Now it should be cancellable");
    
    [promise cancel];
    
    XCTAssertEqual(cancelled, 1, @"Cancel handler should be called once");
    
    XCTAssertThrows([deferred fulfil:nil], @"Shouldn't be possible to do further state changes");
    XCTAssertThrows([deferred fail:nil], @"Shouldn't be possible to do further state changes");
    XCTAssertThrows([deferred progress:1.f], @"Shouldn't be possible to do further state changes");
}

@end
