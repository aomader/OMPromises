//
// OMPromiseTests.m
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

@interface OMPromisesTests : XCTestCase

@property id result;
@property id result2;
@property NSError *error;

@end

@implementation OMPromisesTests

- (void)setUp {
    [super setUp];

    self.result = @.1337;
    self.result2 = @.31337;
    self.error = [NSError errorWithDomain:@"idontgiveadamn" code:1337 userInfo:nil];
}

- (void)tearDown {
    [OMPromise setGlobalDefaultQueue:nil];
    [super tearDown];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#pragma mark - Queue

- (void)testGlobalDefaultQueue {
    XCTAssertEqual([OMPromise globalDefaultQueue], (dispatch_queue_t)nil, @"Global default queue should be nil if not specified otherwise.");

    OMPromise *promise = [OMPromise promiseWithResult:self.result];
    XCTAssertEqual(promise.defaultQueue, (dispatch_queue_t)nil, @"defaultQueue should inherit the globalDefaultQueue");

    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    [OMPromise setGlobalDefaultQueue:mainQueue];
    XCTAssertEqual([OMPromise globalDefaultQueue], mainQueue, @"Global default queue should be overridable");

    OMDeferred *deferred = [OMDeferred deferred];
    XCTAssertEqual(deferred.promise.defaultQueue, mainQueue, @"defalultQueue should inherit the globalDefaultQueue");
}

- (void)testDefaultQueue {
    OMPromise *promise = [OMPromise promiseWithResult:self.result];

    XCTAssertEqual(promise.defaultQueue, (dispatch_queue_t)nil, @"defaultQueue should inherit the globalDefaultQueue");

    dispatch_queue_t mainQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    promise.defaultQueue = mainQueue;

    __block int called = 0;
    [promise fulfilled:^(id _) {
        XCTAssertEqual(dispatch_get_current_queue(), mainQueue, @"Should run on default queue");
        called += 1;
    }];

    WAIT_UNTIL(called == 1, 1, @"Fulfilled block should have been called");

    dispatch_queue_t otherQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    XCTAssertNotEqual(mainQueue, otherQueue, @"queues should not be identical");

    called = 0;
    [promise fulfilled:^(id _) {
        XCTAssertEqual(dispatch_get_current_queue(), otherQueue, @"Should run on specified queue");
        called += 1;
    } on:otherQueue];

    WAIT_UNTIL(called == 1, 1, @"Fulfilled block should have been called");
}

- (void)testOn {
    OMPromise *promise = [OMPromise promiseWithResult:self.result];

    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    OMPromise *promise2 = [promise on:mainQueue];

    XCTAssertEqual(promise, promise2, @"on: should return self");
    XCTAssertEqual(promise.defaultQueue, mainQueue, @"defalultQueue should be set by on:");
}

#pragma mark - Return

- (void)testTaskPromise {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    XCTAssertNotEqual(queue, dispatch_get_current_queue(), @"Current queue shouldnt be dispatch queue");
    
    __block int called = 0;
    OMPromise *promise = [OMPromise promiseWithTask:^id{
        XCTAssertEqual(queue, dispatch_get_current_queue(), @"Should run on specified queue");
        called += 1;
        return self.result;
    } on:queue];
    
    WAIT_UNTIL(called == 1, 1, @"Task should be executed");
    
    XCTAssertEqual(promise.state, OMPromiseStateFulfilled, @"Promise should be fulfilled");
    XCTAssertEqual(promise.result, self.result, @"Promise should have the supplied result");
}

- (void)testTaskPromiseThrowException {
    NSException *exception = [NSException exceptionWithName:@"foo" reason:@"bar" userInfo:nil];
    
    OMPromise *promise = [OMPromise promiseWithTask:^id{
        @throw exception;
        return self.result;
    }];
    
    WAIT_UNTIL(promise.state == OMPromiseStateFailed, 1, @"Promise should have failed");
    
    XCTAssertEqual(promise.error.code, OMPromisesExceptionError, @"Error should be caused by exception");
}

- (void)testTaskPromiseReturnError {
    OMPromise *promise = [OMPromise promiseWithTask:^id{
        return self.error;
    }];
    
    WAIT_UNTIL(promise.state == OMPromiseStateFailed, 1, @"Promise should have failed");
    
    XCTAssertEqual(promise.error, self.error, @"error should be the one returned by the task");
}

- (void)testFulfilledPromise {
    OMPromise *promise = [OMPromise promiseWithResult:self.result];
    
    XCTAssertEqual(promise.state, OMPromiseStateFulfilled, @"Promise should be fulfilled");
    XCTAssertEqual(promise.result, self.result, @"Promise should have the supplied result");
    XCTAssertEqualWithAccuracy(promise.progress, 1.f, FLT_EPSILON, @"Progress should be 1");
}

- (void)testFailedPromise {
    OMPromise *promise = [OMPromise promiseWithError:self.error];
    
    XCTAssertEqual(promise.state, OMPromiseStateFailed, @"Promise should be failed");
    XCTAssertEqual(promise.error, self.error, @"Promise should have the supplied error");
    XCTAssertEqualWithAccuracy(promise.progress, 0.f, FLT_EPSILON, @"Progress should be 0");
}

#pragma mark - Callbacks

- (void)testBindOnAlreadyFulfilledPromise {
    OMPromise *promise = [OMPromise promiseWithResult:self.result];
    
    __block int called = 0, calledProgress = 0;
    [[[promise fulfilled:^(id result) {
        XCTAssertEqual(result, self.result, @"The supplied result should be identical");
        called += 1;
    }] failed:^(NSError *error) {
        XCTFail(@"Fail should not have been called");
    }] progressed:^(float progress) {
        XCTAssertEqualWithAccuracy(progress, 1.f, FLT_EPSILON, @"Progress should be 0");
        calledProgress += 1;
    }];
    
    XCTAssertEqual(called, 1, @"fulfilled-block should have been called once");
    XCTAssertEqual(calledProgress, 1, @"progressed-block should have been called once");
}

- (void)testBindsOnNotAlreadyFulfilledPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    __block int called = 0, progressCalled = 0;
    [[[deferred.promise fulfilled:^(id result) {
        XCTAssertEqual(result, self.result, @"The supplied result should be identical");
        XCTAssertTrue(progressCalled, @"progress-block should have been called before fulfilled-block");
        called += 1;
    }] failed:^(NSError *error) {
        XCTFail(@"Fail should not have been called");
    }] progressed:^(float progress) {
        XCTAssertFalse(called, @"progressed-block should be called before fulfilled-block");
        XCTAssertEqualWithAccuracy(progress, 1.f, FLT_EPSILON, @"Progress should be 1");
        progressCalled += 1;
    }];

    XCTAssertEqual(called, 0, @"fulfilled-block should not have been called");
    [deferred fulfil:self.result];
    XCTAssertEqual(called, 1, @"fulfilled-block should have been called once");
    XCTAssertEqual(progressCalled, 1, @"progressed-block should have been called once");
}

