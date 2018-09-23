#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ./msgs.sh
source ./gits.sh
source ./operations.sh

# This will start logging commands this script executes.
set -x

# This will stop logging, without printing the "stop logging commands" command.
{ set +x; } 2>/dev/null

title "This is going to build off of the previous demonstration, showing how a"\
      "less-than-happy-path merge conflict might be resolved through"\
      "linearization via git rebase."
reset_repo

msg "Files and branches incoming..."

echo -e "Here is our first file" > file_a.txt
{ set -x; } 2>/dev/null
git add file_a.txt
git commit -m "Add file_a.txt"
{ set +x; } 2>/dev/null

nl
git_co -b new_files/1/file_b.txt
echo -e "Here's another file." > file_b.txt
{ set -x; } 2>/dev/null
git add file_b.txt
git commit -m "Add file_b.txt"
{ set +x; } 2>/dev/null

nl
git_co -b new_files/2/file_c.txt
echo -e "A third one...." > file_c.txt
{ set -x; } 2>/dev/null
git add file_c.txt
git commit -m "Add file_c.txt"
{ set +x; } 2>/dev/null

nl
git_co -b new_files/3/file_d.txt
echo -e "And a fourth, for good measure" > file_d.txt
{ set -x; } 2>/dev/null
git add file_d.txt
git commit -m "Add file_d.txt"
{ set +x; } 2>/dev/null

git_lg --all

wsg "If you've been following along, this setup will look very familiar."\
    "\nWe're going to re-create the conflict we saw in the previous demo by"\
    "editing file_b.txt in branches new_files/1 and new_files/2."

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

git_lg --all

wsg "Here is the branch structure that eventually lead to a merge conflict in"\
    "our prevous demo."\
    "\nRather than waiting to find merge conflicts during the stack collapse,"\
    "let's go looking for them by using git rebase to linearize the history of"\
    "this stack."

{ set -x; } 2>/dev/null
git rebase new_files/1/file_b.txt new_files/2/file_c.txt --onto new_files/1/file_b.txt
{ set +x; } 2>/dev/null

git_lg --all

wsg "The first rebase succeeded; new_files/2 is now on top of the branch that"\
    "new_files/1 created."\
    "\nLet's continue."

{ set -x; } 2>/dev/null
{ set +e; } 2>/dev/null
git rebase new_files/2/file_c.txt new_files/3/file_d.txt --onto new_files/2/file_c.txt
{ set -e; } 2>/dev/null
{ set +x; } 2>/dev/null


wsg "And here we are, back at a conflict. But this time it's in new_files/3"\
    "(or rather, a detached HEAD based on the changes made in new_files/3)."\
    "\nLet's take a look at the state of the repository, make sure we know"\
    "what's up..."

git status
nl
describe_file file_b.txt

wsg "Yep, that looks like a rebase conflict if I've ever seen one."\
    "\nLet's fix that up by combining the two changes..."

echo -e "Here's an important and amazing file." >| file_b.txt
describe_file file_b.txt
git add file_b.txt
git rebase --continue

git_lg --all

wsg "Now that the rebase conflict is resolved, we're back to a fully linear"\
    "history. This merge is now guaranteed to complete without conflict."\
    "We could even fast-forward merge master, but then we'd not know who"\
    "performed the merge."

git_co new_files/2/file_c.txt
git_merge_branch new_files/3/file_d.txt
nl

git_co new_files/1/file_b.txt
git_merge_branch new_files/2/file_c.txt
nl

git_co master
git_merge_branch new_files/1/file_b.txt

git_lg --all

wsg "This concludes the first series of demos. Now that the first few pitfalls"\
    "have been exposed, and the primary motivations have been shown it's time"\
    "to dig into more corner cases and show off"
