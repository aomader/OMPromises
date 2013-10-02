
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
 [0, 1]. It may only increase.
 */
@property(readonly) NSNumber *progress;

///---------------------------------------------------------------------------------------
/// @name Bind & Return
///---------------------------------------------------------------------------------------

/** Bind blocks to the outcome of the promise.
 
 thenCb can either return a simple value, in which case the returned promise is
 immediately fulfilled, or another promise, which is bound to the returned promise.
 The returned promise fails in case the bound promise or the promise itself fails.
 
 @param thenCb Called once in case the promise has been fulfilled. Can either return a
               simple value or another promise which is bound to the returned promise.
 @param failCb Called once in case the promise failed.
 @param progressCb Called, maybe multiple times, in case of an increase in progress.
 @return A successive promise which represents the outcome of the bound blocks.
 */
- (OMPromise *)then:(id (^)(id result))thenCb
               fail:(void (^)(NSError *error))failCb
           progress:(void (^)(NSNumber *progress))progressCb;

/** Creates a fulfiled promise.
 
 Simply wraps the supplied value inside a fulfiled promise.
 
 @param result The value to fulfil the promise.
 @return A fulfiled promise.
 */
+ (OMPromise *)return:(id)result;

///---------------------------------------------------------------------------------------
/// @name Convenience
///---------------------------------------------------------------------------------------

- (OMPromise *)then:(id (^)(id result))thenCb;

- (OMPromise *)then:(id (^)(id result))thenCb
               fail:(void (^)(NSError *error))failCb;

@end