- (void)testBindsOnAlreadyFailedPromise {
    OMPromise *promise = [OMPromise promiseWithError:self.error];

    __block int called = 0;
    [[[promise fulfilled:^(id result) {
        XCTFail(@"fulfilled-block should not have been called");
    }] failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"The supplied error should be identical");
        called += 1;
    }] progressed:^(float progress) {
        XCTFail(@"progressed-block should not have been called");
    }];
    
    XCTAssertEqual(called, 1, @"failed-block should have been called once");
}

- (void)testBindsOnNotAlreadyFailedPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    __block int called = 0;
    [[[deferred.promise fulfilled:^(id result) {
        XCTFail(@"fulfilled-block should not have been called");
    }] failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"The supplied error should be identical");
        called += 1;
    }] progressed:^(float progress) {
        XCTFail(@"progressed-block should not have been called");
    }];
    
    XCTAssertEqual(called, 0, @"failed-block should not have been called yet");
    [deferred fail:self.error];
    XCTAssertEqual(called, 1, @"failed-block should have been called");
}

- (void)testNoInitialProgress {
    OMDeferred *deferred = [OMDeferred deferred];
    [deferred.promise progressed:^(float progress) {
        XCTFail(@"there shouldnt be any progress");
    }];
}

- (void)testInitialProgress {
    OMDeferred *deferred = [OMDeferred deferred];
    
    [deferred progress:.5f];
    
    __block int called = 0;
    [deferred.promise progressed:^(float progress) {
        XCTAssertEqualWithAccuracy(progress, .5f, FLT_EPSILON, @"Unexpected progress");
        called += 1;
    }];
    
    XCTAssertEqual(called, 1, @"progressed-block should not have been called until now");
}

- (void)testIncreasingProgress {
    OMDeferred *deferred = [OMDeferred deferred];

    __block int called = 0;
    [deferred.promise progressed:^(float progress) {
        float values[] = {.1f, .5f, 1.f};
        XCTAssertEqualWithAccuracy(values[called], progress, FLT_EPSILON, @"Unexpected progress");
        called += 1;
    }];

    XCTAssertEqual(called, 0, @"progressed-block should not have been called until now");
    [deferred progress:.1f];
    XCTAssertEqual(called, 1, @"progressed-block should be called once");
    [deferred progress:.1f];
    XCTAssertEqual(called, 1, @"progressed-block should be called once");
    [deferred progress:.5f];
    XCTAssertEqual(called, 2, @"progressed-block should be called twice");
    [deferred fulfil:self.result];
    XCTAssertEqual(called, 3, @"progressed-block should be called three times");
}

- (void)testMultipleBindsOnNotAlreadyFulfilledPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    __block int called1 = 0, called2 = 0;
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

    __block int called1 = 0, called2 = 0;
    [[deferred.promise failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"The supplied error should be identical");
        called1 += 1;
    }] failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"The supplied error should be identical");
        called2 += 1;
    }];

    XCTAssertEqual(called1, 0, @"first failed-block should not have been called yet");
    XCTAssertEqual(called2, 0, @"second failed-block should not have been called yet");
    [deferred fail:self.error];
    XCTAssertEqual(called1, 1, @"first failed-block should have been called once");
    XCTAssertEqual(called2, 1, @"second failed-block should have been called once");
}

- (void)testFulfilledQueue {
    OMDeferred *deferred = [OMDeferred deferred];
        
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    XCTAssertNotEqual(queue, dispatch_get_current_queue(), @"Current queue shouldnt be dispatch queue");
    
    __block int called = 0;
    [deferred.promise fulfilled:^(id result) {
        XCTAssertEqual(result, self.result, @"The supplied result should be identical");
        XCTAssertEqual(queue, dispatch_get_current_queue(), @"Should run on specified queue");
        called += 1;
    } on:queue];
        
    [deferred fulfil:self.result];
    
    WAIT_UNTIL(called == 1, 1, @"Not called within 1 sec");
}

- (void)testFailedQueue {
    OMDeferred *deferred = [OMDeferred deferred];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    XCTAssertNotEqual(queue, dispatch_get_current_queue(), @"Current queue shouldnt be dispatch queue");
    
    __block int called = 0;
    [deferred.promise failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"The supplied error should be identical");
        XCTAssertEqual(queue, dispatch_get_current_queue(), @"Should run on specified queue");
        called += 1;
    } on:queue];
    
    [deferred fail:self.error];
    
    WAIT_UNTIL(called == 1, 1, @"Not called within 1 sec");
}

