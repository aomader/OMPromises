//
//  OMPromise+Combinators.m
//  OMPromises
//
//  Created by Oliver Mader on 02.10.13.
//  Copyright (c) 2013 reaktor42. All rights reserved.
//

#import "OMPromise+Combinators.h"

#import "OMDeferred.h"
#import "OMDeferred+Helpers.h"

@implementation OMPromise (Combinators)

+ (OMPromise *)chain:(NSArray *)fs initial:(id)result {
    OMDeferred *deferred = [OMDeferred deferred];
    
    if (fs.count == 0) {
        [deferred fulfil:result];
    } else {
        id (^f)(id) = [fs objectAtIndex:0];
        id nextResult = f(result);
        [([nextResult isKindOfClass:OMPromise.class] ? nextResult : [OMPromise return:result]) then:^id(id nextResult) {
            [[OMPromise chain:[fs subarrayWithRange:NSMakeRange(1, fs.count - 1)] initial:nextResult] then:^id(id x) {
                [deferred fulfil:x];
                return nil;
            } fail:[deferred failBlock] progress:^(NSNumber *progress) {
                [deferred progress:@(progress.floatValue / fs.count * (fs.count - 1) + 1.f/fs.count)];
            }];
            return nil;
        } fail:[deferred failBlock] progress:^(NSNumber *progress) {
            [deferred progress:@(progress.floatValue / fs.count)];
        }];
    }
    
    return deferred.promise;
}

+ (OMPromise *)any:(NSArray *)promises {
    return nil;
}

+ (OMPromise *)all:(NSArray *)promises {
    OMDeferred *deferred = [OMDeferred deferred];
    
    __block NSMutableArray *results = [NSMutableArray arrayWithCapacity:promises.count];
    __block NSUInteger done = 0;
    
    for (OMPromise *promise in promises) {
        [results addObject:[NSNull null]];
        NSUInteger idx = [promises indexOfObject:promise];
        [promise then:^id(id result) {
            if (deferred.state == OMPromiseStateUnfulfilled) {
                results[idx] = result ? result : [NSNull null];
                if (++done == results.count) {
                    [deferred fulfil:results];
                } else {
                    [deferred progress:@((float)done/results.count)];
                }
            }
            return nil;
        } fail:^(NSError *error) {
            [deferred fail:error];
        } progress:^(NSNumber *progress) {
            
        }];
    }
    
    return deferred.promise;
}

- (OMPromise *)map:(id (^)(id))f {
    OMDeferred *deferred = [OMDeferred deferred];
    
    [self then:^(NSArray *result) {
        NSMutableArray *r = [NSMutableArray arrayWithCapacity:result.count];
        for (id x in result) {
            [r addObject:f(x)];
        }
        return [OMPromise all:r];
    } fail:[deferred failBlock]];
    
    return deferred.promise;
}

@end
