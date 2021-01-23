import sequtils, tables, strutils, os
import zero_functional, html_dsl
import core


proc make_session_table(sessions: Table[string, seq[string]]): string=
  let nAntennas = sessions.values --> map(len it).max()
  html:
    table:
      tr:
        th "Session"
        for i in 1..nAntennas:
          th "GPS $1" % $i

      for name, points in sessions:
        tr:
          td: name
          for p in points:
            td p


proc make_point_rec(point, session: string): string=
  func myId(i: int): string = point & session & $i

  html:
    divs(class="pointRec"):
      divs(class="ident"):
        divs(class="identCell"):
          bold: "Punkt: "  
          point
        divs(class="identCell"):
          bold: "Session: " 
          session
      divs(class="contents"):
        divs(class="tabWithHeading l"):
          divs: "Höhenablesung"
          table:
            tr:
              th()
              th "v"
              th "s1"
              th "s2"
            tr:
              td "Start"
              td input()
              td input()
              td input()
            tr:
              td "Ende"
              td input()
              td input()
              td input()
            tr:
              td "Diff \u2264 2mm"
              td label(id=myId(1), "")
              td label(id=myId(2), "")
              td label(id=myId(3), "")
            tr:
              td "reduziert"
              td label(id=myId(4), "")
              td label(id=myId(5), "")
              td label(id=myId(6), "")
        divs(class="tabWithHeading r"):
          divs: "Beobachtungen"
          table:
            tr:
              th "Zeit"
              th "# Sats"
              th "PDOP"
            tr:
              td input()
              td input()
              td input()
            tr:
              td input()
              td input()
              td input()
      divs(class="hLayout upperline"):
        divs:
          bold "Mittelwert Höhe ARP: "
          ""
        divs:
          bold "Mittelwert ARP abzgl v0: "
          ""
      divs(class="hLayout upperline"):
        divs:
          input(type="checkbox")
          label "Kontrolle NRP \u2264 10 \u00B0"
        divs:
          input(type="checkbox")
          label "Kontrolle Zentrierung \u2264 2mm"
      divs(class="vLayout upperline"):
        "Bermerkung:"
        textarea()


proc makeHtml*(state: GuiState): string=
  html:
    heads:
      meta(charset="utf-8")
      title "Session Title"
      style:
        "my.css".readFile()
      script:
        "my.js".readFile()
    bodys(onLoad="onLoad()"):
      h1 "Session Table"
      makeSessionTable(state.graph.sessions)
      for session, points in state.graph.sessions:
        for point in points:
          make_point_rec(point, session)

