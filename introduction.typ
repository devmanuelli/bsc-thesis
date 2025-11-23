= Introduction

Distributed systems are ubiquitous in modern computing, from household devices to global cloud platforms. Programming these systems introduces challenges beyond sequential programming: services must communicate across network boundaries, handle heterogeneous protocols, and process structured data exchanged in formats like JSON and XML.

Jolie is a programming language designed specifically for service-oriented distributed systems. Its distinctive feature is _protocol independence_: business logic remains unchanged whether services communicate via HTTP, SOAP, or binary protocols. This separation between behavior and deployment simplifies integration across heterogeneous systems.

Jolie extends this philosophy to data representation through _tree-structured variables_. Every variable in Jolie is a tree that can hold a root value and arbitrarily nested children. This design eliminates the impedance mismatch between the hierarchical data formats services exchange (JSON, XML) and the language's native data model---no serialization libraries or schema bindings required.

However, while Jolie's tree variables elegantly represent structured data, the language provides no native primitives for _querying_ these structures. Developers must write nested loops to traverse and filter tree data, negating the declarative benefits of the tree abstraction. TQuery, an external library, addressed this gap by introducing MongoDB-style operators, but its specification requires deep cloning during operations, resulting in significant memory overhead---benchmarks show 10× memory consumption compared to imperative loops.

This thesis presents *PATHS* and *VALUES*, native Jolie language primitives for declarative tree querying. By directly exploiting Jolie's internal tree representation, these primitives eliminate both the verbosity of imperative traversal and the performance penalties of external libraries. A query that previously required nested loops or incurred substantial memory duplication becomes a single declarative expression.

The remainder of this thesis is organized as follows. @background provides essential background on Jolie's architecture, tree variable model, and the TQuery library's limitations. @paths-values presents the PATHS and VALUES primitives, their syntax and semantics. @path-pval introduces the native `path` type and the `pval()` function for dereferencing path values. @conclusion summarizes contributions and discusses future work.
