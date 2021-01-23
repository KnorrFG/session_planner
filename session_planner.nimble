# Package

version       = "0.1.0"
author        = "felix"
description   = "A tool to plan GPS Sessions for surveyors"
license       = "MIT"
srcDir        = "src"
bin           = @["session_planner"]


# Dependencies

requires "nim >= 1.4.0",
  "nigui",
  "zero_functional",
  "karax"
