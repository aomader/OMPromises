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

#import <Foundation/Foundation.h>

@class OMDeferred<ResultType>;
@class OMLazyPromise<__covariant ResultType>;

NS_ASSUME_NONNULL_BEGIN

/** Possible states of an OMPromise.
 */
typedef NS_ENUM(NSInteger, OMPromiseState) {
    OMPromiseStateUnfulfilled = 0,
    OMPromiseStateFailed = 1,
    OMPromiseStateFulfilled = 2
};

/** Codes used for errors that lie in the domain of OMPromisesErrorDomain.
 */
typedef NS_ENUM(NSInteger, OMPromisesErrorCodes) {
    /** An user supplied block raised an exception. */
    OMPromisesExceptionError,
    /** Indicates that the promise has been cancelled. */
    OMPromisesCancelledError,
    /** Indicates that no promise passed to the any: combinator got fulfilled. */
    OMPromisesCombinatorAnyNonFulfilledError
};

/** The error domain used within NSError to distinguish errors specific
 to OMPromises.
 */
extern NSString *const OMPromisesErrorDomain;

/** OMPromise proxies the outcome of a long-running asynchronous operation. It's
 a read-only object which is described essentially by state. The state defines
 how to interpret the values kept in result, error and progress.
 If state is equal to OMPromiseStateFulfilled, the value kept in result is meaningful.
 If state is equal to OMPromiseStateUnfulfilled, the value kept in error is meaningful.
 Otherwise the promise is unfulfilled and the user might consult progress for further
 information.

 In order to get informed if either progress, result or error change, one can register
 a block using progressed:, fulfilled: or failed: to get called. You might register
 multiple blocks for the same event. Also the methods return self in order to easily
 chain multiple method calls.

 Sometimes it might be necessary to create a promise, once a promise is fulfilled, thus
 building a chain of promises. That's the use-case of then:. The method takes a block
 that is called once the promise is fulfilled and returns a new promise. The supplied
 block has to return a value, either a promise or any other value, which is used to
 determine the outcome of the newly returned promise. If the promise fails the 
 block isn't called and the returned promise fails as well.
 If you want to build a chain in case the promise fails, you use rescue:. It's very
 similar to then:, but the supplied block is called in case the promise fails.
 
 To build more complex structures you might use one combinator of join:, chain:initial:,
 all:, any:, collect: or relay:. See the corresponding method documentation for more
 information.
 
 We have two blocking methods which are designed for testing purposes and should only
 be used in testing scenarios and not in production code. The methods
 waitForResultWithin: and waitForErrorWithin: block the current execution until a certain
 state is reached within a certain interval.

 **Note:** Creating an instance of `OMPromise` yourself is in most of the cases useless,
 since the promise will never change any of its properties.
 */
@interface OMPromise<__covariant ResultType> : NSObject

///---------------------------------------------------------------------------------------
/// @name Current state
///---------------------------------------------------------------------------------------

/** Current state.

 May only change from `OMPromiseStateUnfulfilled` to either `OMPromiseStateFailed` or
 `OMPromiseStateFulfilled`.
 */
@property(readonly, nonatomic) OMPromiseState state;

/** Maybe the promised result.
 
 Contains the result in case the promise has been fulfilled.
 */
@property(readonly, nonatomic, nullable) ResultType result;

/** Maybe an error.
 
 Contains the reason in case the promise failed.
 */
@property(readonly, nonatomic, nullable) NSError *error;

/** Progress of the underlying workload.
 
 Describes the progress of the underlying workload as a floating point number in range
 [0, 1]. It only increases.
 */
@property(readonly, nonatomic) float progress;

/** Whether the underlying operation supports cancellation or not.
 
 In case cancellable is `YES`, it's safe to call cancel.
 */
@property(readonly, nonatomic) BOOL cancellable;

///---------------------------------------------------------------------------------------
/// @name Queue Management
///---------------------------------------------------------------------------------------

