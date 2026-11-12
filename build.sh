#!/bin/sh

# output goes to
# ~/Library/Developer/Xcode/DerivedData/DarkModeBuddy-*/Build/Products/Debug/DarkModeBuddy.app

# until we update the build targets
xcodebuild -project DarkModeBuddy.xcodeproj \
	-scheme DarkModeBuddy -configuration Debug build \
	MACOSX_DEPLOYMENT_TARGET=12.0 \
	CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
