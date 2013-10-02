//
//  OMDeferred+Helpers.h
//  OMPromises
//
//  Created by Oliver Mader on 02.10.13.
//  Copyright (c) 2013 reaktor42. All rights reserved.
//

#import "OMDeferred.h"

@interface OMDeferred (Helpers)

- (void (^)(NSError *))failBlock;
- (void (^)(NSNumber *))progressBlock;

@end
