// Example thesis document

#import "template.typ": thesis

#show: thesis.with(
  title: "Your Thesis Title Here",
  author: "Matteo Manuelli",
  supervisor: "Prof. Saverio Giallorenzo",
  department: "Department of Computer Science and Engineering",
  degree: "Master's Degree in Computer Science",
  academic-year: "2024/2025",
  session: "March",
)

#include "introduction.typ"

#include "background.typ"

#include "paths-values.typ"

#include "path-pval.typ"

#include "conclusion.typ"

#bibliography("bibliography.bib", title: "Bibliography", style: "ieee")
