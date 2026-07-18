#!/usr/bin/env bash
set -euo pipefail

app_dir="apps/sso-users"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
cd "$repo_root"

changed=()
while IFS= read -r line; do
	path="${line:3}"
	if [[ "$path" == *" -> "* ]]; then
		path="${path##* -> }"
	fi
	changed+=("$path")
done < <(git status --porcelain --untracked-files=all -- "$app_dir")

if [[ ${#changed[@]} -eq 0 ]]; then
	echo "check-version: no sso-users app changes detected"
	exit 0
fi

version_changed=false
changelog_changed=false
code_changed=false
code_paths=()

for path in "${changed[@]}"; do
	case "$path" in
		"$app_dir/VERSION")
			version_changed=true
			;;
		"$app_dir/CHANGELOG.md")
			changelog_changed=true
			;;
		"$app_dir/README.md"|"$app_dir/go.sum"|"$app_dir/.env"|"$app_dir/sso-users"|"$app_dir/"*.csv|"$app_dir/"*.json|"$app_dir/"*.log)
			;;
		"$app_dir/"*)
			code_changed=true
			code_paths+=("$path")
			;;
	esac
done

if [[ "$version_changed" == true && "$changelog_changed" != true ]]; then
	echo "check-version: VERSION changed, but CHANGELOG.md was not updated" >&2
	exit 1
fi

if [[ "$code_changed" != true ]]; then
	echo "check-version: no versioned code/build changes detected"
	exit 0
fi

if [[ "$version_changed" != true || "$changelog_changed" != true ]]; then
	echo "check-version: code/build files changed without both VERSION and CHANGELOG.md updates" >&2
	echo "check-version: update apps/sso-users/VERSION and apps/sso-users/CHANGELOG.md" >&2
	echo "check-version: changed code/build files:" >&2
	printf '  - %s\n' "${code_paths[@]}" >&2
	exit 1
fi

echo "check-version: VERSION and CHANGELOG.md updated with code/build changes"