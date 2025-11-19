import ballerina/io;

enum Sex {
    MALE = "Male",
    FEMALE = "Female"
}

type Person record {
    string name;
    string surname;
    Sex sex;
    Person[] children;
};

function findMatchingGrandfathers(Person[] persons) returns Person[] {
    return from var person in persons
        where person.sex == MALE
        where (from var child in person.children
               from var grandchild in child.children
               where grandchild.name == person.name
               select 1).length() > 0
        select person;
}

public function main() returns error? {
    json data = check io:fileReadJson("test-data.json");
    Person[] persons = check data.fromJsonWithType();

    Person[] result = findMatchingGrandfathers(persons);

    io:println(string `Found ${result.length()} matching grandfathers:`);
    foreach var grandfather in result {
        io:println(string `- ${grandfather.name} ${grandfather.surname}`);
    }
}
