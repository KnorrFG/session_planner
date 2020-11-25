import sequtils, tables, strutils, os
import zero_functional, karax / [karaxdsl, vdom]
import core


proc make_session_table(sessions: Table[string, seq[string]]): VNode=
  let nAntennas = sessions.values --> map(len it).max()
  buildHtml(table):
    tr:
      th text "Session"
      for i in 1..nAntennas:
        th text "GPS $1" % $i

    for name, points in sessions:
      tr:
        td: text name
        for p in points:
          td text p


proc make_point_rec(point, session: string): VNode=
  func myId(i: int): string = point & session & $i

  buildHtml():
    tdiv(class="pointRec"):
      tdiv(class="ident"):
        tdiv(class="identCell"):
          bold: text "Punkt: "  
          text point
        tdiv(class="identCell"):
          bold: text "Session: " 
          text session
      tdiv(class="contents"):
        tdiv(class="tabWithHeading l"):
          tdiv: text "Höhenablesung"
          table:
            tr:
              th()
              th text "v"
              th text "s1"
              th text "s2"
            tr:
              td text "Start"
              td input()
              td input()
              td input()
            tr:
              td text "Ende"
              td input()
              td input()
              td input()
            tr:
              td text "Diff \u2264 2mm"
              td label(id=myId(1), text "")
              td label(id=myId(2), text "")
              td label(id=myId(3), text "")
            tr:
              td text "reduziert"
              td label(id=myId(4), text "")
              td label(id=myId(5), text "")
              td label(id=myId(6), text "")
        tdiv(class="tabWithHeading r"):
          tdiv: text "Beobachtungen"
          table:
            tr:
              th text "Zeit"
              th text "# Sats"
              th text "PDOP"
            tr:
              td input()
              td input()
              td input()
            tr:
              td input()
              td input()
              td input()
      tdiv(class="hLayout upperline"):
        tdiv:
          bold text "Mittelwert Höhe ARP: "
          text ""
        tdiv:
          bold text "Mittelwert ARP abzgl v0: "
          text ""
      tdiv(class="hLayout upperline"):
        tdiv:
          input(type="checkbox")
          label text "Kontrolle NRP \u2264 10 \u00B0"
        tdiv:
          input(type="checkbox")
          label text "Kontrolle Zentrierung \u2264 2mm"
      tdiv(class="vLayout upperline"):
        text "Bermerkung:"
        textarea()


    
  

proc makeHtml*(state: GuiState): string=
  let src = buildHtml(html):
    head:
      meta(charset="utf-8")
      link(rel="stylesheet", href= "file://" & getCurrentDir() / "my.css")
      title text "Session Title"
    body:
      h1 text "Session Table"
      makeSessionTable(state.graph.sessions)
      make_point_rec("1", "Lala")

  $src
