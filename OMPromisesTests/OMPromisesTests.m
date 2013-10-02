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

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
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

@end
