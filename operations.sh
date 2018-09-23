DEMO_ROOT_DIR="$(pwd)"
cd_root() {
    cd ${DEMO_ROOT_DIR}
}

reset_repo() {
    if [ -d repo ]; then
        rm -rf repo
    fi
    mkdir repo
    cd repo

    git init .
    { set -x; } 2>/dev/null
    git commit --allow-empty -m "First Commit"
    { set +x; } 2>/dev/null
}
