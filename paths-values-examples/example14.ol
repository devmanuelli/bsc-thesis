// Example 14: OR Conditions
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.users[0] << { name = "Alice", role = "admin" }
        data.users[1] << { name = "Bob", role = "user" }
        data.users[2] << { name = "Charlie", role = "moderator" }
        data.users[3] << { name = "Dave", role = "user" }

        // Query: Admins OR moderators
        staff << values data.users[*] where
            $.role == "admin" ||
            $.role == "moderator"

        // Verify results
        println@Console("Example 14: OR Conditions")();
        println@Console("Expected: Alice and Charlie")();
        println@Console("Got: " + #staff.results + " results")();

        for (i = 0, i < #staff.results, i++) {
            println@Console("  - " + staff.results[i].name + " (" + staff.results[i].role + ")")()
        };

        if (#staff.results == 2 &&
            staff.results[0].name == "Alice" &&
            staff.results[1].name == "Charlie") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
