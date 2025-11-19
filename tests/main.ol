from file import File
from console import Console

service Main {
    embed File as File
    embed Console as Console

    main {
        readFile@File({
            filename = "test-data.json"
            format = "json"
        })(data);

        res << values data._[*] where $.sex == "Male" && $.name == $.children[*].children[*].name

        println@Console("Found " + #res.results + " matching grandfathers:")();
        i = 0;
        while (i < #res.results) {
            println@Console("- " + res.results[i].name + " " + res.results[i].surname)();
            i++
        }
    }
}
