APP := sso-users

.PHONY: build clean check check-version test version

build:
	go build -o $(APP) .

clean:
	rm -f $(APP)

check: test build check-version

check-version:
	bash ./scripts/check-version.sh

test:
	go test ./...

version:
	go run . -version