#import "OMDeferred.h"

#import "OMPromise+Protected.h"

static NSMutableArray *unfulfilledDeferreds;

@implementation OMDeferred

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        if (!unfulfilledDeferreds) {
            unfulfilledDeferreds = [NSMutableArray arrayWithCapacity:1];
        }
        [unfulfilledDeferreds addObject:self];
    }
    return self;
}

+ (OMDeferred *)deferred {
    return [[OMDeferred alloc] init];
}

#pragma mark - Public Methods

- (OMPromise *)promise {
    return self;
}

- (void)fulfil:(id)result {
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
    NSAssert(self.state == OMPromiseStateUnfulfilled, @"Can only progress while being Unfulfilled");
    
    self.progress = progress;
    
    for (void (^cb)(NSNumber *) in self.progressCbs) {
        cb(progress);
    }
}

@end
