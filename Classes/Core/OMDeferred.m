//
// OMPromise.h
// OMPromises
//
// Copyright (C) 2013-2015 Oliver Mader
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

#import "OMDeferred.h"

#import "OMPromise+Protected.h"

@implementation OMDeferred

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        self.defaultQueue = [OMPromise globalDefaultQueue];
        self.progress = 0.f;
    }
    return self;
}

+ (OMDeferred *)deferred {
    return [[OMDeferred alloc] init];
}

#pragma mark - Public Methods

- (OMPromise *)promise {
    return self;
}

- (void)fulfil:(id)result {
    [self progress:1.f];
    
    @synchronized (self) {
        NSAssert(self.state == OMPromiseStateUnfulfilled, @"Can only get fulfilled while being Unfulfilled");
        
        self.result = result;
        self.state = OMPromiseStateFulfilled;
    }
    
    for (void (^fulfilHandler)(id) in self.fulfilHandlers) {
        fulfilHandler(result);
    }

    [self cleanup];
}

- (void)fail:(NSError *)error {
    @synchronized (self) {
        NSAssert(self.state == OMPromiseStateUnfulfilled, @"Can only fail while being Unfulfilled");
        
        self.error = error;
        self.state = OMPromiseStateFailed;
    }
    
    for (void (^failHandler)(NSError *) in self.failHandlers) {
        failHandler(error);
    }

    [self cleanup];
}

- (void)progress:(float)progress {
    NSArray *progressHandlers = nil;
    
    @synchronized (self) {
        NSAssert(self.state == OMPromiseStateUnfulfilled, @"Can only progress while being Unfulfilled");
        NSAssert(self.progress <= progress + FLT_EPSILON, @"Progress must not decrease");
        NSAssert(progress <= 1.0f + FLT_EPSILON, @"Progress must be in range (0, 1]");
        
        if (self.progress < progress - FLT_EPSILON) {
            self.progress = MIN(1.0f, progress);
            progressHandlers = self.progressHandlers;
        }
        
    }
    
    if (progressHandlers) {
        @synchronized (progressHandlers) {
            for (void (^progressHandler)(float) in progressHandlers) {
                progressHandler(progress);
            }
        }
    }
}

- (BOOL)tryFulfil:(id)result {
    @synchronized (self) {
        if (self.state == OMPromiseStateUnfulfilled) {
            [self fulfil:result];
            return YES;
        }
    }

    return NO;
}

- (BOOL)tryFail:(NSError *)error {
    @synchronized (self) {
        if (self.state == OMPromiseStateUnfulfilled) {
            [self fail:error];
            return YES;
        }
    }

    return NO;
}

- (BOOL)tryProgress:(float)progress {
    @synchronized (self) {
        if (self.state == OMPromiseStateUnfulfilled && progress > self.progress + FLT_EPSILON) {
            [self progress:progress];
            return YES;
        }
    }

    return NO;
}

#pragma mark - Cancellation

- (void)cancelled:(void (^)(OMDeferred *deferred))cancelHandler {
    [super cancelled:cancelHandler];
}

@end

