//
// OMPromiseTests.h
// OMPromisesTests
//
// Copyright (C) 2013 Oliver Mader
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

@interface OMPromisesTests : XCTestCase

@property id result;
@property id result2;
@property NSError *error;

@end

@implementation OMPromisesTests

- (void)setUp {
    self.result = @.1337;
    self.result2 = @.31337;
    self.error = [NSError ];
}

- (void)testFulfilledPromise {
    OMPromise *promise = [OMPromise promiseWithResult:self.result];
    
    XCTAssertEqual(promise.state, OMPromiseStateFulfilled, @"Promise should be fulfilled");
    XCTAssertEqual(promise.result, self.result, @"Promise should have the supplied result");
    XCTAssertEqualWithAccuracy(promise.progress.floatValue, 1.f, FLT_EPSILON, @"Progress should be 1");
}

- (void)testFailedPromise {
    OMPromise *promise = [OMPromise promiseWithError:self.error];
    
    XCTAssertEqual(promise.state, OMPromiseStateFailed, @"Promise should be failed");
    XCTAssertEqual(promise.error, self.error, @"Promise should have the supplied error");
    XCTAssertEqualWithAccuracy(promise.progress.floatValue, 0.f, FLT_EPSILON, @"Progress should be 0");
}

- (void)testBindOnAlreadyFulfilledPromise {
    OMPromise *promise = [OMPromise promiseWithResult:self.result];
    
    __block BOOL called = NO, progressCalled = NO;
    [[[promise fulfilled:^(id result) {
        XCTAssertEqual(result, self.result, @"The supplied result should be identical");
        XCTAssertTrue(progressCalled, @"progress-block should have been called before fulfilled-block");
        called = YES;
    }] failed:^(NSError *error) {
        XCTFail(@"Fail should not have been called");
    }] progressed:^(NSNumber *progress) {
        XCTAssertFalse(called, @"progressed-block should be called before fulfilled-block");
        XCTAssertEqualWithAccuracy(progress.floatValue, 1.f, FLT_EPSILON, @"Progress should be 1");
        progressCalled = YES;
    }];
    
    XCTAssertTrue(called, @"fulfilled-block should have been called");
}

- (void)testBindsOnNotAlreadyFulfilledPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    __block BOOL called = NO, progressCalled = NO;
    [[[promise fulfilled:^(id result) {
        XCTAssertEqual(result, self.result, @"The supplied result should be identical");
        XCTAssertTrue(progressCalled, @"progress-block should have been called before fulfilled-block");
        called = YES;
    }] failed:^(NSError *error) {
        XCTFail(@"Fail should not have been called");
    }] progressed:^(NSNumber *progress) {
        XCTAssertFalse(called, @"progressed-block should be called before fulfilled-block");
        XCTAssertEqualWithAccuracy(progress.floatValue, 1.f, FLT_EPSILON, @"Progress should be 1");
        progressCalled = YES;
    }];

    XCTAssertFalse(called, @"fulfilled-block should not have been called");
    [deferred fulfil:self.result];
    XCTAssertTrue(called, @"fulfilled-block should have been called");
}

- (void)testBindsOnAlreadyFailedPromise {
    OMPromise *promise = [OMPromise promiseWithError:self.error];

    __block BOOL called = NO;
    [[[promise fulfilled:^(id result) {
        XCTFail(@"fulfilled-block should not have been called");
    }] failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"The supplied error should be identical");
        called = YES;
    }] progressed:^(NSNumber *progress) {
        XCTFail(@"progressed-block should not have been called");
    }];
    
    XCTAssertTrue(called, @"failed-block should have been called");
}

- (void)testBindsOnNotAlreadyFailedPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    __block BOOL called = NO;
    [[[promise fulfilled:^(id result) {
        XCTFail(@"fulfilled-block should not have been called");
    }] failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"The supplied error should be identical");
        called = YES;
    }] progressed:^(NSNumber *progress) {
        XCTFail(@"progressed-block should not have been called");
    }];
    
    XCTAssertFalse(called, @"failed-block should not have been called yet");
    [deferred fail:self.error];
    XCTAssertTrue(called, @"failed-block should have been called");
}

