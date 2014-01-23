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

#import "CTBlockDescription.h"
#import "OMPromises.h"

typedef NS_ENUM(NSInteger, OMPromiseHandler) {
    OMPRomiseHandlerUnknown = -1,
    OMPromiseHandlerFulfilled,
    OMPromiseHandlerFailed,
    OMPromiseHandlerProgressed,
    OMPromiseHandlerThen,
    OMPromiseHandlerRescue
};

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

    [[[self fulfilled:^(id result) {
        [deferred fulfil:result];
    }] failed:^(NSError *error) {
        id next = rescueHandler(error);
        float failedAt = self.progress;
        if ([next isKindOfClass:OMPromise.class]) {
            [[[(OMPromise *)next fulfilled:^(id result) {
                [deferred fulfil:result];
            }] failed:^(NSError *error) {
                [deferred fail:error];
            }] progressed:^(float progress) {
                [deferred progress:failedAt + (1 - failedAt)*progress];
            }];
        } else {
            [deferred fulfil:next];
        }
    }] progressed:^(float progress) {
        [deferred progress:progress];
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

#pragma mark - Combinators & Transformers

- (OMPromise *)join {
    return [OMPromise chain:@[
        ^(id _) {
            return self;
        }, ^(id inner) {
            return inner;
        }] initial:nil];
}

+ (OMPromise *)chain:(NSArray *)handlers initial:(id)result {
    OMDeferred *deferred = [OMDeferred deferred];
    
    NSUInteger total = 0;
    OMPromiseHandler handlerTypes[handlers.count];
    
    // the workload portion is determined by the total amount of then handlers
    for (NSUInteger i = 0; i < handlers.count; ++i) {
        handlerTypes[i] = [OMPromise typeOfHandler:handlers[i]];
        total += (handlerTypes[i] == OMPromiseHandlerThen) ? 1 : 0;
    }
    
    OMPromise *promise = [OMPromise promisify:result];
    NSUInteger done = 0;
    
    for (NSUInteger i = 0; i < handlers.count; ++i) {
        id f = handlers[i];
        OMPromiseHandler type = handlerTypes[i];
        
        if (type == OMPromiseHandlerFulfilled) {
            [promise fulfilled:f];
        } else if (type == OMPromiseHandlerProgressed) {
            [promise progressed:f];
        } else if (type == OMPromiseHandlerFailed) {
            [promise failed:f];
        } else if (type == OMPromiseHandlerThen) {
            promise = [promise then:f];
        } else if (type == OMPromiseHandlerRescue) {
            promise = [promise rescue:f];
            
        } else {
            [NSException raise:@"Invalid block type"
                        format:@"The supplied block %@ is of unknown type", f];
        }
        
        BOOL updateProgress = type == OMPromiseHandlerRescue;
        for (NSUInteger j = i + 1; j < handlers.count && !updateProgress; ++j) {
            updateProgress = handlerTypes[j] == OMPromiseHandlerThen;
            if (handlerTypes[j] == OMPromiseHandlerRescue)
                break;
        }
        
        if (updateProgress) {
            float doneProgress = (float)done / total;
            [[promise
              progressed:^(float part) {
                  [deferred progress:doneProgress + part / total];
              }]
             fulfilled:^(id _) {
                 [deferred progress:doneProgress + 1.f / total];
             }];
            done += 1;
        }
    }
    
    // final promise fulfills/fails the chain
    [[promise
        fulfilled:^(id result) {
            [deferred fulfil:result];
        }]
        failed:^(NSError *error) {
            [deferred fail:error];
        }];
    
    return deferred.promise;
}

+ (OMPromise *)chain:(NSArray *)handlers
            previous:(OMPromise *)previous
            deferred:(OMDeferred *)deferred
            progress:(float)progress
               total:(NSUInteger)total {
    // base case
    if (handlers.count == 0) {
        [[previous
            failed:^(NSError *error) {
                [deferred fail:error];
            }]
            fulfilled:^(id result) {
                [deferred fulfil:result];
            }];
        return deferred.promise;
    }
    
    id f = handlers[0];
    OMPromiseHandler type = [OMPromise typeOfHandler:f];
    
    if (type == OMPromiseHandlerFulfilled) {
        [previous fulfilled:f];
    } else if (type == OMPromiseHandlerProgressed) {
        [previous progressed:f];
    } else if (type == OMPromiseHandlerFailed) {
        [previous failed:f];
    } else if (type == OMPromiseHandlerThen) {
        previous = [previous then:f];
    } else if (type == OMPromiseHandlerRescue) {
        previous = [previous rescue:f];
    } else {
        [NSException raise:@"Invalid block type"
                    format:@"The supplied block %@ is of unknown type", f];
    }
    
    if (type == OMPromiseHandlerThen) {
        [[previous
            progressed:^(float part) {
                [deferred progress:progress + part / total];
            }]
            fulfilled:^(id _) {
                [deferred progress:progress + 1.f / total];
            }];
        
        progress += 1.f / total;
    }
    
    return [OMPromise chain:[handlers subarrayWithRange:NSMakeRange(1, handlers.count - 1)]
                   previous:previous
                   deferred:deferred
                   progress:progress
                      total:total];
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

+ (OMPromiseHandler)typeOfHandler:(id)handler {
    NSMethodSignature *signature = [[[CTBlockDescription alloc] initWithBlock:handler] blockSignature];
    
    if ([signature numberOfArguments] != 2) {
        return OMPRomiseHandlerUnknown;
    }
    
    // parse return type
    BOOL callback = [signature methodReturnType][0] == 'v';
    BOOL chain = [signature methodReturnType][0] == '@';
    
    // parse argument
    BOOL error = strcmp([signature getArgumentTypeAtIndex:1], "@\"NSError\"") == 0;
    BOOL progress = strcmp([signature getArgumentTypeAtIndex:1], "f") == 0;
    BOOL result = !error && [signature getArgumentTypeAtIndex:1][0] == '@';
    
    if (callback && error) {
        return OMPromiseHandlerFailed;
    } else if (callback && progress) {
        return OMPromiseHandlerProgressed;
    } else if (callback && result) {
        return OMPromiseHandlerFulfilled;
    } else if (chain && error) {
        return OMPromiseHandlerRescue;
    } else if (chain && result) {
        return OMPromiseHandlerThen;
    }
    
    return OMPRomiseHandlerUnknown;
}

- (void)cleanup {
    self.fulfilHandlers = nil;
    self.failHandlers = nil;
    self.progressHandlers = nil;
}

@end

