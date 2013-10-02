#import "OMPromise.h"

/** Represents a bunch of work.
 
 The bunch of work can progress and either fail or be fulfilled. Once failed or
 fulfilled the deferred is done. Meaning it cannot progress, fail or be fulfilled
 again.
 */
@interface OMDeferred : OMPromise

///---------------------------------------------------------------------------------------
/// @name Initialization
///---------------------------------------------------------------------------------------

/** Returns a new instance of the deferred.
 
 Internally, a reference to this newly created deferred is stored until it is either
 fulfilled or failed. So ensure to finalize all deferred either way in order to prevent
 memory leaks.
 */
+ (OMDeferred *)deferred;

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
 
 Implicitly sets the progress to 1.
 
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
