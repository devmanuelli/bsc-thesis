// Example 11: PATHS vs VALUES
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        inventory.items[0] << { name = "Laptop", price = 1200 }
        inventory.items[1] << { name = "Mouse", price = 25 }
        inventory.items[2] << { name = "Monitor", price = 450 }

        // Using VALUES
        println@Console("=== Using VALUES ===")();
        expensive_values << values inventory.items[*] where $.price > 100
        println@Console("Number of results: " + #expensive_values.results)();
        for (i = 0, i < #expensive_values.results, i++) {
            println@Console("  " + expensive_values.results[i].name + ": $" + expensive_values.results[i].price)()
        };

        // Using PATHS
        println@Console("\n=== Using PATHS ===")();
        expensive_paths << paths inventory.items[*] where $.price > 100
        println@Console("Number of paths: " + #expensive_paths.results)();
        for (i = 0, i < #expensive_paths.results, i++) {
            println@Console("  Path: " + expensive_paths.results[i])();
            // Dereference path to get actual value
            item << pval(expensive_paths.results[i]);
            println@Console("    -> " + item.name + ": $" + item.price)()
        };

        // Verify
        if (#expensive_values.results == 2 && #expensive_paths.results == 2) {
            println@Console("\n✅ PASSED")()
        } else {
            println@Console("\n❌ FAILED")()
        }
    }
}
