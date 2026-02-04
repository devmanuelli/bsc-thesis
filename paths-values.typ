#import "@preview/fletcher:0.5.8": diagram, node, edge

= Native Declarative Querying: PATHS and VALUES <paths-values>

This chapter presents the PATHS and VALUES primitives, native Jolie language constructs for declarative tree querying. We begin by introducing the syntax and semantics of these expressions, including the six path operations for navigating tree structures. We then examine the WHERE clause for filtering results and the \$ operator for referring to the current candidate value. The HAS operator for structural filtering is presented, followed by a discussion of the language extensions required to support these primitives. Finally, we analyze the implementation's complexity, demonstrating linear time and space performance through zero-copy navigation of Jolie's internal tree representation.

== Motivation

As established in the previous chapter, native Jolie provides no primitives to exploit its sophisticated tree variable representation for querying. While TQuery addressed this gap through an external library, it introduced significant performance overhead. The PATHS and VALUES expressions represent native Jolie language primitives that provide declarative tree querying by directly exploiting Jolie's internal Java tree variable representation (`Value` and `ValueVector` structures), eliminating both external dependencies and cloning overhead.

=== Motivating Example

By directly exploiting Jolie's internal Java tree variable representation, the grandfather problem—previously requiring nested loops or TQuery's pipeline with cloning overhead—simplifies dramatically. The same query that took 15 lines of imperative code or incurred substantial memory duplication with TQuery now becomes a single declarative expression:

#figure(
```jolie
values data._[*] where
    $.sex == "Male" &&
    $.name == $.children[*].children[*].name
```,
  caption: [PATHS/VALUES grandfather query with declarative filtering]
) <paths-values-grandfather>

This expression traverses the entire data tree, filters for male persons, and checks if any grandchild's name matches the grandfather's name—all in three lines without explicit loops or intermediate variables.

The query integrates naturally into a complete Jolie program:

```jolie
from file import File
from console import Console

service Main {
    embed File as File
    embed Console as Console

    main {
        readFile@File({
            filename = "test-data.json"
            format = "json"
        })(data);

        result << values data._[*] where
            $.sex == "Male" &&
            $.name == $.children[*].children[*].name;

        println@Console("Found " + #result.results + " matching grandfathers:")();
        i = 0;
        while (i < #result.results) {
            println@Console("- " +
                result.results[i].name + " " +
                result.results[i].surname
            )();
            i++
        }
    }
}
```

Running this program produces:

```
Found 2 matching grandfathers:
- John Smith
- George Brown
```

== Syntax and Semantics

PATHS and VALUES expressions share a common syntax structure that enables flexible tree querying through composable operations.

=== Basic Syntax

```jolie
paths <path-clause> where <where-clause>
values <path-clause> where <where-clause>
```

The *path-clause* defines which parts of the tree to traverse, while the *where-clause* filters results based on conditions. The key distinction: `paths` returns path-type values representing locations in the tree (e.g., `data[0].field`), while `values` returns deep copies of the actual data at those locations. The native `path` type enables subsequent dereferencing via `pval()`, which provides reference access without copying.

=== Path Operations

Six composable operations enable flexible tree navigation:

#table(
  columns: (auto, auto, auto),
  align: (left, left, left),
  table.header([*Operation*], [*Syntax*], [*Description*]),
  table.hline(),
  [Field], [`.field`], [Access named property],
  [Field Wildcard], [`.*`], [Match any field at current level],
  [Array Index], [`[n]`], [Specific array element],
  [Array Wildcard], [`[*]`], [All array elements],
  [Recursive Field], [`..field`], [Find field at any depth],
  [Recursive Wildcard], [`..*`], [All fields at any depth],
)

*Grammar:*

```
path-clause := identifier array-access? suffix*

suffix := dot-access array-access?

dot-access := '.' field
            | '.' '*'
            | '.' '.' field
            | '.' '.' '*'

array-access := '[' integer ']'
              | '[' '*' ']'
```

Where `identifier` is the root variable name, `field` is an identifier, and `integer` is a numeric literal. The grammar naturally prevents consecutive array accesses: each `array-access` is optional and can only appear after the identifier or after a `dot-access`, never after another `array-access`.

These operations compose naturally. For example:
- `data[0]` — first element of data array
- `data[*]` — all elements in data array
- `data[*].items[2]` — third item in each data record
- `data[*].items[*]` — all items in all data records
- `tree..status` — all status fields at any depth
- `data[*].*[*]` — all array elements in all fields of all data records

=== The WHERE Clause and `$` Operator

The WHERE clause uses the special `$` operator to represent the current value being evaluated. When combined with path operations, `$` enables powerful filtering:

