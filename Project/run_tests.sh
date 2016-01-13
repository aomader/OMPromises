#!/bin/sh

xctool -workspace OMPromises.xcworkspace -scheme iOS-Tests -sdk iphonesimulator -configuration Debug test ONLY_ACTIVE_ARCH=NO
ios_tests=$?

xctool -workspace OMPromises.xcworkspace -scheme OSX-Tests -sdk macosx -configuration Debug test ONLY_ACTIVE_ARCH=NO
osx_tests=$?

# xctool doesnt support tvOS, thus we just built it for now
xctool -workspace OMPromises.xcworkspace -scheme tvOS-Tests -sdk appletvos -configuration Debug build ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
tvos_tests=$?

exit `expr $ios_tests + $osx_tests + $tvos_tests`