- (void)testProgressedQueue {
    OMDeferred *deferred = [OMDeferred deferred];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    XCTAssertNotEqual(queue, dispatch_get_current_queue(), @"Current queue shouldnt be dispatch queue");
    
    __block int called = 0;
    [deferred.promise progressed:^(float progress) {
        XCTAssertEqualWithAccuracy(progress, .5f, FLT_EPSILON, @"incorrect progress value");
        XCTAssertEqual(queue, dispatch_get_current_queue(), @"Should run on specified queue");
        called += 1;
    } on:queue];
    
    [deferred progress:.5f];
    
    WAIT_UNTIL(called == 1, 1, @"Not called within 1 sec");
}

#pragma mark - Bind

- (void)testThenReturnPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    __block int called = 0, calledProgress = 0, calledFulfil = 0, calledFail = 0;
    OMDeferred *nextDeferred = [OMDeferred deferred];
    OMPromise *nextPromise = [[[deferred.promise then:^(id result) {
        XCTAssertEqual(result, self.result, @"Supplied result should be identical to the one passed to fulfil:");
        called += 1;
        return nextDeferred.promise;
    }] progressed:^(float progress) {
        float progressValues[] = {.5f, .75f, 1.f};
        XCTAssertEqualWithAccuracy(progress, progressValues[calledProgress], FLT_EPSILON, @"incorrect progress value");
        calledProgress += 1;
    }] fulfilled:^(id result) {
        XCTAssertEqual(result, self.result2, @"Supplied result should be identical to the one passed to fulfil:");
        calledFulfil += 1;
    }];
    
    [[[nextPromise then:^(id result) {
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
    XCTAssertEqual(calledProgress, 1, @"progressed-block should have been called once");

    [nextDeferred progress:.5f];
    [nextDeferred fulfil:self.result2];
    XCTAssertEqual(nextPromise.state, OMPromiseStateFulfilled, @"Second promise should be fulfilled");
    XCTAssertEqual(calledProgress, 3, @"progressed-block should have been called exactly twice");
    XCTAssertEqual(calledFulfil, 1, @"fulfilled-block should have been called exactly once");
    XCTAssertEqual(calledFail, 1, @"failed-block should have been called exactly once");
}

- (void)testThenReturnAlreadyFulfilledPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    OMPromise *promise = [deferred.promise then:^id(id _) {
        return [OMPromise promiseWithResult:self.result2];
    }];

    [deferred fulfil:self.result];
    XCTAssertEqual(promise.state, OMPromiseStateFulfilled, @"Promise should be fulfilled");
    XCTAssertEqual(promise.result, self.result2, @"Result should be from inner promise");
}

- (void)testThenReturnValue {
    OMDeferred *deferred = [OMDeferred deferred];

    __block int called = 0, calledFulfil = 0;
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
    XCTAssertEqual(nextPromise.result, self.result2, @"Final result should be the last returned one");
    XCTAssertEqual(called, 1, @"then-block should have been called exactly once");
    XCTAssertEqual(calledFulfil, 1, @"fulfilled-block should have been called exactly once");
}

- (void)testThenReturnError {
    OMDeferred *deferred = [OMDeferred deferred];
    
    __block int called = 0, calledFailed = 0;
    OMPromise *nextPromise = [[deferred.promise then:^id(id result) {
        called += 1;
        return self.error;
    }] failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"supplied error should be identical to previously returned one");
        calledFailed += 1;
    }];
    
    [deferred fulfil:self.result];
    XCTAssertEqual(nextPromise.state, OMPromiseStateFailed, @"Second promise should have failed");
    XCTAssertEqual(nextPromise.error, self.error, @"Final error should be the last returned one");
    XCTAssertEqual(called, 1, @"rescue-block should have been called exactly once");
    XCTAssertEqual(calledFailed, 1, @"fulfilled-block should have been called exactly once");
}

- (void)testThenProgressChain {
    OMDeferred *deferred1 = [OMDeferred deferred];
    OMDeferred *deferred2 = [OMDeferred deferred];
    OMDeferred *deferred3 = [OMDeferred deferred];
    
    __block int called = 0;
    [[[deferred1.promise then:^(id result) {
        return deferred2.promise;
    }] then:^id(id result) {
        return deferred3.promise;
    }] progressed:^(float progress) {
        float progressValues[] = {1/6.f, 1/3.f, .75f * 1/3 + 1/3.f, 2/3.f, 5/6.f, 1.f};
        XCTAssertEqualWithAccuracy(progress, progressValues[called], FLT_EPSILON, @"incorrect progress value");
        called += 1;
    }];
    
    [deferred1 progress:.5f];
    XCTAssertEqual(called, 1, @"progressed-block should have been called once by now");
    
    [deferred1 fulfil:nil];
    XCTAssertEqual(called, 2, @"progressed-block should have been called twice by now");
    
    [deferred2 progress:.75f];
    XCTAssertEqual(called, 3, @"progressed-block should have been called three times by now");
    
    [deferred2 fulfil:nil];
    XCTAssertEqual(called, 4, @"progressed-block should have been called four times by now");
    
    [deferred3 progress:.5f];
    XCTAssertEqual(called, 5, @"progressed-block should have been called five times by now");
    
    [deferred3 fulfil:nil];
    XCTAssertEqual(called, 6, @"progressed-block should have been called six times by now");
}

