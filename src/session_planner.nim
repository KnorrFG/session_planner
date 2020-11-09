import nigui
import sequtils, tables, sets, hashes, sugar
import core, parser, geometry


proc renderToCanvas(points: seq[Point], sessions: iterator: HashSet[string],
                    canvas: Canvas, bgColor=bgColor)=
  canvas.areaColor = bgColor
  canvas.fill()

  canvas.lineColor = fgColor
  canvas.fontSize = 20
  canvas.fontFamily = "Arial"

  let normPoints = normalizePoints(points,
                                   canvas.width.float64,
                                   canvas.height.float64).
                   mapIt((it.name, it)).toTable

  for p in normPoints.values:
  # Coordinates are Pixels, left top is 0, 0
    canvas.areaColor = p.color
    canvas.drawEllipseArea(p.x, p.y, pointDiameter, pointDiameter)
    canvas.drawText(p.name,
                    p.x - int(0.45 * canvas.getTextWidth(p.name).float64),
                    p.y + canvas.getTextLineHeight())

  for s in sessions():
    for (a, b) in twoElemSubSets(s):
      let
        na = normPoints[a]
        nb = normPoints[b]
      canvas.drawLine(na.x + pointRadius, na.y + pointRadius,
                      nb.x + pointRadius, nb.y + pointRadius)


proc addNorthArrow(canvas: Canvas, rotation: float64)=
  ## This will add a north arrow to the Graph, as it seems, that niGui does not
  ## offer any image rotation, or the ability to load an image from memory the
  ## only way to add a North Arrow, is by manually drawing it
  
  # From the canvas coordinates system point of view, the points are rotated,
  # while they are inverted (the y component gets inverted, due to different
  # orginis). The inversion messes with the rotation. While I strongly suspect
  # that a simple minus in front of the rotation angle for the arrow would do,
  # I am not 100% sure. Therefore, to be sure I get the correct roation, I
  # invert the y-component of the arrow coords, then rotate them, and then
  # invert them again. This way the rotation is guaranteed to match with the
  # points rotation
  let
    (root, head, larm, rarm) = (0, 1, 2, 3)
    points = [(0.0, 1.0), (0.0, -1.0), (-0.5, -0.5), (0.5, -0.5)].
        mapIt((it[0], 1 - it[1])).
        mapIt(rotate(it, rotation)).
        mapIt((it[0], 1 - it[1])).
        mapIt(initPoint(it[0], it[1]))

    absPoints = collect(newSeq):
      for p in points:
        (p + (0.5, 1.0)) * 0.02 * canvas.height +
          (0.9 * canvas.width, 0.9 * canvas.height)

  proc line(start: int, dest: int)=
    canvas.drawLine(absPoints[start].x.int, absPoints[start].y.int, 
                    absPoints[dest].x.int, absPoints[dest].y.int)

  withTemp(canvas.lineWidth, 2):
    line(larm, head)
    line(rarm, head)
    line(root, head)


proc storeAsImage(state: Graph, savePath: string)=
  var img = newImage()
  img.resize(1240, 1754)
  let 
    (coords, angle) = rotateToDinA4(state.points)
    points = collect(newSeq):
      for (c, p) in zip(coords, state.points):
        p.set(x=c[0], y=c[1])

  renderToCanvas points, toFirstClassIter state.sessions.values, 
                 img.canvas, rgb(0, 0, 0, 0)
  addNorthArrow(img.canvas, angle)
  img.saveToPngFile savePath


var state = parseGraph(default_text)
app.init()

var win= newWindow("Session Planer")

var vLayout = newLayoutContainer(Layout_Vertical)
win.add(vLayout)
var buttonRow = newLayoutContainer(Layout_Horizontal)
vLayout.add(buttonRow)

var exportButton = newButton("\u2611 Export")
buttonRow.add(exportButton)
exportButton.onClick = proc(ev: ClickEvent)=
  var dialog = newSaveFileDialog()
  dialog.title = "Exportieren nach:"
  dialog.defaultExtension = "png"
  dialog.run()
  if dialog.file != "":
    storeAsImage(state, dialog.file)

var textArea = newTextArea()
vLayout.add(textArea)
textArea.text = defaultText

var 
  drawWin = newWindow("Session Planer - Graph")
  drawing = newControl()
drawWin.add(drawing)
drawing.widthMode = WidthMode_Expand
drawing.heightMode = HeightMode_Expand
drawing.onDraw = proc(event: DrawEvent)=
  renderToCanvas(state.points, toFirstClassIter state.sessions.values,
                 event.control.canvas) 

win.onKeyDown = proc(event: KeyboardEvent)=
  if Key_Return.isDown() and Key_ControlL.isDown():
    try:
      state = parseGraph(textArea.text)
      drawing.forceRedraw()
    except ParserError as e:
      win.alert("Fehler: " & e.msg)
    event.handled = true

win.onCloseClick = proc(event: CloseClickEvent) =
  win.dispose()
  drawWin.dispose()

win.show()
drawWin.show()
app.run()