- `where $ > 5` — current value exceeds 5
- `where $.status == "active"` — current value has status field equal to "active"
- `where $.tags[*] == "urgent"` — any tag equals "urgent" (existential)
- `where $..technologies[*] == "Python"` — any technologies field at any depth contains "Python"
- `where $ has "field"` — current value contains field "field"

The `has` operator checks field existence, useful for structural filtering rather than value-based filtering.

*WHERE Clause Grammar:*

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

The grammar encodes operator precedence explicitly: `||` (lowest) binds less tightly than `&&`, which binds less tightly than `!` (highest), with parentheses overriding precedence. The `current-value` production allows `$` with all path operations---field access, wildcards, array indexing, and recursive descent (e.g., `$.field[*]`, `$..nested[*]`).

==== Parse-Time Restriction of `$`

The `$` operator is restricted to WHERE clauses through parse-time validation. Attempting to use `$` outside a WHERE clause produces a compile-time error:

```jolie
// INVALID: $ outside WHERE clause
x = $;  // Error: $ can only be used in WHERE clauses
```

The parser maintains an `inWhereClause` flag that is set when entering a WHERE clause and cleared upon exit. When the scanner encounters `$`, the parser checks this flag and rejects the program if `$` appears in an invalid context:

```
/home/matteo/examples/test.ol:15: error: $ can only be used in WHERE clauses

15:        x = $;
              ^
```

This restriction ensures `$` has well-defined semantics---it always refers to the current candidate value during WHERE clause evaluation, never to an undefined or ambient context.

=== Existential Semantics

The WHERE clause uses *existential semantics*: a condition matches if *any* value in the evaluation satisfies it (∃), not all. This is critical for array comparisons.

When path operations with wildcards (`[*]`, `.*`) produce arrays, comparison operators perform element-wise existential matching: the condition succeeds if *any* element from the left operand matches *any* element from the right operand.

In the grandfather example:

```jolie
$.name == $.children[*].children[*].name
```

The expression `$.children[*].children[*].name` expands to an array of all grandchildren names. The equality operator checks if *any* element from the left operand (the grandfather's name) equals *any* element from the right operand array (grandchildren names). This eliminates the need for explicit loops to check "does any element match?"

*Example:* If `$.children[*].children[*].name` yields `["John", "Emma"]`, the condition `$.name == $.children[*].children[*].name` with `$.name = "John"` succeeds because "John" appears in the array.

Similarly, in the companies filtering:

```jolie
$.technologies[*] == "Python"
```

The left operand `$.technologies[*]` produces an array of all technologies for the current project. Internally, the comparison operator converts both operands to arrays: the left side yields multiple values through the wildcard, while the right side literal `"Python"` becomes a singleton array `["Python"]`. The operator then performs a nested iteration over both arrays, succeeding if *any* element from the left matches *any* element from the right. This uniform array-based evaluation applies to all comparison operators—whether comparing array-to-literal (`$.technologies[*] == "Python"`), literal-to-literal (`$.status == "active"`), or array-to-array (`$.children[*].name == $.grandchildren[*].name`)—enabling consistent existential semantics across all operand combinations.

==== Independent Condition Evaluation

Each comparison in a WHERE clause evaluates independently to a boolean, which are then combined by logical operators (`&&`, `||`). Consider querying for employees named "Matteo Rossi":

```jolie
values data where
    $.employees[*].name == "Matteo" &&
    $.employees[*].surname == "Rossi"
```

If the data contains:
- Employee 1: name="Matteo", surname="Maggio"
- Employee 2: name="Roberto", surname="Rossi"

The query *matches* even though no single employee satisfies both conditions:
1. `$.employees[*].name == "Matteo"` evaluates independently → TRUE (Matteo Maggio exists)
2. `$.employees[*].surname == "Rossi"` evaluates independently → TRUE (Roberto Rossi exists)
3. TRUE `&&` TRUE → TRUE

Each comparison produces a boolean result based on its own existential evaluation, without correlation to which specific elements satisfied other comparisons. The logical operators combine these boolean results, not the underlying array elements.

To match a specific employee, reference the same structural level:

```jolie
// Match specific employee
values data.employees[*] where $.name == "Matteo" && $.surname == "Rossi"
```

Here, `$` refers to each employee candidate individually, so both conditions evaluate against the same employee object.

=== The HAS Operator

Standard comparison operators (`==`, `<`, etc.) filter based on *values*—they compare the content stored at a path. However, real-world data often requires *structural* filtering: selecting nodes based on which fields they contain, regardless of the values in those fields.

Consider a common API design challenge: optional fields with semantic meaning. When designing a meeting request API, clients may send:

```json
{ "title": "Sprint Planning", "participants": ["Alice", "Bob"] }
{ "title": "Solo Review" }
{ "title": "Team Sync", "participants": [] }
```

The second request has *no* `participants` field—intuitively meaning "participants not specified." The third has an *empty* `participants` array—meaning "explicitly no participants." These are semantically different: one is unspecified, the other is explicitly empty.

Value-based comparison cannot distinguish these cases. Checking `$.participants == ""` or array length fails when the field is absent entirely. The `has` operator addresses this:

```jolie
// Find meetings where participants were explicitly specified
specified << values requests[*] where $ has "participants"
```

This returns only the first and third requests, filtering based on field *existence* rather than field *value*. Without `has`, defensive programming is required:

```jolie
// Without has: manual existence check
if (is_defined(request.participants)) {
    // process participants
}
```

The `has` operator takes a field name to check:

```jolie
// Filter requests that specify participants
values requests[*] where $ has "participants"

// Combine with value comparisons
values orders[*] where $ has "priority" && $.priority == "high"

// Check nested structure existence
values users[*] where $.profile has "preferences"
```

This structural filtering complements value-based filtering, enabling queries that distinguish "field absent" from "field present but empty"—a distinction that would otherwise require explicit null-checking or try-catch patterns in imperative code.

== Language Extensions

Implementing PATHS and VALUES required extending Jolie's lexical and syntactic infrastructure.

=== New Keywords and Tokens

The scanner recognizes six new tokens:

#table(
  columns: (auto, auto),
  align: (left, left),
  table.header([*Token*], [*Purpose*]),
  table.hline(),
  [`paths`], [Begins a PATHS expression],
  [`values`], [Begins a VALUES expression],
  [`where`], [Introduces the filter clause],
  [`has`], [Structural existence operator],
  [`pval`], [Path evaluation function],
  [`$`], [Current value reference in WHERE],
)

