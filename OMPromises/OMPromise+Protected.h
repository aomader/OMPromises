#import "OMPromise.h"

@interface OMPromise (Protected)

@property(readonly) NSMutableArray *thenCbs;
@property(readonly) NSMutableArray *failCbs;
@property(readonly) NSMutableArray *progressCbs;

- (void)setError:(NSError *)error;
- (void)setResult:(id)result;
- (void)setProgress:(NSNumber *)progress;
- (void)setState:(OMPromiseState)state;

@end
