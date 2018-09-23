#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ./msgs.sh
source ./gits.sh
source ./demos.sh
source ./operations.sh

stitle 3<<EOM
One of the more common causes for a stack rebase is a wandering master.
Let's take a look at what happens when you need to rebase an entire stack onto a
new master. Specifically what can go wrong.
EOM

reset_repo
nl
showcmd "Set up master" 3<<'SCRIPT'
    echo -e "Here is our first file" > file_a.txt
    git add file_a.txt
    git commit -m "Add file_a.txt"

    echo -e "Here's another file." > file_b.txt
    git add file_b.txt
    git commit -m "Add file_b.txt"
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
Here we are again, ready to start building a stack off of master. This time,
though, master already has a few files in place for us to work off of.

Let's get started.
EOM

showcmd "Fist branch" 3<<'SCRIPT'
    git_co -b add_files/1/step_one
    echo -e "A third one...." > file_c.txt
    git add file_c.txt
    git commit -m "Add file_c.txt"
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
file_c.txt was added, easy peasy. Next up is file_d.txt.

For this demo, let's pretend file_d.txt relies on file_b.txt, and that
file_b.txt has a bug in it that we found while adding file_d.txt.

Instead of just adding file_d.txt in this branch, we're going to also fix the
bug in file_b.txt.
EOM

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

show_single_cmd git_lg --all

swsg 3<<EOM
That's that. Let's keep going with this stack.
EOM

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
There we have it. Four branches, all neatly stacked, linearized, and ready to
collapse into master.

Today, though, we're not the only ones working on this project. While we were
getting the add_files stack ready, someone else found that bug in file_b.txt
that we quickly patched, and gave it a proper fixing.

Let's update master and see where everything stands.
EOM

showcmd "Another developer fixes file_b..." 3<<'SCRIPT'
    git_co -b bug_fix master
    echo -e "Here's an important and amazing file." >| file_b.txt
    git add file_b.txt
    git commit -m "Resolve a bug that was in file_b.txt"
SCRIPT

showcmd "And their feature branch is merged" 3<<'SCRIPT'
    git_co master
    git_merge_branch bug_fix
    git branch -d bug_fix
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
Looks like we're not so linearized anymore.

Our stack is still linear, but master has moved. We might (read: definitely
do) have a conflict with what's been added to master since we opened this stack.

We already have an answer to this problem; git rebase --onto.
EOM

showcmd "Move the first branch" 3<<'SCRIPT'
    git rebase master add_files/1/step_one --onto master
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
The first branch in the stack moved over just fine.

The second branch contains that quick patch to file_b.txt. Got a guess as to
what's about to happen?
EOM

{ set +e; } 2>/dev/null
showcmd "Move the second branch" 3<<'SCRIPT'
    git rebase add_files/1/step_one add_files/2/step_two --onto add_files/1/step_one
SCRIPT

swsg 3<<EOM
Oh goodness.
A rebase conflict.
Wow.
EOM

show_single_cmd git status
nl
describe_file file_b.txt

swsg 3<<EOM
As expected, our change to file_b.txt conflicts with what's currently on master,
specifically what was brought in by the dedicated fix.

Because we know that the code in master (the current base) is the correct code
to resolve with, we can use some shorthand to resolve this conflict;
git checkout --ours
EOM

showcmd "Fix the rebase conflict" 3<<'SCRIPT'
    git checkout --ours file_b.txt
    git add file_b.txt
    git rebase --continue
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
The file_b merge conflict has been resolved, so now---

Wait. I'm sorry. That commit message.

We're no longer including a fix for file_b.txt in this commit, so we should
update the message to reflect that. Good git citizenship, and all that.
EOM

showcmd "Ammend our git commit message..." 3<<'SCRIPT'
    git commit --amend -m "Add file_d.txt"
SCRIPT

show_single_cmd git_lg --all


swsg 3<<EOM
Okay. That's much better.

The file_b.txt merge conflict has been resolved, so now we can continue rebasing
this stack.
EOM

{ set +e; } 2>/dev/null
showcmd "Move the third branch" 3<<'SCRIPT'
    git rebase add_files/2/step_two add_files/3/step_three --onto add_files/2/step_two
SCRIPT
{ set -e; } 2>/dev/null

swsg 3<<EOM
Wait. Another merge conflic?

Let's take a look at what's going on.
EOM

show_single_cmd git status

swsg 3<<EOM
Okay, file_b.txt is conflicting. Again? Let's see what git has to say about it's
current state.
EOM

show_single_cmd git diff

swsg 3<<EOM
Well that's... something. git diff is coming up blank?

What does the file actually look like right now?
EOM

describe_file file_b.txt

swsg 3<<EOM
Message text
In addition to git diff coming up blank, file_b.txt is definitely in the state
that we want it to be in.

Maybe if we take a closer look at the rebase conflict message, we'll be
able to figure out what's going on.
EOM

swsg 3<<EOM
    First, rewinding head to replay your work on top of it...
    Applying: Add file_d.txt, fix a bug in file_b.txt
    . . .
    The copy of the patch that failed is found in: .git/rebase-apply/patch

Ah ha! It's trying to apply the *old version* of the file_d.txt addition, where
we patched file_b.txt, and still used the commit message,
"Add file_d.txt, fix a bug in file_b.txt"

Let's take a look at the failing patch file.
EOM

cat .git/rebase-apply/patch

swsg 3<<EOM
There are two changes in here. One is /dev/null to b/file_d.txt (which is the
addition of file_d.txt), and the other is a/file_b.txt to b/file_b.txt (the
modification of file_b.txt).

Looking at the body of that patch, we can see why it failed to land; the
contents of file_b.txt at this point in our rebased history is different from
what this commit -- the old version of this commit, specifically -- expected it
to be.
EOM

smsg 3<<EOM
To clarify, the root problem here isn't the content of the commit we're trying
to apply, it's that we're trying to apply this commit at all.

When we ran the command to rebase add_files/3/step_three onto the new version of
add_files/2/step_two we did something very naive;

    git rebase add_files/2/step_two add_files/3/step_three --onto add_files/2/step_two

We asked git move the range of commits between the *new version* of
add_files/2/step_two and add_files/3/step_three, and use the new version of
add_files/2/step_two as a new base.

Because the history between master and add_files/2/step_two is now fundamentally
different than the history between master and the *old version* of
add_files/2/step_two, this is effectively impossible. We're asking git to move a
fork in our repository's history onto the tip of one of the tongs of that fork.
Nonsense.

What we need to be doing is asking git to move the range of commits between the
old version of add_files/2/step_two and add_files/3/step_three, and use the new
version of add_files/2/step_two as a new base.

Check out the next demo to see how we can do that.
EOM
