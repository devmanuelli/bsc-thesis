from file import File
from console import Console

service Main {
    embed File as File
    embed Console as Console

    main {
        println@Console("Loading large_data.json...")();
        readFile@File({
            filename = "large_data.json"
            format = "json"
        })(data);
        println@Console("Data loaded successfully!")();

        // Debug: check data structure
        println@Console("Number of companies: " + #data.companies)();

        // PATHS/VALUES query - first with true to get all
        println@Console("\nTesting basic navigation...")();
        all_projects << values data.companies[*].company.departments[*].teams[*].projects[*]
            where true;
        println@Console("Total projects: " + #all_projects.results)();

        // Now with status filter only
        in_progress << values data.companies[*].company.departments[*].teams[*].projects[*]
            where $.status == "in_progress";
        println@Console("In progress projects: " + #in_progress.results)();

        // Finally with both filters
        println@Console("Running PATHS/VALUES query with both filters...")();
        results << values data.companies[*].company.departments[*].teams[*].projects[*]
            where $.status == "in_progress" &&
                  $.technologies[*] == "Python";

        println@Console("PATHS/VALUES found: " + #results.results + " matching projects")();

        // Show first 3 results
        println@Console("\nFirst 3 matching projects:")();
        for (i = 0, i < 3 && i < #results.results, i++) {
            println@Console("  - " + results.results[i].project_id + ": " + results.results[i].name + " (status: " + results.results[i].status + ")")()
        }
    }
}
