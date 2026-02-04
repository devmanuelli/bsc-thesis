// Example thesis document

// Official Unibo frontespizio (generated from LaTeX template)
#set page(margin: 0pt)
#image("frontespizio.pdf", width: 100%, height: 100%)
#pagebreak()

#import "template.typ": thesis

#show: thesis.with(
  title: "Native Operators for the Efficient Query of Jolie Tree-like Values",
  author: "Matteo Manuelli",
  supervisor: "Dott. Saverio Giallorenzo",
  cosupervisor: "Dott. Claudio Guidi",
  department: "Dipartimento di Informatica - Scienza e Ingegneria",
  degree: "Corso di Laurea in Informatica",
  academic-year: "2024/2025",
  session: "March",
)

#include "introduction.typ"

#include "background.typ"

#include "paths-values.typ"

#include "path-pval.typ"

#include "conclusion.typ"

// Remove "Chapter N" prefix from bibliography heading
#show heading.where(level: 1): it => {
  pagebreak(to: "odd")
  block(spacing: 1.5em)[
    #text(size: 20pt, weight: "bold")[
      #it.body
    ]
  ]
}

#set heading(numbering: none)
#bibliography("bibliography.bib", title: "Bibliography", style: "ieee")
