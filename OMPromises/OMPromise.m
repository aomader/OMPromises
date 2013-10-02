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

    void (^then)(id) = ^(id result) {
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
    };
    
    void (^fail)(NSError *) = ^(NSError *error) {
        if (g) {
            g(error);
        }
        [deferred fail:error];
    };
    
    if (self.state == OMPromiseStateFulfilled) {
        then(self.result);
    } else if (self.state == OMPromiseStateFailed) {
        fail(self.error);
    } else {
        [self.thenCbs addObject:then];
        [self.failCbs addObject:fail];
        [self.progressCbs addObject:^(NSNumber *progress) {
            if (h) {
                h(progress);
            }
            [deferred progress:@(progress.floatValue)];
        }];
    }
    
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

- (void)setProgress:(NSNumber *)progress {
    _progress = progress;
}

- (void)setState:(OMPromiseState)state {
    NSAssert(_state == OMPromiseStateUnfulfilled && state != OMPromiseStateUnfulfilled,
             @"A state transition requires to go from Unfulfilled to either Fulfilled or Failed");
    _state = state;
}

@end

