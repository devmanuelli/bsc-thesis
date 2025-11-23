// This file demonstrates that $ is restricted to WHERE clauses
// Attempting to compile this file should produce a parse error:
// "$ can only be used in WHERE clauses"

from console import Console

service DollarRestrictionTest {
    embed Console as Console

    main {
        data[0] = 10;
        data[1] = 20;

        // INVALID: $ outside WHERE clause
        x = $;  // Parse error: $ can only be used in WHERE clauses
    }
}
