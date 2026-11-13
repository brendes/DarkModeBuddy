# until we update the build targets.
TARGET_VERSION := 12.0
DERIVEDDIR := $$(HOME)/Library/Developer/Xcode/DerivedData/

# build uses ad-hoc signing with hardened runtime
build:
	xcodebuild -project DarkModeBuddy.xcodeproj -scheme DarkModeBuddy \
		-configuration Debug build \
		MACOSX_DEPLOYMENT_TARGET=$(TARGET_VERSION) \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_ALLOWED=YES \
		CODE_SIGNING_REQUIRED=YES \
		ENABLE_HARDENED_RUNTIME=YES

install: build
	cp -r $(DERIVEDDIR)/DarkModeBuddy-*/Build/Products/Debug/DarkModeBuddy.app \
		$$(HOME)/Applications/
