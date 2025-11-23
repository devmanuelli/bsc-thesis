from console import Console
from @jolie.tquery.main import TQuery

service Main {
    embed Console as Console
    embed TQuery as TQuery

    main {
        // Create test data
        a.b.c[0] = 0;
        a.b.c[1] = 1;

        // Create 100-element sibling array
        for (i = 0, i < 100, i++) {
            a.__b[i] = i
        };

        println@Console("=== BEFORE UNWIND ===")();
        println@Console("a.b.c[0] = " + a.b.c[0])();
        println@Console("a.b.c[1] = " + a.b.c[1])();
        println@Console("a.__b[0] = " + a.__b[0])();
        println@Console("a.__b[99] = " + a.__b[99])();
        println@Console("a.__b size = " + #a.__b)();

        // Unwind a.b.c
        unwind@TQuery({
            data << a
            query = "b.c"
        })(result);

        println@Console("\n=== AFTER UNWIND ===")();
        println@Console("Number of unwound records: " + #result.result)();

        // Check sizes (avoid vivification)
        println@Console("\nRecord 0:")();
        println@Console("  c size = " + #result.result[0].b.c + " (was 2, now 1 due to a=a[0])")();
        println@Console("  __b size = " + #result.result[0].__b + " (cloned)")();

        println@Console("\nRecord 1:")();
        println@Console("  c size = " + #result.result[1].b.c)();
        println@Console("  __b size = " + #result.result[1].__b + " (cloned)")();

        // MODIFY record 0's __b array
        println@Console("\n=== MODIFYING RECORD 0's __b ===")();
        originalSize0 = #result.result[0].__b;
        originalSize1 = #result.result[1].__b;

        // Change size of record 0's __b by adding element
        result.result[0].__b[100] = 9999;
        println@Console("Added element to record 0's __b")();

        // Check sizes after modification
        println@Console("\n=== AFTER MODIFICATION ===")();
        println@Console("Record 0 __b size = " + #result.result[0].__b + " (was " + originalSize0 + ")")();
        println@Console("Record 1 __b size = " + #result.result[1].__b + " (was " + originalSize1 + ")")();

        if (#result.result[1].__b != originalSize1) {
            println@Console("\n❌ SHARED REFERENCE! Arrays are NOT independent!")()
        } else {
            println@Console("\n✓ DEEP CLONE confirmed! Arrays are independent.")()
        }
    }
}