/** Returns the defaultQueue set for each promise on creation.

 The global default queue is used as default parameter for defaultQueue of
 each OMPromise instance. It defaults to nil.

 @return The global default queue.
 @see setGlobalDefaultQueue:
 @see defaultQueue
 */
+ (dispatch_queue_t)globalDefaultQueue;

/** Override the global default queue.

 @param queue The new global default queue.
 @see globalDefaultQueue
 */
+ (void)setGlobalDefaultQueue:(dispatch_queue_t)queue;

/** Blocks are dispatched to this queue if not specified otherwise.

 This property inherits the globalDefaultQueue property during instantiation.
 Calls that take a block where you don't explicitly provide the GCD queue, use
 this queue to dispatch the block to.
 If this property is set to nil, blocks are executed in the calling context.

 @see globalDefaultQueue:
 @see on:
 */
@property(nonatomic) dispatch_queue_t defaultQueue;

/** Convenience method to set the defaultQueue and ease successive operations.

 @return The current promise.
 @see defaultQueue
 */
- (instancetype)on:(dispatch_queue_t)queue;

///---------------------------------------------------------------------------------------
/// @name Creation
///---------------------------------------------------------------------------------------

/** Create a promise with its outcome determined by a supplied block.
 
 The promise completed with the result of the block. If anything within the block
 raises an exception, the promise fails with the OMPromiseExceptionError code.
 The block is executed asynchronously in a background queue. If you need more control
 where the block is executed, have a look at promiseWithTask:on:.
 
 @param task The task describing the outcome of the promise.
 @return A new promise.
 @see promiseWithTask:on:
 @see promiseWithLazyTask:
 */
+ (OMPromise<ResultType> *)promiseWithTask:(id (^)())task;

/** Similar to promiseWithTask:, but executes the block on a specific queue.
 
 @param task The task describing the outcome of the promise.
 @param queue Context in which the block is executed.
 @return A new promise.
 @see promiseWithTask:
 */
+ (OMPromise<ResultType> *)promiseWithTask:(id (^)())task on:(dispatch_queue_t)queue;

/** Create a fulfilled promise.
 
 Simply wraps the supplied value inside a fulfilled promise.
 
 @param result The value to fulfil the promise.
 @return A fulfilled promise.
 */
+ (OMPromise<ResultType> *)promiseWithResult:(nullable ResultType)result;

/** Create a promise which gets fulfilled after a certain delay.

 After a certain amount of time the promise gets fulfilled using the supplied value.
 
 @param result The value to fulfil the promise.
 @param delay Time span to wait before fulfilling the promise.
 @return A promise that will get fulfilled.
 @see promiseWithResult:
 */
+ (OMPromise<ResultType> *)promiseWithResult:(nullable ResultType)result after:(NSTimeInterval)delay;

/** Create a failed promise.
 
 @param error Reason why the promise failed.
 @return A failed promise.
 */
+ (OMPromise<ResultType> *)promiseWithError:(nullable NSError *)error;

/** Create a promise which fails after a certain delay.

 After a certain amount of time the promise fails using the supplied error.
 
 @param error Reason why the promise failed.
 @param delay Time span to wait before the promise fails.
 @return A promise that will fail.
 @see promiseWithError:
 */
+ (OMPromise<ResultType> *)promiseWithError:(nullable NSError *)error after:(NSTimeInterval)delay;

///---------------------------------------------------------------------------------------
/// @name Building promise chains
///---------------------------------------------------------------------------------------

/** Create a new promise by binding the fulfilled result to another promise.

 The supplied block gets called in case the promise gets fulfilled. If the promise fails,
 the block is not called and the returned promise fails (short-circuited).
 
 The block can either return a promise, n which case the returned promise is bound to
 the promise returned by this method. But it can also return a simple id value, which
 either directly fulfils the returned promise or fails it, in case the object returned by
 the block is of type NSError.
 
 If the supplied block raises an exception during execution, the promise fails also
 with an OMPromiseExceptionError error code.
 
 The returned promise is aware of all parent promises and thus models the progress as
 an equal distribution of workload amongst all promises in the chain.

 @param thenHandler Block to be called once the promise gets fulfilled.
 @return A new promise.
 @see rescue:
 */
