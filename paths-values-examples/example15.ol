// Example 15: Array Size Filtering
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.meetings[0] << {
            title = "Daily Standup",
            participants[0] = "Alice",
            participants[1] = "Bob",
            participants[2] = "Charlie",
            participants[3] = "Dave"
        }
        data.meetings[1] << {
            title = "1-on-1",
            participants[0] = "Alice",
            participants[1] = "Bob"
        }
        data.meetings[2] << {
            title = "Team Planning",
            participants[0] = "Alice",
            participants[1] = "Bob",
            participants[2] = "Charlie"
        }
        data.meetings[3] << {
            title = "Quick Chat",
            participants[0] = "Alice"
        }

        // Query: Meetings with more than 2 participants
        large_meetings << values data.meetings[*] where #$.participants > 2

        // Verify results
        println@Console("Example 15: Array Size Filtering")();
        println@Console("Expected: Daily Standup and Team Planning")();
        println@Console("Got: " + #large_meetings.results + " results")();

        for (i = 0, i < #large_meetings.results, i++) {
            println@Console("  - " + large_meetings.results[i].title +
                          " (" + #large_meetings.results[i].participants + " participants)")()
        };

        if (#large_meetings.results == 2 &&
            large_meetings.results[0].title == "Daily Standup" &&
            large_meetings.results[1].title == "Team Planning") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
