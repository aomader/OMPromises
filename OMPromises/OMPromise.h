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

/** Possible states of an @p OMPromise.
 */
typedef enum OMPromiseState {
    OMPromiseStateUnfulfilled = 0,
    OMPromiseStateFailed = 1,
    OMPromiseStateFulfilled = 2
} OMPromiseState;


/** Proxies the outcome of a deferred.
 */
@interface OMPromise : NSObject

///---------------------------------------------------------------------------------------
/// @name Current State
///---------------------------------------------------------------------------------------

/** Current state.

 May only change from @p OMPromiseStateUnfulfilled to either @p OMPromiseStateFailed or
 @p OMPRomiseStateFulfilled.
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
 
 Describes the progress of the underyling workload as a floating point number in range
 [0, 1]. It only increases.
 */
@property(readonly) NSNumber *progress;

///---------------------------------------------------------------------------------------
/// @name Creation
///---------------------------------------------------------------------------------------

/** Create a fulfilled promise.
 
 Simply wraps the supplied value inside a fulfiled promise.
 
 @param result The value to fulfil the promise.
 @return A fulfiled promise.
 */
+ (OMPromise *)promiseWithResult:(id)result;

/** Create a failed promise.
 
 @param error Reason why the promise failed.
 @return A failed promise.
 */
+ (OMPromise *)promiseWithError:(NSError *)error;

///---------------------------------------------------------------------------------------
/// @name Binds
///---------------------------------------------------------------------------------------

/** Create a new promise, its outcome depends on the promise and maybe on the supplied block.

 The newly returned promise fails, if the current promise fails. If it instead gets fulfilled
 the thenHandler is called with the result as argument. The value returned from that block call
 is then used to either fulfil the newly returned promise or replace it, in case the value is
 a promise itself.

 @param thenHandler Block to be called once the promise gets fulfilled.
 @return A new promise.
 */
- (OMPromise *)then:(id (^)(id result))thenHandler;

/** Register a block to be called when the promise gets fulfilled.

 @param fulfilHandler Block to be called.
 @return The promise itself.
 */
- (OMPromise *)fulfilled:(void (^)(id result))fulfilHandler;

/** Register a block to be called when the promise fails.

 @param failHandler Block to be called.
 @return The promise itself.
 */
- (OMPromise *)failed:(void (^)(NSError *))failHandler;

/** Register a block to be called when the promise progresses.

 @param progressHandler Block to be called.
 @return The promise itself.
 */
- (OMPromise *)progressed:(void (^)(NSNumber *))progressHandler;

///---------------------------------------------------------------------------------------
/// @name Combinators
///---------------------------------------------------------------------------------------

// chain promise generators, basically the same as calling multiple binds
+ (OMPromise *)chain:(NSArray *)fs initial:(id)data;

// race for the first fulfiled promise in promises, yields the winning result
+ (OMPromise *)any:(NSArray *)promises;

// requires all promises to be fullfilled, yields an array containing all results
+ (OMPromise *)all:(NSArray *)promises;

// combination of then and all, requires the first result to return an array
- (OMPromise *)map:(id (^)(id result))f;

@end
