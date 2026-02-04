// Example 2: Filtering by Age
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.users[0] << { name = "Alice", age = 30, country = "USA" }
        data.users[1] << { name = "Bob", age = 17, country = "Canada" }
        data.users[2] << { name = "Charlie", age = 25, country = "UK" }

        // Query: Users 18 or older
        adults << values data.users[*] where $.age >= 18

        // Verify results
        println@Console("Example 2: Filtering by Age")();
        println@Console("Expected: Alice and Charlie")();
        println@Console("Got: " + #adults.results + " results")();

        for (i = 0, i < #adults.results, i++) {
            println@Console("  - " + adults.results[i].name + " (age " + adults.results[i].age + ")")()
        };

        if (#adults.results == 2 &&
            adults.results[0].name == "Alice" &&
            adults.results[1].name == "Charlie") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
