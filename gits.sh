# Set a git pager tha I know how to work with...
GIT_PAGER="less -F -X"

git_lg() {
    git log $@ --color=always --graph --abbrev-commit --date=iso --decorate --format=format:'%C(yellow)%h%C(reset) - %s %C(yellow)%d%C(reset)'
}

git_clean_branches() {
    git branch --merged master | grep -ve 'master' -e '[*]' | xargs -n1 git branch -d
}

git_merge_branch() {
    git merge --no-ff --no-edit $@
}

git_co() {
    git checkout $@
}
