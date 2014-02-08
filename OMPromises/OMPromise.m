//
// OMPromise.h
// OMPromises
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

#import "OMPromise+Protected.h"

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
@property NSMutableArray *cancelHandlers;

@property(assign) NSUInteger depth;

@end

@implementation OMPromise

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        _depth = 1;
    }
    return self;
}

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

- (void)setCancellable:(BOOL)cancellable {
    _cancellable = cancellable;
}

- (void)setState:(OMPromiseState)state {
    NSAssert(_state == OMPromiseStateUnfulfilled && state != OMPromiseStateUnfulfilled,
             @"A state transition requires to go from Unfulfilled to either Fulfilled or Failed");
    _state = state;
}

#pragma mark - Return

+ (OMPromise *)promiseWithTask:(id (^)())task {
    return [OMPromise promiseWithTask:task on:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

+ (OMPromise *)promiseWithTask:(id (^)())task on:(dispatch_queue_t)queue {
    return [[OMPromise promiseWithResult:nil]
        then:^(id _) {
            return task();
        } on:queue];
}

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
    return [self then:thenHandler on:nil];
}

- (OMPromise *)then:(id (^)(id result))thenHandler on:(dispatch_queue_t)queue {
    OMDeferred *deferred = [OMDeferred deferred];
    
    NSUInteger current = self.depth;
    NSUInteger next = self.depth + 1;
    
    deferred.promise.depth = next;
    
    [[[self
        progressed:^(float progress) {
            [deferred progress:progress * ((float)current/next)];
        }]
        failed:^(NSError *error) {
            [deferred fail:error];
        }]
        fulfilled:^(id result) {
            [[OMPromise bind:deferred with:thenHandler using:result]
                progressed:^(float progress) {
                    [deferred progress:progress/next + ((float)current/next)];
                }];
        } on:queue];
    
    return deferred.promise;
}

- (OMPromise *)rescue:(id (^)(NSError *error))rescueHandler {
    return [self rescue:rescueHandler on:nil];
}

- (OMPromise *)rescue:(id (^)(NSError *error))rescueHandler on:(dispatch_queue_t)queue {
    OMDeferred *deferred = [OMDeferred deferred];
    deferred.promise.depth = self.depth;
    
    [[[self
        progressed:^(float progress) {
            [deferred progress:progress];
        }]
        fulfilled:^(id result) {
            [deferred fulfil:result];
        }]
        failed:^(NSError *error) {
            float failedAt = self.progress;
            [[OMPromise bind:deferred with:rescueHandler using:error]
                progressed:^(float progress) {
                    [deferred progress:failedAt + (1 - failedAt)*progress];
                }];
        } on:queue];
    
    return deferred.promise;
}

#pragma mark - Callbacks

- (OMPromise *)fulfilled:(void (^)(id result))fulfilHandler {
    return [self fulfilled:fulfilHandler on:nil];
}

- (OMPromise *)fulfilled:(void (^)(id result))fulfilHandler on:(dispatch_queue_t)queue {
    if (queue != nil) {
        fulfilHandler = ^(id result) {
            dispatch_async(queue, ^{
                fulfilHandler(result);
            });
        };
    }
    
    OMPromiseState state;
    
    @synchronized (self) {
        state = self.state;
        
        if (state == OMPromiseStateUnfulfilled) {
            if (self.fulfilHandlers == nil) {
                self.fulfilHandlers = [NSMutableArray arrayWithCapacity:1];
            }
            [self.fulfilHandlers addObject:fulfilHandler];
        }
    }
    
    if (state == OMPromiseStateFulfilled) {
        fulfilHandler(self.result);
    }
    
    return self;
}

- (OMPromise *)failed:(void (^)(NSError *error))failHandler {
    return [self failed:failHandler on:nil];
}

- (OMPromise *)failed:(void (^)(NSError *error))failHandler on:(dispatch_queue_t)queue {
    if (queue != nil) {
        failHandler = ^(NSError *error) {
            dispatch_async(queue, ^{
                failHandler(error);
            });
        };
    }
    
    OMPromiseState state;
    
    @synchronized (self) {
        state = self.state;
        
        if (state == OMPromiseStateUnfulfilled) {
            if (self.failHandlers == nil) {
                self.failHandlers = [NSMutableArray arrayWithCapacity:1];
            }
            [self.failHandlers addObject:failHandler];
        }
    }
    
    if (self.state == OMPromiseStateFailed) {
        failHandler(self.error);
    }
    
    return self;
}

- (OMPromise *)progressed:(void (^)(float progress))progressHandler {
    return [self progressed:progressHandler on:nil];
}

- (OMPromise *)progressed:(void (^)(float progress))progressHandler on:(dispatch_queue_t)queue {
    if (queue != nil) {
        progressHandler = ^(float progress) {
            dispatch_async(queue, ^{
                progressHandler(progress);
            });
        };
    }
    
    if (self.progress > 0.f) {
        progressHandler(self.progress);
    }
    
    @synchronized (self) {
        if (self.state == OMPromiseStateUnfulfilled) {
            if (self.progressHandlers == nil) {
                self.progressHandlers = [NSMutableArray arrayWithCapacity:1];
            }
            @synchronized (self.progressHandlers) {
                [self.progressHandlers addObject:progressHandler];
            }
        }
    }
    
    return self;
}

#pragma mark - Cancellation

- (void)cancel {
    @synchronized (self) {
        NSAssert(self.cancellable, @"Promise does not support cancellation!");
        
        self.state = OMPromiseStateFailed;
        self.error = [NSError errorWithDomain:OMPromisesErrorDomain
                                         code:OMPromisesCancelledError
                                     userInfo:nil];
    }

    for (void (^cancelHandler)(OMDeferred *) in self.cancelHandlers) {
        cancelHandler((OMDeferred *)self);
    }
    
    for (void (^failHandler)(NSError *) in self.failHandlers) {
        failHandler(self.error);
    }

    [self cleanup];
}

- (void)cancelled:(void (^)(OMDeferred *deferred))cancelHandler {
    @synchronized (self) {
        if (self.state == OMPromiseStateUnfulfilled) {
            if (self.cancelHandlers == nil) {
                self.cancelHandlers = [NSMutableArray arrayWithCapacity:1];
            }
            [self.cancelHandlers addObject:cancelHandler];
            self.cancellable = YES;
        }
    }
}

#pragma mark - Combinators & Transformers

- (OMPromise *)join {
    return [self then:^(OMPromise *next) {
        return next;
    }];
}

+ (OMPromise *)chain:(NSArray *)handlers initial:(id)result {
    OMPromise *promise = result;
    
    if (![result isKindOfClass:OMPromise.class]) {
        promise = [OMPromise promiseWithResult:result];
        promise.depth = 0;
    }
    
    for (id f in handlers) {
        OMPromiseHandler type = [OMPromise typeOfHandler:f];
        
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
    }
    
    return promise;
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

+ (OMPromise *)bind:(OMDeferred *)deferred with:(id (^)(id))handler using:(id)parameter {
    id next = nil;
    
    @try {
        next = handler(parameter);
    }
    @catch (NSException *exception) {
        next = [NSError errorWithDomain:OMPromisesErrorDomain
                                   code:OMPromisesExceptionError
                               userInfo:@{NSUnderlyingErrorKey: exception}];
    }
    
    if ([next isKindOfClass:OMPromise.class]) {
        return [[(OMPromise *)next fulfilled:^(id result) {
            [deferred fulfil:result];
        }] failed:^(NSError *error) {
            [deferred fail:error];
        }];
    } else if ([next isKindOfClass:NSError.class]) {
        [deferred fail:next];
    } else {
        [deferred fulfil:next];
    }
    
    return nil;
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
    self.cancelHandlers = nil;
}

@end

