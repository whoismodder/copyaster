SDK = /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
TARGET = arm64-apple-macos14.0
APP = build/Copyaster.app
EXEC = build/Copyaster

SOURCES = \
	Copyaster/App/CopyasterApp.swift \
	Copyaster/App/AppDelegate.swift \
	Copyaster/App/AppState.swift \
	Copyaster/Models/ClipboardItem.swift \
	Copyaster/Services/ClipboardMonitor.swift \
	Copyaster/Services/HotkeyManager.swift \
	Copyaster/Services/StorageManager.swift \
	Copyaster/Views/PanelView.swift \
	Copyaster/Views/ClipRow.swift \
	Copyaster/Views/HoverPreviewView.swift \
	Copyaster/Views/InlineSelectorView.swift \
	Copyaster/Views/FloatingPanel.swift \
	Copyaster/Views/SettingsView.swift \
	Copyaster/Services/LaunchManager.swift

FRAMEWORKS = -framework AppKit -framework SwiftUI -framework Carbon

.PHONY: build run clean

icons:
	@swift scripts/generate_appicon.swift

build:
	@mkdir -p build
	swiftc -target $(TARGET) -sdk $(SDK) $(FRAMEWORKS) -parse-as-library -o $(EXEC) $(SOURCES)
	@rm -rf $(APP)
	@mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	@cp $(EXEC) $(APP)/Contents/MacOS/Copyaster
	@cp Copyaster/Resources/Info.plist $(APP)/Contents/
	@if [ -f build/AppIcon.icns ]; then cp build/AppIcon.icns $(APP)/Contents/Resources/AppIcon.icns; fi
	@echo "APPL????" > $(APP)/Contents/PkgInfo
	@echo "Build OK -> $(APP)"

run: build
	@open $(APP)

dmg: build
	@rm -f build/Copyaster.dmg
	create-dmg \
		--volname "Copyaster" \
		--window-pos 200 120 \
		--window-size 540 380 \
		--icon-size 120 \
		--icon "Copyaster.app" 140 170 \
		--hide-extension "Copyaster.app" \
		--app-drop-link 400 170 \
		--no-internet-enable \
		"build/Copyaster.dmg" \
		"build/Copyaster.app" || true
	@echo "DMG OK -> build/Copyaster.dmg"

clean:
	@rm -rf build
