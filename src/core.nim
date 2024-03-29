import tables, sets, strutils, sequtils, options, sugar, macros, json, times,
  os
import zero_functional

type
  HorizontalNamePosition* = enum
    hnpLeft, hnpMiddle, hnpRight
  VerticalNamePosition* = enum
    vnpAbove, vnpMiddle, vnpBelow
  NamePosition* = object
    horizontal*: HorizontalNamePosition
    vertical*: VerticalNamePosition
  Color* = object
    r*, g*, b*: int
  AbstractPoint*[T] = object
    name*: string
    x*, y*: T
    color*: Color
    namePosition*: NamePosition
  Point* = AbstractPoint[float64]
  NormPoint* = AbstractPoint[int]
  Sessions* = OrderedTable[string, seq[string]]
  Points = seq[Point]
  Graph* = object
    points*: Points
    sessions*: Sessions
  State* = ref object
    graph*: Graph
    txtOverImg*: string
    txtOverHtml*: string


func initNamePosition*(h: HorizontalNamePosition, v: VerticalNamePosition):
  NamePosition =
    NamePosition(horizontal:h, vertical: v)


func fixLineEndings*(s: string): string = s.splitLines().join("\p")

let
  bgColor* = Color(r:255, g:255, b:255)
  fgColor* = Color(r:0, g:0, b:0)
  txtColor* = fgColor
  txtOverColor* = Color(r:180, g:180, b:180) 
  pointRadius* = 5
  pointDiameter* = 2 * pointRadius
  colorsTable* = toTable {
    "hellblau": Color(r: 0, g:191, b: 255),
    "blau": Color(r: 0, g: 0, b: 205),
    "rot": Color(r:205, g:0, b:0),
    "schwarz": Color(r:0, g:0, b:0),
    "grün": Color(r:50, g:205, b:50),
    "gelb": Color(r:255, g:215, b:0),
    "orange": Color(r:255, g:140, b:0),
    "pink": Color(r:255, g:20, b:147),
    "violet": Color(r:148, g:0, b:211),
  }
  default_points* = """
      # Name Rechts Hoch [Farbe [Namens Position]]
      1 4593466 5637921
      2 4597209 5637946
      3 4595591 5639878 gelb L
      4 4598250 5642330 gelb LU
      5 4592250 5645330 violet RO
  """.dedent.fixLineEndings

  default_sessions* = """
    # Ich bin ein Kommentar und werde ignoriert werden.
    1 {1 2}
    2 { 3 4 5 }
    3 { 1 2 3 4 }
  """.dedent.fixLineEndings


template toFirstClassIter*(it: untyped): untyped=
  (iterator(): auto =
    for x in it:
      yield x)


template withTemp*(field, tmpVal, code):untyped=
  let oldVal = field
  field = tmpVal
  code
  field = oldVal


proc newState*(graph: Graph, txtOverImg, txtOverHtml: string): State=
  result = new State
  result.graph = graph
  result.txtOverImg = txtOverImg
  result.txtOverHtml = txtOverHtml


proc `$`*(x: State): string = repr(x)


func twoElemSubSets*[T](s: seq[T]): seq[(T, T)]=
  if s.len < 2:
    return

  var s = s
  while s.len > 2:
    let cur = s.pop
    for it in s:
      result.add((cur, it))
  result.add((s.pop, s.pop))

proc getMultipleOccurences*[T](xs: openArray[T]): Table[T, int] =
  toSeq(xs.toCountTable.pairs).filterIt(it[1] > 1).toTable

macro myAssert*(arg: untyped): untyped =
  # all node kind identifiers are prefixed with "nnk"
  arg.expectKind nnkInfix
  arg.expectLen 3
  # operator as string literal
  let op  = newLit(" " & arg[0].repr & " ")
  let lhs = arg[1]
  let rhs = arg[2]
 
  result = quote do:
    if not `arg`:
      raise newException(AssertionDefect,$`lhs` & `op` & $`rhs`)
