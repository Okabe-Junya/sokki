.PHONY: app run test lint fmt clean

app:
	sh scripts/build-app.sh

run: app
	open build/Koe.app

test:
	swift test

lint:
	swift format lint --strict --recursive Sources Tests Package.swift

fmt:
	swift format --in-place --recursive Sources Tests Package.swift

clean:
	rm -rf .build build