- (OMPromise *)then:(id (^)(ResultType _Nullable result))thenHandler;

/** Similar to then:, but executes the supplied block asynchronously on a specific queue.
 
 @param thenHandler Block to be called once the promise gets fulfilled.
 @param queue Context in which the block is executed.
 @return A new promise.
 @see then:
 */
- (OMPromise *)then:(id (^)(ResultType _Nullable result))thenHandler on:(dispatch_queue_t)queue;

/** Create a new promise by binding the error reason to another promise.

 Similar to then:, but the supplied block is called in case the promise fails, from
 which point on it behaves like then:. If the promise gets fulfilled the step is skipped.
 The returned promise proxies the progress of the original one. In case the original
 promise fails, the rescueHandler continues from that point on.

 @param rescueHandler Block to be called once the promise failed.
 @return A new promise.
 @see then:
 */
- (OMPromise *)rescue:(id (^)(NSError *_Nullable error))rescueHandler;

/** Similar to rescue:, but executes the supplied block asynchronously on a specific queue.
 
 @param rescueHandler Block to be called once the promise failed.
 @param queue Context in which the block is executed.
 @return A new promise.
 @see rescue:
 */
- (OMPromise *)rescue:(id (^)(NSError *_Nullable error))rescueHandler on:(dispatch_queue_t)queue;

///---------------------------------------------------------------------------------------
/// @name Registering callbacks
///---------------------------------------------------------------------------------------

/** Register a block to be called when the promise gets fulfilled.
 
 The handler is immediately executed if the promise is already in the fulfilled state.

 @param fulfilHandler Block to be called.
 @return The promise itself.
 */
- (instancetype)fulfilled:(void (^)(ResultType _Nullable result))fulfilHandler;

/** Similar to fulfilled:, but executes the supplied block asynchronously on a specific
 queue.

 @param fulfilHandler Block to be called.
 @param queue Context in which the block is executed.
 @return The promise itself.
 @see fulfilled:
 */
- (instancetype)fulfilled:(void (^)(ResultType _Nullable result))fulfilHandler on:(dispatch_queue_t)queue;

/** Register a block to be called when the promise fails.
 
 The handler is immediately executed if the promise is already in the failed state.

 @param failHandler Block to be called.
 @return The promise itself.
 */
- (instancetype)failed:(void (^)(NSError *_Nullable error))failHandler;

/** Similar to failed:, but executes the supplied block asynchronously on a specific queue.
 
 @param failHandler Block to be called.
 @param queue Context in which the block is executed.
 @return The promise itself.
 @see failed:
 */
- (instancetype)failed:(void (^)(NSError *_Nullable error))failHandler on:(dispatch_queue_t)queue;

/** Register a block to be called when the promise progresses.
 
 If the promise already made some progress
 the handler is called immediately with the current progress. That's also true if you register a progressed
 block at an already fulfilled/failed promise.

 @param progressHandler Block to be called.
 @return The promise itself.
 */
- (instancetype)progressed:(void (^)(float progress))progressHandler;

/** Similar to progressed:, but executes the supplied block asynchronously on a specific
 queue.
 
 @param progressHandler Block to be called.
 @param queue Context in which the block is executed.
 @return The promise itself.
 @see progressed:
 */
- (instancetype)progressed:(void (^)(float progress))progressHandler on:(dispatch_queue_t)queue;

/** Register a block to be called once the promise changed its state.

 The block is executed when the promise got fulfilled or failed. It might be used for
 finalizing tasks which should be executed always.

 @param alwaysHandler Block to be called.
 @return The promise itself.
 */
- (instancetype)always:(void (^)(OMPromiseState state, ResultType _Nullable result, NSError *_Nullable error))alwaysHandler;

/** Similar to always:, but executes the supplied block asynchronously on a specific queue.

 @param alwaysHandler Block to be called.
 @param queue Context in which the block is executed
 @return The promise itself.
 @see always:
 */
