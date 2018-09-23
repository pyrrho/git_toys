#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ./msgs.sh
source ./gits.sh
source ./operations.sh

# This will start logging commands this script executes.
{ set -x; } 2>/dev/null

# This will stop logging, without printing the "stop logging commands" command.
{ set +x; } 2>/dev/null

title "One of the more common causes for a stack rebases is a wandering"\
      "master. \nLet's see what happens when you want to rebase an entire"\
      "stack onto a new master."
reset_repo

msg "Files and branches incoming..."

echo -e "Here is our first file" > file_a.txt
{ set -x; } 2>/dev/null
git add file_a.txt
git commit -m "Add file_a.txt"
{ set +x; } 2>/dev/null

nl

echo -e "Here's another file." > file_b.txt
{ set -x; } 2>/dev/null
git add file_b.txt
git commit -m "Add file_b.txt"
{ set +x; } 2>/dev/null

git_lg
wsg "Here we are again, ready to start building a stack off of master. This"\
    "time, master already has a few files in place."\
    "\nLet's get started."

git_co -b add_files/1/step_one
echo -e "A third one...." > file_c.txt
{ set -x; } 2>/dev/null
git add file_c.txt
git commit -m "Add file_c.txt"
{ set +x; } 2>/dev/null

git_lg
wsg "file_c.txt was added without a hitch. Good for us. Next up is file_d.txt"\
    "\nFor this demo, let's pretend file_d.txt relies on file_b.txt, and that"\
    "file_b.txt has a bug that we found while adding file_d.txt."\
    "\nInstead of just adding file_d.txt in this branch, we're also going to"\
    "fix the bug in file_b.txt."

git_co -b add_files/2/step_two

echo -e "Here's an important file with a qick fix added." >| file_b.txt
describe_file file_b.txt

nl

echo -e "And a fourth, for good measure" > file_d.txt

{ set -x; } 2>/dev/null
git add file_b.txt
git add file_d.txt
git commit -m "Add file_d.txt, fix a bug in file_b.txt"
{ set +x; } 2>/dev/null

git_lg --all

wsg "That's that, let's keep going with this stack."

nl
git_co -b add_files/3/step_three

echo -e "Wow, five files? What a complex repository." > file_e.txt
{ set -x; } 2>/dev/null
git add file_e.txt
git commit -m "Add file_e.txt"
{ set +x; } 2>/dev/null

nl
git_co -b add_files/4/step_four

echo -e "A sixth file? Madness." > file_f.txt
{ set -x; } 2>/dev/null
git add file_f.txt
git commit -m "Add file_f.txt"
{ set +x; } 2>/dev/null

git_lg --all

wsg "Done. Four branches, all neatly stacked, linearized and ready to collapse"\
    "into master."\
    "\nToday, though, we're not the only ones working on this project. While"\
    "we were getting the add_files stack ready, someone else found the same"\
    "bug in file_b.txt that we quickly patched, and gave it a proper fixing."\
    "\nLet's update master and see were everything stands."

git_co master
git_co -b bug_fix

echo -e "Here's an important and amazing file." >| file_b.txt
{ set -x; } 2>/dev/null
git add file_b.txt
git commit -m "Resolve a bug that was in file_b.txt"
{ set +x; } 2>/dev/null

nl
git_co master
git_merge_branch bug_fix
git branch -d bug_fix

git_lg --all

wsg "Now we're not so linearized anymore. Our stack is still linear, but"\
    "master has moved so we might (definitely do) have a conflict with master."\
    "\nWe already have an answer; git rebase --onto."

{ set -x; } 2>/dev/null
git rebase master add_files/1/step_one --onto master
{ set +x; } 2>/dev/null

git_lg --all

wsg "The first branch in the stack moved over just fine."\
    "\nThe second branch contains that quick patch to file_b.txt, though. Got"\
    "a guess about what's about to happen?"

