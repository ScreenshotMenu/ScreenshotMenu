APP_NAME = ScreenshotMenu
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
DMG = $(APP_NAME).dmg

# Code signing / notarization
SIGN_IDENTITY = Developer ID Application: Global Tech Distribution s.r.o. (CBBC6T33XY)
TEAM_ID = CBBC6T33XY
NOTARY_PROFILE = notary-profile
ENTITLEMENTS = ScreenshotMenu.entitlements

# DMG window layout
DMG_BG = Resources/dmg-background.tiff
DMG_WINDOW = 620 420
DMG_ICON_SIZE = 128

.PHONY: build bundle run clean install sign notarize staple release dmg dmg-bg

build:
	swift build -c release

bundle: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Info.plist $(APP_BUNDLE)/Contents/
	cp Resources/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/

run: bundle
	open $(APP_BUNDLE)

clean:
	swift package clean
	rm -rf $(APP_BUNDLE) $(DMG) $(APP_NAME).zip

install: bundle
	cp -r $(APP_BUNDLE) /Applications/

# Sign the bundle with Developer ID + hardened runtime
sign: bundle
	codesign --force --deep --options runtime --timestamp \
		--entitlements $(ENTITLEMENTS) \
		--sign "$(SIGN_IDENTITY)" \
		$(APP_BUNDLE)
	codesign --verify --strict --verbose=2 $(APP_BUNDLE)

# Submit to Apple notary service and wait for the result
notarize: sign
	rm -f $(APP_NAME).zip
	ditto -c -k --keepParent $(APP_BUNDLE) $(APP_NAME).zip
	xcrun notarytool submit $(APP_NAME).zip \
		--keychain-profile "$(NOTARY_PROFILE)" --wait
	rm -f $(APP_NAME).zip

# Staple the notarization ticket onto the app
staple: notarize
	xcrun stapler staple $(APP_BUNDLE)
	xcrun stapler validate $(APP_BUNDLE)

# Regenerate the DMG background (1x + 2x -> hidpi tiff)
dmg-bg:
	swift scripts/generate-dmg-background.swift 1 Resources/dmg-bg.png
	swift scripts/generate-dmg-background.swift 2 Resources/dmg-bg@2x.png
	tiffutil -cathidpicheck Resources/dmg-bg.png Resources/dmg-bg@2x.png -out $(DMG_BG)

# Styled DMG (custom background, drag-to-Applications layout). Requires `brew install create-dmg`.
dmg: bundle
	rm -f $(DMG)
	rm -rf dmg_src && mkdir dmg_src
	cp -R $(APP_BUNDLE) dmg_src/
	create-dmg \
		--volname "$(APP_NAME)" \
		--volicon "Resources/AppIcon.icns" \
		--background "$(DMG_BG)" \
		--window-pos 200 120 \
		--window-size $(DMG_WINDOW) \
		--icon-size $(DMG_ICON_SIZE) \
		--icon "$(APP_BUNDLE)" 160 230 \
		--app-drop-link 460 230 \
		--hide-extension "$(APP_BUNDLE)" \
		--no-internet-enable \
		"$(DMG)" "dmg_src"
	rm -rf dmg_src

# Full distributable pipeline: build -> sign -> notarize -> staple app -> styled dmg -> notarize+staple dmg
# Note: packages the already-signed/stapled bundle directly (does NOT re-run `bundle`).
release: staple
	rm -f $(DMG)
	rm -rf dmg_src && mkdir dmg_src
	cp -R $(APP_BUNDLE) dmg_src/
	create-dmg \
		--volname "$(APP_NAME)" \
		--volicon "Resources/AppIcon.icns" \
		--background "$(DMG_BG)" \
		--window-pos 200 120 \
		--window-size $(DMG_WINDOW) \
		--icon-size $(DMG_ICON_SIZE) \
		--icon "$(APP_BUNDLE)" 160 230 \
		--app-drop-link 460 230 \
		--hide-extension "$(APP_BUNDLE)" \
		--no-internet-enable \
		"$(DMG)" "dmg_src"
	rm -rf dmg_src
	codesign --force --sign "$(SIGN_IDENTITY)" --timestamp $(DMG)
	xcrun notarytool submit $(DMG) --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple $(DMG)
	xcrun stapler validate $(DMG)
	spctl -a -vvv -t open --context context:primary-signature $(DMG)
	# Embed the app icon as the .dmg file's Finder icon (xattr only — does not affect signature/staple)
	cp Resources/AppIcon.icns /tmp/dmgicon.icns
	sips -i /tmp/dmgicon.icns >/dev/null
	DeRez -only icns /tmp/dmgicon.icns > /tmp/dmgicon.rsrc
	Rez -append /tmp/dmgicon.rsrc -o $(DMG)
	SetFile -a C $(DMG)
	rm -f /tmp/dmgicon.icns /tmp/dmgicon.rsrc
