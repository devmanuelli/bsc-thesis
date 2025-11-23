from console import Console
from file import File
from @jolie.tquery.main import TQuery

service Main {
    embed Console as Console
    embed File as File
    embed TQuery as TQuery

    main {
        // Read JSON file
        readFile@File({
            filename = "../tests/test-data.json"
            format = "json"
        })(data);

        // TQuery Pipeline: unwind → filter sex → match names
        stages[0].unwindQuery = "_.children.children";
        stages[1].matchQuery.equal << { path = "_.sex" data = "Male" };
        stages[2].matchQuery.equal << { left = "_.name" right = "_.children.children.name" };

        pipeline@TQuery({ data << data pipeline << stages })(filtered);

        // ================================================================
        // Print results
        // ================================================================
        for (i = 0, i < #filtered.result, i++) {
            person -> filtered.result[i]._;
            println@Console("Found: " + person.name + " " + person.surname)()
        }
    }
}
