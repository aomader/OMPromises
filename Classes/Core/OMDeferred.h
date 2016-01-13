//
// OMDeferred.h
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

#import "OMPromise.h"

NS_ASSUME_NONNULL_BEGIN

/** An OMDeferred is an abstract construct to control the outcome of an aligned
 OMPromise, which is used to proxy the outcome of an asynchronous operation.

 In order to model a long-running asynchronous operation, you would create an instance
 of OMDeferred using deferred. You use this instance to control the state of the
 underlying OMPromise, accessed by promise.

 You might call progress: multiple times to keep the user informed, followed by a final
 call to either fulfil:, in case everything went as expected, or fail: otherwise.
 
 If it is possible and desirable to stop or abort the abstracted operation, you should
 register a cancel-handler using cancelled:. Doing so makes the aligned promise
 implicitly cancellable, thus the handler is called once someone calls cancel on the
 promise.

 It's important to understand that the OMDeferred/OMPromise is sealed, once its stated
 has been changed by calling fulfil: or fail:. After that calls to progress:, fulfil:
 or fail: result in an exception.

 There are safe variants of the state changing methods namely tryFulfil:, tryFail:
 and tryProgress:. They will never throw an exception but describe the outcome of
 the operation by their return values. Although that sounds convenient you should not
 use them unless it's absolutely necessary. Most of the time you find better ways and
 structure your code and execution paths better if you use the three main functions.
 */
@interface OMDeferred<ResultType> : NSObject

///---------------------------------------------------------------------------------------
/// @name Creation
///---------------------------------------------------------------------------------------

/** Create and return a new deferred.
 */
+ (OMDeferred *)deferred;

///---------------------------------------------------------------------------------------
/// @name Accessing the underlying promise
///---------------------------------------------------------------------------------------

/** Returns the associated promise.
 
 Proxies the outcome of the underlying bunch of work.
 */
@property(readonly, nonatomic) OMPromise *promise;

///---------------------------------------------------------------------------------------
/// @name Change state
///---------------------------------------------------------------------------------------

/** Finalizes the deferred by settings its state to OMPromiseStateFulfilled.
 
 Implicitly sets the progress to 1.0f.
 
 @param result Result to set and propagate.
 @see fail:
 */
- (void)fulfil:(nullable ResultType)result;

/** Finalizes the deferred by settings its state to OMPromiseStateFailed.
 
 @param error Error to set and propagate.
 @see fulfil:
 */
- (void)fail:(nullable NSError *)error;

/** Update the progress.
 
 The new progress has to be higher than the previous one. Equal values are skipped,
 but lower values raise an exception. The progress must be less than or equal to 1.0f.
 
 @param progress Higher progress to set and propagate.
 */
- (void)progress:(float)progress;

///---------------------------------------------------------------------------------------
/// @name Safely trying to change state
///---------------------------------------------------------------------------------------

/** Tries to finalize the deferred by settings its state to OMPromiseStateFulfilled.

 Tries to set the state similar to fulfil: but doesn't throw an exception if the
 promise is not unfulfilled anymore.

 @param result Result to set and propagate.
 @return Whether the operation was successful or not.
 @see fulfil:
 */
- (BOOL)tryFulfil:(nullable ResultType)result;

/** Tries to finalize the deferred by settings its state to OMPromiseStateFailed.

 Tries to set the state similar to fail: but doesn't throw an exception if the
 promise is not unfulfilled anymore.

 @param error Error to set and propagate.
 @return Whether the operation was successful or not.
 @see fail:
 */
- (BOOL)tryFail:(nullable NSError *)error;

/** Tries to update the progress.

 Tries to update the progress similar to progress:, but doesn't throw an exception
 if the value is less than the current value or the promise is not unfulfilled anymore.

 @param progress Progress to set and propagate.
 @return Whether the operation was successful or not.
 @see progress:
 */
- (BOOL)tryProgress:(float)progress;

///---------------------------------------------------------------------------------------
/// @name Cancellation
///---------------------------------------------------------------------------------------

/** Add a handler to be called on cancel.
 
 If at least one handler is registered, it is assumed that the corresponding promise
 supports cancellation. Once the promise is cancelled, it changes into a failed state
 with error code OMPromisesCancelledError and the corresponding cancel-handlers and
 fail-handlers are called.
 
 @param cancelHandler The block to be called, once the promise is cancelled.
 */
- (void)cancelled:(void (^)(OMDeferred *deferred))cancelHandler;

@end

NS_ASSUME_NONNULL_END
