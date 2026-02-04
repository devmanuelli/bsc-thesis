// Example 4: Multiple Conditions with AND
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.projects[0] << { name = "API Server", status = "in_progress", language = "Python" }
        data.projects[1] << { name = "Frontend", status = "completed", language = "JavaScript" }
        data.projects[2] << { name = "Data Pipeline", status = "in_progress", language = "Python" }
        data.projects[3] << { name = "Mobile App", status = "in_progress", language = "Kotlin" }

        // Query: In-progress Python projects
        active_python << values data.projects[*] where
            $.status == "in_progress" &&
            $.language == "Python"

        // Verify results
        println@Console("Example 4: Multiple Conditions with AND")();
        println@Console("Expected: API Server and Data Pipeline")();
        println@Console("Got: " + #active_python.results + " results")();

        for (i = 0, i < #active_python.results, i++) {
            println@Console("  - " + active_python.results[i].name)()
        };

        if (#active_python.results == 2 &&
            active_python.results[0].name == "API Server" &&
            active_python.results[1].name == "Data Pipeline") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
