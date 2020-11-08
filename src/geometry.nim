import tables, sets, strutils, sequtils, options, sugar, math, macros
import core


converter intToFloat64*(i: int): float64 = i.float64
converter pointToVec*[T](p: AbstractPoint[T]): (T, T) = (p.x, p.y)
converter iVecToFVec(x: (int, int)): (float64, float64) =
  (x[0].float64, x[1].float64)
converter pointSeqToVecSeq*[T](ps: seq[AbstractPoint[T]]): seq[(T, T)]=
  ps.map(pointToVec)
    

func `+`*[T](p: (T, T), offset: (T, T)): AbstractPoint[T]=
  (p[0] + offset[0], p[1] + offset[1])


func high[T2](T: typedesc[(T2, T2)]): T = (T2.high, T2.high)
func `-`[T](l:(T, T), r: (T, T)): (T, T) = (l[0] - r[0], l[1] - r[1])
func dot[T](l: (T, T), r: (T, T)): T = l[0] * r[0] + l[1] * r[1]
func abs[T](l: (T, T)): float64 = sqrt(float64(l[0] * l[0] + l[1] * l[1]))
func angle[T](l: (T, T), r: (T, T)): float64 =
  arccos(float64(dot(l, r) / (abs(l) * abs(r))))


func boundingRectSize[T](ps: seq[(T, T)]): (float64, float64)=
  let
    xs = ps.mapIt(it[0])
    ys = ps.mapIt(it[1])
    minX = min xs
    maxX = max xs
    minY = min ys
    maxY = max ys
  (maxX - minX, maxY - minY)


func rotate*[T](p: (T, T), a: float64): (float64, float64)=
  let 
    s = sin a
    c = cos a
  (p[0] * c - p[1] * s, p[0] * s + p[1] * c)


func findConvexHullStartPoint[T](points: seq[(T, T)]): (T, T)=
  ## reruns the left-top-most point
  func `<`(l: (T, T), r:(T, T)): bool=
    l[0] < r[0] or l[0] == r[0] and l[1] > r[1]
  min points


func findNextPointInConvexHull[T](p: (T, T), vecA: (T, T),
                                  points: seq[(T, T)]): (T, T)=
  points.minBy (cp: (T, T)) => angle(vecA, cp - p)


func findConvexHull[T: SomeNumber](points: seq[(T, T)]): HashSet[(T, T)]=
  case len points:
    of 0..2: raise newException(ValueError,
      "Cannot compute the convex hull of less than 3 points.")
    of 3:
      return toHashSet points
    else:
      discard

  var 
    lastP = findConvexHullStartPoint points
    vec = (0.0, 1.0)
    nextP: (T, T)
  result.incl lastP

  while true:
    nextP = findNextPointInConvexHull(lastP, vec, points)
    if nextP in result:
      break

    result.incl(nextP)
    vec = nextP - lastP
    lastP = nextP


iterator slidingWindow2[T](xs: openArray[T]): (T, T)=
  for i in 0..<xs.high:
    yield (xs[i], xs[i + 1])


func rotateToDinA4*[T](ps: seq[(T, T)]): (seq[(T, T)], float64)=
  ## Returns the points rotated to fit DinA4 optimally, and the corresponding
  ## rotation angle
  var
    smallestArea = float64.high
    smallestW, smallestH: float64

  for (a, b) in slidingWindow2 toSeq findConvexHull ps:
    let 
      rotation = angle((1.0, 0.0), b - a) mod (0.5 * PI)
      rotatedPoints = ps.mapIt(rotate(it, rotation))
      (w, h) = boundingRectSize rotatedPoints
      area = w * h
    
    if area < smallestArea:
      smallestArea = area
      smallestW = w
      smallestH = h
      result = (rotatedPoints, rotation)

    if smallestW > smallestH:
      result = (result[0].mapIt(rotate(it, 0.5*PI)), result[1] + 0.5*PI)


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


# This is from the macro tutorial. Super usefull, why isnt it the default
# assert?
when isMainModule:
  let 
    points = toHashSet(mapLiterals(
      [(0, 2), (2, 2), (2, 0), (0, 0), (1, 1)], float64))
    expResults = points.dup(excl((1.0, 1.0)))
    res = findConvexHull toSeq points
  doAssert res == expResults

  const eps = 1e-7
  myAssert angle((0, 1), (1, 0)) == 0.5 * PI
  myAssert abs(rotate((1, 0), 0.5 * PI) - (0.0, 1.0)) < eps
  myAssert abs(rotate((1, 1), PI) - (-1.0, -1.0)) < eps

