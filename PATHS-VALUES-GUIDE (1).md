# PATHS and VALUES: Examples Guide

Native Jolie primitives for declarative tree querying.

## Basic Syntax

```jolie
paths <path-clause> where <where-clause>   // Returns path values (new primitive type)
values <path-clause> where <where-clause>  // Returns actual values (deep copies)
```

**Important**: The WHERE clause is **mandatory**. Every PATHS/VALUES expression must include a filtering condition.

## Result Structure

When you execute a PATHS or VALUES query, the results are stored in the `.results` field:

```jolie
res << values data.items[*] where $.price > 100

// Actual results are in: res.results
// res.results is an array containing matching items
// Access individual results: res.results[0], res.results[1], etc.
// Number of results: #res.results
```

**Important**:
- Always access results through `.results`, not the variable directly
- **VALUES returns deep copies** - modifications to results don't affect original data
- **PATHS returns path values** (new primitive type) - use `pval()` to dereference and access the original data (see [Using pval()](#using-pval---dereferencing-path-values) section for complete usage patterns)

```jolie
// ✓ CORRECT
for (i = 0; i < #res.results; i++) {
    println@Console(res.results[i].name)()
}

// ✗ WRONG
for (i = 0; i < #res; i++) {
    println@Console(res[i].name)()  // This won't work!
}
```

### Path Values as Primitive Type

Path values are a native primitive type in Jolie. As such:
- They can be sent across external service boundaries (between client and server)
- They can be used in operation parameters and return values
- Structural validation occurs only at external service boundaries (input/output ports)
- When a path value enters or exits an external service, Jolie validates its structure
- Invalid paths are rejected with a `TypeMismatch` fault at the boundary
- No validation occurs for embedded services

This allows external services to exchange path references safely, with automatic validation ensuring only well-formed paths cross external service boundaries.

**Example: Sending path values across services**

```jolie
from console import Console

type PathRequest { testPath: path }
type PathResponse { returnPath: path }

interface PathInterface {
    requestResponse: testPath(PathRequest)(PathResponse)
}

service Server {
    embed Console as ServerConsole

    execution { concurrent }

    inputPort ServerInput {
        location = "socket://localhost:18889"
        protocol: sodep
        interfaces: PathInterface
    }

    main {
        testPath(req)(res) {
            println@ServerConsole("[SERVER] ✓ Received valid path")();
            // Create PATH using paths expression
            testData.server.response = 1;
            pathsResult << paths testData where true;
            res.returnPath = pathsResult.results[0]
        }
    }
}

service Client {
    embed Console as Console

    outputPort ServerPort {
        location = "socket://localhost:18889"
        protocol: sodep
        interfaces: PathInterface
    }

    main {
        println@Console("=== PATH Type Validation Tests ===")();

        // TEST 1: Valid simple path (Client→Server)
        println@Console("\n[TEST 1] Valid path: data.user.name")();
        scope (test1) {
            install(TypeMismatch => println@Console("❌ FAILED")());
            testPath@ServerPort({ testPath = "data.user.name" })(response);
            println@Console("✅ PASSED")()
        };

        // TEST 2: Valid complex path (Client→Server)
        println@Console("\n[TEST 2] Complex path: data[0].users[5].name")();
        scope (test2) {
            install(TypeMismatch => println@Console("❌ FAILED")());
            testPath@ServerPort({ testPath = "data[0].users[5].name" })(response);
            println@Console("✅ PASSED")()
        };

        // TEST 3: Invalid path (Client→Server validation)
        println@Console("\n[TEST 3] Invalid path: data[invalid].field")();
        passed = false;
        scope (test3) {
            install(TypeMismatch => { println@Console("✅ PASSED - Correctly rejected")(); passed = true });
            testPath@ServerPort({ testPath = "data[invalid].field" })(response);
            if (!passed) { println@Console("❌ FAILED - Should have been rejected")() }
        };

        // TEST 4: Server→Client PATH validation
        println@Console("\n[TEST 4] Server returns valid PATH")();
        scope (test4) {
            install(TypeMismatch => println@Console("❌ FAILED - Server PATH not validated")());
            testPath@ServerPort({ testPath = "test.path" })(response);
            // If we got here without TypeMismatch, the server's PATH was validated
            println@Console("✅ PASSED")()
        };

        println@Console("\n === Tests Complete ===")()
    }
}
```

## Using pval() - Dereferencing Path Values

The `pval()` function dereferences path values to access or modify the actual data they reference. Importantly, **`pval()` can be used both as an lvalue (for writing) and as an rvalue (for reading)**.

### pval() as LVALUE (Writing/Modifying Data)

You can use `pval()` on the left side of assignments to modify data:

```jolie
// Get a path using PATHS primitive
userPaths << paths data.users[*] where $.name == "Bob"
path << userPaths.results[0]

// 1. Field assignment with =
pval(path).name = "Robert"              // Simple assignment to field
pval(path).address.city = "Florence"    // Nested field assignment

// 2. Field deep copy with <<
newAddress << { city = "Venice", zipCode = "30100" }
pval(path).address << newAddress        // Deep copy entire structure

// 3. Root assignment with =
newUser << { name = "Robert", age = 26 }
pval(path) = newUser                    // Assign at root level

// 4. Root deep copy with <<
pval(path) << newUser                   // Deep copy entire value at root
```

### pval() as RVALUE (Reading Data)

You can use `pval()` on the right side of assignments to read data:

```jolie
// Get path to employee
empPaths << paths employees[*] where $.id == "E002"
empPath << empPaths.results[0]

// 1. Read entire value
employeeData << pval(empPath)           // Copy entire employee record

// 2. Read specific fields
name = pval(empPath).name               // Read single field
salary = pval(empPath).salary

// 3. Use in expressions
newSalary = pval(empPath).salary + 5000 // Arithmetic operations
total = pval(path1).balance + pval(path2).balance

// 4. Use in conditions
if (pval(empPath).salary > 55000) {
    println@Console(pval(empPath).name + " has high salary")()
}
```

### Combining LVALUE and RVALUE Usage

You can use `pval()` as both lvalue and rvalue in the same operation:

```jolie
// Swap values between two paths
itemAPaths << paths inventory[*] where $.item == "A"
itemBPaths << paths inventory[*] where $.item == "B"
pathA << itemAPaths.results[0]
pathB << itemBPaths.results[0]

// Read from pathB, write to pathA
tempQty = pval(pathA).quantity                    // rvalue
pval(pathA).quantity = pval(pathB).quantity       // both lvalue and rvalue
pval(pathB).quantity = tempQty                    // lvalue

// Transfer between accounts
pval(acc1Path).balance = pval(acc1Path).balance - 200   // rvalue and lvalue
pval(acc2Path).balance = pval(acc2Path).balance + 200
```

### Key Points

- ✅ **pval() works as lvalue**: Can modify data through path references
- ✅ **pval() works as rvalue**: Can read data through path references
- ✅ **Works with nested fields**: `pval(path).field.subfield`
- ✅ **Works with arrays**: `pval(path).array[0]`
- ✅ **Supports both = and <<**: Simple assignment vs deep copy
- ✅ **Can be used in expressions**: Arithmetic, string concatenation, conditions
- ✅ **Path-to-path operations**: `pval(dest) << pval(src)`

### TODO

**⚠️ The # operator does not work with pval() expressions**

The `#` (array size) operator only accepts:
1. VariablePath (e.g., `#items[0].tags`) ✓
2. CurrentValueExpression (e.g., `#$.field` in WHERE clause) ✓
3. NOT pval() expressions ✗

**Workaround (Required)**:

```jolie
// ✗ DOESN'T WORK
count = #pval(itemPath).tags

// ✓ CORRECT: Use intermediate variable
temp = pval(itemPath).tags
count = #temp
```

You must copy the value from `pval()` to an intermediate variable before using the `#` operator.

**⚠️ Cannot do ref -> pval()**

## Formal Grammar

### Path Expression Grammar

```
path-expression := identifier array-access? suffix*

suffix := dot-access array-access?

dot-access := '.' field
            | '.' '*'
            | '.' '.' field
            | '.' '.' '*'

array-access := '[' integer ']'
              | '[' '*' ']'
```

Where:
- `identifier` is the root variable name
- `field` is an identifier
- `integer` is a numeric literal

The grammar prevents consecutive array accesses: each `array-access` can only appear after the identifier or after a `dot-access`, never after another `array-access`.

**Examples**:
- `data[0]` — first element of data array
- `data[*]` — all elements in data array
- `data[*].items[2]` — third item in each data record
- `data[*].items[*]` — all items in all data records
- `tree..status` — all status fields at any depth
- `data[*].*[*]` — all array elements in all fields of all data records

### WHERE Clause Grammar

```
where-clause := 'where' boolean-expr

boolean-expr := or-expr

or-expr := and-expr
         | or-expr '||' and-expr

and-expr := not-expr
          | and-expr '&&' not-expr

not-expr := '!' not-expr
          | primary-expr

primary-expr := comparison-expr
              | '(' boolean-expr ')'

comparison-expr := operand compare-op operand
                 | operand 'has' operand

operand := current-value
         | literal
         | identifier

current-value := '$' suffix*

compare-op := '==' | '!=' | '<' | '>' | '<=' | '>='

literal := string-literal | integer | boolean
```

**Operator Precedence** (highest to lowest):
1. `!` (NOT) - highest precedence
2. `&&` (AND)
3. `||` (OR) - lowest precedence
4. Parentheses `()` override precedence

The `current-value` production allows `$` with all path operations: field access, wildcards, array indexing, and recursive descent (e.g., `$.field[*]`, `$..nested[*]`).

---

## Example 1: Select All (Using WHERE true)

**Scenario**: Extract all items from an array.

```jolie
// Data
data.cart.items[0] << { name = "Laptop", price = 999 }
data.cart.items[1] << { name = "Mouse", price = 25 }
data.cart.items[2] << { name = "Keyboard", price = 75 }

// Get all items (WHERE clause is mandatory, use "where true" for no filtering)
all << values data.cart.items[*] where true

// Returns all 3 items in all.results
```

---

## Example 2: Filtering by Age

**Scenario**: Find adult users.

```jolie
// Data
data.users[0] << { name = "Alice", age = 30, country = "USA" }
data.users[1] << { name = "Bob", age = 17, country = "Canada" }
data.users[2] << { name = "Charlie", age = 25, country = "UK" }

// Query: Users 18 or older
adults << values data.users[*] where $.age >= 18

// Returns: Alice record and Charlie record in adults.results

// Iterate through results
for (i = 0; i < #adults.results; i++) {
    println@Console(adults.results[i].name)()
}
```

---

## Example 3: Array Matching (Existential Semantics)

**Scenario**: Find tasks tagged as "urgent".

```jolie
// Data
data.tasks[0] << {
    title = "Fix bug #123",
    tags[0] = "backend",
    tags[1] = "urgent",
    tags[2] = "security"
}
data.tasks[1] << {
    title = "Update docs",
    tags[0] = "documentation",
    tags[1] = "low-priority"
}
data.tasks[2] << {
    title = "Deploy hotfix",
    tags[0] = "deployment",
    tags[1] = "urgent"
}

// Query: Tasks with ANY tag equal to "urgent"
urgent << values data.tasks[*] where $.tags[*] == "urgent"

// How it works:
// task[0]: Any tag equals "urgent"? YES (has "urgent") → include
// task[1]: Any tag equals "urgent"? NO → exclude
// task[2]: Any tag equals "urgent"? YES (has "urgent") → include

// Returns: tasks[0] and tasks[2] records
```

---

## Example 4: Multiple Conditions with AND

**Scenario**: Find in-progress Python projects.

```jolie
// Data
data.projects[0] << { name = "API Server", status = "in_progress", language = "Python" }
data.projects[1] << { name = "Frontend", status = "completed", language = "JavaScript" }
data.projects[2] << { name = "Data Pipeline", status = "in_progress", language = "Python" }
data.projects[3] << { name = "Mobile App", status = "in_progress", language = "Kotlin" }

// Query: In-progress Python projects
active_python << values data.projects[*] where
    $.status == "in_progress" &&
    $.language == "Python"

// Evaluation:
// project[0]: status is "in_progress"? YES, language is "Python"? YES
//             Result: TRUE && TRUE = include ✓
//
// project[1]: status is "in_progress"? NO
//             Result: FALSE && ... = exclude ✗
//
// project[2]: status is "in_progress"? YES, language is "Python"? YES
//             Result: TRUE && TRUE = include ✓
//
// project[3]: status is "in_progress"? YES, language is "Python"? NO
//             Result: TRUE && FALSE = exclude ✗

// Returns: API Server record and Data Pipeline record
```

---

## Example 5: The HAS Operator

**Scenario**: Find records with optional fields present.

```jolie
// Data
data.requests[0] << {
    title = "Sprint Planning",
    participants[0] = "Alice",
    participants[1] = "Bob"
}
data.requests[1].title = "Solo Review"
// No participants field

// Query: Requests where participants field exists
with_participants << values data.requests[*] where $ has "participants"

// Evaluation:
// requests[0]: has "participants" field? YES → include
// requests[1]: has "participants" field? NO → exclude

// Returns: requests[0] record
```

---

## Example 6: Combining HAS with Value Checks

**Scenario**: Find high-priority tasks (only where priority is defined).

```jolie
// Data
data.tasks[0] << { title = "Fix bug", priority = "high", assignee = "Alice" }
data.tasks[1] << { title = "Write docs", assignee = "Bob" }
data.tasks[2] << { title = "Deploy", priority = "low", assignee = "Charlie" }
data.tasks[3] << { title = "Review PR", priority = "high", assignee = "Alice" }

// Query: High-priority tasks
high_priority << values data.tasks[*] where
    $ has "priority" &&
    $.priority == "high"

// Evaluation:
// task[0]: has priority? YES, equals "high"? YES → include ✓
// task[1]: has priority? NO → exclude ✗
// task[2]: has priority? YES, equals "high"? NO → exclude ✗
// task[3]: has priority? YES, equals "high"? YES → include ✓

// Returns: tasks[0] and tasks[3] records
```

---

## Example 7: Independent Condition Evaluation

**Scenario**: Searching for "Matteo Rossi" - demonstrating independent evaluation.

```jolie
// Data
data.employees[0] << { name = "Matteo", surname = "Maggio" }
data.employees[1] << { name = "Roberto", surname = "Rossi" }

// ⚠️ BE CAREFUL: Querying at data level
wrong << values data where
    $.employees[*].name == "Matteo" &&
    $.employees[*].surname == "Rossi"

// Why it matches (unexpectedly):
// $.employees[*].name produces ["Matteo", "Roberto"]
//   → Any equals "Matteo"? YES → TRUE
//
// $.employees[*].surname produces ["Maggio", "Rossi"]
//   → Any equals "Rossi"? YES → TRUE
//
// Result: TRUE && TRUE = TRUE
// Matches even though no single employee has both!

// ✓ BETTER: Query at employee level
correct << values data.employees[*] where
    $.name == "Matteo" &&
    $.surname == "Rossi"

// Evaluation per employee:
// employee[0]: name ="Matteo" AND surname ="Maggio"
//              TRUE && FALSE = FALSE → exclude ✗
//
// employee[1]: name ="Roberto" AND surname ="Rossi"
//              FALSE && TRUE = FALSE → exclude ✗
//
// Returns: No matching records (correct!)
```

---

## Example 8: Grandfather Name-Matching

**Scenario**: Find grandfathers whose name matches at least one grandchild.

```jolie
// Data
data._[0] << {
    name = "John",
    surname = "Smith",
    sex = "Male",
    children[0] << {
        name = "Mary",
        children[0] << { name = "John", surname = "Doe" },
        children[1] << { name = "Emma", surname = "Doe" }
    }
}
data._[1] << {
    name = "Robert",
    surname = "Jones",
    sex = "Male",
    children[0] << {
        name = "Sarah",
        children[0] << { name = "Michael", surname = "Brown" }
    }
}

// Query
grandfathers << values data._[*] where
    $.sex == "Male" &&
    $.name == $.children[*].children[*].name

// Evaluation:
// person[0]:
//   $.sex == "Male"? YES
//   $.name is "John"
//   $.children[*].children[*].name produces ["John", "Emma"]
//   "John" matches any in ["John", "Emma"]? YES
//   Result: TRUE && TRUE = include ✓
//
// person[1]:
//   $.sex == "Male"? YES
//   $.name is "Robert"
//   $.children[*].children[*].name produces ["Charlie"]
//   "Robert" matches any in ["Charlie"]? NO
//   Result: TRUE && FALSE = exclude ✗

// Returns: John Smith's complete record
```

---

## Example 9: Deep Hierarchy Navigation

**Scenario**: Find Python projects across 4-level company hierarchy.

```jolie
// Data structure
data.companies[0] << {
    name = "TechCorp",
    departments[0] << {
        name = "Engineering",
        teams[0] << {
            name = "Backend",
            projects[0] << {
                name = "API",
                status = "in_progress",
                technologies[0] = "Python",
                technologies[1] = "PostgreSQL"
            },
            projects[1] << {
                name = "Frontend",
                status = "in_progress",
                technologies[0] = "JavaScript",
                technologies[1] = "React"
            }
        },
        teams[1] << {
            name = "Data",
            projects[0] << {
                name = "ETL",
                status = "in_progress",
                technologies[0] = "Python",
                technologies[1] = "Spark"
            }
        }
    }
}
data.companies[1] << {
    name = "FinanceCorp",
    departments[0] << {
        name = "Trading",
        teams[0] << {
            name = "Algorithms",
            projects[0] << {
                name = "HFT",
                status = "in_progress",
                technologies[0] = "C++",
                technologies[1] = "Rust"
            }
        }
    }
}

// Query: In-progress Python projects across entire organization
python_projects << values data.companies[*].departments[*].teams[*].projects[*]
    where $.status == "in_progress" &&
          $.technologies[*] == "Python"

// Path navigates:
// companies[*] → all companies
// .departments[*] → all departments
// .teams[*] → all teams
// .projects[*] → all projects

// Evaluation per project:
// TechCorp/Engineering/Backend/API:
//   status ="in_progress" AND has "Python" → include ✓
//
// TechCorp/Engineering/Backend/Frontend:
//   status ="in_progress" but no "Python" → exclude ✗
//
// TechCorp/Engineering/Data/ETL:
//   status ="in_progress" AND has "Python" → include ✓
//
// FinanceCorp/Trading/Algorithms/HFT:
//   status ="in_progress" but no "Python" → exclude ✗

// Returns = 2 project records (API and ETL)
```

---

## Example 10: Recursive Descent

**Scenario**: Find all status fields at any depth.

```jolie
// Data
data.project.status = "active"
data.project.subprojects[0].status = "pending"
data.project.subprojects[0].tasks[0].status = "completed"
data.project.subprojects[1].status = "active"

// Query: All status fields at any depth (using "where true" to include all)
all_statuses << values data..status where true

// Result
// ["active", "pending", "completed", "active"]

// The .. operator searches recursively
// WHERE clause is still required (here we use "where true")
```

---

## Example 11: PATHS vs VALUES

### Using VALUES

```jolie
// Data
data.projects[0] << { name = "WebApp", status = "active", budget = 50000 }
data.projects[1] << { name = "Mobile", status = "pending", budget = 30000 }
data.projects[2] << { name = "API", status = "active", budget = 40000 }

// Query with VALUES
active << values data.projects[*] where $.status == "active"

// Result contains deep copies
// active.results[0] = { name = "WebApp", status = "active", budget = 50000 }
// active.results[1] = { name = "API", status = "active", budget = 40000 }

// Directly use the data
total = 0;
for (i = 0; i < #active.results; i++) {
    total += active.results[i].budget
};
println@Console("Total = " + total)()
// Output: Total = 90000
```

### Using PATHS

```jolie
// Same data
data.projects[0] << { name = "WebApp", status = "active", budget = 50000 }
data.projects[1] << { name = "Mobile", status = "pending", budget = 30000 }
data.projects[2] << { name = "API", status = "active", budget = 40000 }

// Query with PATHS
active_paths << paths data.projects[*] where $.status == "active"

// Result contains path values (primitive type)
// active_paths.results[0] = path "data.projects[0]"
// active_paths.results[1] = path "data.projects[2]"

// Use pval() to access data
for (i = 0; i < #active_paths.results; i++) {
    path << active_paths.results[i];
    project << pval(path);

    println@Console("Active at " + path)();
    println@Console("  Name = " + project.name)()
}
// Output:
// Active at data.projects[0]
//   Name: WebApp
// Active at data.projects[2]
//   Name: API
```

---

## Example 12: Finding Incomplete Records

**Scenario**: Data validation - find records with missing fields.

```jolie
// Data
data.users[0] << { name = "Alice", email = "alice@ex.com", phone = "555-0100" }
data.users[1] << { name = "Bob", email = "bob@ex.com" }  // Missing phone
data.users[2] << { name = "Charlie", phone = "555-0102" }  // Missing email

// Complete contact info
complete << values data.users[*] where
    $ has "email" &&
    $ has "phone"
// Returns: users[0] record

// Missing email
no_email << values data.users[*] where !($ has "email")
// Returns: users[2] record

// Missing ANY required field
incomplete << values data.users[*] where
    !($ has "email") ||
    !($ has "phone")
// Returns: users[1] and users[2] records
```

---

## Example 13: Complex Filtering

**Scenario**: E-commerce product search.

```jolie
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

// Evaluation:
// product[0]: electronics? YES, in stock? YES, has "sale"? YES → include ✓
// product[1]: electronics? NO → exclude ✗
// product[2]: electronics? YES, in stock? YES, has "sale"? YES → include ✓

// Returns: products[0] and products[2] records
```

---

## Example 14: OR Conditions

**Scenario**: Find admin or moderator users.

```jolie
// Data
data.users[0] << { name = "Alice", role = "admin" }
data.users[1] << { name = "Bob", role = "user" }
data.users[2] << { name = "Charlie", role = "moderator" }
data.users[3] << { name = "Dave", role = "user" }

// Query: Admins OR moderators
staff << values data.users[*] where
    $.role == "admin" ||
    $.role == "moderator"

// Evaluation:
// user[0]: role ="admin"? YES → include ✓
// user[1]: role ="admin" OR "moderator"? NO → exclude ✗
// user[2]: role ="moderator"? YES → include ✓
// user[3]: role ="admin" OR "moderator"? NO → exclude ✗

// Returns: users[0] and users[2] records
```

---

## Example 15: Array Size Filtering

**Scenario**: Find meetings with more than 2 participants.

```jolie
// Data
data.meetings[0] << {
    title = "Daily Standup",
    participants[0] = "Alice",
    participants[1] = "Bob",
    participants[2] = "Charlie",
    participants[3] = "Dave"
}
data.meetings[1] << {
    title = "1-on-1",
    participants[0] = "Alice",
    participants[1] = "Bob"
}
data.meetings[2] << {
    title = "Team Planning",
    participants[0] = "Alice",
    participants[1] = "Bob",
    participants[2] = "Charlie"
}
data.meetings[3] << {
    title = "Quick Chat",
    participants[0] = "Alice"
}

// Query: Meetings with more than 2 participants
large_meetings << values data.meetings[*] where #$.participants > 2

// Evaluation:
// meeting[0]: #participants = 4, 4 > 2? YES → include ✓
// meeting[1]: #participants = 2, 2 > 2? NO → exclude ✗
// meeting[2]: #participants = 3, 3 > 2? YES → include ✓
// meeting[3]: #participants = 1, 1 > 2? NO → exclude ✗

// Returns: meetings[0] and meetings[2] records
```

---

## Summary of Key Concepts

### WHERE Clause is Mandatory
- Every PATHS/VALUES expression MUST include a WHERE clause
- Use `where true` to select all items without filtering

### Existential Semantics
- Comparisons check if **ANY** element matches
- `$.tags[*] == "urgent"` succeeds if any tag equals "urgent"
- All operands become arrays internally

### Independent Evaluation
- Each comparison produces a boolean independently
- `&&` and `||` combine booleans, not array elements
- Query at the correct structural level

### HAS Operator
- Checks field existence, not value
- Distinguishes "absent" from "present but empty"

### PATHS vs VALUES
- **VALUES**: Returns deep copies of data
- **PATHS**: Returns path values (new primitive type) representing locations in the tree
- Use `pval()` to dereference path values - works as both lvalue (writing) and rvalue (reading)
- See [Using pval()](#using-pval---dereferencing-path-values) for complete usage patterns

---

For complete semantics and implementation details, see the thesis.
