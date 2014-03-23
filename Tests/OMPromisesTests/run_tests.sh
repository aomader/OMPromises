#!/bin/sh

xctool -workspace OMPromisesTests.xcworkspace -scheme iOS-Tests -sdk iphonesimulator -configuration Release test ONLY_ACTIVE_ARCH=NO
ios_tests=$?

xctool -workspace OMPromisesTests.xcworkspace -scheme OS-X-Tests -sdk macosx -configuration Release test ONLY_ACTIVE_ARCH=NO
osx_tests=$?

exit `expr $ios_tests + $osx_tests`

