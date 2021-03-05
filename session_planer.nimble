# Package

version       = "0.1.0"
author        = "Felix Knorr"
description   = "A tool to plan GPS Sessions for surveyors"
license       = "MIT"
srcDir        = "src"
bin           = @["session_planer"]


# Dependencies

requires "nim >= 1.4.0",
  "nigui == 0.2.4",
  "zero_functional",
  "cairo"

# Tasks

import os

task winbuild, "build task for windows":
  if defined(windows):
    exec "nimble build --app:gui -d:release"
    exec "nimble js -o:my.js -d:release src/report_js.nim"
    exec "rcedit session_planer.exe --set-icon icon.ico"
  else:
    echo "only on windows"

task deploy, "copies all relevant files to a target dir":
  let 
    targetpath = paramstr(paramCount()).absolutePath
    binary = if defined windows: "session_planer.exe"
             else: "session_planer"
    files = @[binary] &
      "antenna.jpg default_text.txt icon.ico my.css my.js north.png".split

  if not dirExists targetpath:
    mkDir targetpath
  for file in files:
    cpFile file, targetpath / file
  
