#!/bin/sh
#
# Xcode Cloud — TestFlight「測試重點」(What to Test)
#
# Same hook as iChingSwiftUI. Without it, every TestFlight build arrives with an
# empty note, and there is no way to tell which commit a build came from.
#
# Xcode Cloud reads `TestFlight/WhatToTest.<locale>.txt` from the primary repository
# when it distributes a build. This hook runs after `xcodebuild` and before that
# distribution, so the file is generated here and carries this build's commit.
# It is gitignored: a committed copy would always be stale.
#
# Two filters iChing does not need. The note must not name the branch — one branch
# was `palm-square-layout`, and a tester must not read that platform name. Suit
# symbols are rejected as invalid characters. Both are stripped from the finished
# note, so a commit subject cannot leak them either.
#
# Only the archive action produces something to distribute; test-only workflows skip.

set -eu

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
  echo "ci_post_xcodebuild: action is '${CI_XCODEBUILD_ACTION:-none}', no TestFlight note to write"
  exit 0
fi

repo="${CI_PRIMARY_REPOSITORY_PATH:-$PWD}"
notes_dir="$repo/TestFlight"
mkdir -p "$notes_dir"

version=$(sed -n 's/^MARKETING_VERSION[[:space:]]*=[[:space:]]*\(.*\)$/\1/p' \
  "$repo/Configurations/Version.xcconfig" | tr -d '[:space:]')
build="${CI_BUILD_NUMBER:-?}"

# Tag or pull-request number only. Never CI_BRANCH.
if [ -n "${CI_TAG:-}" ]; then
  source_ref="tag ${CI_TAG}"
elif [ -n "${CI_PULL_REQUEST_NUMBER:-}" ]; then
  source_ref="PR #${CI_PULL_REQUEST_NUMBER}"
else
  source_ref=""
fi

# `CI_COMMIT` is the full hash; git is asked for the rest. Xcode Cloud clones shallowly,
# so anything below `git log -1` has to tolerate a history that is not all there.
commit="${CI_COMMIT:-$(git -C "$repo" rev-parse HEAD 2>/dev/null || echo '?')}"
short_commit=$(printf '%.7s' "$commit")
subject=$(git -C "$repo" log -1 --pretty=%s 2>/dev/null || echo '')
committed_at=$(git -C "$repo" log -1 --date=format:'%Y-%m-%d %H:%M' --pretty=%cd 2>/dev/null || echo '')
recent=$(git -C "$repo" log -8 --pretty='- %h %s' 2>/dev/null || echo '')

note_file="$notes_dir/WhatToTest.en-US.txt"
{
  printf '%s (build %s)\n' "$version" "$build"
  if [ -n "$source_ref" ]; then
    printf '%s · %s · %s\n' "$source_ref" "$short_commit" "$committed_at"
  else
    printf '%s · %s\n' "$short_commit" "$committed_at"
  fi
  printf 'workflow: %s\n' "${CI_WORKFLOW:-?}"
  if [ -n "$subject" ]; then
    printf '\n%s\n' "$subject"
  fi
  if [ -n "$recent" ]; then
    printf '\n最近的變更 / Recent commits:\n%s\n' "$recent"
  fi
} > "$note_file"

# Testers read this file. Strip the platform name and the characters TestFlight rejects.
sed -e 's/[♠♦♣♥]//g' -e 's/</ /g' -e 's/[Pp]alm//g' "$note_file" > "$note_file.tmp"
mv "$note_file.tmp" "$note_file"

# TestFlight rejects a note over 4000 characters, and a truncated note beats a build
# that fails to distribute. `wc -c` counts *bytes* — a Chinese commit subject is 3
# bytes per character, so this cuts well before the real limit — and `head -c` can
# slice a character in half, so `iconv -c` drops whatever partial sequence it left.
if [ "$(wc -c < "$note_file")" -gt 3900 ]; then
  head -c 3900 "$note_file" | iconv -c -f UTF-8 -t UTF-8 > "$note_file.tmp"
  printf '\n…\n' >> "$note_file.tmp"
  mv "$note_file.tmp" "$note_file"
fi

echo "ci_post_xcodebuild: wrote $note_file"
cat "$note_file"
