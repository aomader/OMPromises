//
// OMLazyPromise.h
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

#import "OMPromise.h"

NS_ASSUME_NONNULL_BEGIN

/** Represents "lazy" work that is only started once somebody is interested in it.

 In order to start the underlying work, one must register at least one callback
 block (i.e., fulfilled:, failed:, progressed:, always:) or any chaining method.
 */
@interface OMLazyPromise<__covariant ResultType> : OMPromise<ResultType>

/** Create a promise with its outcome _lazily_ determined by the supplied block.

 In contrast to the other task based methods, this one doesn't immediately
 trigger the execution of the supplied block. Instead, it waits for the returned
 promise to being used, i.e., someone's registering callback handlers to it.

 @param task The task describing the outcome of the promise.
 @return A new _lazy_ promise.
 @see lazyPromiseWithTask:on:
 */
+ (OMLazyPromise<ResultType> *)promiseWithTask:(id (^)())task;

/** Similar to promiseWithTask:, but executes the block on the specified queue.

 @param task The task describing the outcome of the promise.
 @param queue Context in which the block is executed.
 @return A new _lazy_ promise.
 @see lazyPromiseWithTask:
 */
+ (OMLazyPromise<ResultType> *)promiseWithTask:(id (^)())task on:(dispatch_queue_t)queue;

+ (OMLazyPromise<ResultType> *)promiseWithDetailedTask:(void (^)(OMDeferred *deferred))task;

+ (OMLazyPromise<ResultType> *)promiseWithDetailedTask:(void (^)(OMDeferred *deferred))task on:(dispatch_queue_t)queue;

/** Indicates whether the represented work has already been started.
 */
@property(nonatomic) BOOL started;

- (OMLazyPromise *)then:(id (^)(ResultType _Nullable result))thenHandler;
- (OMLazyPromise *)then:(id (^)(ResultType _Nullable result))thenHandler on:(dispatch_queue_t)queue;
- (OMLazyPromise *)rescue:(id (^)(NSError *_Nullable error))rescueHandler;
- (OMLazyPromise *)rescue:(id (^)(NSError *_Nullable error))rescueHandler on:(dispatch_queue_t)queue;

/** Forces the start of the underlying work.

 @return Whether the work has been started or not in case it was started before.
 @see started
 */
- (BOOL)start;

@end

NS_ASSUME_NONNULL_END
