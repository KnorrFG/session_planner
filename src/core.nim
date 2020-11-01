import tables, sets, strutils, sequtils, options, sugar
import nigui, optionsutils

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
  Popable*[T] = concept s
    s.pop() is T


converter intToFloat64*(i: int): float64 = i.float64


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


func initPoint*[T](x, y: T, name="", color=colorsTable["schwarz"]):
    AbstractPoint[T] = AbstractPoint[T](name:name, x:x, y:y, color:color)


# This could be autogenerated by a macro
func set*[T, T2](p: AbstractPoint[T],
             name: string = p.name,
             x: T2 = T2(p.x),
             y: T2 = T2(p.y),
             color: Color = p.color):
  AbstractPoint[T2] = AbstractPoint[T2](name:name, x:x, y:y, color:color)


func `+`*[T](p: AbstractPoint[T], offset: (T, T)): AbstractPoint[T]=
  p.set(x = p.x + offset[0], y = p.y + offset[1])
    

func `+`*[T](p: AbstractPoint[T], offset: T): AbstractPoint[T]=
  p + (offset, offset)


func `*`*[T](p: AbstractPoint[T], factor: T): AbstractPoint[T]=
  p.set(x = p.x * factor, y = p.y * factor)


func normalizePoints*(ps: seq[Point], w, h: float64): seq[NormPoint]=
  ## Point coordinates are quite large, and assume 0, 0 at the left bottom
  ## This function recomputes them to be from 0 to (w, h) and the origin at the
  ## top left

  if ps.len == 0:
    return
  if ps.len == 1:
    let p = ps[0]
    return @[initPoint(int(w / 2), int(h / 2), p.name, p.color)]

  let
    target_w = w * 0.8
    target_h = h * 0.8
    w_offset = int(w * 0.1)
    h_offset = int(h * 0.1)
    max_x = ps.mapIt(it.x).foldl(max(a, b))
    min_x = ps.mapIt(it.x).foldl(min(a, b))
    max_y = ps.mapIt(it.y).foldl(max(a, b))
    min_y = ps.mapIt(it.y).foldl(min(a, b))
    max_w = max_x - min_x
    max_h = max_y - min_y
    x_scale = target_w / max_w
    y_scale = target_h / max_h
    scale = min(x_scale, y_scale)
  ps.mapIt(NormPoint(name: it.name,
            x: int((it.x - min_x) * scale) + w_offset,
            y: int((max_h - (it.y - min_y)) * scale) + h_offset,
            color: it.color))


func twoElemSubSets*[T](s: Popable[T]): seq[(T, T)]=
  if s.len < 2:
    return

  var s = s
  while s.len > 2:
    let cur = s.pop
    for it in s:
      result.add((cur, it))
  result.add((s.pop, s.pop))