- (instancetype)always:(void (^)(OMPromiseState state, ResultType _Nullable result, NSError *_Nullable error))alwaysHandler
                    on:(dispatch_queue_t)queue;

///---------------------------------------------------------------------------------------
/// @name Cancellation
///---------------------------------------------------------------------------------------

/** Cancel a still unfulfilled promise.
 
 If the deferred supports cancellation, it should try to stop/abort the corresponding
 task. By default a deferred _does not_ support cancellation, in which case a call
 to cancel would throw an exception.
 */
- (void)cancel;

///---------------------------------------------------------------------------------------
/// @name Combinators & Transformers
///---------------------------------------------------------------------------------------

/** Remove one level of OMPromise wrapping.
 
 Transforms a promise of type OMPromise[OMPromise[a]] into a promise of type OMPromise[a].
 @return A new promise with one level of wrapping removed.
 */
- (OMPromise *)join;

/** Create a promise chain as if you would register blocks in immediate succession.

 You can use all kind of blocks as they are specified by then:, rescue:, fulfilled:,
 failed: and progressed:.
 The initial value can either be a simple object or a promise.

 @param thenHandlers Sequence of then: handler blocks.
 @param result Initial result supplied to the first handler block.
 @return A new promise describing the whole chain.
 */
+ (OMPromise *)chain:(NSArray *)thenHandlers initial:(nullable id)result;

/** Race for the first fulfilled promise in parallel.

 The new returned promise gets fulfilled if any of the supplied promises does.
 If no promise gets fulfilled, the returned promise fails.

 The progress aligns to the mostly progressed promise.

 @param promises A sequence of promises.
 @return A new promise.
 */
+ (OMPromise *)any:(NSArray<OMPromise *> *)promises;

/** Wait for all promises to get fulfilled.

 In case that all supplied promises get fulfilled, the promise itself returns
 an array containing all results for the supplied promises while respecting the
 correct order. `nil` has been replaced by `[NSNull null]`. If any promise fails,
 the returned promise fails also.

 Similar to chain: the workload of each promise is considered equal to
 determine the overall progress.

 @param promises A sequence of promises.
 @return A new promise.
 */
+ (OMPromise<NSArray *> *)all:(NSArray<OMPromise *> *)promises;

/** Collects the outcome of all promises.
 
 Once all promises either failed or got fulfilled, the new promise gets fulfilled
 with an array containing the outcome of all supplied promises in order.
 Values of `nil` are replaced with `NSNull.null`.
 The new promise never fails and its progress is determined by an equal distribution
 amonst the supplied promises.
 
 @param promises A sequence of promises.
 @return A new promise yielding an array containing all outcomes in order.
 */
+ (OMPromise<NSArray *> *)collect:(NSArray<OMPromise *> *)promises;

/** Relays all promise events to a deferred.

  Relays state transitions as well as progress notifications to the supplied
  deferred, if possible.

  @param deferred The deferred to be controlled.
  @return The promise itself.
 */
- (instancetype)relay:(OMDeferred<ResultType> *)deferred;

///---------------------------------------------------------------------------------------
/// @name Testing
///---------------------------------------------------------------------------------------

/** Wait for the promise to get fulfilled within a certain interval.
 
 Blocks the current execution until the promise got fulfilled or the time is up,
 in which case it throws an exception. Throws also an exception when the promise fails.
 You should use this method only for testing purposes and nothing more.
 
 @param seconds The waiting interval, -1. for infinity.
 @return The result of the promise.
 @see waitForErrorWithin:
 */
- (nullable ResultType)waitForResultWithin:(NSTimeInterval)seconds;

/** Wait for the promise to fail within a certain interval.
 
 Blocks the current execution until the promise failed or the time is up,
 in which case it throws an exception. Throws also an exception when the promise gets
 fulfilled.
 You should use this method only for testing purposes and nothing more.
 
 @param seconds The waiting interval, -1. for infinity.
 @return The error of the promise.
 @see waitForResultWithin:
 */
- (nullable NSError *)waitForErrorWithin:(NSTimeInterval)seconds;

@end

NS_ASSUME_NONNULL_END
