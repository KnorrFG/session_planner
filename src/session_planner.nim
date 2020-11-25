import nigui, zero_functional
import sequtils, tables, sets, hashes, sugar, strutils, times, os
import core, parser, geometry, gui, htmlGen


proc getFilePathViaDialog(title: string, defaultExtension: string): string=
  var dialog = newSaveFileDialog()
  dialog.title = title
  dialog.defaultExtension = defaultExtension
  dialog.run()
  return dialog.file


proc renderToCanvas(state: GuiState, canvas: Canvas, bgColor=bgColor,
                    txtOverColor=txtOverColor)=
  canvas.areaColor = bgColor
  canvas.fill()

  canvas.lineColor = fgColor
  canvas.fontSize = 20
  canvas.fontFamily = "Arial"
  canvas.textColor = txtColor

  let normPoints = normalizePoints(state.graph.points,
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

  for s in state.graph.sessions.values:
    for (a, b) in twoElemSubSets(s):
      let
        na = normPoints[a]
        nb = normPoints[b]
      canvas.drawLine(na.x + pointRadius, na.y + pointRadius,
                      nb.x + pointRadius, nb.y + pointRadius)

  canvas.textColor = txtOverColor
  canvas.drawText(state.txtOver,
                  int(0.05 * canvas.width), int(0.05 * canvas.height))


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


func nLines[T](ses: T): int =
  let l = ses.len
  int(l * (l - 1) * 0.5)


proc storeAsImage(state: GuiState, savePath: string)=
  var img = newImage()
  img.resize(1240, 1754)

  let
    (coords, angle) = rotateToDinA4(state.graph.points)
    points = collect(newSeq):
      for (c, p) in zip(coords, state.graph.points):
        p.set(x=c[0], y=c[1])
    rotatedGraph = Graph(points: points, sessions: state.graph.sessions)

  renderToCanvas(newGuiState(rotatedGraph, state.txtOver), img.canvas)
  addNorthArrow(img.canvas, angle)
  img.saveToPngFile savePath


var state: GuiState
app.init()

var win= newWindow("Session Planer")

var vLayout = newLayoutContainer(Layout_Vertical)
win.add(vLayout)
var buttonRow = newLayoutContainer(Layout_Horizontal)
vLayout.add(buttonRow)


var 
  (l1, pointArea) = createNamedTextArea("Punkte:")
  (l2, sessionArea) = createNamedTextArea("Sessions:")
  (l3, txtOverArea) = createNamedTextArea("Text:")

pointArea.text = default_points
sessionArea.text = default_sessions
txtOverArea.text = readFile "default_text.txt"
vLayout.add(l1)
vLayout.add(l2)
vLayout.add(l3)

var exportButton = newButton("\u2611 Export")
buttonRow.add(exportButton)
exportButton.onClick = proc(ev: ClickEvent)=
  let filePath = getFilePathViaDialog("Exportieren nach:", "png")
  if filePath != "":
    storeAsImage(state, filePath)
    let 
      fileSplit = splitFile(filePath)
      htmlPath = fileSplit.dir / fileSplit.name & ".html"
    htmlPath.writeFile makeHtml state


var 
  drawWin = newWindow("Session Planer - Graph")
  drawing = newControl()
drawWin.add(drawing)
drawing.widthMode = WidthMode_Expand
drawing.heightMode = HeightMode_Expand
drawing.onDraw = proc(event: DrawEvent)=
  renderToCanvas(state, event.control.canvas) 


proc getState(): GuiState=
  let g = Graph(points: parsePoints(pointArea.text),
                sessions: parseSessions(sessionArea.text))
  assert_graph_valid(g)

  let
    nLines = g.sessions.values --> map(nLines(it)).fold(0, a + it)
    nPoints = g.points.len
    txt = txtOverArea.text % ["nLinien", $nLines, "nPunkte", $nPoints,
                              "heute", now().format("dd'.'mm'.'yyyy")]
  newGuiState(g, txt)


win.onKeyDown = proc(event: KeyboardEvent)=
  if Key_Return.isDown() and Key_ControlL.isDown():
    try:
      state = getState()
      drawing.forceRedraw()
    except ParserError as e:
      win.alert("Fehler: " & e.msg)
    event.handled = true

win.onCloseClick = proc(event: CloseClickEvent) =
  win.dispose()
  drawWin.dispose()

state = getState()
writeFile getHomeDir() / "tmp/graph.html", makeHtml state
#win.show()
#drawWin.show()
#app.run()
