#import "OMPromise.h"

#import "OMDeferred.h"

@interface OMPromise ()

@property(readonly) NSMutableArray *thenCbs;
@property(readonly) NSMutableArray *failCbs;
@property(readonly) NSMutableArray *progressCbs;

@end

@implementation OMPromise

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        _thenCbs = [NSMutableArray array];
        _failCbs = [NSMutableArray array];
        _progressCbs = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Public Methods

- (OMPromise *)then:(id (^)(id result))f {
    return [self then:f fail:nil progress:nil];
}

- (OMPromise *)then:(id (^)(id result))f fail:(void (^)(NSError *error))g {
    return [self then:f fail:g progress:nil];
}

- (OMPromise *)then:(id (^)(id result))f fail:(void (^)(NSError *error))g progress:(void (^)(NSNumber *progress))h {
    OMDeferred *deferred = [OMDeferred deferred];

#warning call immediately if self is not unfulfilled, requires reference to error and result
    [self.thenCbs addObject:[(^(id result) {
        id x = f(result);
        if ([x isKindOfClass:OMPromise.class]) {
            [(OMPromise *)x then:^id(id result) {
                [deferred fulfil:result];
                return nil;
            } fail:^(NSError *error) {
                [deferred fail:error];
            } progress:^(NSNumber *progress) {
                [deferred progress:progress];
            }];
        } else {
            [deferred fulfil:x];
        }
    }) copy]];
    [self.failCbs addObject:^(NSError *error) {
        if (g) {
            g(error);
        }
        [deferred fail:error];
    }];
    [self.progressCbs addObject:^(NSNumber *progress) {
        if (h) {
            h(progress);
        }
        [deferred progress:@(progress.floatValue)];
    }];

    return deferred.promise;
}

+ (OMPromise *)return:(id)result {
    OMDeferred *deferred = [OMDeferred deferred];
    [deferred fulfil:result];
    return deferred.promise;
}

#pragma mark - Property Interaction

- (void)setError:(NSError *)error {
    _error = error;
}

- (void)setResult:(id)result {
    _result = result;
}

- (void)setState:(OMPromiseState)state {
    NSAssert(_state == OMPromiseStateUnfulfilled && state != OMPromiseStateUnfulfilled,
             @"A state transition requires to go from Unfulfilled to either Fulfilled or Failed");
    _state = state;
}

#pragma mark - Combinators

+ (OMPromise *)chain:(NSArray *)fs initial:(id)result {
    OMDeferred *deferred = [OMDeferred deferred];

    if (fs.count == 0) {
        [deferred fulfil:result];
    } else {
        id (^f)(id) = [fs objectAtIndex:0];
        id nextResult = f(result);
        [([nextResult isKindOfClass:OMPromise.class] ? nextResult : [OMPromise return:result]) then:^id(id nextResult) {
            [[OMPromise chain:[fs subarrayWithRange:NSMakeRange(1, fs.count - 1)] initial:nextResult] then:^id(id x) {
                [deferred fulfil:x];
                return nil;
            } fail:[deferred failBlock] progress:^(NSNumber *progress) {
                [deferred progress:@(progress.floatValue / fs.count * (fs.count - 1) + 1.f/fs.count)];
            }];
            return nil;
        } fail:[deferred failBlock] progress:^(NSNumber *progress) {
            [deferred progress:@(progress.floatValue / fs.count)];
        }];
    }

    return deferred.promise;
}

+ (OMPromise *)any:(NSArray *)promises {
    return nil;
}

+ (OMPromise *)all:(NSArray *)promises {
    OMDeferred *deferred = [OMDeferred deferred];
    
    __block NSMutableArray *results = [NSMutableArray arrayWithCapacity:promises.count];
    __block NSUInteger done = 0;
    
    for (OMPromise *promise in promises) {
        [results addObject:[NSNull null]];
        NSUInteger idx = [promises indexOfObject:promise];
        [promise then:^id(id result) {
            if (deferred.state == OMPromiseStateUnfulfilled) {
                results[idx] = result ? result : [NSNull null];
                if (++done == results.count) {
                    [deferred fulfil:results];
                } else {
                    [deferred progress:@((float)done/results.count)];
                }
            }
            return nil;
        } fail:^(NSError *error) {
            [deferred fail:error];
        } progress:^(NSNumber *progress) {
            
        }];
    }
    
    return deferred.promise;
}

- (OMPromise *)map:(id (^)(id))f {
    OMDeferred *deferred = [OMDeferred deferred];

    [self then:^(NSArray *result) {
        NSMutableArray *r = [NSMutableArray arrayWithCapacity:result.count];
        for (id x in result) {
            [r addObject:f(x)];
        }
        return [OMPromise all:r];
    } fail:[deferred failBlock]];

    return deferred.promise;
}

@end
