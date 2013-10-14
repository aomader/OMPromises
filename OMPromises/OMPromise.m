//
// OMPromise.h
// OMPromises
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

#import "OMPromise.h"

#import "OMPromises.h"

@interface OMPromise ()

@property NSMutableArray *fulfilHandlers;
@property NSMutableArray *failHandlers;
@property NSMutableArray *progressHandlers;

@end

@implementation OMPromise

#pragma mark - Property Interaction

- (void)setError:(NSError *)error {
    _error = error;
}

- (void)setResult:(id)result {
    _result = result;
}

- (void)setProgress:(float)progress {
    _progress = progress;
}

- (void)setState:(OMPromiseState)state {
    NSAssert(_state == OMPromiseStateUnfulfilled && state != OMPromiseStateUnfulfilled,
             @"A state transition requires to go from Unfulfilled to either Fulfilled or Failed");
    _state = state;
}

#pragma mark - Return

+ (OMPromise *)promiseWithResult:(id)result {
    OMDeferred *deferred = [OMDeferred deferred];
    [deferred fulfil:result];
    return deferred.promise;
}

+ (OMPromise *)promiseWithResult:(id)result after:(NSTimeInterval)delay {
    OMDeferred *deferred = [OMDeferred deferred];
    [deferred performSelector:@selector(fulfil:) withObject:result afterDelay:delay];
    return deferred.promise;
}

+ (OMPromise *)promiseWithError:(NSError *)error {
    OMDeferred *deferred = [OMDeferred deferred];
    [deferred fail:error];
    return deferred.promise;
}

+ (OMPromise *)promiseWithError:(NSError *)error after:(NSTimeInterval)delay {
    OMDeferred *deferred = [OMDeferred deferred];
    [deferred performSelector:@selector(fail:) withObject:error afterDelay:delay];
    return deferred.promise;
}

#pragma mark - Bind

- (OMPromise *)then:(id (^)(id result))thenHandler {
    OMDeferred *deferred = [OMDeferred deferred];

    [[self fulfilled:^(id result) {
        id next = thenHandler(result);
        if ([next isKindOfClass:OMPromise.class]) {
            [(OMPromise *)next control:deferred];
        } else {
            [deferred fulfil:next];
        }
    }] failed:^(NSError *error) {
        [deferred fail:error];
    }];

    return deferred.promise;
}

- (OMPromise *)rescue:(id (^)(NSError *error))rescueHandler {
    OMDeferred *deferred = [OMDeferred deferred];

    [[self fulfilled:^(id result) {
        [deferred fulfil:result];
    }] failed:^(NSError *error) {
        id next = rescueHandler(error);
        if ([next isKindOfClass:OMPromise.class]) {
            [(OMPromise *)next control:deferred];
        } else {
            [deferred fulfil:next];
        }
    }];

    return deferred.promise;
}

#pragma mark - Callbacks

- (OMPromise *)fulfilled:(void (^)(id result))fulfilHandler {
    if (self.state == OMPromiseStateFulfilled) {
        fulfilHandler(self.result);
    }

    if (self.state == OMPromiseStateUnfulfilled) {
        if (self.fulfilHandlers == nil) {
            self.fulfilHandlers = [NSMutableArray arrayWithCapacity:1];
        }
        [self.fulfilHandlers addObject:fulfilHandler];
    }

    return self;
}

- (OMPromise *)failed:(void (^)(NSError *))failHandler {
    if (self.state == OMPromiseStateFailed) {
        failHandler(self.error);
    }

    if (self.state == OMPromiseStateUnfulfilled) {
        if (self.failHandlers == nil) {
            self.failHandlers = [NSMutableArray arrayWithCapacity:1];
        }
        [self.failHandlers addObject:failHandler];
    }

    return self;
}

- (OMPromise *)progressed:(void (^)(float))progressHandler {
    if (self.state == OMPromiseStateUnfulfilled) {
        if (self.progressHandlers == nil) {
            self.progressHandlers = [NSMutableArray arrayWithCapacity:1];
        }
        [self.progressHandlers addObject:progressHandler];
    }

    return self;
}

