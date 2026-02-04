= The Native `path` Type and `pval` <path-pval>

This chapter introduces the native path primitive type and the `pval()` function operator for dereferencing path values. We begin by examining the design rationale for `pval()` as a distinct operator rather than extending existing syntax. The path type is then presented as a first-class primitive, with discussion of its protocol-agnostic communication properties including wire format representation and type validation at message boundaries. The `pval()` function is explored in detail, demonstrating its use for reading values, writing values, and performing deep copies. We examine the two-phase query pattern enabled by separating path collection from value access, and conclude with runtime type checking mechanisms that ensure type safety without repeated validation.

The `paths` expression returns values representing locations in a tree structure. However, these values cannot be used directly---they are symbolic references, not the actual data. Without a mechanism to dereference them, `paths` results would be useless. The `pval()` function bridges this gap, converting path references into accessible values.

== Design Consideration: Why `pval()`?

Jolie already supports dynamic field names through parenthesized expressions in paths:

```jolie
fieldName = "status";
x = order.(fieldName);  // Equivalent to order.status
```

A natural extension would be to use similar syntax for path dereferencing:

```jolie
// Hypothetical syntax (NOT implemented)
result = (pathVar).field;
```

However, this approach would break the parser. Jolie's grammar allows parentheses in multiple contexts: grouping expressions `(a + b)`, function calls `foo()`, and dynamic field access `a.(expr).c`. Adding `(expr).field` as a standalone construct would make the grammar ambiguous---the parser could not distinguish between a parenthesized expression and a path dereference without unbounded lookahead, violating context-free grammar requirements.

The `pval()` function provides an unambiguous alternative. The `pval` keyword signals path evaluation, and parentheses serve their standard role of delimiting the argument:

```jolie
result = pval(pathVar).field;  // Unambiguous: evaluate path, then access field
```

== The `path` Primitive Type

The `path` type is a new Jolie primitive that stores a symbolic location such as `mydata[1]` or `tree.field[2].subfield`. Unlike strings, paths are structured references that the runtime can resolve to actual tree locations.

The implementation adds `ValuePath` to the Jolie runtime:

```java
public class ValuePath {
    private final String path;

    public ValuePath(String path) {
        this.path = path;
    }

    public String getPath() {
        return path;
    }
}
```

The `Value` class gains methods for path handling: `isPath()`, `pathValue()`, `setValue(ValuePath)`, and `create(ValuePath)`. Type checking works as expected:

```jolie
res << paths data[*] where $ > 100;
if (res.results[0] instanceof path) {
    println@Console("Got a path value")()
}
```

=== Protocol-Agnostic Communication

As a primitive type, `path` must be sendable as messages across services, just like other primitive types such as `int`, `string`, or `bool`.

```jolie
type PathRequest {
    target: path
}

type PathResponse {
    resolved: path
    value: any
}

interface PathResolver {
    RequestResponse:
        resolve(PathRequest)(PathResponse)
}
```

==== Wire Format: No Type Metadata

Jolie's type system operates on interface contracts, not wire-level metadata. When a `path` value is transmitted, it is serialized as a plain string without special type markers. For example, the path `data[1].field` appears on the wire as:

- *JSON*: `{"target": "data[1].field"}`
- *XML*: `<target>data[1].field</target>`
- *Binary (SODEP)*: String type header + encoded path string

This design keeps wire formats simple and protocol-agnostic. The interface contract—not the message payload—declares that `target` has type `path`.

==== Type Validation at Message Boundaries

Since wire formats carry no type metadata, incoming messages must be validated against their interface contracts. When a service receives a message declaring a `path` field, the type system validates that the received string is a valid instance of the path grammar.

The validation process:
1. Check if the value is already a `ValuePath` object (values from PATHS primitives or already validated within this runtime)
2. If not, attempt to parse the string as a path expression
3. Verify the string conforms to the path grammar (identifiers, field accesses, array indices)
4. Reject malformed paths with a type error

This approach ensures type safety without trusting external input. The interface contract defines what type is expected (`path`), and the type system enforces this by validating the structural correctness of received strings against the grammar.

*Important*: Path validation occurs only at _external_ service boundaries—when path values cross input/output ports between independent services. Embedded services operating within the same runtime do not trigger validation. Values already validated—whether from PATHS primitives or previous type checks within the same runtime—skip re-validation for efficiency, but any string received over the wire is always validated to ensure it represents a legitimate path expression.

== The `pval()` Function

The `pval()` function---short for "path evaluation"---dereferences a path to access the actual data at that location. Importantly, *`pval()` works both as an lvalue (for writing/modifying data) and as an rvalue (for reading data)*, providing complete bidirectional access through path references.

=== Syntax

```
pval( path-clause ) suffix*
```

The function takes a path value and returns a reference to the actual data. Optional suffixes (`.field`, `[n]`) allow further navigation from the dereferenced location.

=== Reading Values

