#!/bin/sh

xctool -workspace OMPromisesTests.xcworkspace -scheme iOS-Tests -sdk iphonesimulator -configuration Debug test ONLY_ACTIVE_ARCH=NO
ios_tests=$?

xctool -workspace OMPromisesTests.xcworkspace -scheme OS-X-Tests -sdk macosx -configuration Debug test ONLY_ACTIVE_ARCH=NO
osx_tests=$?

# xctool doesnt support tvOS, thus we just built it for now
xctool -workspace OMPromisesTests.xcworkspace -scheme tvOS-Tests -sdk appletvos -configuration Debug build ONLY_ACTIVE_ARCH=NO
tvos_tests=$?

exit `expr $ios_tests + $osx_tests + $tvos_tests`

