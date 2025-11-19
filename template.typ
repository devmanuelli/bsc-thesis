// Minimal University of Bologna thesis template
// Compliant with official Unibo specs

#let thesis(
  title: "",
  author: "",
  supervisor: "",
  department: "",
  degree: "",
  academic-year: "",
  session: "",
  body,
) = {
  set document(author: author, title: title)

  // Specs: 2.5cm + 0.5-0.8cm binding offset on spine (left)
  set page(
    margin: (left: 31mm, right: 25mm, top: 25mm, bottom: 25mm),
    numbering: none,
  )

  // Specs: Serif font, 12pt, justified, 1.5 line spacing
  set text(font: "Linux Libertine O", size: 12pt, lang: "en")
  set par(justify: true, leading: 0.75em)

  // Specs: 10pt footnotes
  show footnote: set text(10pt)

  // Cover page (no logo - prohibited by university)
  align(center)[
    #v(4cm)
    #text(14pt, smallcaps[Alma Mater Studiorum]) \
    #v(0.5em)
    #text(16pt, weight: "bold")[Università di Bologna]
    #v(2cm)

    #department \
    #text(weight: "bold")[#degree]
    #v(3cm)

    #text(20pt, weight: "bold")[#title]
    #v(2cm)

    #grid(
      columns: (1fr, 1fr),
      [*Supervisor:* \ #supervisor],
      [*Presented by:* \ #author]
    )

    #v(1fr)
    #text(11pt)[
      Graduation session of #session \
      Academic year #academic-year
    ]
    #v(1cm)
  ]

  pagebreak()

  // Table of contents
  outline(title: "Table of Contents", depth: 3)
  pagebreak()

  // Main content
  set page(numbering: "1", number-align: center)
  counter(page).update(1)
  set heading(numbering: "1.1")

  // Specs: sections start on odd pages only
  show heading.where(level: 1): it => {
    pagebreak(to: "odd")
    it
  }

  body
}
