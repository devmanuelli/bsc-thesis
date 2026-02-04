// PVAL Example 1: Using pval() as LVALUE (Writing/Modifying Data)
from console import Console

service Main {
    embed Console as Console

    main {
        println@Console("=== PVAL as LVALUE (Writing) ===")();

        // Setup data
        data.users[0] << { name = "Bob", age = 25, address << { city = "Milan", country = "Italy" } }

        // Get a path using PATHS primitive
        userPaths << paths data.users[*] where $.name == "Bob"
        path << userPaths.results[0]

        println@Console("\n1. Field assignment with =")();
        println@Console("Before: " + pval(path).name)();
        pval(path).name = "Robert"
        println@Console("After: " + pval(path).name)();
        println@Console("Verify: " + data.users[0].name)();

        println@Console("\n2. Nested field assignment")();
        println@Console("Before: " + pval(path).address.city)();
        pval(path).address.city = "Florence"
        println@Console("After: " + pval(path).address.city)();
        println@Console("Verify: " + data.users[0].address.city)();

        println@Console("\n3. Field deep copy with <<")();
        newAddress << { city = "Venice", country = "Italy", zipCode = "30100" }
        println@Console("Before has zipCode: " + (pval(path).address has "zipCode"))();
        pval(path).address << newAddress
        println@Console("After city: " + pval(path).address.city)();
        println@Console("After zipCode: " + pval(path).address.zipCode)();
        println@Console("Verify: " + data.users[0].address.zipCode)();

        println@Console("\n4. Root deep copy with <<")();
        newUser << { name = "Roberto", age = 26, status = "active" }
        pval(path) << newUser
        println@Console("After name: " + pval(path).name)();
        println@Console("After age: " + pval(path).age)();
        println@Console("After status: " + pval(path).status)();
        println@Console("Verify: " + data.users[0].status)();

        // Verify all tests
        if (data.users[0].name == "Roberto" &&
            data.users[0].age == 26 &&
            data.users[0].status == "active" &&
            data.users[0].address.zipCode == "30100") {
            println@Console("\n✅ PASSED - All lvalue operations work")()
        } else {
            println@Console("\n❌ FAILED")()
        }
    }
}
