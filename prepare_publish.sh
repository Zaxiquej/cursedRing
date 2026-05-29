#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

coi_line='<script src="coi-serviceworker.js"></script>'
index_line='<script src="index.js"></script>'

if ! grep -Fq "$coi_line" index.html; then
	tmp_file="$(mktemp)"
	awk -v coi="$coi_line" -v idx="$index_line" '
		{
			if (index($0, idx) > 0) {
				match($0, /^[[:space:]]*/)
				print substr($0, RSTART, RLENGTH) coi
			}
			print
		}
	' index.html > "$tmp_file"
	mv "$tmp_file" index.html
	echo "Added coi-serviceworker.js before index.js."
else
	echo "coi-serviceworker.js is already present."
fi

git add -A
tree_hash="$(git write-tree)"
commit_hash="$(git commit-tree "$tree_hash" -m "Publish web export")"
git update-ref refs/heads/main "$commit_hash"

git reflog expire --expire=now --expire-unreachable=now --all
git gc --prune=now --aggressive

echo
echo "Prepared single-snapshot commit: ${commit_hash:0:7}"
git count-objects -vH
echo
echo "Push it with:"
echo "git push --force-with-lease origin main"
