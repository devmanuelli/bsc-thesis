package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
)

type Sex string

const (
	Male   Sex = "Male"
	Female Sex = "Female"
)

type Person struct {
	Name     string   `json:"name"`
	Surname  string   `json:"surname"`
	Children []Person `json:"children"`
	Sex      Sex      `json:"sex"`
}

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

func main() {
	data, err := os.ReadFile("test-data.json")
	if err != nil {
		log.Fatal(err)
	}

	var persons []Person
	if err := json.Unmarshal(data, &persons); err != nil {
		log.Fatal(err)
	}

	result := findMatchingGrandfathers(persons)

	fmt.Printf("Found %d matching grandfathers:\n", len(result))
	for _, grandfather := range result {
		fmt.Printf("- %s %s\n", grandfather.Name, grandfather.Surname)
	}
}