These tokens are registered as unreserved keywords, meaning they can still be used as identifiers in contexts where there is no ambiguity---preserving backward compatibility with existing Jolie programs that may use these names as variables.

== Complexity Analysis

The implementation achieves linear time and space complexity through careful design choices.

=== Time Complexity

The `navigate()` function applies operations sequentially, transforming a set of candidate locations at each step:

```java
List<Candidate> candidates = new ArrayList<>();
candidates.add(new Candidate(rootVec, from.path()[0].key().evaluate().strValue()));

for (PathOperation op : ops) {
    List<Candidate> next = new ArrayList<>();
    candidates.forEach(c -> next.addAll(expand(c, op)));
    candidates = next;
}
```

Each `Candidate` is a lightweight record storing a reference (vector + index) and path string—no value copying occurs. The variable `ops` contains the list of path operations. For example, `data.items[0].name` produces `ops = [Field("items"), ArrayIndex(0), Field("name")]`.

The nested loop structure suggests O(|ops| × |candidates|) complexity. However, |candidates| is not the tree size N—it represents the current working set of locations being navigated. For non-recursive operations, |candidates| is bounded by tree width w (the maximum branching factor encountered), not total tree size. The complexity is thus O(|ops| × w), which is linear in the tree structure being traversed.

Consider how this processes the query `data[*].status` over an array with 5 elements:

```
Tree structure:
data[0].status = "ok"
data[1].status = "pending"
data[2].status = "ok"
data[3].status = "failed"
data[4].status = "pending"

ops = [ArrayWildcard(), Field("status")]

Initial:
  candidates = [(ref: data, path: "data")]

Step 1: Apply ArrayWildcard()
  Process 1 candidate (data) → produces 5 candidates
  candidates → [(ref: data[0], path: "data[0]"),
                (ref: data[1], path: "data[1]"),
                (ref: data[2], path: "data[2]"),
                (ref: data[3], path: "data[3]"),
                (ref: data[4], path: "data[4]")]
  Work: O(5)

Step 2: Apply Field("status")
  Process 5 candidates → produces 5 candidates
  (ref: data[0], "data[0]") → (ref: data[0].status, "data[0].status")
  (ref: data[1], "data[1]") → (ref: data[1].status, "data[1].status")
  (ref: data[2], "data[2]") → (ref: data[2].status, "data[2].status")
  (ref: data[3], "data[3]") → (ref: data[3].status, "data[3].status")
  (ref: data[4], "data[4]") → (ref: data[4].status, "data[4].status")
  Work: O(5)

Total work: O(1 + 5 + 5) = O(11)
Total candidates processed: 1 + 5 + 5 = 11
Complexity: O(|ops| × w) where w = 5 (array size)
```

Visualization of the transformation:

#figure(
  diagram(
    node-stroke: 1pt,
    spacing: (8pt, 20pt),

    node((2, 0), [data]),
    edge((2, 0), (0, 1), "-"),
    edge((2, 0), (1, 1), "-"),
    edge((2, 0), (2, 1), "-", label-side: right, [`[*]`]),
    edge((2, 0), (3, 1), "-"),
    edge((2, 0), (4, 1), "-"),

    node((0, 1), [data\[0\]]),
    node((1, 1), [data\[1\]]),
    node((2, 1), [data\[2\]]),
    node((3, 1), [data\[3\]]),
    node((4, 1), [data\[4\]]),

    edge((0, 1), (0, 2), "-"),
    edge((1, 1), (1, 2), "-"),
    edge((2, 1), (2, 2), "-", label-side: right, [.status]),
    edge((3, 1), (3, 2), "-"),
    edge((4, 1), (4, 2), "-"),

    node((0, 2), [data\[0\].status]),
    node((1, 2), [data\[1\].status]),
    node((2, 2), [data\[2\].status]),
    node((3, 2), [data\[3\].status]),
    node((4, 2), [data\[4\].status]),
  ),
  caption: [Linear traversal: each node visited once per operation, references only]
)

Each operation transforms the current candidate set by creating new references, never copying tree data.

Work per operation type (per candidate):

- *Field access* (`.field`): O(1) via hash map lookup
- *Array index* (`[n]`): O(1) via direct access
- *Field wildcard* (`.*`): O(k) where k = number of fields in that node
- *Array wildcard* (`[*]`): O(m) where m = array size of that node
- *Recursive descent* (`..field`, `..*`): O(N) via breadth-first search over the entire subtree

For non-recursive operations, the total complexity is O(|ops| × w) where w is the maximum width (branching factor) encountered during traversal—bounded by tree structure, not tree size N.

For recursive operations (`..field`, `..*`), the single operation itself performs a breadth-first search over all N nodes, dominating the complexity: O(N) regardless of |ops|.

=== Space Complexity

Navigation creates `Candidate` wrapper objects without copying values:

```java
// Candidate stores: (ValueVector reference, index, path string)
record Candidate(ValueVector vector, UnsignedInteger index, String path) {
    Value value() { return vector.get(index.intValue()); }
}

// Field access: return reference wrapper, no cloning
ValueVector vec = c.value().children().get(name);
yield List.of(new Candidate(vec, c.path() + "." + name));
```

For N matching nodes, space complexity is O(N × d) where d is tree depth:
- N `Candidate` objects, each O(1) + path string of length O(d)
- No tree data duplication

The `VALUES` expression performs deep copy only for matching results into the result array—after filtering, not during traversal.

== Performance Evaluation <evaluation>

This section presents empirical evaluation of the PATHS and VALUES primitives, comparing their performance against traditional imperative loops. The benchmarks use the same dataset, query, and test environment described in the TQuery evaluation (@background), enabling direct comparison. Since PATHS and VALUES share the same navigation and filtering implementation—differing only in whether they return path references or deep-copied values—we benchmark VALUES as representative of both primitives. TQuery is not included in these benchmarks because, as demonstrated in @background, it exhausts available memory and terminates under concurrent load, making comparison at these concurrency levels unfeasible.

=== Implementations Compared

The benchmark compares the imperative nested for-loop implementation from @background against an equivalent VALUES query:

```jolie
data -> global.data;
results << values data.companies[*].company.departments[*].teams[*].projects[*]
    where $.status == request.status && $.technologies[*] == request.technology
```

=== Benchmark Execution

Both implementations handle concurrent HTTP requests at increasing load levels (100–500 parallel requests). Each concurrency level is repeated 20 times; results report mean and standard deviation. We measure P50 and P95 latency—the response times below which 50% and 95% of requests complete, respectively—as well as peak heap usage and young generation garbage collection frequency via `jstat`. Both latency plots share the same Y-axis scale to allow direct visual comparison.

=== Results

#figure(
  image("pv_benchmark_results.png"),
  caption: [Performance comparison: PATHS/VALUES vs Imperative across concurrency levels (mean ± std dev, N=20 runs)]
)

VALUES achieves *24–35% lower median latency* across all concurrency levels. At 500 concurrent requests, mean P50 drops from 3,099ms to 2,346ms. These gains stem from iterative in-place descent over Jolie's internal structures, early termination via existential semantics, and reduced instruction overhead—the Jolie-level loop machinery is replaced by Java-native traversal in the runtime.

Garbage collection events decrease by *30–34%* consistently across all levels, indicating lower object allocation during query execution.

Peak memory is the only metric where imperative loops outperform VALUES: the imperative approach uses less heap across all concurrency levels tested, with the gap widening under higher load. This is expected, as VALUES builds intermediate candidate lists during traversal, while the imperative approach processes elements incrementally.

Overall, PATHS/VALUES delivers both simpler code and better latency—contradicting the common assumption that declarative abstractions necessarily sacrifice efficiency for expressiveness.