{ set -x; } 2>/dev/null
{ set +e; } 2>/dev/null
git rebase add_files/1/step_one add_files/2/step_two --onto add_files/1/step_one
{ set -e; } 2>/dev/null
{ set +x; } 2>/dev/null

wsg "Hey. Look. A merge conflict."

git status
nl
describe_file file_b.txt

wsg "As expected, our change to file_b.txt conflicts with what's currently on"\
    "master, brought in by the dedicated fix."\
    "\nBecause we know that the code in master (the current base) is the"\
    "correct code to resolve with, we can use some shorthand to resolve this"\
    "conflict; git checkout --ours."

{ set -x; } 2>/dev/null
git checkout --ours file_b.txt
git add file_b.txt
git rebase --continue
{ set +x; } 2>/dev/null

git_lg --all

wsg "The file_b.txt merge conflict has been resolved, so now..."\
    "\nWait. That commit message."\
    "\nWe're no longer including a fix for file_b.txt in this commit, so we"\
    "should update the message to reflect that. Good git citizenship, and all."

git commit --amend -m "Add file_d.txt"
git_lg --all

wsg "Okay. That's better."\
    "\nThe file_b.txt merge conflict has been resolved, so now we can continue"\
    "rebasing the stack."

{ set -x; } 2>/dev/null
{ set +e; } 2>/dev/null
git rebase add_files/2/step_two add_files/3/step_three --onto add_files/2/step_two
{ set -e; } 2>/dev/null
{ set +x; } 2>/dev/null

wsg "Wait. Another merge conflict?"\
    "\nLet's take a look at what's going on."

git status

wsg "Okay, file_b.txt is conflicting. Again? Let's see what git has to say"\
    "about it."

{ set -x; } 2>/dev/null
git diff
{ set +x; } 2>/dev/null

wsg "Well that's... something. \`git diff\` is coming up blank?"

describe_file file_b.txt

wsg "In addition to \`git diff\` coming up blank, file_b.txt is in the state"\
    "that we want it to be in."\
    "\nMaybe if we take a closer look at the rebase conflict message, we'll be"\
    "able to figure out what's going on."

wsg "    First, rewinding head to replay your work on top of it..."\
    "\n    Applying: Add file_d.txt, fix a bug in file_b.txt"\
    "\n    . . ."\
    "\n    The copy of the patch that failed is found in: .git/rebase-apply/patch"\
    "\n"\
    "\nAh ha! It's trying to apply the *old version* of the file_d.txt"\
    "addition, where we patched file_b.txt."\
    "\nLet's take a look at the failing patch file."

cat .git/rebase-apply/patch

wsg "There should be two changes in here. One is /dev/null to b/file_d.txt"\
    "(which is the addition of file_d.txt), but the other should be"\
    "a/file_b.txt to b/file_b.txt (the modification of file_b.txt)."\
    "\nLooking at the body of that patch, we can see why it failed to land;"\
    "the contents of file_b.txt at this point in our rebased history is"\
    "different from what this commit -- the old version of this commit --"\
    "expected it to be."\

wsg "To clarify, the root problem here isn't the contents of the commit we're"\
    "trying to apply, it's that we're trying to apply this commit at all."\
    "\nWhen we ran the command to rebase add_files/3/step_three into the new"\
    "version of add_files/2/step_two we did something very naive;"\
    "\n    git rebase add_files/2/step_two add_files/3/step_three --onto add_files/2/step_two"\
    "\nWe asked git move the range of commits between the *new version* of"\
    "add_files/2/step_two to add_files/3/step_three, and use the new version"\
    "of add_files/2/step_two as a new base."\
    "\nBecause the history between master and add_files/2/step_two is now"\
    "fundimentally different than the history between master and the *old"\
    "version* of add_files/2/step_two, this is effectively impossible."\
    "\nWhat we need to be doing is asking git to move the range of commits"\
    "between the old version of add_files/2/step_two to"\
    "add_files/3/step_three, and use the new version of add_files/2/step_two"\
    "as a new base."\
    "\nCheck out the next demo to see how we can do that."

