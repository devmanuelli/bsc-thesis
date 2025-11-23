from console import Console

service HasOperatorDemo {
    embed Console as Console

    main {
        // Meeting requests with different participant specifications
        requests[0].title = "Sprint Planning";
        requests[0].participants[0] = "Alice";
        requests[0].participants[1] = "Bob";

        requests[1].title = "Solo Review";
        // No participants field - "not specified"

        requests[2].title = "Team Sync";
        requests[2].participants = "";  // Field exists but empty

        println@Console("=== All Requests ===")();
        for (i = 0, i < #requests, i++) {
            println@Console("- " + requests[i].title)()
        };

        println@Console("\n=== Requests WITH 'participants' field (using has) ===")();
        specified << values requests[*] where $ has "participants";

        for (i = 0, i < #specified.results, i++) {
            println@Console("- " + specified.results[i].title)()
        };

        println@Console("\n'Solo Review' filtered out: field absent vs field empty")()
    }
}
