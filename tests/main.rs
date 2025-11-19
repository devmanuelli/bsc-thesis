use serde::{Deserialize, Serialize};
use std::fs;

#[derive(Debug, Serialize, Deserialize, PartialEq)]
enum Sex {
    Male,
    Female,
}

#[derive(Debug, Serialize, Deserialize)]
struct Person {
    name: String,
    surname: String,
    children: Vec<Person>,
    sex: Sex,
}

fn find_matching_grandfathers(persons: &[Person]) -> Vec<&Person> {
    persons
        .iter()
        .filter(|person| person.sex == Sex::Male)
        .filter(|person| {
            person
                .children
                .iter()
                .flat_map(|child| child.children.iter())
                .any(|grandchild| grandchild.name == person.name)
        })
        .collect()
}

fn main() {
    let data = fs::read_to_string("test-data.json").expect("failed to read test data");

    let persons: Vec<Person> = serde_json::from_str(&data).expect("failed to parse test data");

    let result = find_matching_grandfathers(&persons);

    println!("Found {} matching grandfathers:", result.len());
    for grandfather in result {
        println!("- {} {}", grandfather.name, grandfather.surname);
    }
}
