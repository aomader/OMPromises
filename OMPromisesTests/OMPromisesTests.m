//
//  OMPromisesTests.m
//  OMPromisesTests
//
//  Created by Oliver Mader on 02.10.13.
//  Copyright (c) 2013 reaktor42. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "OMPromises.h"

@interface OMPromisesTests : XCTestCase

@end

@implementation OMPromisesTests

- (void)ASDtestExample
{
    OMDeferred *deferred = [OMDeferred deferred];
    
    [[deferred then:^(NSNumber *n) {
        NSLog(@"n1< %d", n.intValue);
        NSNumber *m = @(n.intValue * n.intValue);
        NSLog(@"n1> %d", m.intValue);
        return m;
    }] then:^(NSNumber *n) {
        NSLog(@"n2< %d", n.intValue);
        NSNumber *m = @(n.intValue + n.intValue);
        NSLog(@"n2> %d", m.intValue);
        return m;
    }];
    
    [deferred fulfil:@3];
    
    OMPromise *(^late)(NSNumber *) = ^(NSNumber *n) {
        NSLog(@"Create late %.2f", n.floatValue);
        OMDeferred *deferred = [OMDeferred deferred];
        
        [deferred performSelector:@selector(progress:) withObject:@.5f afterDelay:n.floatValue/2];
        [deferred performSelector:@selector(fulfil:) withObject:@(n.floatValue * 2) afterDelay:n.floatValue];
        return deferred.promise;
    };
     /*
    
    [[[late(@.5f) then:late] then:late] then:late];
    */
    
    [[late(@.5f) then:^(id x) {
        return [OMPromise all:@[late(@.1f), late(@.2f), late(@.3f)]];
    }] then:^id(NSArray *results) {
        NSLog(@"All lates done");
        return nil;
    } fail:nil progress:^(NSNumber *progress) {
        NSLog(@"all progress %.2f", progress.floatValue);
    }];
    
    /*
    [[OMPromise chain:@[
                       late, late, late, late
                       ] initial:@.5f] then:^id(id _) {
        NSLog(@"chain is done");
        return nil;
    } fail:^(NSError *error) {
        NSLog(@"chain error");
    } progress:^(NSNumber *progress) {
        NSLog(@"chain progress %.2f", progress.floatValue);
    }];
*/
     
    NSDate *twoSecondsFromNow = [NSDate dateWithTimeIntervalSinceNow:14.0];
    [[NSRunLoop currentRunLoop]  runMode:NSDefaultRunLoopMode beforeDate:twoSecondsFromNow];
            /*while ([[NSRunLoop currentRunLoop]  runMode:NSDefaultRunLoopMode beforeDate:twoSecondsFromNow]) {
                twoSecondsFromNow = [NSDate dateWithTimeIntervalSinceNow:10.0];
            }*/
}

- (void)testReturn {
    id result = @.1f;
    OMPromise *promise = [OMDeferred return:result];
    
    XCTAssertEqual(promise.state, OMPromiseStateFulfilled, @"Promise should be fulfilled");
    XCTAssertEqual(promise.result, result, @"Promise should have the supplied result");
}

- (void)testThenOnAlreadyFulfilledPromise {
    id result = @.1f;
    OMPromise *promise = [OMDeferred return:result];
    
    __block BOOL called = NO;
    [promise then:^id(id result1) {
        XCTAssertEqual(result1, result, @"The supplied result should be identical");
        called = YES;
        return nil;
    }];
    
    XCTAssertTrue(called, @"then-block should have been called");
}

- (void)testThenOnNotAlreadyFulfilledPromise {
    id result = @.1f;
    OMDeferred *deferred = [OMDeferred deferred];
    
    __block BOOL called = NO;
    [deferred.promise then:^id(id result1) {
        XCTAssertEqual(result1, result, @"The supplied result should be identical");
        called = YES;
        return nil;
    }];
    
    XCTAssertFalse(called, @"then-block should not have been called");
    [deferred fulfil:result];
    XCTAssertTrue(called, @"then-block should have been called");
}

- (void)testMultipleThenOnNotAlreadyFulfilledPromise {
    id result = @.1f;
    OMDeferred *deferred = [OMDeferred deferred];
    
    __block BOOL called1 = NO;
    __block BOOL called2 = NO;
    [deferred.promise then:^id(id result1) {
        XCTAssertEqual(result1, result, @"The supplied result should be identical");
        called1 = YES;
        return nil;
    }];
    [deferred.promise then:^id(id result1) {
        XCTAssertEqual(result1, result, @"The supplied result should be identical");
        called2 = YES;
        return nil;
    }];
    
    XCTAssertFalse(called1, @"first then-block should not have been called");
    XCTAssertFalse(called2, @"second then-block should not have been called");
    [deferred fulfil:result];
    XCTAssertTrue(called1, @"first then-block should have been called");
    XCTAssertTrue(called2, @"first then-block should have been called");
}

@end
