#let _draft = state("resolution-draft", false)

/// Fill-in placeholder. Highlighted when `draft: true`.
#let blank(body) = context {
  if _draft.get() {
    highlight(fill: rgb("#fff3a3"), extent: 1pt)[\[#body\]]
  } else [\[#body\]]
}

/// Reference to a section of the Corporation's Bylaws.
#let bylaws(sec) = [Section #sec of the Bylaws]

#let _words = ("zero", "one", "two", "three", "four", "five", "six", "seven",
  "eight", "nine", "ten", "eleven", "twelve")
/// "four (4)"
#let num-words(n) = if n < _words.len() [#_words.at(n) (#n)] else [#n]

#let _fmt-date(d) = if type(d) == datetime {
  d.display("[month repr:long] [day padding:none], [year]")
} else if d == none { blank[Date] } else { d }

// ---- Clause machinery ------------------------------------------------------------

#let _resolved-count = counter("resolution-resolved")
#let _article-count = counter("resolution-article")

/// Numbered topical heading ("1. Title"). Resets RESOLVED sequencing.
#let article(body) = {
  _article-count.step()
  _resolved-count.update(0)
  block(sticky: true, above: 1.4em, below: 0.75em, text(weight: "bold",
    context [#_article-count.display("1.")#h(0.5em)#body]))
}

/// Unnumbered bold heading (e.g. "Counterparts; Electronic Signatures").
#let subhead(body) = {
  _resolved-count.update(0)
  block(sticky: true, above: 1.4em, below: 0.75em, text(weight: "bold", body))
}

/// Recital. Supply the text that follows "WHEREAS,".
#let whereas(body) = par[#strong[WHEREAS], #body]

/// Transition from recitals to resolutions.
#let now-therefore(body: [the Board hereby adopts the following resolutions:]) = par[
  #strong[NOW, THEREFORE], #body
]

/// Operative clause. First in each article reads "RESOLVED"; subsequent ones
/// read "RESOLVED FURTHER". Override with `lead: "..."`.
#let resolved(lead: auto, body) = {
  _resolved-count.step()
  context {
    let n = _resolved-count.get().first()
    let l = if lead != auto { lead } else if n <= 1 { "RESOLVED" } else { "RESOLVED FURTHER" }
    par[#strong[#l], #body]
  }
}

/// Lettered list inside a clause.
#let items(..entries) = pad(left: 2em, enum(numbering: "(a)", spacing: 0.7em,
  ..entries.pos()))

/// Indented list of names.
#let names(..entries) = pad(left: 3em, stack(spacing: 0.65em, ..entries.pos()))

/// Exhibit on a new page.
#let exhibit(letter, title, body) = {
  pagebreak(weak: true)
  align(center)[
    #text(weight: "bold")[EXHIBIT #letter]
    #v(0.4em)
    #text(weight: "bold")[#upper(title)]
  ]
  v(1em)
  body
}

// ---- Signature block --------------------------------------------------------------

#let _sig(name, role, date: none) = block(breakable: false, width: 100%, below: 2em)[
  #set par(justify: false, spacing: 0.5em)
  #v(2.6em)
  #box(width: 50%, line(length: 100%, stroke: 0.6pt))\
  #if name == none [#box(width: 50%, blank[Name])] else [#name]\
  #role
  #v(0.4em)
  Date:#h(0.4em)#box(width: 22%, stroke: (bottom: 0.6pt), outset: (bottom: 2pt),
    if date != none { _fmt-date(date) })
]

// ---- Main template -------------------------------------------------------------------

