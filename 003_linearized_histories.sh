#!/usr/bin/env bash
set -euo pipefail
IFS=$'
\t'

source ./msgs.sh
source ./gits.sh
source ./operations.sh

stitle 3<<EOM
This is going to build off of the previous demonstration, showing how a
less-than-happy-path merge conflict might be resolved through linearization
via git rebase.
EOM
reset_repo

msg "Files and branches incoming..."

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

show_single_cmd git_lg --all

swsg 3<<EOM
If you've been following along, this setup will look very familiar.

We're going to re-create the conflict we saw in the previous demo by editing
file_b.txt in branches new_files/1 and new_files/2."
EOM


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
Here is the branch structure that eventually lead to a merge conflict in our
prevous demo.

Rather than waiting to find merge conflicts during the stack collapse, let's go
looking for them by using git rebase to linearize the history of this stack.
EOM

showcmd "Move new_files/2 onto the new new_files/1" 3<<'SCRIPT'
    git rebase new_files/1/file_b.txt new_files/2/file_c.txt --onto new_files/1/file_b.txt
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
The first rebase succeeded; new_files/2 is now on top of the fork that
new_files/1 created.

new_files/3 is in it's own version of the history, though, no longer a
descendent of new_files/2 or new_file/1.

Let's continue.
EOM

{ set +e; } 2>/dev/null
showcmd "Move new_file/3 onto the new new_files/2" 3<<'SCRIPT'
    git rebase new_files/2/file_c.txt new_files/3/file_d.txt --onto new_files/2/file_c.txt
SCRIPT
{ set -e; } 2>/dev/null

swsg 3<<EOM
And here we are, back at a conflict. But this time it's in new_files/3 (or
rather, a mid-rebase detached HEAD based on the changes made in new_files/3).

Let's take a look at the state of the repository to make sure we know exactly
what's going on.
EOM

show_single_cmd git status
show_single_cmd describe_file file_b.txt

swsg 3<<EOM
Yep, that looks like a rebase conflict if I've ever seen one.

Let's fix that up by combining the two changes...
EOM

showcmd "Fix the file_b.txt rebase conflict" 3<<'SCRIPT'
    echo -e "Here's an important and amazing file." >| file_b.txt
    describe_file file_b.txt
    git add file_b.txt
    git rebase --continue
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
Now that the rebase conflict is resolved, we're back to a fully linear history.
This merge is now guaranteed to complete without conflict. We could even
fast-forward merge master, but then we'd not know who performed the merge.
EOM

showcmd "Collapse the stack" 3<<'SCRIPT'
    git_co new_files/2/file_c.txt
    git_merge_branch new_files/3/file_d.txt

    git_co new_files/1/file_b.txt
    git_merge_branch new_files/2/file_c.txt

    git_co master
    git_merge_branch new_files/1/file_b.txt
SCRIPT

show_single_cmd git_lg --all

swsg 3<<EOM
This concludes the first series of demos.

Now that the first (few) pitfall(s) have been exposed, and the primary
motivations have been demonstrated, it's time to dig into more corner cases and maybe even show off a bit.
EOM
