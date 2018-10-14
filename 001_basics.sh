#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

source ./msgs.sh
source ./gits.sh
source ./operations.sh

stitle 3<<EOM
This demo will show off the simplest form of stacked git branches. It will be
linear, contain no conflicts, and resolve without issue.
This is a very simple demonstration of the happiest-path.
EOM
reset_repo

msg "The the repository has been initialized. Let's add a file..."

showcmd "file_a.txt" 3<<'SCRIPT'
    echo -e "Here is our first file" > file_a.txt
    describe_file file_a.txt
    git add file_a.txt
    git commit -m "Add file_a.txt"
SCRIPT

swsg 3<<EOM
A repository has been initialized, and we've added a file.

Let's add a couple more files, this time in a stack.
EOM

showcmd "First branch: add file_b.txt" 3<<'SCRIPT'
    git_co -b new_files/1/file_b.txt

    echo -e "Here's another file." > file_b.txt
    describe_file file_b.txt

    git add file_b.txt
    git commit -m "Add file_b.txt"
SCRIPT


showcmd "Second branch: add file_c.txt" 3<<'SCRIPT'
    git_co -b new_files/2/file_c.txt

    echo -e "A third one...." > file_c.txt
    describe_file file_c.txt

    git add file_c.txt
    git commit -m "Add file_c.txt"
SCRIPT

showcmd "Third branch: add file_d.txt" 3<<'SCRIPT'
    git_co -b new_files/3/file_d.txt

    echo -e "And a fourth, for good measure" > file_d.txt
    describe_file file_d.txt

    git add file_d.txt
    git commit -m "Add file_d.txt"
SCRIPT

swsg 3<<EOM
Now we have a few files, and a few branches waiting to be merged.

Let's take a look at the git log as a graph...
EOM

show_single_cmd git_lg --all

swsg 3<<EOM
Well that's... pretty unremarkable, actually.

Note that every commit is on it's own branch, though. This would look much more
impressive if each of these branches added a full blown feature rather than a
single file. If each associated PR included 10 commits spanning 20 files, the
separation of new_files/2 from new_files/3 would have significant impact for
reviewers. If new_files/1 was a pile of whitespace changes, those modifications
wouldn't be conflated with the meaningful changes elsewhere in the stack.

That's not the case, but we can pretend, yeah?

Anyway. Let's collapse this sucker, and merge the child branches into their
respective parents.
EOM

showcmd "Merge new_files/3/file_d.txt" 3<<'SCRIPT'
    git_co new_files/2/file_c.txt
    git_merge_branch new_files/3/file_d.txt
SCRIPT

showcmd "Merge new_files/2/file_c.txt" 3<<'SCRIPT'
    git_co new_files/1/file_b.txt
    git_merge_branch new_files/2/file_c.txt
SCRIPT

swsg 3<<EOM
Actually, let's pause here for a moment.

We've merged new_files/3 into new_files/2, and new_files/2 into new_files/1.
This is an important moment for this stack as we've aggregated all of the work
down into a single branch, are are about to merge that into master. Let's take a
look at what the graph looks like in this moment.
EOM

show_single_cmd git_lg --all

swsg 3<<EOM
Now this is looking like something.

Did you notice how the order of these branches has been inverted? Instead of
new_files/3 being newer than and denoting something built on top of new_files/2,
new_files/3 is subordinate to the merge commit that is now the head of
new_files/2. Similarly, new_files/1 has subsumed new_files/2 and now
transitively includes the entire stack.

Additionally, the work done in each branch is now recorded in the history of
the repository; each terrace of that little mountain growing out to the right
of the graph is its own discrete piece of work, reviewed and approved
independent of the whole.

The entire stack is still a linear history on top of master -- and that's
actually the whole point. There are a series of branches, but they've all been
merged back down, so what we're about to merge is a straight shot.
EOM

showcmd "Merge new_files/1/file_b.txt" 3<<'SCRIPT'
    git_co master
    git merge --no-ff --no-edit new_files/1/file_b.txt
SCRIPT

show_single_cmd git_lg

swsg 3<<EOM
Now new_files/1 has been merged into master, and the whole stack collapsed. Each
piece of work has been (well... let's pretend they've been) reviewed and
recorded independently.

And that's that. There you have the simplest happy-path.
EOM