- (void)testIncreasingProgress {
    OMDeferred *deferred = [OMDeferred deferred];

    NSArray *values = @[@.1f, @.5f, @1.f];
    
    __block NSUInteger called = 0;
    [deferred.promise progressed:^(NSNumber *progress) {
        XCTAssertEqualWithAccuracy([values[called] floatValue], progress.floatValue, FLT_EPSILON, @"Unexpected progress");
        called += 1;
    }];

    XCTAssertEqual(called, 0, @"progressed-block should not have been called until now");
    [deferred progress:values[0]];
    XCTAssertEqual(called, 1, @"progressed-block should be called once");
    [deferred progress:values[0]];
    XCTAssertEqual(called, 1, @"progressed-block should be called once");
    [deferred progress:values[1]];
    XCTAssertEqual(called, 2, @"progressed-block should be called twice");
    [deferred fulfil:self.result];
    XCTAssertEqual(called, 3, @"progressed-block should be called three times");
}

- (void)testMultipleBindsOnNotAlreadyFulfilledPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    __block NSUInteger called1 = 0, called2 = 0;
    [[deferred.promise fulfilled:^(id result) {
        XCTAssertEqual(result, self.result, @"The supplied result should be identical");
        called1 += 1;
    }] fulfilled:^(id result) {
        XCTAssertEqual(result, self.result, @"The supplied result should be identical");
        called2 += 1;
    }];

    XCTAssertEqual(called1, 0, @"first fulfilled-block should not have been called yet");
    XCTAssertEqual(called2, 0, @"second fulfilled-block should not have been called yet");
    [deferred fulfil:self.result];
    XCTAssertEqual(called1, 1, @"first fulfilled-block should have been called once");
    XCTAssertEqual(called2, 1, @"second fulfilled-block should have been called once");
}

- (void)testMultipleBindsOnNotAlreadyFailedPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    __block NSUInteger called1 = 0, called2 = 0;
    [[deferred.promise failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"The supplied error should be identical");
        called1 += 1;
    }] failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"The supplied error should be identical");
        called2 += 1;
    }];

    XCTAssertEqual(called1, 0, @"first fulfilled-block should not have been called yet");
    XCTAssertEqual(called2, 0, @"second fulfilled-block should not have been called yet");
    [deferred fulfil:self.result];
    XCTAssertEqual(called1, 1, @"first fulfilled-block should have been called once");
    XCTAssertEqual(called2, 1, @"second fulfilled-block should have been called once");
}

- (void)testThenReturnPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    __block NSUInteger called = 0, calledProgress = 0, calledFulfil = 0, calledFail = 0;
    OMDeferred *nextDeferred = [OMDeferred deferred];
    OMPromise *nextPromise = [[[[[[deferred.promise then:^(id result) {
        XCTAssertEqual(result, self.result, @"Supplied result should be identical to the one passed to fulfil:");
        called += 1;
        return nextDeferred.promise;
    }] progressed:^(NSNumber *progress) {
        calledProgress += 1;
    }] fulfilled:^(id result) {
        XCTAssertEqual(result, self.result2, @"Supplied result should be identical to the one passed to fulfil:");
        calledFulfil += 1;
    }] then:^(id result) {
        return [OMPromise promiseWithError:self.error];
    }] then:^(id result) {
        XCTFail(@"On error then should short circuit");
        return result;
    }] failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"Supplied error should be identical to previous error in chain");
        calledFail += 1;
    }];

    [deferred fulfil:self.result];
    XCTAssertEqual(nextPromise.state, OMPromiseStateUnfulfilled, @"Second promise should not be fulfilled yet");
    XCTAssertEqual(called, 1, @"then-block should have been called exactly once");

    [nextDeferred progress:@.5f];
    [nextDeferred fulfil:self.result2];
    XCTAssertEqual(nextPromise.state, OMPromiseStateFulfilled, @"Second promise should be fulfilled");
    XCTAssertEqual(calledProgress, 2, @"progressed-block should have been called exactly twice");
    XCTAssertEqual(calledFulfil, 1, @"fulfilled-block should have been called exactly once");
    XCTAssertEqual(calledFail, 1, @"failed-block should have been called exactly once");
}

