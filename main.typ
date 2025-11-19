// Example thesis document

#import "template.typ": thesis

#show: thesis.with(
  title: "Your Thesis Title Here",
  author: "Your Name",
  supervisor: "Prof. Supervisor Name",
  department: "Department of Computer Science and Engineering",
  degree: "Master's Degree in Computer Science",
  academic-year: "2024/2025",
  session: "March",
)

= Introduction

Your content goes here.

#bibliography("bibliography.bib", title: "Bibliography", style: "ieee")
