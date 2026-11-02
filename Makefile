APP := build/Build/Products/Release/QuickCalc.app
XCODEBUILD := xcodebuild -project QuickCalc.xcodeproj -scheme QuickCalc -destination generic/platform=macOS -derivedDataPath build

.PHONY: build run install test icon archive clean

# Release build, signed to run locally unless Config/Local.xcconfig sets a team.
build:
	@$(XCODEBUILD) -configuration Release build -quiet
	@echo "Built $(APP) ($$(du -sh $(APP) | cut -f1))"

run: build
	@pkill -x QuickCalc || true
	@open $(APP)

install: build
	@pkill -x QuickCalc || true
	@rm -rf /Applications/QuickCalc.app
	@cp -R $(APP) /Applications/
	@open /Applications/QuickCalc.app
	@echo "Installed /Applications/QuickCalc.app"

test:
	@swift test --package-path QuickCalcCore

icon:
	@swift scripts/make-icon.swift QuickCalc/Resources/Assets.xcassets/AppIcon.appiconset

# App Store archive; needs DEVELOPMENT_TEAM in Config/Local.xcconfig. Upload from Xcode's Organizer.
archive:
	@$(XCODEBUILD) -configuration Release archive -archivePath build/QuickCalc.xcarchive
	@open build/QuickCalc.xcarchive

clean:
	@rm -rf build
