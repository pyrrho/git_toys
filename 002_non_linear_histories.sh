#!/usr/bin/env sh
set -euo pipefail
IFS=$'\n\t'

source ./msgs.sh
source ./gits.sh
source ./demos.sh
source ./operations.sh

# This will start logging commands this script executes.
set -x

# This will stop logging, without printing the "stop logging commands" command.
{ set +x; } 2>/dev/null

title "This is going to be another happy-path demonstration (mostly), this"\
      "time showing off a non-linearized history (and the issues that can"\
      "arise from said history)."
reset_repo

msg "Files and branches incoming..."

echo "Here is our first file" > file_a.txt
{ set -x; } 2>/dev/null
git add file_a.txt
git commit -m "Add file_a.txt"
{ set +x; } 2>/dev/null

nl
git_co -b new_files/1/file_b.txt
echo "Here's another file." > file_b.txt
{ set -x; } 2>/dev/null
git add file_b.txt
git commit -m "Add file_b.txt"
{ set +x; } 2>/dev/null

nl
git_co -b new_files/2/file_c.txt
echo "A third one...." > file_c.txt
{ set -x; } 2>/dev/null
git add file_c.txt
git commit -m "Add file_c.txt"
{ set +x; } 2>/dev/null

nl
git_co -b new_files/3/file_d.txt
echo "And a fourth, for good measure" > file_d.txt
{ set -x; } 2>/dev/null
git add file_d.txt
git commit -m "Add file_d.txt"
{ set +x; } 2>/dev/null

git_lg --all

wsg "This state should look familiar to you, if you've seen the previous demo."\
    "\nBut What happens if we find a bug in file_b.txt during a review? A fix"\
    "willneed to be applied. Obviously. But where?"\
    "\nBranch new_files/3 -- the latest in our stack, and the current HEAD --"\
    "doesn't have anything to do with file_b, so the fix doesn't 'fit' there."\
    "We could make a new branch, but then the flaw will remain in branches"\
    "new_files/2 and new_files/3."\
    "\nLet's backtrack to branch new_files/2 and fix the issue at its roots."

git_co new_files/1/file_b.txt
describe_file file_b.txt

nl
{ set -x; } 2>/dev/null
sed -i '' 's/another/an amazing/' file_b.txt
{ set +x; } 2>/dev/null
describe_file file_b.txt

{ set -x; } 2>/dev/null
git ci file_b.txt -m "Fixed a bug in file_b.txt"
{ set +x; } 2>/dev/null

git_lg --all

wsg "This give us a branch in our history. It's all correct and valid, but it"\
    "looks a little off."\
    "\nWe do know that the change we made won't trigger a conflict though, so"\
    "let's go ahead and collapse this sucker."

git_co new_files/2/file_c.txt
git_merge_branch new_files/3/file_d.txt
nl

git_co new_files/1/file_b.txt
git_merge_branch new_files/2/file_c.txt
nl

git_co master
git_merge_branch new_files/1/file_b.txt
nl

git_lg --all

wsg "And there you have a non-conflicting branch revision, merged without"\
    "linearizing the history."\
    "\nIt's nice when it works like this, but unfortunately you won't know if"\
    "there's going to be a conflict with this pattern until you start merging."\
    "\nHere. Check this out."

cd_root

reset_repo

echo "Here is our first file" > file_a.txt
{ set -x; } 2>/dev/null
git add file_a.txt
git commit -m "Add file_a.txt"
{ set +x; } 2>/dev/null

nl
git_co -b new_files/1/file_b.txt
echo "Here's another file." > file_b.txt
{ set -x; } 2>/dev/null
git add file_b.txt
git commit -m "Add file_b.txt"
{ set +x; } 2>/dev/null

nl
git_co -b new_files/2/file_c.txt
echo "A third one...." > file_c.txt
{ set -x; } 2>/dev/null
git add file_c.txt
git commit -m "Add file_c.txt"
{ set +x; } 2>/dev/null

nl
git_co -b new_files/3/file_d.txt
echo "And a fourth, for good measure" > file_d.txt
{ set -x; } 2>/dev/null
git add file_d.txt
git commit -m "Add file_d.txt"
{ set +x; } 2>/dev/null

nl
git_co new_files/3/file_d.txt
describe_file file_b.txt
nl
{ set -x; } 2>/dev/null
sed -i '' 's/another/an important/' file_b.txt
{ set +x; } 2>/dev/null
describe_file file_b.txt

{ set -x; } 2>/dev/null
git ci file_b.txt -m "Squashed a bug in file_b.txt [Hey look! A conflict!]"
{ set +x; } 2>/dev/null

nl
git_co new_files/1/file_b.txt
describe_file file_b.txt
nl
{ set -x; } 2>/dev/null
sed -i '' 's/another/an amazing/' file_b.txt
{ set +x; } 2>/dev/null
describe_file file_b.txt

{ set -x; } 2>/dev/null
git ci file_b.txt -m "Fixed a bug in file_b.txt"
{ set +x; } 2>/dev/null

git_lg --all

wsg "So here we are again, with a history much like the non-conflicting one we"\
    "just collapsed."\
    "\nThis history, however, has two commits that edit file_b.txt, and those"\
    "commits live in two separate branches."\
    "\nDo you see where this is going?"

git_co new_files/2/file_c.txt
git_merge_branch new_files/3/file_d.txt
git_lg --all

wsg "We've now merged new_files/3 into new_files/2, and that merge succeeded."\
    "\nThis history might look a little confusing since we're in the middle of"\
    "a collapse. I paused here to highlight the fact that this merge"\
    "succeeded, that this history is actually correct, and that it's..."\
    "well... confusing to look at."\
    "\nLet's continue, and see what happens when we merge the combined"\
    "new_files/2 + new_files/3 into new_files/1..."

git_co new_files/1/file_b.txt
set +e
git_merge_branch new_files/2/file_c.txt
set -e
nl

describe_file file_b.txt

wsg "Here we are at the merge conflict I was teasing previously."\
    "\nThe really imporant note here is that git didn't fail until we"\
    "attempted to merge the conflicting histories, halfway through the stack"\
    "collapse operation."\
    "\nIf we were doing this in GitHub or another system that required reviews"\
    "prior to a merge, we'd be in a tough spot. We could modify new_files/2"\
    "prior to merging it into new_files/1 and re-request a review for that"\
    "branch -- a branch that now contains all of its original changes, all"\
    "changes from branches higher in the stack, _and_ the changes required to"\
    "resolve the merge conflict. We could revert the merges that had already"\
    "been done and fix the conflict in a clean new_files/3 (how one would"\
    "un-merge the sack, or prove that the merge conflict was resolved is left"\
    "to an exercise for the reader). Or maybe we could open a new branch"\
    "(new_files/2.5/fix_merge_conflicts?) targeting the half collapsed stack"\
    "--- a branching structure sure to confuse no one at all </scarcasm>."\
    "\nI won't speak for anyone else, but none of these seem like a good"\
    "choice to me. Let's move on to a better solution."
