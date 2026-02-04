// Example 3: Array Matching (Existential Semantics)
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.tasks[0] << {
            title = "Fix bug #123",
            tags[0] = "backend",
            tags[1] = "urgent",
            tags[2] = "security"
        }
        data.tasks[1] << {
            title = "Update docs",
            tags[0] = "documentation",
            tags[1] = "low-priority"
        }
        data.tasks[2] << {
            title = "Deploy hotfix",
            tags[0] = "deployment",
            tags[1] = "urgent"
        }

        // Query: Tasks tagged as "urgent"
        urgent << values data.tasks[*] where $.tags[*] == "urgent"

        // Verify results
        println@Console("Example 3: Array Matching (Existential Semantics)")();
        println@Console("Expected: tasks[0] and tasks[2]")();
        println@Console("Got: " + #urgent.results + " results")();

        for (i = 0, i < #urgent.results, i++) {
            println@Console("  - " + urgent.results[i].title)()
        };

        if (#urgent.results == 2 &&
            urgent.results[0].title == "Fix bug #123" &&
            urgent.results[1].title == "Deploy hotfix") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
