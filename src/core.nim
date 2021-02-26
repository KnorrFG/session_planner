import tables, sets, strutils, sequtils, options, sugar, macros, json, times,
  os

type
  Color* = object
    r*, g*, b*: int
  AbstractPoint*[T] = object
    name*: string
    x*, y*: T
    color*: Color
  Point* = AbstractPoint[float64]
  NormPoint* = AbstractPoint[int]
  Sessions = Table[string, seq[string]]
  Points = seq[Point]
  Graph* = object
    points*: Points
    sessions*: Sessions
  State* = ref object
    graph*: Graph
    txtOverImg*: string
    txtOverHtml*: string


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
      # Name Rechts Hoch [Farbe]
      1 4593466 5637921
      2 4597209 5637946
      3 4595591 5639878 gelb
      4 4598250 5642330 gelb
      5 4592250 5645330 violet
  """.dedent.fixLineEndings

  default_sessions* = """
    # Ich bin ein Kommentar und werde ignoriert werden.
    Lala {1 2}
    Foo { 3 4 5 }
    Bar { 1 2 3 4 }
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



type Popable*[T] = concept s
    s.pop() is T


func twoElemSubSets*[T](s: seq[T]): seq[(T, T)]=
  if s.len < 2:
    return

  var s = s
  while s.len > 2:
    let cur = s.pop
    for it in s:
      result.add((cur, it))
  result.add((s.pop, s.pop))

proc getTransferImagePath*(): string = getConfigDir() / $now() & ".png"

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
