#let go-code = ```go
func findMatchingGrandfathers(persons []Person) []Person {
    var result []Person

    for _, person := range persons {
        if person.Sex != Male {
            continue
        }

        for _, child := range person.Children {
            for _, grandchild := range child.Children {
                if grandchild.Name == person.Name {
                    result = append(result, person)
                }
            }
        }
    }

    return result
}
```

#let rust-code = ```rust
fn find_matching_grandfathers(persons: &[Person]) -> Vec<&Person> {
    persons
        .iter()
        .filter(|person| person.sex == Sex::Male)
        .filter(|person| {
            person.children
                .iter()
                .flat_map(|child| child.children.iter())
                .any(|grandchild| grandchild.name == person.name)
        })
        .collect()
}
```

#let js-code = ```javascript
function findMatchingGrandfathers(persons) {
    return persons
        .filter(person => person.sex === 'Male')
        .filter(person =>
            person.children
                .flatMap(child => child.children)
                .some(grandchild => grandchild.name === person.name)
        );
}
```

#let ballerina-code = ```ballerina
function findMatchingGrandfathers(Person[] persons) returns Person[] {
    return from var person in persons
        where person.sex == MALE
        where (from var child in person.children
               from var grandchild in child.children
               where grandchild.name == person.name
               select 1).length() > 0
        select person;
}
```

#let go-lines = go-code.text.split("\n").len()
#let rust-lines = rust-code.text.split("\n").len()
#let js-lines = js-code.text.split("\n").len()
#let ballerina-lines = ballerina-code.text.split("\n").len()

== Querying Hierarchical Data: A Cross-Language Comparison

To illustrate the challenges of querying hierarchical data in traditional programming languages, consider a family tree dataset with the following structure:

```go
type Person struct {
    Name     string   `json:"name"`
    Sex      string   `json:"sex"`
    Children []Person `json:"children"`
}
```

This represents a nested tree where each `Person` has a name, sex, and zero or more children, who themselves may have children (grandchildren from the original person's perspective). Example data:

```json
[
  {
    "name": "John Smith",
    "sex": "Male",
    "children": [
      {
        "name": "Alice Smith",
        "sex": "Female",
        "children": [
          { "name": "John Smith", "sex": "Male", "children": [] }
        ]
      }
    ]
  }
]
```

*Query Goal:* Find all grandfathers (male persons) whose name matches at least one of their grandchildren. This requires:
1. Filtering to male persons only
2. Traversing two levels of nesting (person → children → grandchildren)
3. Checking if any grandchild's name matches the grandfather's name
4. Collecting matching results

Each language implements this query differently:

*Go* (#go-lines lines): Implements the query imperatively with explicit nested loops and manual control flow. Requires manual iteration state management and explicit result collection using `append()`.

#go-code

*Rust* (#rust-lines lines): Uses functional iterator combinators (`filter`, `flat_map`, `any`) to express the query declaratively. The iterator chain avoids explicit loops, but still requires manual flattening of nested structures and complexity in expressing the "grandchild matches name" condition across closure boundaries.

#rust-code

*JavaScript* (#js-lines lines): Leverages array methods (`filter`, `flatMap`, `some`) for a functional approach similar to Rust. The `flatMap` operation flattens the two-level nesting (children → grandchildren) in a single step, and `some` checks for name matches. However, the nested anonymous functions and method chaining can obscure the query logic.

#js-code

*Ballerina* (#ballerina-lines lines): Uses language-integrated query expressions (LINQ-style) with `from`/`where`/`select` clauses. The nested query expression checks for matching grandchildren, but requires computing the length of the result set to determine if any match exists, which is less direct than checking existence.

#ballerina-code
