// Example 13: Complex Filtering
from console import Console

service Main {
    embed Console as Console

    main {
        // Data
        data.products[0] << {
            name = "Laptop",
            price = 1200,
            category = "electronics",
            inStock = true,
            tags[0] = "computers",
            tags[1] = "sale"
        }
        data.products[1] << {
            name = "Desk",
            price = 300,
            category = "furniture",
            inStock = false,
            tags[0] = "office"
        }
        data.products[2] << {
            name = "Monitor",
            price = 400,
            category = "electronics",
            inStock = true,
            tags[0] = "computers",
            tags[1] = "display",
            tags[2] = "sale"
        }

        // Find: electronics, in stock, on sale
        deals << values data.products[*] where
            $.category == "electronics" &&
            $.inStock == true &&
            $.tags[*] == "sale"

        // Verify results
        println@Console("Example 13: Complex Filtering")();
        println@Console("Expected: Laptop and Monitor")();
        println@Console("Got: " + #deals.results + " results")();

        for (i = 0, i < #deals.results, i++) {
            println@Console("  - " + deals.results[i].name)()
        };

        if (#deals.results == 2 &&
            deals.results[0].name == "Laptop" &&
            deals.results[1].name == "Monitor") {
            println@Console("✅ PASSED")()
        } else {
            println@Console("❌ FAILED")()
        }
    }
}
