// Example 8: Grandfather Name-Matching
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data._[0] << {
            name = "John",
            surname = "Smith",
            sex = "Male",
            children[0] << {
                name = "Mary",
                children[0] << { name = "John", surname = "Doe" },
                children[1] << { name = "Emma", surname = "Doe" }
            }
        }
        data._[1] << {
            name = "Robert",
            surname = "Jones",
            sex = "Male",
            children[0] << {
                name = "Sarah",
                children[0] << { name = "Michael", surname = "Brown" }
            }
        }

        // Query: Grandfathers whose name matches a grandchild
        matching << values data._[*] where
            $.sex == "Male" &&
            $.children[*].children[*].name == $.name

        // Verify results
        println@Console("Example 8: Grandfather Name-Matching")();
        println@Console("Expected: John Smith")();
        println@Console("Got: " + #matching.results + " result(s)")();

        for (i = 0, i < #matching.results, i++) {
            println@Console("  - " + matching.results[i].name + " " + matching.results[i].surname)()
        };

        if (#matching.results == 1 &&
            matching.results[0].name == "John" &&
            matching.results[0].surname == "Smith") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