#let resolution(
  // Corporation
  corporation: "Project Pixel Orbital",
  entity: "a California nonprofit public benefit corporation",
  entity-no: "B20260435404",
  // Resolution
  number: none,
  subtitle: none,                 // e.g. [In Lieu of Organizational Meeting]
  short-title: none,              // footer / PDF title; defaults from kind
  date: none,                     // datetime, content, or none (blank)
  kind: "written-consent",        // "written-consent" | "meeting"
  preamble: auto,                 // override the opening paragraph
  // Written consent
  directors: (),                  // names; `none` entries => blank name
  signature-dates: none,          // date to pre-fill on signature lines
  // Meeting
  meeting-type: "special",        // "regular" | "special"
  location: none,
  votes: ("for": none, against: none, abstain: none, absent: none),
  secretary: none,                // name of Secretary signing certificate
  // Exhibits (array of `exhibit(...)`), rendered after the signatures
  exhibits: (),
  // Presentation
  draft: false,
  font: ("Times New Roman", "Times", "Libertinus Serif"),
  body,
) = {
  assert(kind in ("written-consent", "meeting"),
    message: "kind must be \"written-consent\" or \"meeting\"")
  let consent = kind == "written-consent"
  let date-str = _fmt-date(date)
  let short = if short-title != none { short-title }
    else if consent [Unanimous Written Consent of the Board]
    else [Resolutions of the Board]
  let footer-title = if number != none [Resolution No. #number: #short] else { short }

  set document(
    title: if number != none [Resolution No. #number: #short] else { short },
    author: corporation,
  )
  set text(font: font, size: 11pt, lang: "en", region: "US")
  set par(justify: true, leading: 0.6em, spacing: 1.1em)
  set page(
    paper: "us-letter",
    margin: (x: 1in, top: 1in, bottom: 1in),
    footer: context {
      set text(size: 8.5pt)
      grid(columns: (1fr, auto), [#corporation #footer-title],
        [Page #counter(page).display() of #counter(page).final().first()])
    },
    background: if draft {
      rotate(-40deg, text(size: 110pt, weight: "bold", fill: luma(238))[DRAFT])
    },
  )
  _draft.update(draft)

  // ---- Caption ----
  align(center)[
    #set par(spacing: 0.55em, justify: false)
    #set text(weight: "bold", size: 12pt)
    #(if consent [UNANIMOUS WRITTEN CONSENT \ OF THE BOARD OF DIRECTORS OF]
      else [RESOLUTIONS ADOPTED BY \ THE BOARD OF DIRECTORS OF])
    \ #upper(corporation)
    #if subtitle != none [\ #upper(subtitle)]

    #v(0.3em)
    #set text(weight: "regular", style: "italic", size: 10.5pt)
    #entity
    #if entity-no != none [\ California Secretary of State Entity No. #entity-no]
    \ #(if consent [Pursuant to Section 7.14 of the Bylaws and Section 5211(b) of the California Corporations Code]
      else [Adopted at a #meeting-type meeting of the Board of Directors held on #date-str])

    #v(0.6em)
    #set text(style: "normal", size: 11pt)
    *Effective as of:*#h(0.4em)#box(width: 11em, stroke: (bottom: 0.6pt),
      outset: (bottom: 2pt), align(left, date-str))
  ]
  v(0.8em)

  let n = directors.len()
  if preamble != auto { preamble } else if consent [
    The undersigned, constituting all of the directors of #corporation, #entity,
    acting pursuant to Section 7.14 of the Bylaws of the Corporation
    and Section 5211(b) of the California Corporations Code,
    hereby waive any and all requirements of call, notice, and meeting,
    and consent to the adoption of the following resolutions.
  ] else [
    The following recitals and resolutions were duly adopted by the Board of
    Directors of #corporation, #entity, at a
    #meeting-type meeting of the Board duly called and held on
    #date-str#if location != none [ at #location].
  ]

  body

  if consent {
    subhead[Counterparts; Electronic Signatures; Filing]
    [This Consent may be executed in counterparts and by electronic signature,
    each of which shall be deemed an original and all of which together shall
    constitute one instrument. Pursuant to Section 7.14 of the Bylaws, this
    Consent shall be filed with the minutes of the proceedings of the Board.]

    if n > 0 {
      v(1.2em)
      align(center)[\[Signature page follows.\]]
      pagebreak()
      [*IN WITNESS WHEREOF*, the undersigned, constituting all of the directors
      of the Corporation, have executed this Unanimous Written Consent as of the
      date first written above.]
      for d in directors { _sig(d, [Director], date: signature-dates) }
    }
  } else {
    let tally(x) = if x == none { box(width: 2em, stroke: (bottom: 0.6pt)) } else [#x]
    block(breakable: false)[
      #v(1.6em)
      #align(center, strong[CERTIFICATE OF SECRETARY])
      #v(0.3em)
      I certify that I am the duly elected and acting Secretary of
      #corporation, #entity, and that the foregoing resolutions were duly
      adopted by the Board on #date-str by a vote of
      #tally(votes.at("for", default: none)) in favor,
      #tally(votes.at("against", default: none)) opposed,
      #tally(votes.at("abstain", default: none)) abstaining, and
      #tally(votes.at("absent", default: none)) absent, and that such
      resolutions have not been amended or rescinded and remain in full force
      and effect.
      #_sig(secretary, [Secretary])
    ]
  }

  for e in exhibits { e }
}
