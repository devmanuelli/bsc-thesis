// Example 5: The HAS Operator
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.requests[0] << {
            title = "Sprint Planning",
            participants[0] = "Alice",
            participants[1] = "Bob"
        }
        data.requests[1].title = "Solo Review"
        // No participants field

        // Query: Requests where participants field exists
        with_participants << values data.requests[*] where $ has "participants"

        // Verify results
        println@Console("Example 5: The HAS Operator")();
        println@Console("Expected: requests[0] only")();
        println@Console("Got: " + #with_participants.results + " result(s)")();

        for (i = 0, i < #with_participants.results, i++) {
            println@Console("  - " + with_participants.results[i].title)()
        };

        if (#with_participants.results == 1 &&
            with_participants.results[0].title == "Sprint Planning") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
