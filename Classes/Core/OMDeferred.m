//
// OMDeferred.m
// OMPromises
//
// Copyright (C) 2013-2016 Oliver Mader
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

#import "OMDeferred+Internal.h"

#import "OMPromise+Internal.h"

@implementation OMDeferred

#pragma mark - Init

- (instancetype)initWithPromise:(OMPromise *)promise {
    self = [super init];
    if (self) {
        _promise = promise;
    }
    return self;
}

- (instancetype)init {
    return [self initWithPromise:[(id)[OMPromise alloc] init]];
}

+ (OMDeferred *)deferred {
    return [[OMDeferred alloc] init];
}

#pragma mark - Public Methods

- (void)fulfil:(id)result {
    [self.promise fulfil:result];
}

- (void)fail:(NSError *)error {
    [self.promise fail:error];
}

- (void)progress:(float)progress {
    [self.promise progress:progress];
}

- (BOOL)tryFulfil:(id)result {
    return [self.promise tryFulfil:result];
}

- (BOOL)tryFail:(NSError *)error {
    return [self.promise tryFail:error];
}

- (BOOL)tryProgress:(float)progress {
    return [self.promise tryProgress:progress];
}

#pragma mark - Cancellation

- (void)cancelled:(void (^)(OMDeferred *deferred))cancelHandler {
    [self.promise cancelled:^{
        cancelHandler(self);
    }];
}

@end

