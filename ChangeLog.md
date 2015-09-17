# ChangeLog

## 0.4.1 (09/18/2015)

* Fix: Possible crash caused by trying to store missing error in
  an `NSDictionary` (#27)

## 0.4.0 (07/24/2015)

* Fix: Possible crash caused by missing response object (#26)
* Fix: Anticipating rounding errors in progress checks (#16)
* Fix: Potential crashes caused by improper resource management (#25, #19)
* Feature: Add safe methods to perform state changes and adjustments,
  i.e., `tryFulfil:`, `tryFail:` and `tryProgress:`.
* Feature: Add methods `waitForResultWithin:` and `waitForErrorWithin:` to
  simplify testing asynchronous code.
* Feature: Add new `collect:` combinator: it collects all outcomes of the
  supplied promises, i.e., errors and values. Thus it never fails.
* Feature: Add new `relay:` combinator: Relays all promise events to a
  specified deferred.
* Feature: Add new `always:` and `always:on:` callback handlers.

## 0.3.0 (04/04/2014)

* Feature: New `defaultQueue` property on `OMPromise` inheriting from a
  class wide `globalDefaultQueue` changeable through `setGlobalDefaultQueue:`
* Feature: `on:` method to change the `defaultQueue` in a chainable fashion
* Feature: New subspec `OMPromises/HTTP` provides means to create HTTP requests
  through an OMPromise-based API, still considered **beta** though:
  - `OMHTTPRequest` provides static methods to create HTTP requests
  - `OMHTTPResponse` describes the possible outcome of such requests
  - `OMPromise+HTTP` provides HTTP specific transformers, e.g. JSON parsing
* Improvement: Provide `NSLocalizedDescription` values for all returned NSError
  instances and add meaningful `debugDescription` implementations.
* Improvement: General code quality improvements and restructuring

## 0.2.1 (03/29/2014)

* Fix: Possible crash caused by improper chaining (#11)

## 0.2.0 (02/08/2014)

* Fix: Make promises finally thread-safe
* Improvement: `chain:initial:` combinator supports all chaining/callback
  blocks now
* Improvement: Promises created using `then:` or `rescue:` now incorporate
  the number of parent promises to provide an equally distributed progress
* Feature: Create promises based on a task-block using either
  `promiseWithTask:` or `promiseWithTask:on:`
* Feature: Queue-aware `then:` chaining using `then:on:`
* Feature: Queue-aware `rescue:` chaining using `rescue:on:`
* Feature: Queue-aware `fulfilled:` callbacks using `fulfilled:on:`
* Feature: Queue-aware `failed:` callbacks using `failed:on:`
* Feature: Queue-aware `progressed:` callbacks using `progressed:on:`
* Feature: Optional support for cancellation using `cancel` and `cancelled:`

## 0.1.2 (01/08/2014)

* Fix: Possible memory leak due to un-released callback blocks
* Improvement: Add `join` transformer

## 0.1.1 (10/23/2013)

* Improvement: Polish Podfile and add _Tests_ subspec
* Improvement: Add support for Mac OS X

## 0.1.0 (10/14/2013)

* Initial release

