// PVAL Example 3: Combining LVALUE and RVALUE Usage
from console import Console

service Main {
    embed Console as Console

    main {
        println@Console("=== PVAL Combined LVALUE and RVALUE ===")();

        println@Console("\n1. Swap values between two paths")();
        inventory[0] << { item = "A", quantity = 100 }
        inventory[1] << { item = "B", quantity = 50 }

        itemAPaths << paths inventory[*] where $.item == "A"
        itemBPaths << paths inventory[*] where $.item == "B"
        pathA << itemAPaths.results[0]
        pathB << itemBPaths.results[0]

        println@Console("Before swap:")();
        println@Console("  Item A quantity: " + pval(pathA).quantity)();
        println@Console("  Item B quantity: " + pval(pathB).quantity)();

        // Use pval as both rvalue and lvalue to swap values
        tempQty = pval(pathA).quantity                    // rvalue
        pval(pathA).quantity = pval(pathB).quantity       // both lvalue and rvalue
        pval(pathB).quantity = tempQty                    // lvalue

        println@Console("After swap:")();
        println@Console("  Item A quantity: " + pval(pathA).quantity)();
        println@Console("  Item B quantity: " + pval(pathB).quantity)();

        println@Console("\n2. Transfer between accounts")();
        accounts[0] << { id = "ACC1", balance = 1000 }
        accounts[1] << { id = "ACC2", balance = 500 }

        acc1Paths << paths accounts[*] where $.id == "ACC1"
        acc2Paths << paths accounts[*] where $.id == "ACC2"
        acc1Path << acc1Paths.results[0]
        acc2Path << acc2Paths.results[0]

        println@Console("Before transfer:")();
        println@Console("  ACC1: $" + pval(acc1Path).balance)();
        println@Console("  ACC2: $" + pval(acc2Path).balance)();

        // Transfer using pval in arithmetic expressions (rvalue and lvalue)
        transferAmount = 200
        pval(acc1Path).balance = pval(acc1Path).balance - transferAmount
        pval(acc2Path).balance = pval(acc2Path).balance + transferAmount

        println@Console("After $" + transferAmount + " transfer:")();
        println@Console("  ACC1: $" + pval(acc1Path).balance)();
        println@Console("  ACC2: $" + pval(acc2Path).balance)();

        // Verify all tests
        if (pval(pathA).quantity == 50 &&
            pval(pathB).quantity == 100 &&
            pval(acc1Path).balance == 800 &&
            pval(acc2Path).balance == 700) {
            println@Console("\n✅ PASSED - All combined operations work")()
        } else {
            println@Console("\n❌ FAILED")()
        }
    }
}
