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

#import "OMDeferred.h"

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

- (void)setProgress:(NSNumber *)progress {
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

+ (OMPromise *)promiseWithError:(NSError *)error {
    OMDeferred *deferred = [OMDeferred deferred];
    [deferred fail:error];
    return deferred.promise;
}

#pragma mark - Bind

- (OMPromise *)then:(id (^)(id result))thenHandler {
    if (self.state == OMPromiseStateFailed) {
        return self;
    } else if (self.state == OMPromiseStateFulfilled) {
        id next = thenHandler(self.result);
        return [next isKindOfClass:OMPromise.class] ? next : [OMPromise promiseWithResult:next];
    } else {
        OMDeferred *deferred = [OMDeferred deferred];

        [[self fulfilled:^(id result) {
            #warning check blocks for self references
            id next = thenHandler(result);
            if ([next isKindOfClass:OMPromise.class]) {
                [[[(OMPromise *)next fulfilled:^(id result) {
                    [deferred fulfil:result];
                }] failed:^(NSError *error) {
                    [deferred fail:error];
                }] progressed:^(NSNumber *progress) {
                    [deferred progress:progress];
                }];
            } else {
                [deferred fulfil:next];
            }
        }] failed:^(NSError *error) {
            [deferred fail:error];
        }];

        return deferred.promise;
    }
}

- (OMPromise *)rescue:(id (^)(NSError *error))rescueHandler {
    if (self.state == OMPromiseStateFulfilled) {
        return self;
    } else if (self.state == OMPromiseStateFailed) {
        id next = rescueHandler(self.error);
        return [next isKindOfClass:OMPromise.class] ? next : [OMPromise promiseWithResult:next];
    } else {
        OMDeferred *deferred = [OMDeferred deferred];

        [[self fulfilled:^(id result) {
            [deferred fulfil:result];
        }] self failed:^(NSError *error) {
            id next = rescueHandler(error);
            if ([next isKindOfClass:OMPromise.class]) {
                [[[(OMPromise *)next fulfilled:^(id result) {
                    [deferred fulfil:result];
                }] failed:^(NSError *error) {
                    [deferred fail:error];
                }] progressed:^(NSNumber *progress) {
                    [deferred progress:progress];
                }];
            } else {
                [deferred fulfil:next];
            }
        }];

        return deferred.promise;
    }
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

- (OMPromise *)progressed:(void (^)(NSNumber *))progressHandler {
    if (self.state == OMPromiseStateUnfulfilled) {
        if (self.progressHandlers == nil) {
            self.progressHandlers = [NSMutableArray arrayWithCapacity:1];
        }
        [self.progressHandlers addObject:progressHandler];
    }

    return self;
}

#pragma mark - Combinators

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

