#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ./msgs.sh
source ./gits.sh
source ./demos.sh
source ./operations.sh

# This will start logging commands this script executes.
{ set -x; } 2>/dev/null

# This will stop logging, without printing the "stop logging commands" command.
{ set +x; } 2>/dev/null

title "We're going to pick back up where the last demo left off -- we had a" \
    "stack which included a small incidental fix in the middle of it, and" \
    "another developer had come along and fixed the same thing before we" \
    "landed our stack. We needed to rebase, but we ended up with some" \
    "uncomfortable merge conflicts along the way. Before we do anything" \
    "else, let's get back to that state."
reset_repo

msg "Files and branches incoming..."

# --- File A
echo -e "Here is our first file" >file_a.txt
{ set -x; } 2>/dev/null
git add file_a.txt
git commit -m "Add file_a.txt"
{ set +x; } 2>/dev/null
nl

# --- File B
echo -e "Here's another file." >file_b.txt
{ set -x; } 2>/dev/null
git add file_b.txt
git commit -m "Add file_b.txt"
{ set +x; } 2>/dev/null
nl

git_lg --all
wsg "Ok, this is our initial repository state. Let's recreate our stack."

# --- File C
git_co -b add_files/1/step_one
echo -e "A third one...." >file_c.txt
{ set -x; } 2>/dev/null
git add file_c.txt
git commit -m "Add file_c.txt"
{ set +x; } 2>/dev/null
nl

# --- Patch File B, Add File D
git_co -b add_files/2/step_two
echo -e "Here's an important file with a qick fix added." >|file_b.txt
describe_file file_b.txt
nl

echo -e "And a fourth, for good measure" >file_d.txt
{ set -x; } 2>/dev/null
git add file_b.txt
git add file_d.txt
git commit -m "Add file_d.txt, fix a bug in file_b.txt"
{ set +x; } 2>/dev/null
nl

# --- File E
git_co -b add_files/3/step_three
echo -e "Wow, five files? What a complex repository." >file_e.txt
{ set -x; } 2>/dev/null
git add file_e.txt
git commit -m "Add file_e.txt"
{ set +x; } 2>/dev/null
nl

# --- File F
git_co -b add_files/4/step_four
echo -e "A sixth file? Madness." >file_f.txt
{ set -x; } 2>/dev/null
git add file_f.txt
git commit -m "Add file_f.txt"
{ set +x; } 2>/dev/null
nl

# --- SOW CONFLICT
git_lg --all
wsg "Four branches, all neatly stacked, linearized and ready to collapse" \
    "into master, just like before." \
    "\n\n" \
    "Now we need to recreate the other developer's bugfix."

git_co master
git_co -b bug_fix

echo -e "Here's an important and amazing file." >|file_b.txt
{ set -x; } 2>/dev/null
git add file_b.txt
git commit -m "Resolve a bug that was in file_b.txt"
{ set +x; } 2>/dev/null

nl
git_co master
git_merge_branch bug_fix
git branch -d bug_fix

# --- Start our new scenario pieces
git_lg --all
wsg "Ok, we're finally back to where we got in trouble last time. We want to" \
    "rebase our whole stack on top of master, but when we tried doing that" \
    "with rebase --onto we ended up making a mistake:" \
    "\n\n" \
    "We ran this: git rebase add_files/2/step_two add_files/3/step_three" \
    "--onto add_files/2/step_two" \
    "\n\n" \
    "By doing that, we asked git to rebase a commit range between a base" \
    "we had already rebased, and a tip which we hadn't moved yet, with" \
    "predictably disastrous consequences." \
    "\n\n" \
    "This time we're going to be more careful about our rebase. Let's start" \
    "by recording where we're coming from with a few lightweight tags."

{ set -x; } 2>/dev/null
#       TAG NAME                              REF NAME
git tag stacks/rebases/add_files/1/step_one   add_files/1/step_one
git tag stacks/rebases/add_files/2/step_two   add_files/2/step_two
git tag stacks/rebases/add_files/3/step_three add_files/3/step_three
git tag stacks/rebases/add_files/4/step_four  add_files/4/step_four
{ set +x; } 2>/dev/null

# --- Run the rebases correctly
git_lg --all
wsg "Great, now we have two almost-identical names for each branch head." \
    "Why did we do that again?" \
    "\n\n" \
    "Well, git rebase --onto is a ternary operation -- you need 3 git refs to" \
    "point it at the right thing to do. Two to select the range of commits" \
    "you want to move, and a third to pick where you want to put them. These" \
    "tags give us a way to say 'Get me the commits in this branch of my" \
    "stack, and put it on the rebased version of my parent branch.'" \
    "\n\n" \
    "Let's see that in action!"

{ set -x; } 2>/dev/null
# Move branch 1
git rebase master add_files/1/step_one --onto master

msg "First rebase is easy, branch onto master, just like before."

{ set +e; } 2>/dev/null
git rebase \
    stacks/rebases/add_files/1/step_one add_files/2/step_two \
    --onto add_files/1/step_one
{ set -e; } 2>/dev/null
{ set +x; } 2>/dev/null

git status
nl
describe_file file_b.txt

wsg "Ah right, we do have a legitimate merge conflict. Let's resolve that as" \
    "before, taking the upstream commit and fixing the message."

{ set -x; } 2>/dev/null
git checkout --ours file_b.txt
git add file_b.txt
git rebase --continue
git commit --amend -m "Add file_d.txt"
{ set +x; } 2>/dev/null

git_lg --all
wsg "Ok, good to go. Let's finish up the rest of our stacked rebase!"

{ set -x; } 2>/dev/null
git rebase \
    stacks/rebases/add_files/2/step_two add_files/3/step_three \
    --onto add_files/2/step_two
git rebase \
    stacks/rebases/add_files/3/step_three add_files/4/step_four \
    --onto add_files/3/step_three
{ set +x; } 2>/dev/null

git_lg --all
wsg "This is a lot to digest, so let's break it down."

git_lg master~2..add_files/4/step_four
wsg "This is our stack, linear, rebased on master, and ready for us to " \
    "keep working."

git_lg master~2..stacks/rebases/add_files/4/step_four
wsg "This is the linear history we came from. It's the stuff we don't need" \
    "anymore, so let's clean it up and then see what our graph looks like!"

{ set -x; } 2>/dev/null
git tag -d stacks/rebases/add_files/1/step_one
git tag -d stacks/rebases/add_files/2/step_two
git tag -d stacks/rebases/add_files/3/step_three
git tag -d stacks/rebases/add_files/4/step_four
{ set +x; } 2>/dev/null

git_lg --all
msg "There we go! That could have gone a lot worse. Temporary tags are " \
    "shaping up to be a pretty reasonable answer for us!"
