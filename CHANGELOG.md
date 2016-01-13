# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

_Possible log types_:

* `[added]` for new features.
* `[changed]` for changes in existing functionality.
* `[deprecated]` for once-stable features removed in upcoming releases.
* `[removed]` for deprecated features removed in this release.
* `[fixed]` for any bug fixes.
* `[security]` to invite users to upgrade in case of vulnerabilities.

## [Unreleased]

* [added] Support tvOS
* [added] Add new `OMLazyPromise` type
* [changed] Generify `OMPromise` and `OMDeferred`
* [changed] Use composition over inheritance to model `OMDeferred`
* [deprecated] Use the `alloc/init` or `new` pattern in favor of
  `[OMDeferred deferred]`
* ...

## [v0.4.2] - 2015-11-23

* [fixed] Possible crashed by overflowed `progress`

## [v0.4.1] - 2015-09-18

* [fixed] Possible crash caused by trying to store missing error in
  an `NSDictionary` (#27)

## [v0.4.0] - 2015-07-24

* [fixed] Possible crash caused by missing response object (#26)
* [fixed] Anticipating rounding errors in progress checks (#16)
* [fixed] Potential crashes caused by improper resource management (#25, #19)
* [added] Add safe methods to perform state changes and adjustments,
  i.e., `tryFulfil:`, `tryFail:` and `tryProgress:`.
* [added] Add methods `waitForResultWithin:` and `waitForErrorWithin:` to
  simplify testing asynchronous code.
* [added] Add new `collect:` combinator: it collects all outcomes of the
  supplied promises, i.e., errors and values. Thus it never fails.
* [added] Add new `relay:` combinator: Relays all promise events to a
  specified deferred.
* [added] Add new `always:` and `always:on:` callback handlers.

## [v0.3.0] - 2014-04-04

* [added] New `defaultQueue` property on `OMPromise` inheriting from a
  class wide `globalDefaultQueue` changeable through `setGlobalDefaultQueue:`
* [added] `on:` method to change the `defaultQueue` in a chainable fashion
* [added] New subspec `OMPromises/HTTP` provides means to create HTTP requests
  through an OMPromise-based API, still considered **beta** though:
  - `OMHTTPRequest` provides static methods to create HTTP requests
  - `OMHTTPResponse` describes the possible outcome of such requests
  - `OMPromise+HTTP` provides HTTP specific transformers, e.g. JSON parsing
* [fixed] Provide `NSLocalizedDescription` values for all returned NSError
  instances and add meaningful `debugDescription` implementations.
* [fixed] General code quality improvements and restructuring

## [v0.2.1] - 2014-03-29

* [fixed] Possible crash caused by improper chaining (#11)

## [v0.2.0] - 2014-02-08

* [fixed] Make promises finally thread-safe
* [changed] `chain:initial:` combinator supports all chaining/callback
  blocks now
* [changed] Promises created using `then:` or `rescue:` now incorporate
  the number of parent promises to provide an equally distributed progress
* [added] Create promises based on a task-block using either
  `promiseWithTask:` or `promiseWithTask:on:`
* [added] Queue-aware `then:` chaining using `then:on:`
* [added] Queue-aware `rescue:` chaining using `rescue:on:`
* [added] Queue-aware `fulfilled:` callbacks using `fulfilled:on:`
* [added] Queue-aware `failed:` callbacks using `failed:on:`
* [added] Queue-aware `progressed:` callbacks using `progressed:on:`
* [added] Optional support for cancellation using `cancel` and `cancelled:`

## [v0.1.2] - 2014-01-08

* [fixed] Possible memory leak due to un-released callback blocks
* [added] Add `join` transformer

## [v0.1.1] - 2013-10-23

* [added] Polish Podfile and add _Tests_ subspec
* [added] Add support for Mac OS X

## [v0.1.0] - 2013-10-14

* Initial release


[Unreleased]: https://github.com/b52/OMPromises/compare/0.4.2...HEAD
[v0.4.2]: https://github.com/b52/OMPromises/compare/0.4.1...0.4.2
[v0.4.1]: https://github.com/b52/OMPromises/compare/0.4.0...0.4.1
[v0.4.0]: https://github.com/b52/OMPromises/compare/0.3.0...0.4.0
[v0.3.0]: https://github.com/b52/OMPromises/compare/0.2.1...0.3.0
[v0.2.1]: https://github.com/b52/OMPromises/compare/0.2.0...0.2.1
[v0.2.0]: https://github.com/b52/OMPromises/compare/0.1.2...0.2.0
[v0.1.2]: https://github.com/b52/OMPromises/compare/0.1.1...0.1.2
[v0.1.1]: https://github.com/b52/OMPromises/compare/0.1...0.1.1
[v0.1.0]: https://github.com/b52/OMPromises/tree/0.1

