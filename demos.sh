demonstrate_multi_line_echo() {
    echo "This is a multi-line"\
         "echo. The printed text isn't on multiple lines."\
         "\nExcept when I want it"\
         "to be."\
         "\nBe careful, though. If you end a line with a \\\\n...\n"\
         "This happens. :C"
}

demonstrate_multi_line_function_argument_impl() {
    echo "$@"
}

demonstrate_multi_line_function_argument() {
    demonstrate_multi_line_function_argument_impl \
        "This is a multi-line"\
        "function call..."\
        "Passed into echo."\
        "\nThe printed text isn't on multiple lines."\
        "\nExcept when I want it"\
        "to be."\
        "\nBe careful, though. If you end a line with a \\\\n...\n"\
        "This happens. :C"
}
