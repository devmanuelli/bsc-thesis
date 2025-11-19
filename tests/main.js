const fs = require('fs');

function findMatchingGrandfathers(persons) {
    return persons
        .filter(person => person.sex === 'Male')
        .filter(person =>
            person.children
                .flatMap(child => child.children)
                .some(grandchild => grandchild.name === person.name)
        );
}

const data = fs.readFileSync('test-data.json', 'utf8');
const persons = JSON.parse(data);

const result = findMatchingGrandfathers(persons);

console.log(`Found ${result.length} matching grandfathers:`);
result.forEach(grandfather => {
    console.log(`- ${grandfather.name} ${grandfather.surname}`);
});
