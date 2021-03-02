import nigui, zero_functional, cairo, nigui / msgbox
import sequtils, tables, sets, hashes, sugar, strutils, times, os, std/json,
  base64, strformat
import core, parser, geometry, gui, htmlGen, render


type 
  GuiState = object
    pointAreaText, sessionAreaText, miscText: string
  RuntimeInfo = object
    currentSavePath: string 


converter toNiGuiColor(c: core.Color): nigui.Color =
  rgb(byte(c.r), byte(c.g), byte(c.b))


proc load_antenna_image_as_base64(): string =
  let file = "antenna.jpg".open()
  defer: file.close()

  let nBytes = file.getFileSize()
  var buffer = newSeq[byte](nBytes)
  assert file.readBytes(buffer, 0, nBytes) == nBytes
  encode buffer


proc getFilePathViaSaveDialog(title: string, defaultExtension: string): string=
  let cwd = getCurrentDir()
  var dialog = newSaveFileDialog()
  dialog.title = title
  dialog.defaultExtension = defaultExtension
  dialog.run()
  setCurrentDir cwd
  return dialog.file


proc getFilePathViaLoadDialog(title: string): seq[string]=
  let cwd = getCurrentDir()
  var dialog = newOpenFileDialog()
  dialog.title = title
  dialog.directory = getHomeDir()
  dialog.run()
  setCurrentDir cwd
  return dialog.files


proc getDirectoryViaDialog(title: string): string=
  let cwd = getCurrentDir()
  var dialog = newSelectDirectoryDialog()
  dialog.title = title
  dialog.run()
  setCurrentDir cwd
  return dialog.selectedDirectory


func nLines[T](ses: T): int =
  let l = ses.len
  int(l * (l - 1) * 0.5)


proc renderToCanvas(state: State, canvas: Canvas,
                    bgColor=toNiGuiColor bgColor,
                    txtOverColor=toNiGuiColor txtOverColor)=
  let img = renderGraph(state.graph.points, state.graph.sessions,
                        state.txtOverImg, canvas.width, canvas.height)
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
                        state.txtOverImg, 1240, 1754)
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
  let northArrow = newSurface("north.png")
  var 
    state: State
    rtInfo: RuntimeInfo
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
    drawing.forceRedraw()

  proc save(path: string) = path.writeFile($(%*getState()))

  proc saveAs() =
    let savePath = getFilePathViaSaveDialog("Speichern unter", ".p")
    if savePath != "":
      rtInfo.currentSavePath = savePath
      save(savePath)

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
  txtOverArea.text = "default_text.txt".readFile.fixLineEndings

  drawWin.add(drawing)
  drawWin.iconPath = "icon.ico"
  drawing.widthMode = WidthMode_Expand
  drawing.heightMode = HeightMode_Expand

  win.iconPath = "icon.ico"

  drawWin.onCloseClick = proc (ev: CloseClickEvent) = drawWin.hide()
  showGraphButton.onClick = proc (ev: ClickEvent) = drawWin.show()

  win.onKeyDown = proc(event: KeyboardEvent) =
    if Key_Return.isDown() and Key_ControlL.isDown():
      try:
        state = getState().parseState()
        drawing.forceRedraw()
      except ParserError as e:
        win.alert("Fehler: " & e.msg)
      event.handled = true

  win.onCloseClick = proc(event: CloseClickEvent) =
    win.dispose()
    drawWin.dispose()

  exportButton.onClick = proc(ev: ClickEvent)=
    let dir = getDirectoryViaDialog("Exportieren nach:")
    if dir != "":
      storeAsImage(state, dir / "netzentwurf.png", northArrow)
      let nAntennas = state.graph.sessions.values --> map(len it).max()
      for i in 0 ..< nAntennas:
        let filepath = dir / fmt"GPS{i + 1}.html"
        filepath.writeFile(
          makeHtml(state, load_antenna_image_as_base64(), i))

  saveAsButton.onClick = proc(ev: ClickEvent) = saveAs()
  saveButton.onClick = proc(ev: ClickEvent) =
    if rtInfo.currentSavePath != "":
      save(rtInfo.currentSavePath)
    else:
      saveAs()

  loadButton.onClick = proc(ev: ClickEvent) =
    let file = getFilePathViaLoadDialog("Laden")
    if file.len == 1:
      let content = file[0].readFile
      let guiState = content.parseJson.to(GuiState)
      applyGuiState guiState
      rtInfo.currentSavePath = file[0]
      state = guiState.parseState

  drawing.onDraw = proc(event: DrawEvent) =
    renderToCanvas(state, event.control.canvas) 

  state = getState().parseState()
  #writeFile(getHomeDir() & "/tmp/foo.html",
            #makeHtml(state, load_antenna_image_as_base64()))

  #storeAsImage(state, getHomeDir() / "tmp/img.png", northArrow)

  win.show()
  drawWin.show()
  app.run()


main()
