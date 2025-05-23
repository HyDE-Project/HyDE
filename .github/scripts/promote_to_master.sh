#!/bin/bash

COMMIT_LIST=$(git log --pretty=format:"* %s (%h) by %an" origin/master..dev |
    while IFS= read -r line; do
        if [[ ! $line =~ ^"* feat"* && ! $line =~ ^"* fix"* && ! $line =~ ^"* docs"* ]]; then
            echo "* chore${line:1}"
        else
            echo "$line"
        fi
    done)

if [ -z "$COMMIT_LIST" ]; then
    COMMIT_LIST="No new commits - branches may be identical"
fi

MERGE_DATE="Friday"

echo "$COMMIT_LIST" >commit_list.txt

cat <<EOF >>$GITHUB_ENV
PR_BODY<<EOT
This is an automated PR to promote changes from \`dev\` to \`master\`.
Please review and test before merging.


See [TESTING.md](./TESTING.md) for complete testing instructions.


According to our release policy, this PR is expected to be merged on: **$MERGE_DATE**
Testers are encouraged to test the changes before merging.
Please note that this schedule may be adjusted based on the needs of the project.

---
$(cat commit_list.txt)
---

Please review the changes carefully before merging.
EOT
EOF
