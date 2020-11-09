import tables, sets, strutils, sequtils, options, sugar, macros, json
import nigui

let
  bgColor* = rgb(255, 255, 255)
  fgColor* = rgb(0, 0, 0)
  pointRadius* = 5
  pointDiameter* = 2 * pointRadius
  colorsTable* = toTable {
    "hellblau": rgb(0, 191, 255),
    "blau": rgb(0, 0, 205),
    "rot": rgb(205, 0, 0),
    "schwarz": rgb(0, 0, 0),
    "grün": rgb(50, 205, 50),
    "gelb": rgb(255, 215, 0),
    "orange": rgb(255, 140, 0),
    "pink": rgb(255, 20, 147),
    "violet": rgb(148, 0, 211),
  }
  default_text* = dedent """
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
      Lala {1 2}
    }
  """


template toFirstClassIter*(it): auto=
  iterator iter(): auto {.closure.} =
    for x in it:
      yield x
  iter


template withTemp*(field, tmpVal, code):untyped=
  let oldVal = field
  field = tmpVal
  code
  field = oldVal


type
  AbstractPoint*[T] = object
    name*: string
    x*, y*: T
    color*: Color
  Point* = AbstractPoint[float64]
  NormPoint* = AbstractPoint[int]
  Graph* = object
    points*: seq[Point]
    sessions*: Table[string, HashSet[string]]


func initPoint*[T](x, y: T, name="", color=colorsTable["schwarz"]):
    AbstractPoint[T] = AbstractPoint[T](name:name, x:x, y:y, color:color)


# This could be autogenerated by a macro
func set*[T, T2](p: AbstractPoint[T],
             name: string = p.name,
             x: T2 = T2(p.x),
             y: T2 = T2(p.y),
             color: Color = p.color):
  AbstractPoint[T2] = AbstractPoint[T2](name:name, x:x, y:y, color:color)


func `+`*[T](p: AbstractPoint[T], offset: T): AbstractPoint[T]=
  p + (offset, offset)


func `*`*[T](p: AbstractPoint[T], factor: T): AbstractPoint[T]=
  p.set(x = p.x * factor, y = p.y * factor)


func `+`*[T](p: AbstractPoint[T], offset: (T, T)): AbstractPoint[T]=
  p.set(x = p.x + offset[0], y = p.y + offset[1])


type Popable*[T] = concept s
    s.pop() is T


func twoElemSubSets*[T](s: Popable[T]): seq[(T, T)]=
  if s.len < 2:
    return

  var s = s
  while s.len > 2:
    let cur = s.pop
    for it in s:
      result.add((cur, it))
  result.add((s.pop, s.pop))


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
