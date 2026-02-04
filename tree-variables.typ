== Solving Data Heterogeneity: Tree-Structured Variables

Beyond protocol heterogeneity, distributed systems face data heterogeneity—the variety of hierarchical formats (JSON, XML, YAML) used to structure messages. Jolie's tree-structured variable model addresses this challenge through a domain-specific design.

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

Jolie eliminates this mismatch by adopting trees as the universal data representation. A JSON object can be mapped into a Jolie tree. A JSON array maps to multiple tree instances under the same child name. There is no conversion layer, no object-relational mapping—the data format used for communication is the same data structure used in the program.

This uniformity yields several advantages for service integration:

*No Impedance Mismatch*: Data received from external services requires no transformation—it is already in the native format the language operates on.

*Protocol-Agnostic Logic*: Business logic manipulates trees. Whether those trees arrived as JSON, XML, or binary format is irrelevant—the code remains identical.

#include "code-examples.typ"

*Jolie (Pre-TQuery)*:

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

Despite Jolie's tree-structured variables eliminating the need for JSON parsing and object mapping—where JSON, XML, YAML, and other hierarchical formats map seamlessly to the same native data structure—querying still requires explicit nested loops similar to Go. Without declarative query capabilities, developers are forced to write the same three-level traversal pattern to traverse and filter tree data. TQuery addresses this gap by providing declarative operators that leverage Jolie's tree abstraction.

== The Query Gap: From Imperative Loops to Declarative Queries

TQuery introduces declarative tree querying to Jolie by integrating MongoDB aggregation framework operators directly into the language @GMSZ22. This integration addresses a critical challenge in modern distributed systems: ephemeral data handling. In edge and fog computing scenarios—where data privacy regulations (GDPR, HIPAA) mandate minimal data retention, or where local processing reduces network overhead—using external databases like MongoDB introduces unnecessary dependencies, security risks, and performance penalties. TQuery eliminates these issues by enabling powerful query operations on Jolie's native tree structures without requiring external database systems.

By treating trees as first-class queryable structures, TQuery allows developers to express complex data traversal and filtering as declarative query pipelines rather than nested imperative loops. Operations such as `unwind` (flatten nested arrays), `match` (filter records), `project` (shape output), `group` (aggregate data), and `lookup` (join trees) transform what would be four-level nested loops into single-line declarative expressions, while maintaining Jolie's protocol-agnostic design and type safety.

==== Example: Finding Namesake Grandfathers

Consider the task of finding all grandfathers whose name matches at least one of their grandchildren. The imperative approach requires three nested loops with conditional checks:

#figure(
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
```,
  caption: [Imperative grandfather query with nested loops]
) <imperative-grandfather>

With TQuery, this complexity collapses into a declarative pipeline with three stages:

#figure(
```jolie
// TQuery Pipeline: unwind → filter sex → match names
stages[0].unwindQuery = "_.children.children";
stages[1].matchQuery.equal << { path = "_.sex" data = "Male" };
stages[2].matchQuery.equal << { left = "_.name" right = "_.children.children.name" };

pipeline@TQuery({ data << data pipeline << stages })(filtered);
```,
  caption: [TQuery grandfather query with declarative pipeline]
) <tquery-grandfather>

The `unwind` operator flattens the nested `children.children` structure, eliminating two levels of iteration. The first `match` filters by sex, replacing the conditional check. The second `match` performs path-to-path comparison, testing equality between `_.name` (grandfather) and `_.children.children.name` (grandchild) within each unwound record. This reduces 18 lines of imperative code to 5 lines of declarative queries—a 72% reduction while improving readability and maintainability.

==== Performance Considerations: The Cost of Context Preservation

TQuery's declarative elegance comes at a significant performance cost due to transferring data from a Jolie program to the library for querying and due to some of its operators' semantics. For instance, the TQuery specification @GMSZ22 explicitly defines the unwind operator's semantics:

#quote(block: true, attribution: [TQuery specification @GMSZ22, "An overview of the Tquery operators"])[
  The unwind operator ω takes as inputs an array and a path p. The result of the application is a new array containing the "unfolding" of the input array under the path, i.e., where we take each element e from the input array, we find all values under p in e and, for each value, we include in the new array *a copy of e* except it holds only that single value under p.
]

The critical passage is "*a copy of e*"—for each unwound value, TQuery creates a complete copy of the parent element, including all sibling fields. Consider a realistic e-commerce scenario:

```jolie
order.items[0] = { productId: "SKU-001", productName: "Wireless Mouse", quantity: 2 }
order.items[1] = { productId: "SKU-002", productName: "USB-C Cable", quantity: 1 }
order.items[2] = { productId: "SKU-003", productName: "Screen Protector", quantity: 5 }

order.auditLog[0..9] = [
  { event: "order_created", userId: "user123", productId: "SKU-001" },
  { event: "payment_processed", amount: 109.97, productId: "SKU-002" },
  { event: "inventory_reserved", warehouse: "WH-NA-01", productId: "SKU-003" },
  // ... 7 more audit events
]

