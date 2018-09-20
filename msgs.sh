nl() {
    echo ""
}

title() {
    echo "$@"
    echo "========================================"
    read -p "Press 'Return' key to continue..."
    nl
}
msg() {
    nl
    nl
    echo "$@"
    echo "----------------------------------------"
    nl
}

wsg() {
    nl
    nl
    echo "$@"
    echo "----------------------------------------"
    read -p "Press 'Return' key to continue..."
    nl
}

describe_file() {
    echo "File '$1'"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    cat $1
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}