- (void)testThenReturnValue {
    OMDeferred *deferred = [OMDeferred deferred];

    __block NSUInteger called = 0, calledFulfil = 0;
    OMPromise *nextPromise = [[[deferred.promise then:^(id result) {
        called += 1;
        return self.result2;
    }] fulfilled:^(id result) {
        XCTAssertEqual(result, self.result2, @"Supplied result should be identical to the previously returned one");
        calledFulfil += 1;
    }] failed:^(NSError *error) {
        XCTFail(@"failed-block shouldn't be called");
    }];

    [deferred fulfil:self.result];
    XCTAssertEqual(nextPromise.state, OMPromiseStateFulfilled, @"Second promise should be fulfilled");
    XCTAssertEqual(nextPromise.result, self.result, @"Final result should be the last returned one");
    XCTAssertEqual(called, 1, @"then-block should have been called exactly once");
    XCTAssertEqual(calledFulfil, 1, @"fulfilled-block should have been called exactly once");
}

- (void)testRescueReturnPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    __block NSUInteger called = 0, calledProgress = 0, calledFulfil = 0, calledFail = 0;
    OMDeferred *nextDeferred = [OMDeferred deferred];
    OMPromise *nextPromise = [[[[[[deferred.promise rescue:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"Supplied error should be identical to the one passed to fail:");
        called += 1;
        return nextDeferred.promise;
    }] progressed:^(NSNumber *progress) {
        calledProgress += 1;
    }] fulfilled:^(id result) {
        XCTAssertEqual(result, self.result2, @"Supplied result should be identical to the one passed to fulfil:");
        calledFulfil += 1;
    }] then:^(id result) {
        return [OMPromise promiseWithError:self.error];
    }] then:^(id result) {
        XCTFail(@"On error then should short circuit");
        return result;
    }] failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"Supplied error should be identical to previous error in chain");
        calledFail += 1;
    }];

    [deferred fail:self.error];
    XCTAssertEqual(nextPromise.state, OMPromiseStateUnfulfilled, @"Second promise should not be fulfilled yet");
    XCTAssertEqual(called, 1, @"rescue-block should have been called exactly once");

    [nextDeferred progress:@.5f];
    [nextDeferred fulfil:self.result2];
    XCTAssertEqual(nextPromise.state, OMPromiseStateFulfilled, @"Second promise should be fulfilled");
    XCTAssertEqual(calledProgress, 2, @"progressed-block should have been called exactly twice");
    XCTAssertEqual(calledFulfil, 1, @"fulfilled-block should have been called exactly once");
    XCTAssertEqual(calledFail, 1, @"failed-block should have been called exactly once");
}

- (void)testRescueReturnValue {
    OMDeferred *deferred = [OMDeferred deferred];

    __block NSUInteger called = 0, calledFulfil = 0;
    OMPromise *nextPromise = [[[deferred.promise rescue:^(NSError *error) {
        called += 1;
        return self.result;
    }] fulfilled:^(id result) {
        XCTAssertEqual(result, self.result2, @"Supplied result should be identical to the previously returned one");
        calledFulfil += 1;
    }] failed:^(NSError *error) {
        XCTFail(@"failed-block shouldn't be called");
    }];

    [deferred fail:self.error];
    XCTAssertEqual(nextPromise.state, OMPromiseStateFulfilled, @"Second promise should be fulfilled");
    XCTAssertEqual(nextPromise.result, self.result, @"Final result should be the last returned one");
    XCTAssertEqual(called, 1, @"rescue-block should have been called exactly once");
    XCTAssertEqual(calledFulfil, 1, @"fulfilled-block should have been called exactly once");
}

@end

