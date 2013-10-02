//
//  OMDeferredTests.m
//  OMPromises
//
//  Created by Oliver Mader on 02.10.13.
//  Copyright (c) 2013 reaktor42. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OMDeferred.h"

@interface OMDeferredTests : XCTestCase

@property OMDeferred *deferred;

@end

@implementation OMDeferredTests

- (void)testInitialValues {
    OMDeferred *deferred = [OMDeferred deferred];
    
    XCTAssertEqual(deferred.state, OMPromiseStateUnfulfilled, @"Should initially be Unfulfilled");
    XCTAssertNil(deferred.result, @"There shouldn't be a result yet");
    XCTAssertNil(deferred.error, @"There shouldn't be an error");
    XCTAssertEqualWithAccuracy(deferred.progress.floatValue, 0.f, FLT_EPSILON, @"Progress should be 0");
}

- (void)testFulfil {
    OMDeferred *deferred = [OMDeferred deferred];
    
    id result = @.1337f;
    [deferred fulfil:result];
    
    XCTAssertEqual(deferred.state, OMPromiseStateFulfilled, @"Should be Fulfilled by now");
    XCTAssertEqual(deferred.result, result, @"There should be the supplied result by now");
    XCTAssertNil(deferred.error, @"There shouldn't be an error");
    XCTAssertEqualWithAccuracy(deferred.progress.floatValue, 1.f, FLT_EPSILON, @"Progress should be 1");
    
    XCTAssertThrows([deferred fulfil:nil], @"Shouldn't be possible to do further state changes");
    XCTAssertThrows([deferred fail:nil], @"Shouldn't be possible to do further state changes");
    XCTAssertThrows([deferred progress:@1.f], @"Shouldn't be possible to do further state changes");
}

- (void)testFail {
    OMDeferred *deferred = [OMDeferred deferred];
    
    NSError *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:0 userInfo:nil];
    [deferred fail:error];
    
    XCTAssertEqual(deferred.state, OMPromiseStateFailed, @"Should be Fulfilled by now");
    XCTAssertEqual(deferred.error, error, @"There should be the supplied error by now");
    XCTAssertNil(deferred.result, @"There shouldn't be an error");
    XCTAssertEqualWithAccuracy(deferred.progress.floatValue, 1.f, FLT_EPSILON, @"Progress should be 1");
    
    XCTAssertThrows([deferred fulfil:nil], @"Shouldn't be possible to do further state changes");
    XCTAssertThrows([deferred fail:nil], @"Shouldn't be possible to do further state changes");
    XCTAssertThrows([deferred progress:@1.f], @"Shouldn't be possible to do further state changes");
}

- (void)testProgress {
    OMDeferred *deferred = [OMDeferred deferred];
    
    [deferred progress:@.1f];
    
    XCTAssertEqual(deferred.state, OMPromiseStateUnfulfilled, @"Should still be Unfulfilled");
    XCTAssertNil(deferred.error, @"There shouldn't be a result");
    XCTAssertNil(deferred.result, @"There shouldn't be an error");
    XCTAssertEqualWithAccuracy(deferred.progress.floatValue, .1f, FLT_EPSILON, @"Progress should be .1");
    
    [deferred progress:@.2f];
    XCTAssertEqualWithAccuracy(deferred.progress.floatValue, .2f, FLT_EPSILON, @"Progress should be .2");
    
    XCTAssertNoThrow([deferred progress:@.2f], @"Progress should ignore identical values");
    XCTAssertEqualWithAccuracy(deferred.progress.floatValue, .2f, FLT_EPSILON, @"Progress should be .2");
    
    XCTAssertThrows([deferred progress:@.1f], @"Must not decrease progress");
    XCTAssertEqualWithAccuracy(deferred.progress.floatValue, .2f, FLT_EPSILON, @"Progress shouldn't have changed");
}

@end
