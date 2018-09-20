#!/usr/bin/env sh
set -euo pipefail
IFS=$'\n\t'

source ./msgs.sh
source ./gits.sh
source ./demos.sh
source ./operations.sh

# This will silently start logging commands this script executes.
{ set -x; } 2>/dev/null

# This will stop logging, without printing the "stop logging commands" command.
{ set +x; } 2>/dev/null

title "This demo will show off the simplest form of stacks. It's linear, and"\
      "contains no conflicts."

reset_repo

msg "The the repository has been initialized. Let's add a file..."

echo "Here is our first file" > file_a.txt
describe_file file_a.txt

{ set -x; } 2>/dev/null
git add file_a.txt
git commit -m "Add file_a.txt"
{ set +x; } 2>/dev/null

wsg "A repository has been initialized, and we've added a file."\
    "\nLet's add a couple more files, this time in a stack."

git_co -b new_files/1/file_b.txt

echo "Here's another file." > file_b.txt
describe_file file_b.txt

{ set -x; } 2>/dev/null
git add file_b.txt
git commit -m "Add file_b.txt"
{ set +x; } 2>/dev/null

nl
git_co -b new_files/2/file_c.txt

echo "A third one...." > file_c.txt
describe_file file_c.txt

{ set -x; } 2>/dev/null
git add file_c.txt
git commit -m "Add file_c.txt"
{ set +x; } 2>/dev/null

nl
git_co -b new_files/3/file_d.txt

echo "And a fourth, for good measure" > file_d.txt
describe_file file_d.txt

{ set -x; } 2>/dev/null
git add file_d.txt
git commit -m "Add file_d.txt"
{ set +x; } 2>/dev/null

wsg "Now we have a few files, and a few branches waiting to be merged."\
    "\nLet's take a look at the git log as a graph..."

git_lg --all

wsg "And what do we do with stacks?"\
    "\nWhy, we collapse them, now don't we?"

git_co new_files/2/file_c.txt
git_merge_branch new_files/3/file_d.txt
nl

git_co new_files/1/file_b.txt
git_merge_branch new_files/2/file_c.txt
nl

git_co master
git merge --no-ff --no-edit new_files/1/file_b.txt
nl

wsg "We've now merged each of the stacked branches into it's parent -- 3 into"\
    "2 into 1 into master."\
    "\nLet's see what the graph looks like now."

git_lg

wsg "Note how the branches have gone from a decending order -- 3 on top of 2"\
    "on top of 1 on top of master -- to ascending order, with each branch "\
    "(save for the highest) now pointing to a merge commit."\
    "\nOkay. There you have the simplest happy-path."
