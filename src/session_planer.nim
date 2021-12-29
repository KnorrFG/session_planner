import nigui, zero_functional, nigui / msgbox
import sequtils, tables, sets, sugar, strutils, times, os, std/json,
  base64, strformat, times
import core, parser, geometry, gui, htmlGen, render


type 
  GuiState = object
    pointAreaText, sessionAreaText, miscText: string
  RuntimeInfo = object
    currentSavePath: string 
    currentExportPath: string
    tLastDraw: DateTime
    tLastSave: DateTime
    lastGuiState: GuiState
    viewPort: GRect[float]
  ShouldSaveResponse = enum
    rYes=1, rNo, rCancel

   

converter toNiGuiColor(c: core.Color): nigui.Color =
  rgb(byte(c.r), byte(c.g), byte(c.b))


proc shouldSaveDialog(win: Window): ShouldSaveResponse =
  let res = win.msgBox(
  """Das Projekt enthällt ungespeicherte Änderungen. 
     Soll vor dem Beenden gespeichert werden?""".unindent,
     "",
     "Ja", "Nein", "Abbrechen")
  if res > 0: ShouldSaveResponse res
  else: rCancel



proc load_antenna_image_as_base64(path: string): string =
  let file = path.open()
  defer: file.close()

  let nBytes = file.getFileSize()
  var buffer = newSeq[byte](nBytes)
  assert file.readBytes(buffer, 0, nBytes) == nBytes
  encode buffer


proc getFilePathViaSaveDialog(title: string, defaultExtension: string): string=
  #let cwd = getCurrentDir()
  var dialog = newSaveFileDialog()
  dialog.title = title
  dialog.defaultExtension = defaultExtension
  dialog.run()
  #setCurrentDir cwd
  return dialog.file


proc getFilePathViaLoadDialog(title, startDir: string): seq[string]=
  let cwd = getCurrentDir()
  var dialog = newOpenFileDialog()
  dialog.title = title
  dialog.directory = startDir
  dialog.run()
  setCurrentDir cwd
  return dialog.files


proc getDirectoryViaDialog(title, startDir: string): string=
  let cwd = getCurrentDir()
  var dialog = newSelectDirectoryDialog()
  dialog.title = title
  dialog.startDirectory = startDir
  dialog.run()
  setCurrentDir cwd
  return dialog.selectedDirectory


func nLines[T](ses: T): int =
  let l = ses.len
  int(l * (l - 1) * 0.5)


proc renderToCanvas(state: State, canvas: Canvas,
                    bgColor=toNiGuiColor bgColor,
                    txtOverColor=toNiGuiColor txtOverColor,
                    viewPort: GRect[float] = initGRect[float](0, 0, 1, 1))=
  let img = renderGraph(state.graph.points, state.graph.sessions,
                        state.txtOverImg,
                        initGSize[int](canvas.width, canvas.height),
                        viewPort)
  let img2 = newImage()
  img2.resize(img.width, img.height)
  let dataptr = img2.beginPixelDataAccess()
  copyMem(dataptr, img.rawData(), img.width * img.height * 4)
  img2.endPixelDataAccess()
  canvas.drawImage(img2, 0, 0)


proc storeAsImage(state: State, savePath: string, northArrow: render.Surface)=
  let
    (coords, angle) = rotateToDinA4(state.graph.points)
    points = collect(newSeq):
      for (c, p) in zip(coords, state.graph.points):
        p.set(x=c[0], y=c[1])

  let img = renderGraph(points, state.graph.sessions,
                        state.txtOverImg, initGSize[int](1240, 1754),
                        initGRect[float](0, 0, 1, 1))
  img.addNorthArrow(-angle, northArrow)
  img.writeToPng savePath


