from file import File
from console import Console

service Main {
    embed File as File
    embed Console as Console

    main {
        // Load the test data
        readFile@File({
            filename = "large_data.json"
            format = "json"
        })(data);

        println@Console("Total companies: " + #data.companies)();

        // Test the PATHS/VALUES query
        result << values data.companies[*].company.departments[*].teams[*].projects[*]
            where $.status == "in_progress" && $.technologies[*] == "Python";

        println@Console("\n=== Query Results ===")();
        println@Console("Found " + #result.results + " projects matching criteria")();
        println@Console("\nFirst 5 results:")();

        i = 0;
        while (i < #result.results && i < 5) {
            println@Console("- Project " + (i + 1) + ":")();
            println@Console("  Name: " + result.results[i].name)();
            println@Console("  Status: " + result.results[i].status)();

            // Print technologies
            tech = "";
            j = 0;
            while (j < #result.results[i].technologies) {
                if (j > 0) {
                    tech += ", "
                };
                tech += result.results[i].technologies[j];
                j++
            };
            println@Console("  Technologies: " + tech)();
            i++
        }
    }
}
