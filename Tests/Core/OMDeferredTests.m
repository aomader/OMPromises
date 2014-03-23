//
// OMDeferredTests.h
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
#import <Foundation/Foundation.h>
#define FLT_EPSILON .0000001f
#import "OMPromises.h"

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

