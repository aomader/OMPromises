#import "OMDeferred.h"

#import "OMPromise+Protected.h"

static NSMutableArray *unfulfilledDeferreds;

@implementation OMDeferred

#pragma mark - Init

+ (OMDeferred *)deferred {
    OMDeferred *deferred = [[OMDeferred alloc] init];
    if (!unfulfilledDeferreds) {
        unfulfilledDeferreds = [NSMutableArray arrayWithCapacity:1];
    }
    [unfulfilledDeferreds addObject:deferred];
    return deferred;
}

#pragma mark - Public Methods

- (OMPromise *)promise {
    return self;
}

- (void)fulfil:(id)result {
    NSAssert(self.state == OMPromiseStateUnfulfilled, @"");
    [self progress:@1.f];
    self.state = OMPromiseStateFulfilled;
    self.result = result;
    for (void (^cb)(id) in self.thenCbs) {
        cb(result);
    }
    [unfulfilledDeferreds removeObject:self];
}

- (void)fail:(NSError *)error {
    self.state = OMPromiseStateFailed;
    self.error = error;
    for (void (^cb)(NSError *) in self.failCbs) {
        cb(error);
    }
    [unfulfilledDeferreds removeObject:self];
}

- (void)progress:(NSNumber *)progress {
    NSAssert(self.state == OMPromiseStateUnfulfilled, @"");
    for (void (^cb)(NSNumber *) in self.progressCbs) {
        cb(progress);
    }
}

- (void (^)(NSError *error))failBlock {
    return [(^(NSError *error) {
        [self fail:error];
    }) copy];
}

@end
