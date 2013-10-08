# OMPromises

A tested and fully documented promises library comparable to Promises/A with
certain additions and changes to better fit the Objective-C style.

## Demonstration

Assume you want to get [gravatar] images for a list of e-mail addresses, in
case someone doesn't have a [gravatar], you want to fall back to a dummy image.
Once all images are loaded, you might show them to the user.

Here is how you would accomplish such task using OMPromises:

    OMPromise *(^get_gravatar)(NSString *email) = ^(NSString *email) {
        OMDeferred *deferred = [OMDeferred deferred];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:
            [NSString stringWithFormat:@"http://www.gravatar.com/avatar/%@?d=404", email]]];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:dispatch_get_main_queue()
                               completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
                                   if (error != nil) {
                                       [deferred fail:error];
                                   } else {
                                       [deferred fulfil:[UIImage imageWithData:data]];
                                   }
                               }];
        return deferred.promise;
    };

    NSArray *emails = @[
        @"205e460b479e2e5b48aec07710c08d50",
        @"deadc0dedeadc0dedeadc0dedeadc0de"
    ];

    NSMutableArray *promises = [NSMutableArray arrayWithCapacity:emails.count];

    for (NSString *email in emails) {
        OMPromise *imagePromise = [get_gravatar(email) rescue:^(NSError *error) {
            // in case the promise failed, we supply a dummy image to use instead
            return [UIImage imageNamed:@"dummy_image.png"];
        }];
        [promises addObject:imagePromise];
    }

    [[[OMPromise all:promises] fulfilled:^(NSArray *images) {
        // called once all images are loaded, now show them ...
    }] progressed:^(NSNumber *progress) {
        NSLog(@"%.2f%% done...", progress.floatValue * 100.f);
    }];

[gravatar]: http://www.gravatar.com
