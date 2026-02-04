// PVAL Example: Array indexing on pval() results
from console import Console

service Main {
    embed Console as Console

    main {
        println@Console("=== PVAL with Array Indexing ===")();

        // Setup data with arrays
        data.users[0] << {
            name = "Alice",
            tags[0] = "admin",
            tags[1] = "developer",
            tags[2] = "reviewer"
        }
        data.users[1] << {
            name = "Bob",
            tags[0] = "user",
            tags[1] = "tester"
        }
        data.users[2] << {
            name = "Charlie",
            tags[0] = "admin",
            tags[1] = "manager",
            tags[2] = "architect",
            tags[3] = "lead"
        }

        // Find admins using PATHS
        adminPaths << paths data.users[*] where $.tags[*] == "admin"
        println@Console("\nFound " + #adminPaths.results + " admins")();

        // Use pval() with array indexing to access specific tags
        println@Console("\n1. Access first admin's second tag:")();
        secondTag = pval(adminPaths.results[0]).tags[1]
        println@Console("   " + pval(adminPaths.results[0]).name + "'s second tag: " + secondTag)();

        println@Console("\n2. Access second admin's third tag:")();
        thirdTag = pval(adminPaths.results[1]).tags[2]
        println@Console("   " + pval(adminPaths.results[1]).name + "'s third tag: " + thirdTag)();

        // Modify array elements through pval
        println@Console("\n3. Modify array element through pval:")();
        println@Console("   Before: " + pval(adminPaths.results[0]).tags[0])();
        pval(adminPaths.results[0]).tags[0] = "superadmin"
        println@Console("   After: " + pval(adminPaths.results[0]).tags[0])();

        // Access specific array elements with literal indices
        // This demonstrates: pval(res.results[n]).field[index]
        println@Console("\n4. Access array elements with literal indices:")();
        tag0 = pval(adminPaths.results[1]).tags[0]
        tag1 = pval(adminPaths.results[1]).tags[1]
        tag2 = pval(adminPaths.results[1]).tags[2]
        tag3 = pval(adminPaths.results[1]).tags[3]
        println@Console("   Charlie's tags:")();
        println@Console("     Tag[0]: " + tag0)();
        println@Console("     Tag[1]: " + tag1)();
        println@Console("     Tag[2]: " + tag2)();
        println@Console("     Tag[3]: " + tag3)();

        // Verify all tests passed
        if (secondTag == "developer" &&
            thirdTag == "architect" &&
            pval(adminPaths.results[0]).tags[0] == "superadmin" &&
            tag0 == "admin" &&
            tag1 == "manager" &&
            tag2 == "architect" &&
            tag3 == "lead") {
            println@Console("\n✅ PASSED - Array indexing with pval() works")()
        } else {
            println@Console("\n❌ FAILED")()
        }
    }
}
