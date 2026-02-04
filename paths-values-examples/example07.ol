// Example 7: Independent Condition Evaluation
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.employees[0] << { name = "Matteo", surname = "Maggio" }
        data.employees[1] << { name = "Roberto", surname = "Rossi" }

        // ⚠️ BE CAREFUL: Querying at data level
        wrong << values data where
            $.employees[*].name == "Matteo" &&
            $.employees[*].surname == "Rossi"

        // ✓ BETTER: Query at employee level
        correct << values data.employees[*] where
            $.name == "Matteo" &&
            $.surname == "Rossi"

        // Verify results
        println@Console("Example 7: Independent Condition Evaluation")();
        println@Console("\nWrong approach (at data level):")();
        println@Console("  Matches: " + #wrong.results + " (should be 1 - the whole data object)")();

        println@Console("\nCorrect approach (at employee level):")();
        println@Console("  Matches: " + #correct.results + " (should be 0 - no employee has both)")();

        if (#wrong.results == 1 && #correct.results == 0) {
            println@Console("\n✅ PASSED - Demonstrates independent evaluation")()
        } else {
            println@Console("\n❌ FAILED")()
        }
    }
}
