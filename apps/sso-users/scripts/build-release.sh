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
		zip_file "$dist" "${package}.zip" "$binary"
	else
		tar -C "$dist" -czf "${dist}/${package}.tar.gz" "$binary"
	fi

	rm "${dist}/${binary}"
}

zip_file() {
	local dir="$1"
	local archive="$2"
	local binary="$3"

	if command -v zip >/dev/null 2>&1; then
		(
			cd "$dir"
			zip -q "$archive" "$binary"
		)
		return
	fi

	(
		cd "$dir"
		go run /dev/stdin "$archive" "$binary" <<'EOF'
package main

import (
	"archive/zip"
	"io"
	"os"
)

func main() {
	archivePath := os.Args[1]
	binaryPath := os.Args[2]

	archive, err := os.Create(archivePath)
	if err != nil {
		panic(err)
	}
	defer archive.Close()

	writer := zip.NewWriter(archive)
	defer writer.Close()

	file, err := os.Open(binaryPath)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	info, err := file.Stat()
	if err != nil {
		panic(err)
	}

	header, err := zip.FileInfoHeader(info)
	if err != nil {
		panic(err)
	}
	header.Name = binaryPath
	header.Method = zip.Deflate

	entry, err := writer.CreateHeader(header)
	if err != nil {
		panic(err)
	}
	if _, err := io.Copy(entry, file); err != nil {
		panic(err)
	}
}
EOF
	)
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