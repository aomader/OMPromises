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

/** Represents a bunch of work.
 
 The bunch of work can progress and either fail or be fulfilled. Once failed or
 fulfilled the deferred is done. Meaning it cannot progress, fail or be fulfilled
 again.
 */
@interface OMDeferred : OMPromise

///---------------------------------------------------------------------------------------
/// @name Creation
///---------------------------------------------------------------------------------------

/** Returns a new instance of the deferred.
 */
+ (OMDeferred *)deferred;

///---------------------------------------------------------------------------------------
/// @name Accessing the underlying promise
///---------------------------------------------------------------------------------------

/** Returns the associated promise.
 
 Proxies the outcome of the underlying bunch of work.
 */
- (OMPromise *)promise;

///---------------------------------------------------------------------------------------
/// @name Change state
///---------------------------------------------------------------------------------------

/** Finalizes the deferred by settings its state to @p OMPromiseStateFulfilled.
 
 Implicitly sets the progress to 1.
 
 @param result Result to set and propagate.
 @see fail:
 */
- (void)fulfil:(id)result;

/** Finalizes the deferred by settings its state to @p OMPromiseStateFailed.
 
 @param error Error to set and propagate.
 @see fulfil:
 */
- (void)fail:(NSError *)error;

/** Update the progress.
 
 The new progress has to be higher than the previous one.
 
 @param progress Higher progress to set and propagate.
 */
- (void)progress:(NSNumber *)progress;

@end

