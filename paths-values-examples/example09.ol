// Example 9: Deep Hierarchy Navigation
from console import Console

service Main {
    embed Console as Console

    main {
        // Data structure
        data.companies[0] << {
            name = "TechCorp",
            departments[0] << {
                name = "Engineering",
                teams[0] << {
                    name = "Backend",
                    projects[0] << {
                        name = "API",
                        status = "in_progress",
                        technologies[0] = "Python",
                        technologies[1] = "PostgreSQL"
                    },
                    projects[1] << {
                        name = "Frontend",
                        status = "in_progress",
                        technologies[0] = "JavaScript",
                        technologies[1] = "React"
                    }
                },
                teams[1] << {
                    name = "Data",
                    projects[0] << {
                        name = "ETL",
                        status = "in_progress",
                        technologies[0] = "Python",
                        technologies[1] = "Spark"
                    }
                }
            }
        }
        data.companies[1] << {
            name = "FinanceCorp",
            departments[0] << {
                name = "Trading",
                teams[0] << {
                    name = "Algorithms",
                    projects[0] << {
                        name = "HFT",
                        status = "in_progress",
                        technologies[0] = "C++",
                        technologies[1] = "Rust"
                    }
                }
            }
        }

        // Query: In-progress Python projects across entire organization
        python_projects << values data.companies[*].departments[*].teams[*].projects[*]
            where $.status == "in_progress" &&
                  $.technologies[*] == "Python"

        // Verify results
        println@Console("Example 9: Deep Hierarchy Navigation")();
        println@Console("Expected: API and ETL projects")();
        println@Console("Got: " + #python_projects.results + " results")();

        for (i = 0, i < #python_projects.results, i++) {
            println@Console("  - " + python_projects.results[i].name)()
        };

        if (#python_projects.results == 2 &&
            python_projects.results[0].name == "API" &&
            python_projects.results[1].name == "ETL") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
