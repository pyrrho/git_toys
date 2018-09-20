nl() {
    echo -e ""
}

title() {
    echo -e "$@"
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

wsg() {
    nl
    nl
    echo -e "$@"
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
