//
//  OMPromise+Combinators.h
//  OMPromises
//
//  Created by Oliver Mader on 02.10.13.
//  Copyright (c) 2013 reaktor42. All rights reserved.
//

#import "OMPromise.h"

@interface OMPromise (Combinators)

// chain promise generators, basically the same as calling multiple binds
+ (OMPromise *)chain:(NSArray *)fs initial:(id)data;

// race for the first fulfiled promise in promises, yields the winning result
+ (OMPromise *)any:(NSArray *)promises;

// requires all promises to be fullfilled, yields an array containing all results
+ (OMPromise *)all:(NSArray *)promises;

// combination of then and all, requires the first result to return an array
- (OMPromise *)map:(id (^)(id result))f;

@end