proc parseState(gs: GuiState): State=
  let g = Graph(points: parsePoints(gs.pointAreaText),
                sessions: parseSessions(gs.sessionAreaText))
  assert_graph_valid(g)

  let
    nLines = g.sessions.values --> map(nLines(it)).fold(0, a + it)
    nPoints = g.points.len
    txt_sub = (gs.miscText
      .replace("$nLinien", $nLines)
      .replace("$nPunkte", $nPoints)
      .replace("$heute", now().format("dd'.'MM'.'yyyy")))
    txt = parseTextField(txt_sub)
  newState(g, txt.imageText, txt.htmlText)


proc main() =
  let 
    myDir = getAppDir() 
    northArrow = newSurface(myDir / "north.png")
    antenna = load_antenna_image_as_base64(myDir / "antenna.jpg")
    default_text = readFile(myDir / "default_text.txt").fixLineEndings
    js = readFile(myDir / "my.js")
    css = readFile(myDir / "my.css")
  var 
    state: State
    rtInfo: RuntimeInfo

  rtInfo.viewPort = initGRect[float](0, 0, 1, 1)
  app.init()

  var 
    win = newWindow("Session Planer")
    vLayout = newLayoutContainer(Layout_Vertical)
    buttonRow = newLayoutContainer(Layout_Horizontal)
    (l1, pointArea) = createNamedTextArea("Punkte:")
    (l2, sessionArea) = createNamedTextArea("Sessions:")
    (l3, txtOverArea) = createNamedTextArea("Text:")
    exportButton = newButton("\u2611 Export")
    saveAsButton = newButton("Speichern unter")
    saveButton = newButton("Speichern")
    loadButton = newButton("Laden")
    showGraphButton = newButton("Entwurf anzeigen")
    drawWin = newWindow("Session Planer - Graph")
    drawing = newControl()

  proc getState(): GuiState =
    GuiState(pointAreaText: pointArea.text,
             sessionAreaText: sessionArea.text,
             miscText: txtOverArea.text)

  proc applyGuiState(st: GuiState) =
    pointArea.text = st.pointAreaText
    sessionArea.text = st.sessionAreaText
    txtOverArea.text = st.miscText
    rtInfo.tLastDraw = now()
    drawing.forceRedraw()

  proc save(path: string) =
    path.writeFile($(%*getState()))
    rtInfo.tLastSave = now()

  proc saveAs() =
    let savePath = getFilePathViaSaveDialog("Speichern unter", "sp")
    if savePath != "":
      rtInfo.currentSavePath = savePath
      save(savePath)

  proc saveOrSaveAs() =
    if rtInfo.currentSavePath != "":
      save(rtInfo.currentSavePath)
    else:
      saveAs()

  proc load(path: string) =
    let content = path.readFile
    let guiState = content.parseJson.to(GuiState)
    applyGuiState guiState
    rtInfo.currentSavePath = path
    rtInfo.tLastSave = now()
    state = guiState.parseState

  proc updateGraph(forced=false, updateDrawTimeStamp=true) =
    # The draw timestamp is used to check whether there are unsafed changes,
    # however, since I introduced zooming, the drawTimestamp could be newer
    # than the save file. Therefore the two arguments are introduced, so the
    # Graph is updated also when there are no changes in its content, and the
    # timestamps isnt updated then
    let guiState = getState()
    if guiState != rtInfo.lastGuiState or forced:
      try:
        state = guiState.parseState()
        drawing.forceRedraw()
        rtInfo.lastGuiState = guiState
        if updateDrawTimeStamp:
          rtInfo.tLastDraw = now()
      except ParserError as e:
        win.alert("Fehler: " & e.msg)

  win.add(vLayout)
  win.width = 600
  win.height = 800
  vLayout.add(buttonRow)
  vLayout.add(l1)
  vLayout.add(l2)
  vLayout.add(l3)
  buttonRow.add(exportButton)
  buttonRow.add(saveAsButton)
  buttonRow.add(saveButton)
  buttonRow.add(loadButton)
  buttonRow.add(showGraphButton)

  pointArea.text = default_points
  sessionArea.text = default_sessions
  txtOverArea.text = default_text

  drawWin.add(drawing)
  drawWin.onKeyDown = proc(event: KeyboardEvent) =
    let moveFactor = 0.2 * rtInfo.viewPort.w * (
      if Key_ShiftL.isDown(): 2 else: 1)
    event.handled = true
    if Key_Minus.isDown() or Key_NumpadSubtract.isDown():
      rtInfo.viewPort.w *= 1.1
      rtInfo.viewPort.h *= 1.1
      updateGraph(forced=true, updateDrawTimestamp=false)
    elif Key_Plus.isDown() or Key_NumpadAdd.isDown():
      rtInfo.viewPort.w *= 0.9
      rtInfo.viewPort.h *= 0.9
      updateGraph(forced=true, updateDrawTimestamp=false)
    elif Key_Left.isDown():
      rtInfo.viewPort.x -= moveFactor
      updateGraph(forced=true, updateDrawTimestamp=false)
    elif Key_Right.isDown():
      rtInfo.viewPort.x += moveFactor
      updateGraph(forced=true, updateDrawTimestamp=false)
    elif Key_Up.isDown():
      rtInfo.viewPort.y -= moveFactor
      updateGraph(forced=true, updateDrawTimestamp=false)
    elif Key_Down.isDown():
      rtInfo.viewPort.y += moveFactor
      updateGraph(forced=true, updateDrawTimestamp=false)
    else:
      event.handled = false

  drawWin.iconPath = myDir / "icon.ico"
  drawing.widthMode = WidthMode_Expand
  drawing.heightMode = HeightMode_Expand

  win.iconPath = myDir / "icon.ico"

  drawWin.onCloseClick = proc (ev: CloseClickEvent) = drawWin.hide()
  showGraphButton.onClick = proc (ev: ClickEvent) = drawWin.show()

  win.onKeyDown = proc(event: KeyboardEvent) =
    event.handled = true
    if Key_Return.isDown() and Key_ControlL.isDown():
      updateGraph()
    elif Key_ControlL.isDown and Key_S.isDown:
      saveOrSaveAs()
    else:
      event.handled = false

  win.onCloseClick = proc(event: CloseClickEvent) =
    if rtInfo.tLastSave < rtInfo.tLastDraw:
      case shouldSaveDialog(win):
        of rYes: saveOrSaveAs()
        of rCancel: return
        of rNo: discard
    win.dispose()
    drawWin.dispose()

  exportButton.onClick = proc(ev: ClickEvent)=
    let start = if rtInfo.currentExportPath != "":
        rtInfo.currentExportPath
      elif rtInfo.currentSavePath != "":
        rtInfo.currentSavePath.splitPath.head
      else:
        getHomeDir()
    let dir = getDirectoryViaDialog("Exportieren nach:", start)

    if dir != "":
      rtInfo.currentExportPath = dir
      storeAsImage(state, dir / "netzentwurf.png", northArrow)
      let nAntennas = state.graph.sessions.values --> map(len it).max()
      for i in 0 ..< nAntennas:
        let filepath = dir / fmt"GPS{i + 1}.html"
        filepath.writeFile(
          makeHtml(state, antenna, i, js, css))

  saveAsButton.onClick = proc(ev: ClickEvent) = saveAs()
  saveButton.onClick = proc(ev: ClickEvent) = saveOrSaveAs()

  loadButton.onClick = proc(ev: ClickEvent) =
    let file = getFilePathViaLoadDialog("Laden",
                                        rtInfo.currentSavePath.parentDir)
    if file.len == 1:
      load(file[0])

  drawing.onDraw = proc(event: DrawEvent) =
    renderToCanvas(state, event.control.canvas, viewPort=rtInfo.viewPort) 

  if paramCount() == 1:
    load(paramStr(1))
  else:
    rtInfo.lastGuiState = getState()
    rtInfo.tLastDraw = now()
    rtInfo.tLastSave = now()
    state = rtInfo.lastGuiState.parseState()

  win.show()
  drawWin.show()
  app.run()


main()
