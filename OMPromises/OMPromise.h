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


/** Possible states of an OMPromise.
 */
typedef NS_ENUM(NSInteger, OMPromiseState) {
    OMPromiseStateUnfulfilled = 0,
    OMPromiseStateFailed = 1,
    OMPromiseStateFulfilled = 2
};


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
 
 To build more complex structures you might use one combinator of chain:initial:,
 all: or any:.
 */
@interface OMPromise : NSObject

///---------------------------------------------------------------------------------------
/// @name Current state
///---------------------------------------------------------------------------------------

/** Current state.

 May only change from `OMPromiseStateUnfulfilled` to either `OMPromiseStateFailed` or
 `OMPRomiseStateFulfilled`.
 */
@property(assign, readonly) OMPromiseState state;

/** Maybe the promised result.
 
 Contains the result in case the promise has been fulfilled.
 */
@property(readonly) id result;

/** Maybe an error.
 
 Contains the reason in case the promise failed.
 */
@property(readonly) NSError *error;

/** Progress of the underlying workload.
 
 Describes the progress of the underlying workload as a floating point number in range
 [0, 1]. It only increases.
 */
@property(assign, readonly) float progress;

/** Whether the underlying operation supports cancellation or not.
 
 In case cancellable is `YES`, it's safe to call cancel.
 */
@property(assign, readonly) BOOL cancellable;

///---------------------------------------------------------------------------------------
/// @name Creation
///---------------------------------------------------------------------------------------

/** Create a fulfilled promise.
 
 Simply wraps the supplied value inside a fulfilled promise.
 
 @param result The value to fulfil the promise.
 @return A fulfilled promise.
 */
+ (OMPromise *)promiseWithResult:(id)result;

/** Create a promise which gets fulfilled after a certain delay.

 After a certain amount of time the promise gets fulfilled using the supplied value.
 
 @param result The value to fulfil the promise.
 @param delay Time span to wait before fulfilling the promise.
 @return A promise that will get fulfilled.
 @see promiseWithResult:
 */
+ (OMPromise *)promiseWithResult:(id)result after:(NSTimeInterval)delay;

/** Create a failed promise.
 
 @param error Reason why the promise failed.
 @return A failed promise.
 */
+ (OMPromise *)promiseWithError:(NSError *)error;

/** Create a promise which fails after a certain delay.

 After a certain amount of time the promise fails using the supplied error.
 
 @param error Reason why the promise failed.
 @param delay Time span to wait before the promise fails.
 @return A promise that will fail.
 @see promiseWithError:
 */
+ (OMPromise *)promiseWithError:(NSError *)error after:(NSTimeInterval)delay;

///---------------------------------------------------------------------------------------
/// @name Building promise chains
///---------------------------------------------------------------------------------------

/** Create a new promise by binding the fulfilled result to another promise.

 The supplied block gets called in case the promise gets fulfilled. The block can return
 a simple value or another block, in both cases the promise returned by this method
 is bound to the result of the block.

 If the promise fails, the chain is short-circuited and the resulting promise fails too.

 @param thenHandler Block to be called once the promise gets fulfilled.
 @return A new promise.
 @see rescue:
 */
- (OMPromise *)then:(id (^)(id result))thenHandler;

/** Similar to then:, but executes the supplied block asynchrounsly on a specific queue.
 
 @param thenHandler Block to be called once the promise gets fulfilled.
 @param queue Context in which the block is executed.
 @return A new promise.
 @see then:
 */
- (OMPromise *)then:(id (^)(id result))thenHandler on:(dispatch_queue_t)queue;

/** Create a new promise by binding the error reason to another promise.

 Similar to then:, but the supplied block is called in case the promise fails, from
 which point on it behaves like then:. If the promise gets fulfilled the step is skipped.
 The returned promise proxies the progress of the original one. In case the original
 promise fails, the rescueHandler continues from that point on.

 @param rescueHandler Block to be called once the promise failed.
 @return A new promise.
 @see then:
 */
- (OMPromise *)rescue:(id (^)(NSError *error))rescueHandler;

/** Similar to rescue:, but executes the supplied block asynchrounsly on a specific queue.
 
 @param rescueHandler Block to be called once the promise failed.
 @param queue Context in which the block is executed.
 @return A new promise.
 @see rescue:
 */
- (OMPromise *)rescue:(id (^)(NSError *error))rescueHandler on:(dispatch_queue_t)queue;

///---------------------------------------------------------------------------------------
/// @name Registering callbacks
///---------------------------------------------------------------------------------------

/** Register a block to be called when the promise gets fulfilled.

 @param fulfilHandler Block to be called.
 @return The promise itself.
 */
- (OMPromise *)fulfilled:(void (^)(id result))fulfilHandler;

/** Similar to fulfilled:, but executes the supplied block asynchrounsly on a specific
 queue.

 @param fulfilHandler Block to be called.
 @param queue Context in which the block is executed.
 @return The promise itself.
 @see fulfilled:
 */
- (OMPromise *)fulfilled:(void (^)(id result))fulfilHandler on:(dispatch_queue_t)queue;

/** Register a block to be called when the promise fails.

 @param failHandler Block to be called.
 @return The promise itself.
 */
- (OMPromise *)failed:(void (^)(NSError *error))failHandler;

/** Similar to failed:, but executes the supplied block asynchrounsly on a specific queue.
 
 @param failHandler Block to be called.
 @param queue Context in which the block is executed.
 @return The promise itself.
 @see failed:
 */
- (OMPromise *)failed:(void (^)(NSError *error))failHandler on:(dispatch_queue_t)queue;

/** Register a block to be called when the promise progresses.

 @param progressHandler Block to be called.
 @return The promise itself.
 */
- (OMPromise *)progressed:(void (^)(float progress))progressHandler;

/** Similar to progressed:, but executes the supplied block asynchrounsly on a specific
 queue.
 
 @param progressHandler Block to be called.
 @param queue Context in which the block is executed.
 @return The promise itself.
 @see progressed:
 */
- (OMPromise *)progressed:(void (^)(float progress))progressHandler on:(dispatch_queue_t)queue;

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

/** Create a promise chain as if you would do multiple then binds.

 It also respects the progress of each chain step by assuming an equal distribution
 of work over all items, such that it also updates the progress with respect to
 each individual step.

 @param thenHandlers Sequence of then: handler blocks.
 @param initial Initial result supplied to the first then: handler block.
 @return A new promise describing the whole chain.
 */
+ (OMPromise *)chain:(NSArray *)thenHandlers initial:(id)result;

/** Race for the first fulfilled promise in parallel.

 The new returned promise gets fulfilled if any of the supplied promises does.
 If no promise gets fulfilled, the returned promise fails.

 The progress aligns to the mostly progressed promise.

 @param promises A sequence of promises.
 @return A new promise.
 */
+ (OMPromise *)any:(NSArray *)promises;

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
+ (OMPromise *)all:(NSArray *)promises;

@end

