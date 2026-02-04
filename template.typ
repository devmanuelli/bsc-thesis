// Minimal University of Bologna thesis template
// Fully compliant with official Unibo specs

#let thesis(
  title: "",
  author: "",
  supervisor: "",
  cosupervisor: "",
  department: "",
  degree: "",
  academic-year: "",
  session: "",
  body,
) = {
  set document(author: author, title: title)

  // Margins: 2.5cm on all sides + 0.5cm binding offset (inner margin)
  // Double-sided printing (recto/verso)
  set page(
    margin: (
      top: 2.5cm,
      bottom: 2.5cm,
      inside: 3cm,      // 2.5cm + 0.5cm binding offset
      outside: 2.5cm,
    ),
    numbering: none,
    binding: left,      // Binding on left side
  )

  // Font: Libertinus Serif, 12pt, justified, 1.5 line spacing
  // No paragraph indent (Unibo requirement)
  set text(font: "Libertinus Serif", size: 12pt, lang: "en")
  set par(justify: true, leading: 0.65em, first-line-indent: 0em)

  // Specs: 10pt footnotes
  show footnote: set text(10pt)

  // Frame code blocks
  show raw.where(block: true): it => block(
    fill: luma(250),
    stroke: 0.5pt + luma(200),
    inset: 10pt,
    radius: 4pt,
    width: 100%,
    breakable: false,
    it
  )

  // Cover page replaced by official Unibo LaTeX frontespizio (frontespizio.pdf)
  // See main.typ for inclusion

  // Dedication page
  v(3cm)
  align(right)[
    #text(style: "italic")[
      Ad Annagiuli#text(style: "italic", weight: "bold")[etta],\
      anche se fa sempre molto arrabbiare tutti!
    ]
  ]
  v(1fr)
  pagebreak()

  // Table of contents
  outline(title: "Table of Contents", depth: 3)
  pagebreak()

  // Main content
  set page(numbering: "1", number-align: center)
  counter(page).update(1)
  set heading(numbering: "1.1")

  // Sections MUST start on odd pages (Unibo requirement)
  // Display as "Chapter N" on one line, then "Title" on next line
  show heading.where(level: 1): it => {
    pagebreak(to: "odd")
    block(spacing: 1.5em)[
      #text(size: 60pt, weight: "bold")[
        Chapter #counter(heading).display()
      ]
      #v(0.5em)
      #text(size: 28pt, weight: "bold")[
        #it.body
      ]
    ]
  }

  body
}
