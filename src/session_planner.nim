import nigui
import sequtils, tables, sets, hashes, sugar
import core, parser


proc renderToCanvas(points: seq[Point], sessions: iterator: HashSet[string],
                    canvas: Canvas, bgColor=bgColor)=
  canvas.areaColor = bgColor
  canvas.fill()

  canvas.lineColor = fgColor
  canvas.fontSize = 20
  canvas.fontFamily = "Arial"

  let normPoints = normalizePoints(points,
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

  for s in sessions():
    for (a, b) in twoElemSubSets(s):
      let
        na = normPoints[a]
        nb = normPoints[b]
      canvas.drawLine(na.x + pointRadius, na.y + pointRadius,
                      nb.x + pointRadius, nb.y + pointRadius)


proc storeAsImage(state: Graph, savePath: string)=
  var img = newImage()
  img.resize(1240, 1754)
  renderToCanvas state.points, toFirstClassIter state.sessions.values, 
                 img.canvas, rgb(0, 0, 0, 0)
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
