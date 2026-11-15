import os
import re
import sys
import tempfile

#### Fedora KDE version of Startup_Routine/log_cleaner.py: dnf 5 output instead of apt's.
#### Patterns written against a real `dnf upgrade --refresh -y` / `dnf autoremove -y` / `dnf clean packages` log (Fedora 45).

#### Anything resembling a problem survives case-insensitive, even if it also matches lines_to_remove.
#### (?<!no ) and (?<!\b0 ): "no error" and dnf's "0 errors occurred" are not problems.
KEEP = re.compile(
	r"\b(?<!no )(?<!\b0 )(error|errors|fail|failed|failing|failure|cannot|denied|refused|traceback|warning|problem)\b",
	re.I,
)


#### `^\s*` is prepended to every entry below, so a leading tab or spaces still match.
#### `.*` covers the strings that only differ in their ending (remove it / them ...).
lines_to_remove = (

	#### dnf: repository refresh and every progress line (downloads, "[ 3/18] Upgrading ..." steps): they all carry "100% |"
	r"Updating and loading repositories",
	r"Repositories loaded",
	r".*100% \|",
	r"-{20,}",

	#### dnf: table header, the "replacing <old version>" line under each package, size / transaction chatter
	r"Package\s+Arch\s+Version",
	r"replacing ",
	r"Replacing:",
	r"Transaction Summary",
	r"Total size of inbound packages",
	r"After this operation",
	r"Running transaction",
	r"Complete!",
	r"Removed \d+ files, \d+ directories",

	#### flatpak (same as the Mint version). "Installing(?!:)": dnf's "Installing:" section header is kept
	r"Info:",
	r"Need to",
	r"Installation finished. No error reported",
	r"Looking for updates",
	r"This application has been delisted",
	r"Installing(?!:)",
	r"Updating",
	r"Sourcing.*"

)


REMOVE = re.compile("|".join(rf"^\s*(?:{line})" for line in lines_to_remove))


def clean(lines):
	return "".join(ln for ln in lines if KEEP.search(ln) or not REMOVE.search(ln))


def main(path):
	try:

		with open(path, encoding="utf-8", errors="replace") as fh:
			text = clean(fh.readlines())

		fd, tmp = tempfile.mkstemp(dir=os.path.dirname(os.path.abspath(path)), suffix=".tmp")

		with os.fdopen(fd, "w", encoding="utf-8") as fh:
			fh.write(text)
		os.replace(tmp, path)				 #### atomic: never a half-written log

	except OSError as err:
		print(f"log_cleaner: {path}: {err}", file=sys.stderr)
		return 1

	return 0


if __name__ == "__main__":
	if len(sys.argv) != 2:
		sys.exit("usage: log_cleaner.py <logfile>")
	sys.exit(main(sys.argv[1]))