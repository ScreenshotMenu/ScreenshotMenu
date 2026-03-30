APP_NAME = ScreenshotMenu
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app

.PHONY: build bundle run clean

build:
	swift build -c release

bundle: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Info.plist $(APP_BUNDLE)/Contents/

run: bundle
	open $(APP_BUNDLE)

clean:
	swift package clean
	rm -rf $(APP_BUNDLE)

install: bundle
	cp -r $(APP_BUNDLE) /Applications/
