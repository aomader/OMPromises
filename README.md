# OMPromises

A tested and fully documented promises library comparable to Promises/A with
certain additions and changes to better fit the Objective-C style.

## Examples

## Demonstration

Assume you want to get [gravatar] images for a list of e-mail addresses. Additionally
you prepared a fallback image for addresses that don't resolve to an image. Once all
images are fetched, you want to use them for further processing.

Here is how you would accomplish such task using OMPromises:

```objc
// create a promise that represents the outcome of the gravatar lookup
OMPromise *(^getGravatar)(NSString *email) = ^(NSString *email) {
    OMDeferred *deferred = [OMDeferred deferred];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:
        [NSString stringWithFormat:@"http://www.gravatar.com/avatar/%@?d=404", email]]];
    [NSURLConnection
        sendAsynchronousRequest:request
        queue:[NSOperationQueue mainQueue]
        completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
            if (error != nil || [(NSHTTPURLResponse *)res statusCode] != 200) {
                [deferred fail:nil];
            } else {
                [deferred fulfil:[UIImage imageWithData:data]];
            }
        }];
    
    return deferred.promise;
};

NSMutableArray *promises = [NSMutableArray array];
for (NSString *email in @[@"205e460b479e2e5b48aec07710c08d50",
                          @"9fcf5f5c3f289b330baff283b85f7705",
                          @"deadc0dedeadc0dedeadc0dedeadc0de"]) {
    OMPromise *imagePromise = [getGravatar(email)
        rescue:^id(NSError *error) {
            // in case the promise failed, we supply a dummy image to use instead
            return [UIImage imageNamed:@"dummy_image.png"];
        }];
    [promises addObject:imagePromise];
}

// creae a combined promise and bind to its callbacks
[[[OMPromise all:promises] fulfilled:^(NSArray *images) {
    NSLog(@"Done. %i images loaded.", images.count);
    // do something with your images ...
}] progressed:^(NSNumber *progress) {
    NSLog(@"%.2f%%...", progress.floatValue * 100.f);
}];
```

## License

OMPromises is licensed under the terms of the MIT license.
Please see the [LICENSE](LICENSE) file for full details.

[gravatar]: http://www.gravatar.com
