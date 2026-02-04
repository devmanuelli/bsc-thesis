= Conclusion <conclusion>

This thesis presented PATHS and VALUES, native Jolie language primitives for declarative tree querying. By extending the Jolie parser, runtime, and type system, these primitives enable expressive queries over tree-structured data without external dependencies or performance penalties.

== Summary of Contributions

The main contributions of this work are:

1. *Native path operations*: Six composable operations (`.field`, `.*`, `[n]`, `[*]`, `..field`, `..*`) for flexible tree navigation, integrated directly into the Jolie language syntax.

2. *WHERE clause with existential semantics*: A filtering mechanism using the `$` operator to reference the current value, supporting boolean expressions with existential matching---a condition succeeds if any value satisfies it.

3. *The HAS operator*: Structural filtering based on field existence rather than field values, distinguishing "field absent" from "field present but empty."

4. *Native path type and pval*: A new `path` type representing tree locations, with `pval()` for dereferencing paths to actual values, enabling two-phase query-then-access patterns.

5. *Zero-copy evaluation*: By operating directly on Jolie's internal `Value` and `ValueVector` structures, PATHS and VALUES avoid the deep cloning required by TQuery's specification, eliminating the substantial memory overhead observed in benchmarks.

== Addressing the Challenges

Returning to the hierarchical querying challenges illustrated in Chapter 2, PATHS and VALUES provide unified solutions where previous approaches required trade-offs.

*The grandfather name-matching query*, which required imperative nested loops (@imperative-grandfather) or TQuery's multi-stage pipelines (@tquery-grandfather), reduces to:

```jolie
values data._[*] where
    $.sex == "Male" &&
    $.name == $.children[*].children[*].name
```

The query traverses all persons, filters for males, and checks if any grandchild shares the grandfather's name—all in three lines without explicit loops or intermediate variables.

*The companies-departments-teams-projects filtering*, which necessitated MongoDB's complex nested `$reduce` or memory-intensive `$unwind` cascades, becomes:

```jolie
values data.companies[*].company.departments[*].teams[*].projects[*]
    where $.status == "in_progress" && $.technologies[*] == "Python"
```

The path expression navigates four levels deep with wildcard array expansion, while the WHERE clause filters by status and technology in a single declarative statement—eliminating the need for nested `$reduce` functions or memory-intensive `$unwind` stages.

Where previous approaches forced choices between expressiveness and efficiency, schema design and query complexity, or memory overhead and readability, PATHS and VALUES achieve all objectives simultaneously through native integration with Jolie's tree-structured data model.

== Future Work

Several directions remain for future exploration:

*Additional operators*: The current WHERE clause supports comparison and logical operators. Extending with aggregation functions (`count`, `sum`, `avg`) or set operations (`in`, `all`) would increase expressiveness. A `project` operator, inspired by TQuery, could reshape query results by selecting and renaming specific fields, eliminating manual iteration for result formatting.

*Query optimization*: The current implementation evaluates queries eagerly. Lazy evaluation or query plan optimization could improve performance for large datasets or complex conditions.

*Integration with type system*: Stronger static guarantees about path validity and result types could catch errors at compile time rather than runtime.

*Formal semantics*: A formal specification of PATHS and VALUES semantics would enable correctness proofs and guide future extensions.

*Path manipulation service*: A dedicated service for `path` value manipulation would enable operations like path concatenation, decomposition, and conversion between path values and strings, supporting dynamic path construction and introspection.
