from file import File
from console import Console

service Main {
    embed File as File
    embed Console as Console

    main {
        readFile@File({
            filename = "/home/matteo/jolie/test-data.json"
            format = "json"
        })(data);

        println@Console("Testing grandfather query with data._[*]...")();

        result << values data._[*] where
            $.sex == "Male" &&
            $.name == $.children[*].children[*].name;

        println@Console("Found " + #result.results + " matching grandfathers:")();
        for (i = 0, i < #result.results, i++) {
            println@Console("- " + result.results[i].name + " " + result.results[i].surname)()
        }
    }
}