```jolie
mydata[0] = 100;
mydata[1] = 200;
mydata[1].child = "one";
mydata[2] = 300;
mydata[2].child = "two";

// Get paths to elements > 150
res << paths mydata[*] where $ > 150;
// res.results contains: mydata[1], mydata[2]

// Dereference to get actual values
readVal = pval(res.results[0]);        // Returns 200
childVal = pval(res.results[0]).child; // Returns "one"
```

Path navigation composes after dereferencing:

```jolie
mydata[1].children[0] = "first";
mydata[1].children[1] = "second";
arrayVal = pval(res.results[0]).children[1];  // Returns "second"

mydata[1].nested.items[1].name = "item1";
nestedVal = pval(res.results[0]).nested.items[1].name;  // Returns "item1"
```

=== Writing Values

The `pval()` function also works as an lvalue---the left side of an assignment:

```jolie
toUpdate << paths orders[*] where $.status == "pending";

for (i = 0, i < #toUpdate.results, i++) {
    pval(toUpdate.results[i]).status = "processed"
}
```

The parser recognizes `pval(...) = expr` as an assignment statement, generating a `PvalAssignStatement` AST node.

=== Deep Copy

For tree assignment (the `<<` operator), `pval()` supports deep copying entire subtrees into path-referenced locations:

```jolie
// Create a template with nested structure
newData << {
    x = 100
    y = 200
    label = "point"
    nested.a = 1
    nested.b = 2
};

// Find matching records and copy template into each
res << paths data._[*] where $.status == "pending";
for (i = 0, i < #res.results, i++) {
    pval(res.results[i]).extra << newData
}
// Each matching record now has an 'extra' subtree with the full template
```

The parser recognizes `pval(...) << expr` as a deep copy statement, generating a `PvalDeepCopyStatement` AST node that performs a full tree copy to the dereferenced location.

=== Key Capabilities

The `pval()` function provides comprehensive access to path-referenced data:

- *Works as lvalue*: Can modify data through path references (`pval(path).field = value`)
- *Works as rvalue*: Can read data through path references (`x = pval(path).field`)
- *Works with nested fields*: Supports deep navigation (`pval(path).field.subfield`)
- *Works with arrays*: Supports array indexing (`pval(path).array[0]`)
- *Supports both `=` and `<<`*: Simple assignment vs deep copy
- *Can be used in expressions*: Arithmetic (`total = pval(p1).value + pval(p2).value`), conditions (`if (pval(path).salary > 50000)`)
- *Path-to-path operations*: Direct transfers (`pval(dest) << pval(src)`)

== Reference vs. Copy Semantics

A critical distinction exists between `values` and `paths` with `pval()`:

- *`values`* returns *deep copies*---modifying results does not affect the original data
- *`paths` + `pval()`* provides *references*---modifications through `pval()` affect the original data

```jolie
readFile@File({ filename = "data.json", format = "json" })(data);

// VALUES: deep copy semantics
res << values data._[*] where $.status == "active";
res.results[0].status = "modified";
// data._[0].status is UNCHANGED - res contains independent copies

// PATHS + pval: reference semantics
res << paths data._[*] where $.status == "active";
pval(res.results[0]).status = "modified";
// data._[0].status IS CHANGED - pval provides a reference to original
```

This distinction determines which approach to use:
- Use `values` when you need isolated copies for transformation or output
- Use `paths` + `pval()` when you need to modify the original data structure

== Two-Phase Query Pattern

The combination of `paths` and `pval()` enables a two-phase pattern:

1. *Query phase*: Use `paths` to find locations matching criteria
2. *Access phase*: Use `pval()` to read or modify those locations

```jolie
// Phase 1: Find all high-priority items
highPriority << paths tasks[*] where $.priority == "high";

// Phase 2: Process each one
for (i = 0, i < #highPriority.results, i++) {
    path = highPriority.results[i];
    println@Console("Processing: " + pval(path).name)();
    pval(path).processed = true
}
```

The `path` values act as stable references---even as the loop modifies data, the paths remain valid.

== Runtime Type Checking

The `pval()` function checks the nominal type of its argument—verifying it is a `path` type value:

```java
// PvalHelper.resolveVariablePath()
if (!value.isPath()) {
    throw new FaultException("TypeMismatch",
        "pval requires a path type value, got: " + value.strValue());
}
```

This check occurs at evaluation time:

```jolie
x = "not a path";
y = pval(x);  // Throws: TypeMismatch: pval requires a path type value
```

Crucially, the implementation checks only the nominal type, not the internal path structure. This is sound because `path` values have a strong origin guarantee: they can only be created by the `paths` primitive or received via message passing. Both sources ensure structural validity:

- *PATHS primitive*: Constructs `ValuePath` objects directly from successful tree navigation
- *Message passing*: Type system enforces `path` type contracts at communication boundaries

Once the nominal type check succeeds, the runtime has a guarantee that the internal path string is well-formed—no repeated parsing or validation is needed.
