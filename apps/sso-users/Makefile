APP := sso-users
VERSION := $(shell cat VERSION)

.PHONY: build clean check check-version release test version

build:
	go build -o $(APP) .

clean:
	rm -f $(APP)

check: test build check-version

check-version:
	bash ./scripts/check-version.sh

release:
	bash ./scripts/build-release.sh $(VERSION)

test:
	go test ./...

version:
	go run . -version