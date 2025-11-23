from console import Console

service Main {
    embed Console as Console

    main {
        a = 42;

        // Access non-existent field in expression
        if (a.nonexistent == "") {
            println@Console("a.nonexistent equals empty string")();
            println@Console("No exception thrown - safe navigation!")()
        } else {
            println@Console("a.nonexistent does NOT equal empty string")();
            println@Console("a.nonexistent value: '" + a.nonexistent + "'")()
        }
    }
}
