== Solving Data Heterogeneity: Tree-Structured Variables

#quote(block: true, attribution: [Rob Pike, dotGo 2015 @pike2015simplicity])[
  "Last year I went to a conference hosted by Microsoft called Lang.NEXT, and I saw a number of talks, many of which were the leaders of a particular language talking about a new version that was coming out.

  I really was struck by one thing about these talks and these languages, which is most of the talks consisted of features being added by taking something from another language and adding it to this one.
  And I realized that what's happening is all of these languages are turning into the same language. [...]
  You want to have different languages for different problems. You want to have different domains be solved by different ways of thinking and different notations. In other words, you kind of want a tool that's optimized for each particular way you're working."
]

=== Three Principles of Jolie's Variable Model

Jolie's variable model follows three principles:

1. *Scalar-Array Unification* (`a = a[0]`): No distinction between single values and arrays—accessing `a` equals accessing `a[0]`.

2. *Vivification*: Assigning to `x.y.z` automatically creates intermediate nodes `x` and `x.y` if they don't exist.

=== Safe Navigation Example

The following Jolie program demonstrates vivification—accessing non-existent fields returns empty values without exceptions:

```jolie
from console import Console

service Main {
    embed Console as Console

    main {
        a = 42;

        // Access non-existent field in expression
        if (a.nonexistent == "") {
            println@Console("a.nonexistent equals empty string")();
            println@Console("No exception thrown - safe navigation!")()
        }
    }
}
```

Output:
```
a.nonexistent equals empty string
No exception thrown - safe navigation!
```

3. *Everything is a Tree*: Every variable, including array elements, is a tree with a root value and child nodes.

This design choice is motivated by the domain Jolie targets: service-oriented systems. Services communicate by exchanging structured data—JSON arrays, XML hierarchies, nested objects. These formats are inherently tree-structured with repeating elements. Traditional programming languages separate primitives, objects, and arrays into distinct type categories, creating an *impedance mismatch*: the data structures services exchange do not match the native data model of the language, requiring explicit serialization, deserialization, and schema binding. Moreover, traversing nested structures typically necessitates either custom traversal code or external query libraries (JSONPath, XPath, jq), introducing additional dependencies and data conversion overhead.

Jolie eliminates this mismatch by adopting trees as the universal data representation. A JSON object maps directly to a Jolie tree. A JSON array maps to multiple tree instances under the same child name. There is no conversion layer, no object-relational mapping—the data format used for communication is the same data structure used in the program.

This uniformity yields several advantages for service integration:

*No Impedance Mismatch*: Data received from external services requires no transformation—it is already in the native format the language operates on.

*Protocol-Agnostic Logic*: Business logic manipulates trees. Whether those trees arrived as JSON, XML, or binary format is irrelevant—the code remains identical.

#include "code-examples.typ"

=== Tree Traversal in Jolie (Pre-TQuery)

Using the same data structure, Jolie's native tree model simplifies the traversal:

```jolie
from console import Console
from file import File

service Main {
    embed Console as Console
    embed File as File

    main {
        readFile@File({
            filename = "test-data.json"
            format = "json"
        })(data);

        for (person in data._) {
            if (person.sex == "Male") {
                for (child in person.children) {
                    for (grandchild in child.children) {
                        if (grandchild.name == person.name) {
                            println@Console("Found: " + person.name)()
                        }
                    }
                }
            }
        }
    }
}
```

Output:
```
Found: John Smith
Found: George Brown
```

Despite Jolie's sophisticated tree variable representation—where JSON, XML, YAML, and other hierarchical formats map seamlessly to the same native data structure—native Jolie provides no primitives to exploit this uniformity for querying. Without declarative query capabilities, developers are forced to write classic, clumsy nested for-loops to traverse and filter tree data. TQuery addresses this gap by providing declarative operators that leverage Jolie's tree abstraction.

== The Query Gap: From Imperative Loops to Declarative Queries

TQuery introduces declarative tree querying to Jolie by integrating MongoDB aggregation framework operators directly into the language @GMSZ22. This integration addresses a critical challenge in modern distributed systems: ephemeral data handling. In edge and fog computing scenarios—where data privacy regulations (GDPR, HIPAA) mandate minimal data retention, or where local processing reduces network overhead—using external databases like MongoDB introduces unnecessary dependencies, security risks, and performance penalties. TQuery eliminates these issues by enabling powerful query operations on Jolie's native tree structures without requiring external database systems.

By treating trees as first-class queryable structures, TQuery allows developers to express complex data traversal and filtering as declarative query pipelines rather than nested imperative loops. Operations such as `unwind` (flatten nested arrays), `match` (filter records), `project` (shape output), `group` (aggregate data), and `lookup` (join trees) transform what would be four-level nested loops into single-line declarative expressions, while maintaining Jolie's protocol-agnostic design and type safety.

==== Example: Finding Namesake Grandfathers

Consider the task of finding all grandfathers whose name matches at least one of their grandchildren. The imperative approach requires three nested loops with conditional checks:

```jolie
for (person in data._) {
    if (person.sex == "Male") {
        for (child in person.children) {
            for (grandchild in child.children) {
                if (grandchild.name == person.name) {
                    result[#result] << person
                }
            }
        }
    }
}
```

With TQuery, this complexity collapses into a declarative pipeline with three stages:

```jolie
// TQuery Pipeline: unwind → filter sex → match names
stages[0].unwindQuery = "_.children.children";
stages[1].matchQuery.equal << { path = "_.sex" data = "Male" };
stages[2].matchQuery.equal << { left = "_.name" right = "_.children.children.name" };

pipeline@TQuery({ data << data pipeline << stages })(filtered);
```