#pragma mark - Combinators

+ (OMPromise *)chain:(NSArray *)thenHandlers initial:(id)result {
    OMDeferred *deferred = [OMDeferred deferred];
    
    if (thenHandlers.count == 0) {
        [deferred fulfil:result];
    } else {
        id (^f)(id) = [thenHandlers objectAtIndex:0];
        [[[[OMPromise promisify:f(result)] fulfilled:^(id nextResult) {
            [deferred progress:(1.f / thenHandlers.count)];
            
            [[[[OMPromise chain:[thenHandlers subarrayWithRange:NSMakeRange(1, thenHandlers.count - 1)] initial:nextResult] fulfilled:^(id result) {
                [deferred fulfil:result];
            }] failed:^(NSError *error) {
                [deferred fail:error];
            }] progressed:^(float progress) {
                [deferred progress:(progress / thenHandlers.count * (thenHandlers.count - 1) + 1.f/thenHandlers.count)];
            }];
        }] failed:^(NSError *error) {
            [deferred fail:error];
        }] progressed:^(float progress) {
            [deferred progress:(progress / thenHandlers.count)];
        }];
    }
    
    return deferred.promise;
}

+ (OMPromise *)any:(NSArray *)promises {
    OMDeferred *deferred = [OMDeferred deferred];

    __block NSUInteger failed = 0;

    for (OMPromise *promise in promises) {
        [[[promise fulfilled:^(id result) {
            if (deferred.state == OMPromiseStateUnfulfilled) {
                [deferred fulfil:result];
            }
        }] failed:^(NSError *error) {
            if (++failed == promises.count) {
                [deferred fail:[NSError errorWithDomain:OMPromisesErrorDomain
                                                   code:OMPromisesCombinatorAnyNonFulfilledError
                                               userInfo:nil]];
            }
        }] progressed:^(float progress) {
            if (progress > deferred.progress) {
                [deferred progress:progress];
            }
        }];
    }

    if (promises.count == 0) {
        [deferred fail:[NSError errorWithDomain:OMPromisesErrorDomain
                                           code:OMPromisesCombinatorAnyNonFulfilledError
                                       userInfo:nil]];
    }

    return deferred.promise;
}

+ (OMPromise *)all:(NSArray *)promises {
    OMDeferred *deferred = [OMDeferred deferred];

    NSMutableArray *results = [NSMutableArray arrayWithCapacity:promises.count];
    __block NSUInteger done = 0;
    
    void (^updateProgress)() = ^{
        float sum = 0;
        for (OMPromise *promise in promises) {
            sum += promise.progress;
        }
        [deferred progress:(sum / promises.count)];
    };

    for (NSUInteger i = 0; i < promises.count; ++i) {
        [results addObject:[NSNull null]];
        [[[(OMPromise *)promises[i] fulfilled:^(id result) {
            if (deferred.state == OMPromiseStateUnfulfilled) {
                updateProgress();
                
                if (result != nil) {
                    results[i] = result;
                }

                if (++done == promises.count) {
                    [deferred fulfil:results];
                }
            }
        }] failed:^(NSError *error) {
            if (deferred.state == OMPromiseStateUnfulfilled) {
                [deferred fail:error];
            }
        }] progressed:^(float progress) {
            if (deferred.state == OMPromiseStateUnfulfilled) {
                updateProgress();
            }
        }];
    }

    if (promises.count == 0) {
        [deferred fulfil:results];
    }
    
    return deferred.promise;
}

#pragma mark - Private Helper Methods

- (void)control:(OMDeferred *)deferred {
    [[[self fulfilled:^(id result) {
        [deferred fulfil:result];
    }] failed:^(NSError *error) {
        [deferred fail:error];
    }] progressed:^(float progress) {
        [deferred progress:progress];
    }];
}

+ (OMPromise *)promisify:(id)result {
    return [result isKindOfClass:OMPromise.class] ? result : [OMPromise promiseWithResult:result];
}

@end

