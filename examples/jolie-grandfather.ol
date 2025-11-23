from console import Console
from file import File

service Main {
    embed Console as Console
    embed File as File

    main {
        // Read JSON file
        readFile@File({
            filename = "../tests/test-data.json"
            format = "json"
        })(data);

        // Find matching grandfathers
        for (person in data._) {
            if (person.sex == "Male") {
                for (child in person.children) {
                    for (grandchild in child.children) {
                        if (grandchild.name == person.name) {
                            result[#result] << person
                        }
                    }
                }
            }
        };

        // Print results
        for (i = 0, i < #result, i++) {
            println@Console("Found: " + result[i].name + " " + result[i].surname)()
        }
    }
}
