// Example 10: Recursive Descent
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.project.status = "active"
        data.project.subprojects[0].status = "pending"
        data.project.subprojects[0].tasks[0].status = "completed"
        data.project.subprojects[1].status = "active"

        // Query: All "active" status values at any depth
        active_statuses << values data..status where $ == "active"

        // Verify results
        println@Console("Example 10: Recursive Descent")();
        println@Console("Expected: 2 'active' statuses")();
        println@Console("Got: " + #active_statuses.results + " results")();

        for (i = 0, i < #active_statuses.results, i++) {
            println@Console("  - " + active_statuses.results[i])()
        };

        if (#active_statuses.results == 2 &&
            active_statuses.results[0] == "active" &&
            active_statuses.results[1] == "active") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
