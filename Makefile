PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: help setup analyze test clean run-web run-web-server run-macos run-ios run-android build-web build-macos build-apk build-aab build-ios

help:
	@echo "Available targets:"
	@echo "  make setup            - flutter pub get"
	@echo "  make analyze          - flutter analyze"
	@echo "  make test             - flutter test"
	@echo "  make clean            - flutter clean"
	@echo "  make run-web          - run in Chrome"
	@echo "  make run-web-server   - run in local web server"
	@echo "  make run-macos        - run macOS desktop app"
	@echo "  make run-ios          - run on iOS device/simulator"
	@echo "  make run-android      - run on Android device/emulator"
	@echo "  make build-web        - build web release"
	@echo "  make build-macos      - build macOS release"
	@echo "  make build-apk        - build Android APK"
	@echo "  make build-aab        - build Android App Bundle"
	@echo "  make build-ios        - build iOS without codesign"

setup:
	@bash "$(PROJECT_DIR)/tool/flutter_exec.sh" pub get

analyze:
	@bash "$(PROJECT_DIR)/tool/flutter_exec.sh" analyze

test:
	@bash "$(PROJECT_DIR)/tool/flutter_exec.sh" test

clean:
	@bash "$(PROJECT_DIR)/tool/flutter_exec.sh" clean

run-web:
	@bash "$(PROJECT_DIR)/tool/run_web.sh" chrome

run-web-server:
	@bash "$(PROJECT_DIR)/tool/run_web.sh" server

run-macos:
	@bash "$(PROJECT_DIR)/tool/run_macos.sh"

run-ios:
	@bash "$(PROJECT_DIR)/tool/run_ios.sh"

run-android:
	@bash "$(PROJECT_DIR)/tool/run_android.sh"

build-web:
	@bash "$(PROJECT_DIR)/tool/build_web.sh"

build-macos:
	@bash "$(PROJECT_DIR)/tool/build_macos.sh"

build-apk:
	@bash "$(PROJECT_DIR)/tool/build_apk.sh"

build-aab:
	@bash "$(PROJECT_DIR)/tool/build_aab.sh"

build-ios:
	@bash "$(PROJECT_DIR)/tool/build_ios.sh"
