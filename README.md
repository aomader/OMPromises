# OMPromises

A tested and fully documented promises library comparable to Promises/A with
certain additions and changes to better fit the Objective-C style.

## Demonstration

Assume you want to get [gravatar] images for a list of e-mail addresses, in
case someone doesn't have a [gravatar], you want to fall back to a dummy image.
Once all images are loaded, you might show them to the user.

Here is how you would accomplish such task using OMPromises:

    OMPromise *(^get_gravatar)(NSString *email) = ^(NSString *email) {
        // network related code that loads the image and fulfils the promise..
    };

    NSArray *emails = @[
        @"b52@reaktor42.de",
        @"doesnt@exist.xyz"
    ];

    NSMutableArray *promises = [NSMutableArray arrayWithCapacity:emails.count];

    for (NSString *email in emails) {
        OMPromise *imagePromise = [get_gravatar(email) rescue:^(NSError *error) {
            // in case the promise failed, we supply a dummy image to use instead
            return [UIImage imageNamed:@"dummy_image.png"];
        }];

        [promises addObject:imagePromise];
    }

    [[OMPromise all:promises] fulfilled:^(NSArray *images) {
        // called once all images are loaded, now show them ...
    }];

[gravatar]: http://www.gravatar.com
