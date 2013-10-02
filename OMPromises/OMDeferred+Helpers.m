//
//  OMDeferred+Helpers.m
//  OMPromises
//
//  Created by Oliver Mader on 02.10.13.
//  Copyright (c) 2013 reaktor42. All rights reserved.
//

#import "OMDeferred+Helpers.h"

@implementation OMDeferred (Helpers)

- (void (^)(NSError *))failBlock {
    //@weakify(self);
    return ^(NSError *error) {
        //@strongify(self);
        [self fail:error];
    };
}

- (void (^)(NSNumber *))progressBlock {
    //@weakify(self);
    return ^(NSNumber *progress) {
        //@strongify(self);
        [self progress:progress];
    };
}

@end
