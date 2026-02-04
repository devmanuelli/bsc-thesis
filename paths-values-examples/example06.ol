// Example 6: Combining HAS with Value Checks
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.tasks[0] << { title = "Critical Bug", priority = "high" }
        data.tasks[1].title = "Documentation"
        // No priority field
        data.tasks[2] << { title = "Refactoring", priority = "low" }
        data.tasks[3] << { title = "Security Patch", priority = "high" }

        // Query: High-priority tasks
        high_priority << values data.tasks[*] where
            $ has "priority" &&
            $.priority == "high"

        // Verify results
        println@Console("Example 6: Combining HAS with Value Checks")();
        println@Console("Expected: tasks[0] and tasks[3]")();
        println@Console("Got: " + #high_priority.results + " results")();

        for (i = 0, i < #high_priority.results, i++) {
            println@Console("  - " + high_priority.results[i].title)()
        };

        if (#high_priority.results == 2 &&
            high_priority.results[0].title == "Critical Bug" &&
            high_priority.results[1].title == "Security Patch") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
