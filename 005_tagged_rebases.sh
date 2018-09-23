#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ./msgs.sh
source ./gits.sh
source ./demos.sh
source ./operations.sh

stitle 3<<EOM
We're going to pick back up where the last demo left off -- we had a stack which
included a small incidental fix in the middle of it, and another developer had
come along and fixed the same thing before we landed our stack.

We needed to rebase our stack, but we ended up creating some uncomfortable merge
conflicts when we tried.

Before we do anything else, let's get back to that state.
EOM
reset_repo

msg "Replaying starting commits..."

showcmd "Create file_a" 3<<'SCRIPT'
    echo -e "Here is our first file" >file_a.txt
    git add file_a.txt
    git commit -m "Add file_a.txt"
SCRIPT

showcmd "Create file_b" 3<<'SCRIPT'
    echo -e "Here's another file." >file_b.txt
    git add file_b.txt
    git commit -m "Add file_b.txt"
SCRIPT

show_single_cmd git_lg --all
wsg "Ok, this is our initial repository state. Let's recreate our stack."

showcmd "First branch: create file_c" 3<<'SCRIPT'
    git_co -b add_files/1/step_one
    echo -e "A third one...." >file_c.txt
    git add file_c.txt
    git commit -m "Add file_c.txt"
SCRIPT

showcmd "Second branch: patch a mistake in file_b" 3<<'SCRIPT'
    git_co -b add_files/2/step_two
    echo -e "Here's an important file with a qick fix added." >|file_b.txt
SCRIPT

describe_file file_b.txt
nl

showcmd "Second branch, still: create file_d" 3<<'SCRIPT'
    echo -e "And a fourth, for good measure" >file_d.txt
    git add file_b.txt
    git add file_d.txt
    git commit -m "Add file_d.txt, fix file_b.txt"
SCRIPT

showcmd "Third branch: create file_e" 3<<'SCRIPT'
    git_co -b add_files/3/step_three
    echo -e "Wow, five files? What a complex repository." >file_e.txt
    git add file_e.txt
    git commit -m "Add file_e.txt"
SCRIPT

showcmd "Fourth branch: create file_f" 3<<'SCRIPT'
    git_co -b add_files/4/step_four
    echo -e "A sixth file? Madness." >file_f.txt
    git add file_f.txt
    git commit -m "Add file_f.txt"
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
Four branches, all neatly stacked, linearized and ready to collapse
into master, just like before.

Now we need to recreate the other developer's bugfix.
EOM

showcmd "Another dev comes along and starts a feature branch..." 3<<'SCRIPT'
    git_co master
    git_co -b bug_fix
SCRIPT

showcmd "fixes the broken file..." 3<<'SCRIPT'
    echo -e "Here's an important and amazing file." >|file_b.txt
    git add file_b.txt
    git commit -m "Resolve a bug that was in file_b.txt"
SCRIPT

showcmd "and finally, commits it." 3<<'SCRIPT'
    git_co master
    git_merge_branch bug_fix
    git branch -d bug_fix
SCRIPT

# --- Start our new scenario pieces
show_single_cmd git_lg --all
swsg 3<<EOM
Ok, we're finally back to where we got in trouble last time. We want to
rebase our whole stack on top of master, but when we tried doing that
with rebase --onto we ended up making a mistake:

We ran this:

    git rebase add_files/2/step_two        \\
               add_files/3/step_three      \\
               --onto add_files/2/step_two

By doing that, we asked git to rebase a commit range between a base
we had already rebased, and a tip which we hadn't moved yet, with
predictably disastrous consequences.

This time we're going to be more careful about our rebase. Let's start
by recording where we're coming from with a few lightweight tags.
EOM

showcmd "Tag all the branches in our stack" 3<<'SCRIPT'
    ### ### TAG_NAME                              REF_NAME
    git tag _rebase/1/step_one   add_files/1/step_one
    git tag _rebase/2/step_two   add_files/2/step_two
    git tag _rebase/3/step_three add_files/3/step_three
    git tag _rebase/4/step_four  add_files/4/step_four
SCRIPT

# --- Run the rebases correctly
show_single_cmd git_lg --all
swsg 3<<EOM
Great, now we have two almost-identical names for each branch head.
Why did we do that again?

Well, \`git rebase --onto\` is a ternary operation: you need 3 git refs to
point it at the right thing to do:

    git rebase <start of range>          \\
               <end of range>            \\
               <where to put that range>

These new tags give us a way to say 'Get me the commits in this branch of my
stack, and put it on the rebased version of my parent branch.'

Let's try our rebases using tags!
EOM

showcmd "Move branch 1" 3<<'SCRIPT'
git rebase master add_files/1/step_one --onto master
SCRIPT

msg "First rebase is easy, branch onto master, just like before."

{ set +e; } 2>/dev/null
showcmd "Move branch two" 3<<'SCRIPT'
git rebase \
    _rebase/1/step_one \
    add_files/2/step_two \
    --onto add_files/1/step_one
SCRIPT
{ set -e; } 2>/dev/null

swsg 3<<EOM
Ah right, we do have a legitimate merge conflict.
Let's resolve that as before, taking the upstream commit and fixing the message.
EOM

show_single_cmd git status
describe_file file_b.txt
nl

showcmd "Fix the merge conflict" 3<<'SCRIPT'
    git checkout --ours file_b.txt
    git add file_b.txt
    git rebase --continue
    git commit --amend -m "Add file_d.txt"
SCRIPT

show_single_cmd git_lg --all
wsg "Ok, good to go. Let's finish up the rest of our stacked rebase!"

showcmd "Move branch three" 3<<'SCRIPT'
git rebase \
    _rebase/2/step_two \
    add_files/3/step_three \
    --onto add_files/2/step_two
SCRIPT
showcmd "Move branch four" 3<<'SCRIPT'
git rebase \
    _rebase/3/step_three \
    add_files/4/step_four \
    --onto add_files/3/step_three
SCRIPT

show_single_cmd git_lg --all
wsg "This is a lot to digest, so let's break it down."

show_single_cmd git_lg master~2..add_files/4/step_four
swsg 3<<EOM
This is our stack, linear, rebased on master, and ready for us to keep working.
EOM

show_single_cmd git_lg master~2.._rebase/4/step_four
swsg 3<<EOM
This is the linear history we came from. It's the stuff we don't need anymore,
so let's clean it up and then see what our graph looks like!
EOM

showcmd "Clean up the temporary rebase tags" 3<<SCRIPT
    git tag -d _rebase/1/step_one
    git tag -d _rebase/2/step_two
    git tag -d _rebase/3/step_three
    git tag -d _rebase/4/step_four
SCRIPT

show_single_cmd git_lg --all
smsg 3<<EOM
There we go! That could have gone a lot worse. Temporary tags are shaping up to
be a pretty reasonable answer for us!
EOM
