import tables, sets, strutils, sequtils
import nigui

type
  Point* = tuple[name: string, x, y: float, color: Color]
  NormPoint* = tuple[name: string, x, y: int, color: Color]
  Graph* = object 
    points*: seq[Point]
    sessions*: Table[string, HashSet[string]]


let 
  bgColor* = rgb(255, 255, 255)
  fgColor* = rgb(0, 0, 0)
  pointRadius* = 5
  pointDiameter* = 2 * pointRadius
  colorsTable* = toTable {
    "hellblau": rgb(0, 191, 255),
    "blau": rgb(0, 0, 205),
    "rot": rgb(205, 0, 0),
    "schwarz": rgb(0, 0, 0),
    "grün": rgb(50, 205, 50),
    "gelb": rgb(255, 215, 0),
    "orange": rgb(255, 140, 0),
    "pink": rgb(255, 20, 147),
    "violet": rgb(148, 0, 211),
  }
  default_text* = dedent """
    Punkte {
      # Name Rechts Hoch [Farbe]
      19494 4593466 5637921
      19115 4597209 5637946
      19114 4595591 5639878 gelb
      19133 4598250 5642330 gelb
    }

    # Ich bin ein Kommentar und werde ignoriert werden.
    Sessions {
      Lala {19494 19115}
    }
  """
