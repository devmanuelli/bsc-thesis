from console import Console
from file import File
from @jolie.tquery.main import TQuery

service Main {
    embed Console as Console
    embed File as File
    embed TQuery as TQuery

    main {
        // Load order data
        readFile@File({
            filename = "order-data.json"
            format = "json"
        })(data);

        println@Console("=== ORIGINAL ORDER DATA ===")();
        println@Console("Order ID: " + data.order.orderId)();
        println@Console("Items count: " + #data.order.items)();
        println@Console("Audit log entries: " + #data.order.auditLog)();

        // Show structure
        println@Console("\nItems:")();
        for (i = 0, i < #data.order.items, i++) {
            println@Console("  [" + i + "] " + data.order.items[i].productName +
                          " (qty: " + data.order.items[i].quantity + ")")()
        };

        println@Console("\nAudit log (first 3 entries):")();
        for (i = 0, i < 3, i++) {
            println@Console("  [" + i + "] " + data.order.auditLog[i].event)()
        };

        // Unwind items using TQuery
        println@Console("\n=== UNWINDING ITEMS WITH TQUERY ===")();
        unwind@TQuery({
            data << data
            query = "order.items"
        })(result);

        println@Console("Unwound records: " + #result.result)();

        // Check each unwound record
        println@Console("\n=== CHECKING UNWOUND RECORDS ===")();
        for (i = 0, i < #result.result, i++) {
            println@Console("\nRecord " + i + ":")();
            println@Console("  Items count: " + #result.result[i].order.items +
                          " (was " + #data.order.items + ", now 1 due to a=a[0])")();
            println@Console("  Product: " + result.result[i].order.items.productName)();
            println@Console("  Audit log entries: " + #result.result[i].order.auditLog +
                          " (cloned)")()
        };

        // Test deep cloning by modifying one record's audit log
        println@Console("\n=== TESTING DEEP CLONE ===")();
        originalSize0 = #result.result[0].order.auditLog;
        originalSize1 = #result.result[1].order.auditLog;
        originalSize2 = #result.result[2].order.auditLog;

        println@Console("Original audit log sizes: " + originalSize0 + ", " +
                      originalSize1 + ", " + originalSize2)();

        // Add entry to record 0's audit log
        newIndex = #result.result[0].order.auditLog;
        result.result[0].order.auditLog[newIndex].event = "MODIFIED_IN_RECORD_0";
        println@Console("\nAdded entry to Record 0's audit log")();

        // Check if other records are affected
        println@Console("\n=== AFTER MODIFICATION ===")();
        println@Console("Record 0 audit log size: " + #result.result[0].order.auditLog +
                      " (was " + originalSize0 + ")")();
        println@Console("Record 1 audit log size: " + #result.result[1].order.auditLog +
                      " (was " + originalSize1 + ")")();
        println@Console("Record 2 audit log size: " + #result.result[2].order.auditLog +
                      " (was " + originalSize2 + ")")();

        if (#result.result[1].order.auditLog != originalSize1 ||
            #result.result[2].order.auditLog != originalSize2) {
            println@Console("\n❌ SHARED REFERENCE! Audit logs are NOT independent!")()
        } else {
            println@Console("\n✓ DEEP CLONE confirmed! Each item has independent audit log copy.")();
            println@Console("\nMemory overhead:")();
            totalOriginal = #data.order.items + #data.order.auditLog;
            totalUnwound = #result.result * (#result.result[0].order.items + #result.result[0].order.auditLog);
            println@Console("  Original: " + #data.order.items + " items + " +
                          #data.order.auditLog + " audit entries = " + totalOriginal + " records")();
            println@Console("  After unwind: " + #result.result + " × (" +
                          #result.result[0].order.items + " item + " +
                          #result.result[0].order.auditLog + " audit entries) = " +
                          totalUnwound + " records")();
            println@Console("  Overhead: " + (totalUnwound - totalOriginal) + " additional records (" +
                          ((totalUnwound * 100) / totalOriginal) + "%)")()
        }
    }
}
