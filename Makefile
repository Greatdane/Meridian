.PHONY: build test app clean run

build:
	swift build

test:
	swift run MeridianChecks

app:
	./scripts/build_app.sh release

run: app
	open -n dist/Meridian.app

clean:
	rm -rf .build dist