unwind@TQuery({ query = "order.items" })
```

When unwinding `items`, the specification requires creating "a copy of e" (the entire order) for each item. This means the 10-element `auditLog` array gets cloned three times—once for each item—resulting in substantial memory duplication.

This behavior is not an implementation artifact but a consequence of the formal semantics. The specification ensures that when unwinding a path, all sibling fields are preserved in each resulting record, requiring complete materialization of the "context" for every unwound element.

*Projection does not eliminate the multiplicative copying.* One might attempt to reduce memory usage by projecting away unnecessary fields before unwinding—retaining only `productId` and `event` from `auditLog` while discarding `productName`, `quantity`, and other attributes. However, this optimization cannot avoid the fundamental issue: unwinding `items` produces 3 output records (one per item), and each output record contains a complete copy of the entire `auditLog` array with its 10 entries. The result is 3 × 10 = 30 individual record copies. While projection reduces the size of each copy, the multiplicative duplication—inherent to the unwind semantics—remains unavoidable.

PATHS and VALUES eliminate this overhead by operating directly on Jolie's tree-structured values without intermediate transformations. The `values` expression returns matching elements with zero-copy evaluation, while `paths` preserves hierarchical context through path references (e.g., `data.companies[0].departments[1].projects[3]`)—enabling queries to identify not just matching leaf nodes but also their position within the parent hierarchy, without verbose joins or intermediate copies.

==== Empirical Validation: Benchmark Results

To quantify the performance implications of the above overhead, we present benchmarks comparing two approaches for filtering deeply nested data: traditional imperative loops and TQuery pipelines.

*Dataset Structure:* The test data (`large_data.json`) contains 4,800 projects nested 4 levels deep following the hierarchy: companies → departments → teams → projects. The dataset is generated with 60 companies, each containing 5 departments, each with 4 teams, and each team managing 4 projects. This structure mirrors real-world organizational hierarchies commonly found in enterprise systems.

*Test Query:* Each benchmark filters projects matching two conditions across different nesting levels: `status == "in_progress"` AND `technology == "Python"`. This query pattern is representative of common analytical tasks where related fields at the same nesting level must be checked simultaneously.

*Implementations Compared:* Two approaches process the same query:

*Imperative*: Traditional nested for-loops traversing all four levels with conditional checks:

```jolie
// WITHOUT TQUERY: Nested loops
resultCount = 0;
for (c = 0, c < #global.data.companies, c++) {
    company -> global.data.companies[c].company;
    for (d = 0, d < #company.departments, d++) {
        dept -> company.departments[d];
        for (t = 0, t < #dept.teams, t++) {
            team -> dept.teams[t];
            for (p = 0, p < #team.projects, p++) {
                project -> team.projects[p];
                if (project.status == request.status) {
                    hasTech = false;
                    for (tech = 0, tech < #project.technologies && !hasTech, tech++) {
                        if (project.technologies[tech] == request.technology) {
                            hasTech = true
                        }
                    };
                    if (hasTech) {
                        response.results[resultCount] << project;
                        resultCount++
                    }
                }
            }
        }
    }
}
```

*TQuery*: Declarative pipeline using `unwind` on the path, followed by `match` with AND conditions, and `project` to shape output:

```jolie
// WITH TQUERY: Pipeline with unwind + match + project
ps[0].unwindQuery = "companies.company.departments.teams.projects.technologies";

ps[1] << {
    matchQuery.and << {
        left.equal << {
            path = "companies.company.departments.teams.projects.status"
            data = request.status
        }
        right.equal << {
            path = "companies.company.departments.teams.projects.technologies"
            data = request.technology
        }
    }
};

ps[2] << {
    projectQuery[0] << {
        dstPath = "project_id"
        value.path = "companies.company.departments.teams.projects.project_id"
    }
    projectQuery[1] << {
        dstPath = "name"
        value.path = "companies.company.departments.teams.projects.name"
    }
    projectQuery[2] << {
        dstPath = "status"
        value.path = "companies.company.departments.teams.projects.status"
    }
    projectQuery[3] << {
        dstPath = "technologies"
        value.path = "companies.company.departments.teams.projects.technologies"
    }
};

pipeline@TQuery({
    data << global.data
    pipeline << ps
})(filtered)
```

The `unwind` operator flattens the nested hierarchy, but creates a copy of the entire parent context for each unwound element, leading to the memory overhead discussed earlier.

*Benchmark Execution:* Tests measure concurrent request performance using a Python script that sends multiple parallel requests to separate Jolie services (one per implementation). Each service processes the same dataset and query. Tests run at three concurrency levels (5, 7, and 9 parallel requests) to observe performance under varying load. Metrics collected include P50/P95 latency percentiles, maximum heap memory usage, and garbage collection events extracted via `jstat` from the JVM runtime.

*Test Environment:* CPU: Intel(R) Core(TM) 7 150U, Memory: 15 GiB, OS: Debian GNU/Linux (kernel 6.1.0-40-amd64), Java: OpenJDK 64-Bit Server VM (build 21.0.8+9-Debian-1).

#figure(
  image("download.png"),
  caption: [Performance comparison across different concurrency levels on 4,800 nested projects]
)

Across all concurrency levels, TQuery consistently exhibits 4.5–5.6× higher latency and consumes approximately 10× more memory than the imperative approach. The elevated garbage collection activity confirms sustained memory pressure from materializing cloned contexts. These results validate the theoretical analysis: the specification's requirement for "a copy of e" translates directly into substantial runtime costs when processing hierarchical data with sibling arrays.
