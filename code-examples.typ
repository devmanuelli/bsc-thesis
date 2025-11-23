#let go-code = ```go
func findMatchingGrandfathers(persons []Person) []Person {
    var result []Person

    for _, person := range persons {
        if person.Sex != Male {
            continue
        }

        found := false
        for _, child := range person.Children {
            for _, grandchild := range child.Children {
                if grandchild.Name == person.Name {
                    result = append(result, person)
                    found = true
                    break
                }
            }
            if found {
                break
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

== Tree Traversal Complexity in Traditional Languages

Go: #go-lines lines

#go-code

Rust: #rust-lines lines

#rust-code

JavaScript: #js-lines lines

#js-code

Ballerina: #ballerina-lines lines

#ballerina-code