The `unwind` operator flattens the nested `children.children` structure, eliminating two levels of iteration. The first `match` filters by sex, replacing the conditional check. The second `match` performs path-to-path comparison, testing equality between `_.name` (grandfather) and `_.children.children.name` (grandchild) within each unwound record. This reduces 18 lines of imperative code to 5 lines of declarative queries—a 72% reduction while improving readability and maintainability.

==== Performance Considerations: The Cost of Context Preservation

TQuery's declarative elegance comes at a significant performance cost due to its specified behavior for context preservation. The TQuery specification @GMSZ22 explicitly defines the unwind operator's semantics:

#quote(block: true, attribution: [TQuery specification @GMSZ22, "An overview of the Tquery operators"])[
  The unwind operator ω takes as inputs an array and a path p. The result of the application is a new array containing the "unfolding" of the input array under the path, i.e., where we take each element e from the input array, we find all values under p in e and, for each value, we include in the new array *a copy of e* except it holds only that single value under p.
]

The critical phrase is "*a copy of e*"—for each unwound value, TQuery creates a complete copy of the parent element, including all sibling fields. Consider a realistic e-commerce scenario:

```jolie
order.items[0] = { productId: "SKU-001", productName: "Wireless Mouse", quantity: 2 }
order.items[1] = { productId: "SKU-002", productName: "USB-C Cable", quantity: 1 }
order.items[2] = { productId: "SKU-003", productName: "Screen Protector", quantity: 5 }

order.auditLog[0..9] = [
  { event: "order_created", userId: "user123" },
  { event: "payment_processed", amount: 109.97 },
  { event: "inventory_reserved", warehouse: "WH-NA-01" },
  // ... 7 more audit events
]

unwind@TQuery({ query = "order.items" })
```

When unwinding `items`, the specification requires creating "a copy of e" (the entire order) for each item. This means the 10-element `auditLog` array gets cloned three times—once for each item—resulting in substantial memory duplication.

This behavior is not an implementation artifact but a consequence of the formal semantics. The specification ensures that when unwinding a path, all sibling fields are preserved in each resulting record, requiring complete materialization of context for every unwound element.

==== Empirical Validation: Benchmark Results

To quantify the performance implications of context preservation, benchmarks from the TQuery repository compare three approaches for filtering deeply nested data: traditional imperative loops, TQuery pipelines, and JsonPath.

*Dataset Structure:* The test data (`large_data.json`) contains 4,800 projects nested 4 levels deep following the hierarchy: companies → departments → teams → projects. The dataset is generated with 60 companies, each containing 5 departments, each with 4 teams, and each team managing 4 projects. This structure mirrors real-world organizational hierarchies commonly found in enterprise systems.

*Test Query:* Each benchmark filters projects matching two conditions across different nesting levels: `status == "in_progress"` AND `technology == "Python"`. This query pattern is representative of common analytical tasks where related fields at the same nesting level must be checked simultaneously.

*Implementations Compared:* Three approaches process the same query: (1) *Imperative*: Traditional nested for-loops traversing all four levels with conditional checks; (2) *TQuery*: Declarative pipeline using `unwind` on the path `companies.company.departments.teams.projects.technologies` followed by `match` with AND conditions; (3) *JsonPath*: Java JsonPath library with filter expressions on the JSON structure.

*Benchmark Execution:* Tests measure concurrent request performance using a Python script that sends multiple parallel requests to separate Jolie services (one per implementation). Each service processes the same dataset and query. Tests run at three concurrency levels (5, 7, and 9 parallel requests) to observe performance under varying load. Metrics collected include P50/P95 latency percentiles, maximum heap memory usage, and garbage collection events extracted via `jstat` from the JVM runtime.

*Test Environment:* CPU: Intel(R) Core(TM) 7 150U, Memory: 15 GiB, OS: Debian GNU/Linux (kernel 6.1.0-40-amd64), Java: OpenJDK 64-Bit Server VM (build 21.0.8+9-Debian-1).

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, center, center, center, center),
    table.header([*Metric*], [*Concurrency*], [*Imperative*], [*TQuery*], [*JsonPath*]),
    table.hline(),
    [P50 latency (ms)], [5 requests], [287], [1,296], [234],
    [], [7 requests], [353], [1,973], [251],
    [], [9 requests], [408], [1,986], [308],
    table.hline(),
    [P95 latency (ms)], [5 requests], [327], [1,314], [284],
    [], [7 requests], [365], [1,979], [306],
    [], [9 requests], [459], [2,005], [403],
    table.hline(),
    [Max heap (MB)], [5 requests], [146.2], [1,455.1], [5.7],
    [], [7 requests], [183.4], [2,082.1], [5.4],
    [], [9 requests], [115.7], [2,348.1], [5.4],
    table.hline(),
    [Young GC events], [5 requests], [6], [19], [1],
    [], [7 requests], [6], [24], [1],
    [], [9 requests], [7], [22], [1],
    table.hline(),
    [Full GC events], [5 requests], [0], [0], [0],
    [], [7 requests], [0], [0], [0],
    [], [9 requests], [0], [0], [0],
  ),
  caption: [Performance comparison across different concurrency levels on 4,800 nested projects]
)

Across all concurrency levels, TQuery consistently exhibits 4.5–5.6× higher latency and consumes approximately 10× more memory than the imperative approach. The memory overhead remains severe even compared to JsonPath (over 200× difference). The elevated garbage collection activity confirms sustained memory pressure from materializing cloned contexts. These results validate the theoretical analysis: the specification's requirement for "a copy of e" translates directly into substantial runtime costs when processing hierarchical data with sibling arrays.
