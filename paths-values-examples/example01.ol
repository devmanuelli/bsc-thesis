// Example 1: Select All (Using WHERE true)
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.cart.items[0] << { name = "Laptop", price = 999 }
        data.cart.items[1] << { name = "Mouse", price = 25 }
        data.cart.items[2] << { name = "Keyboard", price = 75 }

        // Get all items (WHERE clause is mandatory, use "where true" for no filtering)
        all << values data.cart.items[*] where true

        // Verify results
        println@Console("Example 1: Select All")();
        println@Console("Expected: 3 items")();
        println@Console("Got: " + #all.results + " items")();

        for (i = 0, i < #all.results, i++) {
            println@Console("  - " + all.results[i].name + ": $" + all.results[i].price)()
        };

        if (#all.results == 3) {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
