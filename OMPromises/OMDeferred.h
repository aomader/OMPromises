#import "OMPromise.h"

@interface OMDeferred : OMPromise

+ (OMDeferred *)deferred;

- (OMPromise *)promise;

- (void)fulfil:(id)result;

- (void)fail:(NSError *)error;

- (void)progress:(NSNumber *)progress;

@end
