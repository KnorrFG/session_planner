import nigui, sugar, sequtils, random, sets

let 
  bgColor = rgb(255, 255, 255)
  fgColor = rgb(0, 0, 0)
  pointRadius = 5
  pointDiameter = 10


iterator sliding2[T](xs: seq[T]): (T, T)=
  for i in 1..xs.high:
    yield (xs[i-1], xs[i])


proc randColor(): Color= rgb(byte(rand(0..255)), 
                             byte(rand(0..255)), byte(rand(0..255)))


func twoElemSubSets[T](s: seq[T]): seq[(T, T)]=
  if s.len < 2:
    return

  var s = s
  while s.len > 2:
    let cur = s.pop
    for it in s:
      result.add((cur, it))
  result.add((s.pop, s.pop))


app.init()
var win= newWindow("Session Planer")
win.width = scaleToDpi 800
win.height = scaleToDpi 600

proc wRange(): auto= int(0.1 * win.width.float)..int(0.9 * win.width.float)
proc hRange(): auto= int(0.1 * win.height.float)..int(0.9 * win.height.float)

var drawing = newControl()
win.add(drawing)
drawing.widthMode = WidthMode_Expand
drawing.heightMode = HeightMode_Expand

drawing.onDraw = proc (event: DrawEvent)=
  let canvas = event.control.canvas
  canvas.areaColor = bgColor
  canvas.fill()

  canvas.lineColor = fgColor

  let 
    points = (1..rand(3..20)).mapIt((name: $it, x: rand(wRange()), 
                                       y: rand(hRange()), color: randColor()))
    groups = collect(newSeq):
      for i in 1..3:
        collect(newSeq):
          for j in 2..points.high:
            sample(points)

  for p in points:
    canvas.areaColor = p.color
    canvas.drawEllipseArea(p.x, p.y, pointDiameter, pointDiameter)
    canvas.drawText(p.name,
                    p.x - int(0.45 * canvas.getTextWidth(p.name).float),
                    p.y + canvas.getTextLineHeight())

  for g in groups:
    for (a, b) in twoElemSubSets(g):
      canvas.drawLine(a.x + pointRadius, a.y + pointRadius,
                      b.x + pointRadius, b.y + pointRadius)


win.onKeyDown = proc(event: KeyboardEvent)=
  if Key_Return.isDown():
    drawing.forceRedraw


win.show()
app.run()
