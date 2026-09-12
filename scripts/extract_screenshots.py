#!/usr/bin/env python3
"""Extract named PNG screenshots from an Xcode xcresult bundle.

Screenshots must be attached via XCTAttachment in tests:
    let a = XCTAttachment(screenshot: app.screenshot())
    a.name = "01_my_screen"
    a.lifetime = .keepAlways
    add(a)

Usage:
    python3 scripts/extract_screenshots.py <path.xcresult> [output_dir]
    python3 scripts/extract_screenshots.py --latest [output_dir]

    output_dir defaults to screenshots/ (gitignored working folder).

`--latest` takes the newest bundle under BigTwo's DerivedData, which is
otherwise an `ls -t` over a long path — and, worse, a hand-picked path is how you
extract the *previous* run and log a pass for a run that executed nothing.
"""

import glob
import json
import os
import subprocess
import sys

DERIVED = os.path.expanduser("~/Library/Developer/Xcode/DerivedData")


def xcresult_get(xcresult: str, ref: str | None = None) -> dict:
    cmd = ["xcrun", "xcresulttool", "get", "--legacy",
           "--path", xcresult, "--format", "json"]
    if ref:
        cmd += ["--id", ref]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"xcresulttool get failed: {result.stderr.strip()}")
    return json.loads(result.stdout)


def xcresult_export(xcresult: str, ref: str, out_path: str) -> bool:
    result = subprocess.run(
        ["xcrun", "xcresulttool", "export", "--legacy",
         "--path", xcresult, "--id", ref,
         "--output-path", out_path, "--type", "file"],
        capture_output=True, text=True
    )
    return result.returncode == 0


def collect_test_refs(obj: dict | list) -> list[tuple[str, str]]:
    """Return [(test_name, summaryRef)] for every ActionTestMetadata."""
    refs = []
    if isinstance(obj, dict):
        if obj.get("_type", {}).get("_name") == "ActionTestMetadata":
            name = obj.get("name", {}).get("_value", "")
            ref = obj.get("summaryRef", {}).get("id", {}).get("_value", "")
            if ref:
                refs.append((name, ref))
        for v in obj.values():
            refs.extend(collect_test_refs(v))
    elif isinstance(obj, list):
        for item in obj:
            refs.extend(collect_test_refs(item))
    return refs


def collect_attachments(obj: dict | list) -> list[tuple[str, str, str]]:
    """Return [(attachment_name, payloadRef, uti)] for every ActionTestAttachment."""
    atts = []
    if isinstance(obj, dict):
        if obj.get("_type", {}).get("_name") == "ActionTestAttachment":
            name = obj.get("name", {}).get("_value", "")
            ref = obj.get("payloadRef", {}).get("id", {}).get("_value", "")
            uti = obj.get("uniformTypeIdentifier", {}).get("_value", "")
            if name and ref:
                atts.append((name, ref, uti))
        for v in obj.values():
            atts.extend(collect_attachments(v))
    elif isinstance(obj, list):
        for item in obj:
            atts.extend(collect_attachments(item))
    return atts


# XCTest auto-attaches non-screenshot payloads (esp. on failure): a screen
# recording (video), "App UI hierarchy" / "Debug description …" text dumps, and
# internal kXCTAttachment* snapshots. These must not be written out as `.png`.
_SKIP_NAME_PREFIXES = ("kXCTAttachment", "App UI hierarchy", "Debug description")


def _is_image_attachment(name: str, uti: str) -> bool:
    if name.startswith(_SKIP_NAME_PREFIXES):
        return False
    # Keep only image payloads. If the UTI is missing, fall back to allowing it
    # (a named snapshot) — but a non-image UTI (video/text) is always skipped.
    if uti and not (uti.startswith("public.png")
                    or uti.startswith("public.jpeg")
                    or uti == "public.image"):
        return False
    return True


def latest_xcresult() -> str:
    """The newest test bundle Xcode wrote for this project.

    Not `-derivedDataPath`-aware on purpose: this repo builds to Xcode's default
    location (see "Never pass -derivedDataPath" in CLAUDE.md), so there is exactly
    one place to look.
    """
    pattern = os.path.join(DERIVED, "BigTwo-*", "Logs", "Test", "*.xcresult")
    bundles = sorted(glob.glob(pattern), key=os.path.getmtime, reverse=True)
    if not bundles:
        print(f"Error: no .xcresult under {DERIVED}/BigTwo-*/Logs/Test",
              file=sys.stderr)
        sys.exit(1)
    return bundles[0]


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    if sys.argv[1] == "--latest":
        xcresult = latest_xcresult()
        out_dir = sys.argv[2] if len(sys.argv) > 2 else "screenshots"
        print(f"Latest: {os.path.basename(xcresult)}")
    else:
        xcresult = sys.argv[1]
        out_dir = sys.argv[2] if len(sys.argv) > 2 else "screenshots"

    if not os.path.exists(xcresult):
        print(f"Error: {xcresult} not found", file=sys.stderr)
        sys.exit(1)

    os.makedirs(out_dir, exist_ok=True)

    # Step 1 – find the testsRef from the root action result
    root = xcresult_get(xcresult)
    try:
        tests_ref = (root["actions"]["_values"][0]
                     ["actionResult"]["testsRef"]["id"]["_value"])
    except (KeyError, IndexError) as e:
        print(f"Error: could not find testsRef in {xcresult}: {e}", file=sys.stderr)
        sys.exit(1)

    # Step 2 – get all ActionTestMetadata summaryRefs
    tests_obj = xcresult_get(xcresult, tests_ref)
    test_refs = collect_test_refs(tests_obj)
    if not test_refs:
        print("No test summaries found.", file=sys.stderr)
        sys.exit(1)

    # Step 3 – for each test, get its summary and extract named attachments
    ok = err = 0
    seen: set[str] = set()  # deduplicate by name (same PNG may appear in multiple refs)

    for _test_name, summary_ref in test_refs:
        try:
            summary = xcresult_get(xcresult, summary_ref)
        except RuntimeError:
            continue

        for att_name, payload_ref, uti in collect_attachments(summary):
            if att_name in seen:
                continue
            seen.add(att_name)

            if not _is_image_attachment(att_name, uti):
                continue  # skip screen recordings, text dumps, internal attachments

            ext = ".jpg" if uti.startswith("public.jpeg") else ".png"
            out_path = os.path.join(out_dir, att_name + ext)
            if xcresult_export(xcresult, payload_ref, out_path):
                size_kb = os.path.getsize(out_path) // 1024
                print(f"  ✓  {att_name}{ext}  ({size_kb} KB)")
                ok += 1
            else:
                print(f"  ✗  {att_name} (export failed)", file=sys.stderr)
                err += 1

    print(f"\n{ok} screenshot(s) extracted to {out_dir}/")
    if err:
        print(f"{err} failed.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
