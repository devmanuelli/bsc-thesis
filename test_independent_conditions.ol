from console import Console

service Main {
    embed Console as Console

    main {
        // Create test data with Matteo Maggio and Roberto Rossi
        data.employees[0].name = "Matteo";
        data.employees[0].surname = "Maggio";
        data.employees[1].name = "Roberto";
        data.employees[1].surname = "Rossi";

        println@Console("Test data:")();
        println@Console("- Employee 1: " + data.employees[0].name + " " + data.employees[0].surname)();
        println@Console("- Employee 2: " + data.employees[1].name + " " + data.employees[1].surname)();
        println@Console("")();

        // Query for employees where name=="Matteo" AND surname=="Rossi"
        // This will match even though no single employee has both!
        result << values data where
            $.employees[*].name == "Matteo" &&
            $.employees[*].surname == "Rossi";

        println@Console("Query: values data where $.employees[*].name == \"Matteo\" && $.employees[*].surname == \"Rossi\"")();
        println@Console("")();

        if (#result.results > 0) {
            println@Console("Result: MATCHED (data value returned)")();
            println@Console("Reason: Conditions are evaluated independently:")();
            println@Console("  - $.employees[*].name == \"Matteo\" → TRUE (Matteo Maggio exists)")();
            println@Console("  - $.employees[*].surname == \"Rossi\" → TRUE (Roberto Rossi exists)")();
            println@Console("  - TRUE && TRUE → TRUE")();
            println@Console("")();
            println@Console("Note: No single employee has BOTH name=\"Matteo\" AND surname=\"Rossi\",")();
            println@Console("      but the query matches because conditions check ANY element independently.")()
        } else {
            println@Console("Result: NO MATCH")();
            println@Console("(This would be unexpected!)")()
        }
    }
}
