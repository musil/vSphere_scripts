#!/usr/bin/env bash
set -euo pipefail

version="${1:?usage: build-release.sh <version>}"
app="sso-users"
dist="dist"

case "$version" in
	[0-9]*.[0-9]*.[0-9]*) ;;
	*)
		echo "error: version must use MAJOR.MINOR.PATCH format" >&2
		exit 2
		;;
esac

rm -rf "$dist"
mkdir -p "$dist"

build() {
	local goos="$1"
	local goarch="$2"
	local ext="$3"
	local package="${app}_${version}_${goos}_${goarch}"
	local binary="${app}${ext}"

	CGO_ENABLED=0 GOOS="$goos" GOARCH="$goarch" \
		go build -trimpath -ldflags="-s -w" -o "${dist}/${binary}" .

	if [[ "$goos" == "windows" ]]; then
		(
			cd "$dist"
			zip -q "${package}.zip" "$binary"
		)
	else
		tar -C "$dist" -czf "${dist}/${package}.tar.gz" "$binary"
	fi

	rm "${dist}/${binary}"
}

checksum() {
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$@"
	else
		shasum -a 256 "$@"
	fi
}

build darwin arm64 ""
build linux amd64 ""
build windows amd64 ".exe"

(
	cd "$dist"
	checksum \
		"${app}_${version}_darwin_arm64.tar.gz" \
		"${app}_${version}_linux_amd64.tar.gz" \
		"${app}_${version}_windows_amd64.zip" > checksums.txt
)