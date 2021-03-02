import parseutils, strutils, strformat, algorithm, sequtils, tables, sets, sugar
import core


type ParserError* = object of CatchableError

let
    newLine = {'\10', '\13'}
    identEnd = {' ', '\t', '{'}

proc getLineAt(s: string, i: int): string=
  let sub = s[0..i].reversed.join

  var
    start = sub.find(newLine, 1)
    mend = s.find(newLine, i)

  if mend == -1:
    mend = s.high + 1
  if start == -1:
    start = 0
  else:
    start = i - start
  s[start..<mend]
  

proc parseUntilMatching(s: string, buf: var string, match: char, inverse: char,
                        i: int): int=
  var 
    open = 1 
    offset = 0

  while true:
    let no = skipUntil(s, {match, inverse}, i + offset )
    if no == 0 or no + i + offset == s.len:
      # This Case means end of string
      return 0
    else:
      offset += no

    if s[i + offset] == match:
      open -= 1
      if open == 0:
        buf = s[i ..< (i + offset)]
        return offset
    else:
      open += 1
    offset += 1


proc orRaise(i: int, msg: string): int=
  if i == 0:
    raise newException(ParserError, msg)
  return i


proc parseTopLvl(s: string, i=0, res: seq[string] = @[]): seq[string]=
  if i >= s.len:
    return res

  var 
    i = i
    tmp = ""
    res = res

  i += skipWhitespace(s, i)
  if s[i] == '#':
    i += skipUntil(s, newLine, i)
    return parseTopLvl(s, i + 1, res)
  else:
    i += parseUntil(s, tmp, identEnd, i).orRaise("Die Sessionnummer fehlt:\n" &
                                        s.getLineAt(i))
    res.add(tmp.toLower)
    i += skipWhitespace(s, i)
    if i == s.len or s[i] != '{':
      raise newException(ParserError,
        &"Ich habe eine {{ erwartet nach {tmp}\n" & "Zeile: " &
        s.getLineAt(if i < s.len: i else: i - 1))
    else:
      i += 1
      i += parseUntilMatching(s, tmp, '}', '{', i).orRaise(
        "Habe keine zugehoerige } gefunden\n" &
        s.getLineAt(if i < s.len: i else: i - 1))
      res.add(tmp)
      return parseTopLvl(s, i + 1, res)


proc parseFloatOrRaise(s: string): float=
  try:
    s.parseFloat
  except ValueError:
    raise newException(ParserError,
                       &"Anstelle von '{s}' sollte eine Zahl stehen")


proc parsePoints*(s: string): seq[Point]=
  let lines = splitLines(s).mapIt(it.strip.replace(",", ".")).
                filterIt(not it.startswith("#") and it.len > 0)

  for line in lines:
    let elems = line.split()
    if elems.len notin {3, 4}:
      raise newException(ParserError,
        "Zeile muss 3 oder 4 elemente Enthalten, aber ist:\n" & line)
    let color = if elems.len == 3:
      colorsTable["schwarz"]
    else:
      if elems[3] in colorsTable:
        colorsTable[elems[3]]
      else:
        raise newException(ParserError, &"Ungültige Farbe: {elems[3]}")
    result.add(Point(name: elems[0], x: elems[1].parseFloatOrRaise,
                y: elems[2].parseFloatOrRaise, color: color))


proc parseSessions*(s: string): Sessions=
  let 
    tokens = parseTopLvl(s.strip)
    sessions = collect newSeq:
      for i in countup(0, tokens.high, 2): tokens[i]

  for name, count in sessions.getMultipleOccurences:
    raise newException(ParserError,
      fmt"Session {name} kommt {count} mal vor")
  
  for i in countup(0, tokens.high, 2):
    result[tokens[i]] = splitLines(tokens[i + 1]).
                filterIt(not it.startswith("#") and it.len > 0).
                join(" ").split().filterIt(it.len > 0)

  for name, points in result:
    for p, c in getMultipleOccurences(points):
      if c > 1:
        raise newException(ParserError,
          fmt"Punkt {p} kommt {c} mal in Session {name} vor")


#proc `or`[T](x: T, alt: T): T = x
#proc `or`[T](x: typeof(nil), alt: T): T = alt


proc assert_graph_valid*(g: Graph)=
  let registeredPoints = g.points.mapIt(it.name).toHashSet
  for ses, points in g.sessions:
    for p in points:
      if p notin registeredPoints:
        raise newException(ParserError,
          &"Punkt {p} in Session {ses} ist nicht definiert")
          

proc parseGraph*(s: string): Graph=
  let tokens = parseTopLvl(s.strip)
  var entries: Table[string, string] 
  for i in countup(0, tokens.high, 2):
    entries[tokens[i]] = tokens[i+1]

  # Using result here will actually manipulate the result in the call to this
  # function immediately, even when an exception is raised

  let g = Graph(points: parsePoints(entries.getOrDefault("punkte")),
                sessions: parseSessions(entries.getOrDefault("sessions")))
  assert_graph_valid(g)
  return g


proc parseTextField*(t: string): tuple[imageText, htmlText: string] =
  var 
    imgLines: seq[string] = @[]
    htmlLines: seq[string] = @[]

  for line in splitLines(t):
    let l = line.strip()
    if l.startsWith("#"):
      continue
    elif l.startsWith ":h":
      htmlLines.add(l[2 ..< l.len].strip)
    elif l.startsWith ":b":
      imgLines.add(l[2 ..< l.len].strip)
    else:
      htmlLines.add(line)
      imgLines.add(line)

  (imageText: imgLines.join("\p").replace("\t", "    "),
   htmlText: htmlLines.join("\p"))

  

when isMainModule:
  let text = """
    Punkte {
      # Name Rechts Hoch [Farbe]
      1 4593466 5637921
      2 4597209 5637946
      3 4595591 5639878 gelb
      4 4598250 5642330 gelb
      5 4592250 5645330 violet
    }

    # Ich bin ein Kommentar und werde ignoriert werden.
    Sessions {
      Lala {$#}
    }
  """
  for i in 2..5:
    discard parseGraph(text % toSeq(1..i).join(" "))

  for i in 6..10:
    try: discard parseGraph(text % toSeq(1..i).join(" "))
    except ParserError:
      discard

  for i in ["{}", "}", "{SD"]:
    try: discard parseGraph(text % i)
    except ParserError:
      discard