- (void)testThenQueue {
    OMDeferred *deferred = [OMDeferred deferred];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    XCTAssertNotEqual(queue, dispatch_get_current_queue(), @"Current queue shouldnt be dispatch queue");
    
    __block int called = 0;
    [deferred.promise then:^id(id result) {
        XCTAssertEqual(result, self.result, @"The supplied result should be identical");
        XCTAssertEqual(queue, dispatch_get_current_queue(), @"Should run on specified queue");
        called += 1;
        return nil;
    } on:queue];
    
    [deferred fulfil:self.result];
    
    WAIT_UNTIL(called == 1, 1, @"Not called within 1 sec");
}

- (void)testRescueReturnPromise {
    OMDeferred *deferred = [OMDeferred deferred];

    __block int called = 0, calledProgress = 0, calledFulfil = 0, calledFail = 0;
    OMDeferred *nextDeferred = [OMDeferred deferred];
    OMPromise *nextPromise = [[[deferred.promise rescue:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"Supplied error should be identical to the one passed to fail:");
        called += 1;
        return nextDeferred.promise;
    }] progressed:^(float progress) {
        float progressValues[] = {.5f, 1.f};
        XCTAssertEqualWithAccuracy(progress, progressValues[calledProgress], FLT_EPSILON, @"incorrect progress value");
        calledProgress += 1;
    }] fulfilled:^(id result) {
        XCTAssertEqual(result, self.result2, @"Supplied result should be identical to the one passed to fulfil:");
        calledFulfil += 1;
    }];
    
    [[[nextPromise then:^(id result) {
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

    [nextDeferred progress:.5f];
    [nextDeferred fulfil:self.result2];
    XCTAssertEqual(nextPromise.state, OMPromiseStateFulfilled, @"Second promise should be fulfilled");
    XCTAssertEqual(calledProgress, 2, @"progressed-block should have been called exactly twice");
    XCTAssertEqual(calledFulfil, 1, @"fulfilled-block should have been called exactly once");
    XCTAssertEqual(calledFail, 1, @"failed-block should have been called exactly once");
}

- (void)testRescueReturnValue {
    OMDeferred *deferred = [OMDeferred deferred];

    __block int called = 0, calledFulfil = 0;
    OMPromise *nextPromise = [[[deferred.promise rescue:^(NSError *error) {
        called += 1;
        return self.result;
    }] fulfilled:^(id result) {
        XCTAssertEqual(result, self.result, @"Supplied result should be identical to the previously returned one");
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

- (void)testRescueReturnError {
    OMDeferred *deferred = [OMDeferred deferred];
    
    __block int called = 0, calledFailed = 0;
    OMPromise *nextPromise = [[deferred.promise rescue:^(NSError *error) {
        called += 1;
        return self.error;
    }] failed:^(NSError *error) {
        XCTAssertEqual(error, self.error, @"supplied error should be identical to previously returned one");
        calledFailed += 1;
    }];
    
    [deferred fail:self.error];
    XCTAssertEqual(nextPromise.state, OMPromiseStateFailed, @"Second promise should have failed");
    XCTAssertEqual(nextPromise.error, self.error, @"Final error should be the last returned one");
    XCTAssertEqual(called, 1, @"rescue-block should have been called exactly once");
    XCTAssertEqual(calledFailed, 1, @"fulfilled-block should have been called exactly once");
}

- (void)testRescueProxyProgress {
    OMDeferred *deferred = [OMDeferred deferred];
    OMDeferred *nextDeferred = [OMDeferred deferred];
    
    __block int calledProgress = 0;
    OMPromise *nextPromise = [[deferred.promise rescue:^(NSError *error) {
        return nextDeferred.promise;
    }] progressed:^(float progress) {
        float progressValues[] = {.5f, .75f, 1.f};
        XCTAssertEqualWithAccuracy(progress, progressValues[calledProgress], FLT_EPSILON, @"incorrect progress value");
        calledProgress += 1;
    }];
    
    [deferred progress:.5f];
    XCTAssertEqual(calledProgress, 1, @"progress-block should have been called exactly once");
    
    [deferred fail:self.error];
    XCTAssertEqual(calledProgress, 1, @"progress-block should have been called exactly once");
    XCTAssertEqual(nextPromise.state, OMPromiseStateUnfulfilled, @"Second promise should be fulfilled");
    
    [nextDeferred progress:.5f];
    XCTAssertEqual(calledProgress, 2, @"progress-block should have been called exactly once");
    
    [nextDeferred fulfil:self.result];
    XCTAssertEqual(calledProgress, 3, @"progress-block should have been called exactly once");
}

- (void)testRescueQueue {
    OMDeferred *deferred = [OMDeferred deferred];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    XCTAssertNotEqual(queue, dispatch_get_current_queue(), @"Current queue shouldnt be dispatch queue");
    
    __block int called = 0;
    [deferred.promise rescue:^id(NSError *error) {
        XCTAssertEqual(error, self.error, @"The supplied error should be identical");
        XCTAssertEqual(queue, dispatch_get_current_queue(), @"Should run on specified queue");
        called += 1;
        return nil;
    } on:queue];
    
    [deferred fail:self.error];
    
    WAIT_UNTIL(called == 1, 1, @"Not called within 1 sec");
}

#pragma mark - Cancellation

- (void)testCancelException {
    OMDeferred *deferred = [OMDeferred deferred];
    XCTAssertThrows([deferred.promise cancel], @"Deferred must explicitly made cancellable");
}

- (void)testCancelSuccess {
    OMDeferred *deferred = [OMDeferred deferred];
    OMPromise *promise = deferred.promise;
    
    [deferred cancelled:^(id _){}];
    
    __block int failed = 0;
    
    [[[promise progressed:^(float _) {
        XCTFail(@"progressed-block shouldn't be called");
    }] fulfilled:^(id _) {
        XCTFail(@"fulfilled-block shouldn't be called");
    }] failed:^(NSError *error) {
        XCTAssertEqual(error.domain, OMPromisesErrorDomain, @"Error domain incorrect");
        XCTAssertEqual(error.code, OMPromisesCancelledError, @"Error code should be cancelled");
        failed += 1;
    }];
    
    [promise cancel];
    XCTAssertEqual(failed, 1, @"failed-block should have been called once");
}

#pragma mark - Combinators & Transformers

- (void)testJoinOnlyOneLevel {
    OMDeferred *deferred = [OMDeferred deferred];
    OMPromise *original = deferred.promise;
    
    OMPromise *joined  = [original join];
    XCTAssertEqual(joined.state, OMPromiseStateUnfulfilled, @"Joined promise should be unfulfilled");
    
    [deferred fulfil:self.result];
    XCTAssertEqual(joined.state, OMPromiseStateFulfilled, @"Joined promise should be fulfilled");
    XCTAssertEqual(joined.result, self.result, @"Joined promise should have original result");
}

- (void)testJoinFulfil {
    OMDeferred *deferredOuter = [OMDeferred deferred];
    OMDeferred *deferredInner = [OMDeferred deferred];
    OMPromise *promiseOuter = deferredOuter.promise;
    OMPromise *promiseInner = deferredInner.promise;
    
    OMPromise *joined = [promiseOuter join];
    XCTAssertEqual(joined.state, OMPromiseStateUnfulfilled, @"Joined promise should be unfulfilled");
    
    [deferredOuter progress:.5f];
    XCTAssertEqualWithAccuracy(joined.progress, .25f, FLT_EPSILON, @"incorrect progress value");
    
    [deferredOuter fulfil:promiseInner];
    XCTAssertEqualWithAccuracy(joined.progress, .5f, FLT_EPSILON, @"incorrect progress value");
    XCTAssertEqual(joined.state, OMPromiseStateUnfulfilled, @"Joined promise should be unfulfilled");
    
    [deferredInner progress:.5f];
    XCTAssertEqualWithAccuracy(joined.progress, .75f, FLT_EPSILON, @"incorrect progress value");
    
    [deferredInner fulfil:self.result];
    XCTAssertEqualWithAccuracy(joined.progress, 1.f, FLT_EPSILON, @"incorrect progress value");
    XCTAssertEqual(joined.state, OMPromiseStateFulfilled, @"Joined promise should be unfulfilled");
    XCTAssertEqual(joined.result, self.result, @"Joined promise should have result of inner promise");
}

- (void)testJoinFailOuter {
    OMDeferred *deferredOuter = [OMDeferred deferred];
    OMPromise *promiseOuter = deferredOuter.promise;
    
    OMPromise *joined = [promiseOuter join];
    XCTAssertEqual(joined.state, OMPromiseStateUnfulfilled, @"Joined promise should be unfulfilled");
    
    [deferredOuter progress:.5f];
    XCTAssertEqualWithAccuracy(joined.progress, .25f, FLT_EPSILON, @"incorrect progress value");
    
    [deferredOuter fail:self.error];
    XCTAssertEqualWithAccuracy(joined.progress, .25f, FLT_EPSILON, @"incorrect progress value");
    XCTAssertEqual(joined.state, OMPromiseStateFailed, @"Joined promise should have failed");
    XCTAssertEqual(joined.error, self.error, @"Joined promise should have error of outer one");
}

- (void)testJoinFailInner {
    OMDeferred *deferredOuter = [OMDeferred deferred];
    OMDeferred *deferredInner = [OMDeferred deferred];
    OMPromise *promiseOuter = deferredOuter.promise;
    OMPromise *promiseInner = deferredInner.promise;
    
    OMPromise *joined = [promiseOuter join];
    XCTAssertEqual(joined.state, OMPromiseStateUnfulfilled, @"Joined promise should be unfulfilled");
    
    [deferredOuter progress:.5f];
    XCTAssertEqualWithAccuracy(joined.progress, .25f, FLT_EPSILON, @"incorrect progress value");
    
    [deferredOuter fulfil:promiseInner];
    XCTAssertEqualWithAccuracy(joined.progress, .5f, FLT_EPSILON, @"incorrect progress value");
    XCTAssertEqual(joined.state, OMPromiseStateUnfulfilled, @"Joined promise should be unfulfilled");
    
    [deferredInner progress:.5f];
    XCTAssertEqualWithAccuracy(joined.progress, .75f, FLT_EPSILON, @"incorrect progress value");
    
    [deferredInner fail:self.error];
    XCTAssertEqualWithAccuracy(joined.progress, .75f, FLT_EPSILON, @"incorrect progress value");
    XCTAssertEqual(joined.state, OMPromiseStateFailed, @"Joined promise should have failed");
    XCTAssertEqual(joined.error, self.error, @"Joined promise should have error of inner one");
}

- (void)testChainEmptyArray {
    OMPromise *chain = [OMPromise chain:@[] initial:self.result];
    XCTAssertEqual(chain.state, OMPromiseStateFulfilled, @"Chain promise should be fulfilled");
    XCTAssertEqual(chain.result, self.result, @"Chain promise should have the initial result");
}

- (void)testChainFulfil {
    OMDeferred *deferred = [OMDeferred deferred];

    OMPromise *chain = [OMPromise chain:@[
        ^id(id result) {
            return result;
        }, ^id(id result) {
            return deferred.promise;
        }
    ] initial:self.result];

    XCTAssertEqual(chain.state, OMPromiseStateUnfulfilled, @"Chain should be unfulfilled");
    XCTAssertEqualWithAccuracy(chain.progress, .5f, FLT_EPSILON, @"Chain should be have way done");

    [deferred progress:.5f];
    XCTAssertEqualWithAccuracy(chain.progress, .75f, FLT_EPSILON, @"Assuming equal distribution of work load");

    [deferred fulfil:self.result2];
    XCTAssertEqual(chain.state, OMPromiseStateFulfilled, @"Chain should be fulfilled");
    XCTAssertEqual(chain.result, self.result2, @"Chain should have result of last promise in chain");
    XCTAssertEqualWithAccuracy(chain.progress, 1.f, FLT_EPSILON, @"Chain should be done");
}

- (void)testGenericChainFulfil {
    OMDeferred *deferred = [OMDeferred deferred];
    
    __block id resultFulfilled1;
    __block id resultFulfilled2;
    __block int progressed = 0;
    
    OMPromise *chain = [OMPromise chain:@[
        ^id(id result) {
            return result;
        },
        ^(id result) {
            resultFulfilled1 = result;
        },
        ^(NSError *error) {
            XCTFail(@"We shouldnt call the error handler");
        },
        ^id(NSError *error) {
            XCTFail(@"We shouldnt call the rescue handler");
            return nil;
        },
        ^id(id result) {
            return deferred.promise;
        },
        ^(float progress) {
            float values[] = {.5f, .75f, 1.f};
            XCTAssertEqualWithAccuracy(progress, values[progressed++], FLT_EPSILON, @"Unexpected progress");
        },
        ^(id result) {
            resultFulfilled2 = result;
        },
        ^(NSError *error) {
            XCTFail(@"We shouldnt call the error handler");
        },
        ^id(NSError *error) {
            XCTFail(@"We shouldnt call the rescue handler");
            return nil;
        }
    ] initial:self.result];
    
    XCTAssertEqual(chain.state, OMPromiseStateUnfulfilled, @"Chain should be unfulfilled");
    XCTAssertEqualWithAccuracy(chain.progress, .5f, FLT_EPSILON, @"Chain should be have way done");
    XCTAssertEqual(resultFulfilled1, self.result, @"Fulfilled handler should have been called");
    
    [deferred progress:.5f];
    XCTAssertEqualWithAccuracy(chain.progress, .75f, FLT_EPSILON, @"Assuming equal distribution of work load");
    XCTAssertEqual(progressed, 2, @"Progressed handler should have been called");
    
    [deferred fulfil:self.result2];
    XCTAssertEqual(chain.state, OMPromiseStateFulfilled, @"Chain should be fulfilled");
    XCTAssertEqual(resultFulfilled2, self.result2, @"Fulfilled handler should have been called");
    XCTAssertEqual(chain.result, self.result2, @"Chain should have result of last promise in chain");
    XCTAssertEqual(progressed, 3, @"Progressed handler should have been called");
    XCTAssertEqualWithAccuracy(chain.progress, 1.f, FLT_EPSILON, @"Chain should be done");
}

- (void)testChainFail {
    OMDeferred *deferred = [OMDeferred deferred];

    OMPromise *chain = [OMPromise chain:@[
        ^id(id result) {
            return deferred.promise;
        }, ^id(id result) {
            XCTFail(@"Chain should short-circuit in case of failure");
            return nil;
        }
    ] initial:self.result];

    [deferred progress:.5f];
    XCTAssertEqual(chain.state, OMPromiseStateUnfulfilled, @"Chain should be unfulfilled");
    XCTAssertEqualWithAccuracy(chain.progress, .25f, FLT_EPSILON, @"Chain should be have way done");

    [deferred fail:self.error];
    XCTAssertEqual(chain.state, OMPromiseStateFailed, @"Chain should have failed");
    XCTAssertEqual(chain.error, self.error, @"Chain error should be equal to promise error");
    XCTAssertEqualWithAccuracy(chain.progress, .25f, FLT_EPSILON, @"Chain should be have way done");
}

- (void)testGenericChainFail {
    OMDeferred *deferred = [OMDeferred deferred];
    OMDeferred *deferred1 = [OMDeferred deferred];
    
    __block int progressed = 0, progressed1 = 0, progressed2 = 0;
    __block id fulfilled = nil;
    
    OMPromise *chain = [OMPromise chain:@[
        ^id(id result) {
            return deferred.promise;
        },
        ^(float progress) {
            float values[] = {.5f};
            XCTAssertEqualWithAccuracy(values[progressed++], progress, FLT_EPSILON, @"Unexpected progress");
        },
        ^id(id result) {
            XCTFail(@"Chain should short-circuit in case of failure");
            return nil;
        },
        ^(id result) {
            XCTFail(@"Chain should short-circuit in case of failure");
        },
        ^(float progress) {
            float values[] = {.25f};
            XCTAssertEqualWithAccuracy(progress, values[progressed1++], FLT_EPSILON, @"Unexpected progress");
        },
        ^id(NSError *error) {
            XCTAssertEqual(error, self.error, @"We should rescue the previous error");
            return deferred1.promise;
        },
        ^id(NSError *error) {
            XCTFail(@"We shouldnt call the rescue handler once its rescued");
            return nil;
        },
        ^(NSError *error) {
            XCTFail(@"We shouldnt call the error handler once its rescued");
        },
        ^(float progress) {
            float values[] = {.25f, .25f + (.75f * .5f), 1.f};
            XCTAssertEqualWithAccuracy(progress, values[progressed2++], FLT_EPSILON, @"Unexpected progress");
        },
        ^(id result) {
            fulfilled = result;
        },
         ^id(id result) {
            return self.result2;
        }
    ] initial:self.result];
    
    [deferred progress:.5f];
    XCTAssertEqual(chain.state, OMPromiseStateUnfulfilled, @"Chain should be unfulfilled");
    XCTAssertEqual(progressed, 1, @"Progressed handler should have been called once");
    XCTAssertEqual(progressed1, 1, @"Progressed handler should have been called once");
    XCTAssertEqualWithAccuracy(chain.progress, 1/6.f, FLT_EPSILON, @"Chain should be have way done");
    
    [deferred fail:self.error];
    XCTAssertEqual(chain.state, OMPromiseStateUnfulfilled, @"Chain should not have failed");
    XCTAssertEqualWithAccuracy(chain.progress, 1/6.f, FLT_EPSILON, @"Progres should remain");
    XCTAssertEqual(progressed2, 1, @"Progressed handler should have been called once");
    
    [deferred1 progress:.5f];
    XCTAssertEqual(chain.state, OMPromiseStateUnfulfilled, @"Chain should not have failed");
    XCTAssertEqualWithAccuracy(chain.progress, 1/6.f + .5f * 3/6.f, FLT_EPSILON, @"Rescue should fill the remaining progress of the failed promise");
    XCTAssertEqual(progressed2, 2, @"Progressed handler should have been called twice");
    
    [deferred1 fulfil:self.result2];
    XCTAssertEqual(chain.state, OMPromiseStateFulfilled, @"Chain should be done now.");
    XCTAssertEqualWithAccuracy(chain.progress, 6/6.f, FLT_EPSILON, @"Chain should be nearly done");
    XCTAssertEqual(progressed2, 3, @"Progressed handler should have been called three times");
    XCTAssertEqual(chain.result, self.result2, @"Chain should have result of last promise in chain");
}

- (void)testChainInitialPromise {
    OMDeferred *deferred = [OMDeferred deferred];
    
    __block int called = 0;
    OMPromise *chain = [OMPromise chain:@[
        ^id(id result) {
            XCTAssertEqual(result, self.result, @"First result should be determined by initial promise");
            return self.result2;
        }
    ] initial:deferred.promise];
    
    [chain progressed:^(float progress) {
        float values[] = {.25f, .5f, 1.f};
        XCTAssertEqualWithAccuracy(progress, values[called++], FLT_EPSILON, @"Unexpected progress");
    }];
    
    [deferred progress:.5f];
    XCTAssertEqual(called, 1, @"Progressed handler should have been called once");
    
    [deferred fulfil:self.result];
    XCTAssertEqual(called, 3, @"Progressed handler should have been called three times");
    XCTAssertEqual(chain.result, self.result2, @"Last then determines chain result");
}

- (void)testAnyEmptyArray {
    OMPromise *any = [OMPromise any:@[]];
    XCTAssertEqual(any.state, OMPromiseStateFailed, @"Any without any promise should have failed");
    XCTAssertTrue([any.error.domain isEqualToString:OMPromisesErrorDomain], @"Error should be combinator specific");
    XCTAssertEqual(any.error.code, OMPromisesCombinatorAnyNonFulfilledError, @"Error should be combinator specific");
}

- (void)testAnyFulfil {
    OMDeferred *deferred1 = [OMDeferred deferred];
    OMDeferred *deferred2 = [OMDeferred deferred];
    OMDeferred *deferred3 = [OMDeferred deferred];

    OMPromise *any = [OMPromise any:@[deferred1.promise, deferred2.promise, deferred3.promise]];

    [deferred1 progress:.5f];
    XCTAssertEqualWithAccuracy(any.progress, .5f, FLT_EPSILON, @"Any should be have way done");

    [deferred2 progress:.75f];
    XCTAssertEqualWithAccuracy(any.progress, .75f, FLT_EPSILON, @"Any should be nearly done");

    [deferred1 fail:self.error];
    XCTAssertEqual(any.state, OMPromiseStateUnfulfilled, @"Any should be unfulfilled");

    [deferred2 fulfil:self.result];
    XCTAssertEqual(any.state, OMPromiseStateFulfilled, @"Any should be fulfilled");
    XCTAssertEqual(any.result, self.result, @"Result should be identical to the ony supplied by the fulfilled promise");

    XCTAssertNoThrow([deferred3 fulfil:self.result2], @"Another fulfilled promise should have no influence");
    XCTAssertEqual(any.state, OMPromiseStateFulfilled, @"State should be unchanged");
    XCTAssertEqual(any.result, self.result, @"Result should be unchanged");
}

- (void)testAnyFail {
    OMDeferred *deferred1 = [OMDeferred deferred];
    OMDeferred *deferred2 = [OMDeferred deferred];

    OMPromise *any = [OMPromise any:@[deferred1.promise, deferred2.promise]];

    [deferred1 progress:.5f];
    XCTAssertEqualWithAccuracy(any.progress, .5f, FLT_EPSILON, @"Any should be have way done");

    [deferred1 fail:self.error];
    XCTAssertEqual(any.state, OMPromiseStateUnfulfilled, @"Any should be unfulfilled");
    [deferred2 fail:self.error];
    XCTAssertEqual(any.state, OMPromiseStateFailed, @"Any should have failed");
    XCTAssertTrue([any.error.domain isEqualToString:OMPromisesErrorDomain], @"Error should be combinator specific");
    XCTAssertEqual(any.error.code, OMPromisesCombinatorAnyNonFulfilledError, @"Error should be combinator specific");
}

- (void)testAllEmptyArray {
    OMPromise *all = [OMPromise all:@[]];
    XCTAssertEqual(all.state, OMPromiseStateFulfilled, @"An empty set of promises should lead to fulfilled");
    XCTAssertTrue([all.result isEqualToArray:@[]], @"Result should be an empty array");
}

- (void)testAllFulfil {
    OMDeferred *deferred = [OMDeferred deferred];

    OMPromise *all = [OMPromise all:@[deferred.promise, [OMPromise promiseWithResult:self.result]]];

    XCTAssertEqual(all.state, OMPromiseStateUnfulfilled, @"All should be unfulfilled");
    XCTAssertEqualWithAccuracy(all.progress, .5f, FLT_EPSILON, @"All should be have way done");

    [deferred progress:.5f];
    XCTAssertEqualWithAccuracy(all.progress, .75f, FLT_EPSILON, @"All should be nearly done");

    [deferred fulfil:self.result2];
    XCTAssertEqual(all.state, OMPromiseStateFulfilled, @"All should be fulfilled");
    XCTAssertEqualWithAccuracy(all.progress, 1.f, FLT_EPSILON, @"All should be done");
    XCTAssertTrue([all.result isEqualToArray:(@[self.result2, self.result])], @"Result should be an array containing all results");
}

- (void)testAllFail {
    OMDeferred *deferred1 = [OMDeferred deferred];
    OMDeferred *deferred2 = [OMDeferred deferred];

    OMPromise *all = [OMPromise all:@[deferred1.promise, [OMPromise promiseWithResult:self.result], deferred2.promise]];

    [deferred1 progress:.5f];
    XCTAssertEqualWithAccuracy(all.progress, .5f, FLT_EPSILON, @"All should be half way done");
    
    [deferred1 fail:self.error];
    XCTAssertEqual(all.state, OMPromiseStateFailed, @"All should have failed");
    XCTAssertEqual(all.error, self.error, @"Error should be identical to first first failed promises one");

    [deferred2 progress:.5f];
    XCTAssertEqualWithAccuracy(all.progress, .5f, FLT_EPSILON, @"All progress shouldn't change anymore");

    [deferred2 fulfil:self.result];
    XCTAssertEqual(all.state, OMPromiseStateFailed, @"All should have failed");
}

- (void)testCollectEmpty {
    OMPromise *collected = [OMPromise collect:@[]];
    
    XCTAssertEqual(collected.state, OMPromiseStateFulfilled, @"Collected should be fulfilled");
    XCTAssertTrue([collected.result isEqualToArray:@[]], @"Collected should cumulate all results");
}

- (void)testCollect {
    OMDeferred *deferred1 = [OMDeferred deferred];
    OMDeferred *deferred2 = [OMDeferred deferred];
    
    OMPromise *collected = [OMPromise collect:@[deferred1.promise, deferred2.promise, [OMPromise promiseWithResult:nil]]];
    
    XCTAssertEqualWithAccuracy(collected.progress, 1/3.f, FLT_EPSILON, @"Equal distribution of workload");
    
    [deferred1 progress:.5f];
    XCTAssertEqualWithAccuracy(collected.progress, 1/2.f, FLT_EPSILON, @"Equal distribution of workload");
    
    [deferred1 fail:self.error];
    XCTAssertEqual(collected.state, OMPromiseStateUnfulfilled, @"Collected should not have failed");
    XCTAssertEqualWithAccuracy(collected.progress, 2/3.f, FLT_EPSILON, @"Equal distribution of workload");
    
    [deferred2 progress:.5f];
    XCTAssertEqualWithAccuracy(collected.progress, 5/6.f, FLT_EPSILON, @"Equal distribution of workload");
    
    [deferred2 fulfil:self.result];
    XCTAssertEqual(collected.state, OMPromiseStateFulfilled, @"Collected should be fulfilled");
    XCTAssertTrue([collected.result isEqualToArray:(@[self.error, self.result, NSNull.null])], @"Collected should cumulate all results");
}

#pragma mark - Testing

- (void)testWaitForResultWithin {
    OMPromise *failed = [OMPromise promiseWithError:self.error];
    XCTAssertThrows([failed waitForResultWithin:10.], @"Waiting on a failed promise should throw");
    
    OMPromise *fulfilled = [OMPromise promiseWithResult:self.result];
    XCTAssertEqual([fulfilled waitForResultWithin:10.], self.result, @"Should yield result of fulfilled promise");
    
    OMPromise *promise = [OMPromise promiseWithResult:self.result2 after:3.5];
    XCTAssertThrows([promise waitForResultWithin:3.], @"Fulfilling not in time should throw");
    
    NSDate *tic = [NSDate date];
    OMPromise *promise2 = [OMPromise promiseWithResult:self.result2 after:3.5];
    XCTAssertEqual([promise2 waitForResultWithin:4.], self.result2, @"Should yield result of fulfilled promise");
    XCTAssertEqualWithAccuracy(-tic.timeIntervalSinceNow, 3.5, .15, @"Should be more or less exact in timing");
}

- (void)testWaitForErrorWithin {
    OMPromise *fulfilled = [OMPromise promiseWithResult:self.result];
    XCTAssertThrows([fulfilled waitForErrorWithin:10.], @"Waiting on a fulfilled promise should throw");
    
    OMPromise *failed = [OMPromise promiseWithError:self.error];
    XCTAssertEqual([failed waitForErrorWithin:10.], self.error, @"Should yield error of failed promise");
    
    OMPromise *promise = [OMPromise promiseWithError:self.error after:3.5];
    XCTAssertThrows([promise waitForErrorWithin:3.], @"Failing not in time should throw");
    
    NSDate *tic = [NSDate date];
    OMPromise *promise2 = [OMPromise promiseWithError:self.error after:3.5];
    XCTAssertEqual([promise2 waitForErrorWithin:4.], self.error, @"Should yield error of failed promise");
    XCTAssertEqualWithAccuracy(-tic.timeIntervalSinceNow, 3.5, .15, @"Should be more or less exact in timing");
}

#pragma clang diagnostics pop

@end
