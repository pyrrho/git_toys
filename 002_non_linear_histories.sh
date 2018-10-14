#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ./msgs.sh
source ./gits.sh
source ./operations.sh

stitle 3<<EOM
This is going to be another happy-path demonstration (mostly), this timeshowing
off a non-linearized history (and the issues that can arise from said history).
EOM

reset_repo

msg "Files and branches incoming..."

showcmd "Set up master" 3<<'SCRIPT'
    echo -e "Here is our first file" > file_a.txt
    git add file_a.txt
    git commit -m "Add file_a.txt"
SCRIPT

showcmd "First branch: add file_b.txt" 3<<'SCRIPT'
    git_co -b new_files/1/file_b.txt

    echo -e "Here's another file." > file_b.txt
    git add file_b.txt
    git commit -m "Add file_b.txt"
SCRIPT

showcmd "Second branch: add file_c.txt" 3<<'SCRIPT'
    git_co -b new_files/2/file_c.txt

    echo -e "A third one...." > file_c.txt
    git add file_c.txt
    git commit -m "Add file_c.txt"
SCRIPT

showcmd "Third branch: add file_d.txt" 3<<'SCRIPT'
    git_co -b new_files/3/file_d.txt

    echo -e "And a fourth, for good measure" > file_d.txt
    git add file_d.txt
    git commit -m "Add file_d.txt"
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
If you've seen the previous demo, this state should look familiar to you.

Let's take a look at what would happen if we were to find a bug in file_b.txt
(added in new_files/1), _after_ new_files/2 and new_files/3 were pushed to our
central repository.

A fix will need to be applied. Obviously. But where?

Branch new_files/3 -- the latest in our stack, and the current HEAD -- doesn't
have anything to do with file_b, so the fix doesn't 'fit' there. We could make
a new branch, but then the flaw will remain in all previous branches and CI
might spuriously fail.

Well, new_files/2 is a branch, so we can add commits to it. Let's just do that.
EOM

showcmd "Check on file_b.txt ..." 3<<'SCRIPT'
    git_co new_files/1/file_b.txt
    describe_file file_b.txt
SCRIPT
showcmd "... then edit and commit it" 3<<'SCRIPT'
    sed -i '' 's/another/an amazing/' file_b.txt
    describe_file file_b.txt

    git ci file_b.txt -m "Fixed a bug in file_b.txt"
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
This corrects the issue at new_files/1, but now there's an actual fork in our
history. Neuther new_files/2 nor new_files/3 can see the fix, so they're still
broken. It's all correct and valid, but it looks a little off, doesn't it?

We do know that the change we made won't trigger a conflict -- it can't,
because none of the other commits touch file_b.txt -- so let's go ahead and
collapse this stack.
EOM


showcmd "Merge the new_files stack" 3<<'SCRIPT'
    git_co new_files/2/file_c.txt
    git_merge_branch new_files/3/file_d.txt

    git_co new_files/1/file_b.txt
    git_merge_branch new_files/2/file_c.txt

    git_co master
    git_merge_branch new_files/1/file_b.txt
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
And there you have a non-conflicting branch revision, merged without
linearizing the history. And you can even see that the fix was applied to
new_files/1 after new_files/2 was branched. Which I think is pretty cool.

It's nice when it works like this, but unfortunately you (or rather, git) won't
know if there's going to be a conflict with this pattern until you start
merging.

Here. Check this out.
EOM


smsg 3<<EOM
Resetting the repo...
EOM

cd_root
reset_repo

showcmd "Set up the history" 3<<'SCRIPT'
    echo -e "Here is our first file" > file_a.txt
    git add file_a.txt
    git commit -m "Add file_a.txt"

    git_co -b new_files/1/file_b.txt
    echo -e "Here's another file." > file_b.txt
    git add file_b.txt
    git commit -m "Add file_b.txt"

    git_co -b new_files/2/file_c.txt
    echo -e "A third one...." > file_c.txt
    git add file_c.txt
    git commit -m "Add file_c.txt"

    git_co -b new_files/3/file_d.txt
    echo -e "And a fourth, for good measure" > file_d.txt
    git add file_d.txt
    git commit -m "Add file_d.txt"
SCRIPT

showcmd "Check on file_b.txt in new_files/3..." 3<<'SCRIPT'
    git_co new_files/3/file_d.txt
    describe_file file_b.txt
SCRIPT
showcmd "... then edit and commit it" 3<<'SCRIPT'
    sed -i '' 's/another/an important/' file_b.txt
    describe_file file_b.txt

    git ci file_b.txt -m "Squashed a bug in file_b.txt [Hey look! A conflict!]"
SCRIPT

showcmd "Check on file_b.txt in new_files/1..." 3<<'SCRIPT'
    git_co new_files/1/file_b.txt
    describe_file file_b.txt
SCRIPT
showcmd "... then edit and commit it" 3<<'SCRIPT'
    sed -i '' 's/another/an amazing/' file_b.txt
    describe_file file_b.txt

    git ci file_b.txt -m "Fixed a bug in file_b.txt"
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
So here we are again, with a history much like the non-conflicting one we just
collapsed.

This history, however, has two commits that edit file_b.txt, and those commits
live in two separate branches.

Do you see where this is going?
EOM

showcmd "Merge new_files/3/file_d.txt" 3<<'SCRIPT'
    git_co new_files/2/file_c.txt
    git_merge_branch new_files/3/file_d.txt
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
We've now merged new_files/3 into new_files/2, and that merge succeeded.

This history might be a little confusing to look at since we're in the middle of
a collapse. I paused here to highlight the fact that this merge succeeded, that
this history is actually correct, and that it's... well... a little confusing
to look at.

Let's continue, and see what happens when we merge the combined new_files/2 +
new_files/3 into new_files/1...
EOM

{ set +e; } 2>/dev/null
showcmd "Merge new_files/2/file_c.txt" 3<<'SCRIPT'
    git_co new_files/1/file_b.txt
    git_merge_branch new_files/2/file_c.txt
SCRIPT
{ set -e; } 2>/dev/null

describe_file file_b.txt

swsg 3<<EOM
Here we are at the merge conflict I was teasing previously.
EOM

swsg 3<<EOM
The really imporant note here is that git didn't fail until we attempted to
merge the conflicting histories, halfway through the stack collapse operation.

If we were doing this in GitHub or another system that required reviews prior
to a merge, we'd be in a tough spot. We could modify new_files/2 prior to
merging it into new_files/1 and re-request a review for that branch -- a branch
that now contains all of its original changes, all changes from branches higher
in the stack, _and_ the changes required to resolve the merge conflict. We could
revert the merges that had already been done and fix the conflict in a clean
new_files/3 (how one would un-merge the sack, or prove that the merge conflict
was resolved is left as an exercise for the reader). Or maybe we could open a
new branch (new_files/2.5/fix_merge_conflicts?) targeting the half collapsed
stack --- a branching structure that is sure to confuse no one at all.
</scarcasm>

I won't speak for anyone else, but none of these seem like a good choice to me.
Let's move on to a better solution.
EOM

