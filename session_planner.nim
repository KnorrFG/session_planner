import nigui
import sequtils, tables, sets, hashes
import core, parser


proc normalizePoints(ps: seq[Point], w, h: float): seq[NormPoint]=
  ## Point coordinates are quite large, and assume 0, 0 at the left bottom
  ## This function recomputes them to be from 0 to (w, h) and the origin at the
  ## top left

  if ps.len == 0:
    return
  if ps.len == 1:
    let p = ps[0]
    return @[(name: p.name, x: int(w / 2), y: int(h / 2), color: p.color)]

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
  ps.mapIt((name: it.name, 
            x: int((it.x - min_x) * scale) + w_offset,
            y: int((max_h - (it.y - min_y)) * scale) + h_offset,
            color: it.color))


type 
  Popable[T] = concept s
    s.pop() is T


func twoElemSubSets[T](s: Popable[T]): seq[(T, T)]=
  if s.len < 2:
    return

  var s = s
  while s.len > 2:
    let cur = s.pop
    for it in s:
      result.add((cur, it))
  result.add((s.pop, s.pop))


var state = parseGraph(default_text)
app.init()

var win= newWindow("Session Planer")
win.width = scaleToDpi 800
win.height = scaleToDpi 600

var container = newLayoutContainer(Layout_Horizontal)
win.add(container)

var textArea = newTextArea()
container.add(textArea)
textArea.text = defaultText

var drawing = newControl()
container.add(drawing)
drawing.widthMode = WidthMode_Expand
drawing.heightMode = HeightMode_Expand

drawing.onDraw = proc (event: DrawEvent)=
  let canvas = event.control.canvas
  canvas.areaColor = bgColor
  canvas.fill()

  canvas.lineColor = fgColor
  canvas.fontSize = 20
  canvas.fontFamily = "Arial"

  let normPoints = normalizePoints(state.points,
                                   canvas.width.float,
                                   canvas.height.float).
                   mapIt((it.name, it)).toTable

  for p in normPoints.values:
  # Coordinates are Pixels, left top is 0, 0
    canvas.areaColor = p.color
    canvas.drawEllipseArea(p.x, p.y, pointDiameter, pointDiameter)
    canvas.drawText(p.name,
                    p.x - int(0.45 * canvas.getTextWidth(p.name).float),
                    p.y + canvas.getTextLineHeight())

  for s in state.sessions.values:
    echo "render edges for ses: ", s
    for (a, b) in twoElemSubSets(s):
      let
        na = normPoints[a]
        nb = normPoints[b]
      canvas.drawLine(na.x + pointRadius, na.y + pointRadius,
                      nb.x + pointRadius, nb.y + pointRadius)


win.onKeyDown = proc(event: KeyboardEvent)=
  if Key_Return.isDown() and Key_ControlL.isDown():
    try:
      state = parseGraph(textArea.text)
      drawing.forceRedraw()
    except ParserError as e:
      win.alert("Fehler: " & e.msg)
    event.handled = true


win.show()
app.run()
