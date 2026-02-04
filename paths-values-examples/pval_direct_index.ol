// Test: Can we do pval(path)[n] directly?
from console import Console

service Main {
    embed Console as Console

    main {
        println@Console("=== Test pval(path)[n] directly ===")();

        // Setup: Create temporary arrays, then assign them
        temp1[0] = 10
        temp1[1] = 20
        temp1[2] = 30
        data.items[0] << temp1

        temp2[0] = 100
        temp2[1] = 200
        data.items[1] << temp2

        temp3[0] = 1000
        temp3[1] = 2000
        temp3[2] = 3000
        temp3[3] = 4000
        data.items[2] << temp3

        // Get paths to all items (use true since $[0] might not work)
        itemPaths << paths data.items[*] where true
        println@Console("\nFound " + #itemPaths.results + " items")();

        // Try to index pval() result directly
        println@Console("\n1. Try pval(path)[0]:")();
        firstElem = pval(itemPaths.results[0])[0]
        println@Console("   First element: " + firstElem)();

        println@Console("\n2. Try pval(path)[1]:")();
        secondElem = pval(itemPaths.results[0])[1]
        println@Console("   Second element: " + secondElem)();

        println@Console("\n3. Try accessing second path:")();
        elem0 = pval(itemPaths.results[1])[0]
        elem1 = pval(itemPaths.results[1])[1]
        elem2 = pval(itemPaths.results[1])[2]
        elem3 = pval(itemPaths.results[1])[3]
        println@Console("   Elements: " + elem0 + ", " + elem1 + ", " + elem2 + ", " + elem3)();

        // Verify (first item is temp1: [10, 20, 30])
        if (firstElem == 10 &&
            secondElem == 20) {
            println@Console("\n✅ PASSED - pval(path)[n] works!")()
        } else {
            println@Console("\n❌ FAILED - Expected firstElem=10, secondElem=20, got " + firstElem + ", " + secondElem)()
        }
    }
}
