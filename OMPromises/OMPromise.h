typedef enum OMPromiseState {
    OMPromiseStateUnfulfilled = 0,
    OMPromiseStateFailed = 1,
    OMPromiseStateFulfilled = 2
} OMPromiseState;


@interface OMPromise : NSObject

@property(assign, readonly) OMPromiseState state;

@property(readonly) id result;
@property(readonly) NSError *error;
@property(readonly) NSNumber *progress;

// monadic bind
- (OMPromise *)then:(id (^)(id result))f;
- (OMPromise *)then:(id (^)(id result))f fail:(void (^)(NSError *error))g;
- (OMPromise *)then:(id (^)(id result))f fail:(void (^)(NSError *error))g progress:(void (^)(NSNumber *progress))h;

// monadic return
+ (OMPromise *)return:(id)result;

@end
