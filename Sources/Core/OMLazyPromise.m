//
// OMLazyPromise.m
// OMPromises
//
// Copyright (C) 2016 Oliver Mader
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

#import "OMLazyPromise.h"

#import "OMPromise+Internal.h"
#import "OMDeferred+Internal.h"

@interface OMLazyPromise ()

@property(nonatomic, strong) void (^task)(OMDeferred *);
@property(nonatomic) dispatch_queue_t queue;

@end

@implementation OMLazyPromise

#pragma mark - Init

- (instancetype)initWithTask:(void (^)(OMDeferred *))task on:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _started = NO;
        _task = task;
        _queue = queue;
    }
    return self;
}

+ (OMLazyPromise *)promiseWithTask:(id (^)())task {
    return [OMLazyPromise promiseWithTask:task on:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

+ (OMLazyPromise *)promiseWithTask:(id (^)())task on:(dispatch_queue_t)queue {
    return [[OMLazyPromise alloc] initWithTask:^(OMDeferred *deferred) {
        id result = task();

        if ([result isKindOfClass:NSError.class]) {
            [deferred fail:result];
        } else {
            [deferred fulfil:result];
        }
    } on:queue];
}

+ (OMLazyPromise *)promiseWithDetailedTask:(void (^)(OMDeferred *))task {
    return [OMLazyPromise promiseWithDetailedTask:task on:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

+ (OMLazyPromise *)promiseWithDetailedTask:(void (^)(OMDeferred *))task on:(dispatch_queue_t)queue {
    return [[OMLazyPromise alloc] initWithTask:task on:queue];
}

#pragma mark - OMPromise Overrides

- (instancetype)then:(id (^)(id))thenHandler on:(dispatch_queue_t)queue {
    if (self.state != OMPromiseStateUnfulfilled) {
        return [super then:thenHandler on:queue];
    }
    
    if (queue == nil) {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }

    const NSUInteger current = self.depth;
    const NSUInteger next = self.depth + 1;

    OMLazyPromise *promise = [OMLazyPromise promiseWithDetailedTask:^(OMDeferred *deferred) {
        [[[self
                progressed:^(float progress) {
                    [deferred progress:progress * ((float)current/next)];
                }]
                failed:^(NSError *error) {
                    [deferred fail:error];
                }]
                fulfilled:^(id result) {
                    [OMPromise bind:deferred with:thenHandler using:result bias:(float)current/next fraction:1.f/next];
                } on:queue];
    } on:queue];

    promise.depth = next;

    return promise;
}

- (instancetype)rescue:(id (^)(NSError *))rescueHandler on:(dispatch_queue_t)queue {
    if (self.state != OMPromiseStateUnfulfilled) {
        return [super rescue:rescueHandler on:queue];
    }
    
    if (queue == nil) {
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }

    OMLazyPromise *promise = [OMLazyPromise promiseWithDetailedTask:^(OMDeferred *deferred) {
        [[[self
                progressed:^(float progress) {
                    [deferred progress:progress];
                }]
                fulfilled:^(id result) {
                    [deferred fulfil:result];
                }]
                failed:^(NSError *error) {
                    [OMPromise bind:deferred with:rescueHandler using:error bias:self.progress fraction:1.f - self.progress];
                } on:queue];
    } on:queue];

    promise.depth = self.depth;

    return promise;
}

- (instancetype)fulfilled:(void (^)(id))fulfilHandler on:(dispatch_queue_t)queue {
    [self start];

    return [super fulfilled:fulfilHandler on:queue];
}

- (instancetype)failed:(void (^)(NSError *))failHandler on:(dispatch_queue_t)queue {
    [self start];

    return [super failed:failHandler on:queue];
}

- (instancetype)progressed:(void (^)(float))progressHandler on:(dispatch_queue_t)queue {
    [self start];

    return [super progressed:progressHandler on:queue];
}

- (id)waitForResultWithin:(NSTimeInterval)seconds {
    [self start];

    return [super waitForResultWithin:seconds];
}

- (NSError *)waitForErrorWithin:(NSTimeInterval)seconds {
    [self start];

    return [super waitForErrorWithin:seconds];
}

- (void)cleanup {
    [super cleanup];

    self.task = nil;
}

#pragma mark - NSObject Overrides

- (NSString *)debugDescription {
    if (!self.started) {
        return [NSString stringWithFormat:@"<OMLazyPromise: %p; started = NO>", self];
    } else {
        return [super debugDescription];
    }
}

#pragma mark - Private Methods

- (BOOL)start {
    @synchronized (self) {
        if (self.started) {
            return NO;
        } else {
            self.started = YES;
        }
    }

    dispatch_async(self.queue, ^{
        OMDeferred *deferred = [[OMDeferred alloc] initWithPromise:self];

        self.task(deferred);
    });

    return YES;
}

@end
