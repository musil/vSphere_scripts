//go:build ignore

// Command zipfile creates a zip archive containing a single file. It is used
// by scripts/build-release.sh for the Windows release archive so the build
// does not depend on a system zip binary.
//
// Usage: go run ./scripts/zipfile.go <archive.zip> <source-file> <entry-name>
package main

import (
	"archive/zip"
	"fmt"
	"io"
	"os"
)

func main() {
	if len(os.Args) != 4 {
		fmt.Fprintln(os.Stderr, "usage: zipfile <archive.zip> <source-file> <entry-name>")
		os.Exit(2)
	}
	if err := run(os.Args[1], os.Args[2], os.Args[3]); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run(archivePath, sourcePath, entryName string) error {
	source, err := os.Open(sourcePath)
	if err != nil {
		return err
	}
	defer source.Close()

	info, err := source.Stat()
	if err != nil {
		return err
	}

	archive, err := os.Create(archivePath)
	if err != nil {
		return err
	}
	defer archive.Close()

	writer := zip.NewWriter(archive)

	header, err := zip.FileInfoHeader(info)
	if err != nil {
		return err
	}
	header.Name = entryName
	header.Method = zip.Deflate

	entry, err := writer.CreateHeader(header)
	if err != nil {
		return err
	}
	if _, err := io.Copy(entry, source); err != nil {
		return err
	}
	return writer.Close()
}
