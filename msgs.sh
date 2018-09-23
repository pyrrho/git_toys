#!/usr/bin/env bash

source ./formatting.sh

nl() {
    echo -e ""
}

title() {
    echo -e "$@"
    echo -e "========================================"
    read -p "Press 'Return' key to continue..."
    nl
}
stitle() {
    cat <&3
    echo -e "========================================"
    read -p "Press 'Return' key to continue..."
    nl
}

msg() {
    nl
    nl
    echo -e "$@"
    echo -e "----------------------------------------"
    nl
}
smsg() {
    nl
    nl
    cat <&3
    echo -e "----------------------------------------"
    nl
}

wsg() {
    nl
    nl
    echo -e "$@"
    echo -e "----------------------------------------"
    read -p "Press 'Return' key to continue..."
    nl
}
swsg() {
    nl
    nl
    cat <&3
    echo -e "----------------------------------------"
    read -p "Press 'Return' key to continue..."
    nl
}

describe_file() {
    echo -e "File '$1'"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    cat $1
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}

showcmd() {
    cmds=$(cat <&3)
    (   
        set +u
        if [ "$1" != "" ]; then
            echo "${SO_UNDERLINED}${1}${SO_RESET}"
        fi
        set -u
        echo "${cmds}" 2>&1 | sed 's/^[[:blank:]]*/$ /'
        eval "${cmds}" 2>&1 | sed "s/^/${SO_DIM}> ${SO_RESET}/"
    ) | sed 's/^//'
    nl
}

show_single_cmd() {
    echo "$@" | (
        exec 3<&0
        showcmd
    )
}
