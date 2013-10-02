typedef enum OMPromiseState {
    OMPromiseStateUnfulfilled = 0,
    OMPromiseStateFailed = 1,
    OMPromiseStateFulfilled = 2
} OMPromiseState;

@interface OMPromise : NSObject

@property(assign, readonly) OMPromiseState state;

@property(readonly) id result;
@property(readonly) NSError *error;

// monadic bind
- (OMPromise *)then:(id (^)(id result))f;
- (OMPromise *)then:(id (^)(id result))f fail:(void (^)(NSError *error))g;
- (OMPromise *)then:(id (^)(id result))f fail:(void (^)(NSError *error))g progress:(void (^)(NSNumber *progress))h;

// monadic return
+ (OMPromise *)return:(id)result;

// Combinators

// chain promise generators, basically the same as calling multiple binds
+ (OMPromise *)chain:(NSArray *)fs initial:(id)data;

// race for the first fulfiled promise in promises, yields the winning result
+ (OMPromise *)any:(NSArray *)promises;

// requires all promises to be fullfilled, yields an array containing all results
+ (OMPromise *)all:(NSArray *)promises;

// combination of then and all, requires the first result to return an array
- (OMPromise *)map:(id (^)(id result))f;

@end
