// Example 12: Finding Incomplete Records
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.users[0] << { name = "Alice", email = "alice@example.com", phone = "555-1234" }
        data.users[1] << { name = "Bob", email = "bob@example.com" }
        data.users[2] << { name = "Charlie", phone = "555-5678" }

        // Query: Users missing email
        incomplete << values data.users[*] where !($ has "email")

        // Verify results
        println@Console("Example 12: Finding Incomplete Records")();
        println@Console("Expected: Charlie (missing email)")();
        println@Console("Got: " + #incomplete.results + " result(s)")();

        for (i = 0, i < #incomplete.results, i++) {
            println@Console("  - " + incomplete.results[i].name)()
        };

        if (#incomplete.results == 1 &&
            incomplete.results[0].name == "Charlie") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
