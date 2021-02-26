import tables, math, strutils
import cairo, zero_functional

import core, geometry


type 
  SurfaceObj = object
    data: ptr cairo.Surface
  Surface* = ref SurfaceObj

proc `=destroy`(x: var SurfaceObj) = cairo.destroy(x.data)
proc width*(x: Surface): int = x.data.getWidth()
proc height*(x: Surface): int = x.data.getHeight()
proc rawData*(x: Surface): ptr byte = cast[ptr byte](x.data.getData())
proc writeToPng*(self: Surface, path: string) =
  discard self.data.writeToPng(path.cstring)

proc newSurface*(path: string): Surface =
  new result
  result.data = imageSurfaceCreateFromPng(path.cstring)


proc set(x: ptr Context, c: Color) =
  x.setSourceRGB(c.r / 255, c.g / 255, c.b / 255)

proc textExtents(ctx: ptr Context; text: string): TextExtents =
  ctx.textExtents text.cstring, addr result


proc addNorthArrow*(s: Surface, angle: float, image: Surface) =
  var ctx = s.data.create()
  ctx.translate(s.data.getWidth.float * 0.9,
             s.data.getHeight.float * 0.9)
  ctx.scale(0.2, 0.2)
  ctx.translate(image.data.getWidth / 2, image.data.getHeight / 2)
  ctx.rotate(angle)
  ctx.translate(-image.data.getWidth / 2, -image.data.getHeight / 2)
  ctx.setSource(image.data, 0, 0)
  ctx.paint()
  ctx.destroy()

proc renderGraph*(points: seq[Point], sessions: Table[string, seq[string]],
                  textover: string, w, h: int): Surface=
  new result
  result.data = imageSurfaceCreate(FORMAT_ARGB32, w.int32, h.int32)

  var ctx = result.data.create()
  ctx.selectFontFace("Arial", FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
  ctx.setFontSize(18.0)
  let radius = 4

  let normPoints = normalizePoints(points, w, h) --> map((it.name, it)).toTable

  ctx.rectangle(0, 0, w, h)
  ctx.setSourceRGB(1, 1, 1)
  ctx.fill()

  ctx.set(colorsTable["schwarz"])
  for s in sessions.values:
    for (a, b) in twoElemSubSets(s):
      let
        na = normPoints[a]
        nb = normPoints[b]
      ctx.moveTo(na.x, na.y)
      ctx.lineTo(nb.x, nb.y)
      ctx.stroke()

  for p in normPoints.values:
    ctx.set(p.color)
    ctx.arc(p.x, p.y, radius, 0, 2 * PI)
    ctx.fill()
    
    let extent = ctx.textExtents(p.name)
    ctx.set(colorsTable["schwarz"])
    ctx.moveTo(p.x - extent.width / 2, p.y + extent.height * 1.2 + radius)
    ctx.showText(p.name)
    ctx.fill()

    ctx.set(txtOverColor)
    for i, line in pairs textover.splitLines():
      ctx.moveTo(0.05 * w, 0.05 * h + extent.height * 1.5 * i)
      ctx.showText(line)
      ctx.stroke()
    
  ctx.destroy()


