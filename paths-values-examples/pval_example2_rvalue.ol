// PVAL Example 2: Using pval() as RVALUE (Reading Data)
from console import Console

service Main {
    embed Console as Console

    main {
        println@Console("=== PVAL as RVALUE (Reading) ===")();

        // Setup data
        employees[0] << { id = "E001", name = "Alice", salary = 50000 }
        employees[1] << { id = "E002", name = "Bob", salary = 60000 }
        employees[2] << { id = "E003", name = "Charlie", salary = 55000 }

        // Get path to employee
        empPaths << paths employees[*] where $.id == "E002"
        empPath << empPaths.results[0]

        println@Console("\n1. Read entire value")();
        employeeData << pval(empPath)
        println@Console("Copied employee: " + employeeData.name + " (salary: " + employeeData.salary + ")")();

        println@Console("\n2. Read specific fields")();
        name = pval(empPath).name
        salary = pval(empPath).salary
        println@Console("Name: " + name + ", Salary: " + salary)();

        println@Console("\n3. Use in expressions")();
        newSalary = pval(empPath).salary + 5000
        println@Console("Current: " + pval(empPath).salary + ", With raise: " + newSalary)();

        // Calculate using multiple paths
        path1 << empPaths.results[0]
        allPaths << paths employees[*] where true
        path2 << allPaths.results[0]
        total = pval(path1).salary + pval(path2).salary
        println@Console("Total of two salaries: " + total)();

        println@Console("\n4. Use in conditions")();
        if (pval(empPath).salary > 55000) {
            println@Console(pval(empPath).name + " has high salary: $" + pval(empPath).salary)()
        };

        // Verify all tests
        if (employeeData.name == "Bob" &&
            name == "Bob" &&
            salary == 60000 &&
            newSalary == 65000) {
            println@Console("\n✅ PASSED - All rvalue operations work")()
        } else {
            println@Console("\n❌ FAILED")()
        }
    }
}
