import dom, strutils, math, sugar, strformat, stats

template `@!`(id:cstring): untyped = document.getElementById(id)
proc floatVal(id: cstring): float = parseFloat($(@!id.value))
proc floatHtml(id: cstring): float = parseFloat($(@!id.innerHtml))


proc setDiffLe2mm(idA, idB, idOut: cstring) =
  try:
    @!idOut.innerHtml = if abs(idA.floatVal - idB.floatVal) <= 0.0002:
      "&#9989;"
    else:
      "&#10060;"
  except ValueError:
    return 


proc calcReductionS(meanS, sh, s0: float): float {.exportc.} =
    sqrt(meanS ^ 2 - sh ^ 2) - s0


proc onLoad() {.exportc.}=
  for record in document.getElementsByClassName("pointRec"):
    let
      point = $record.getAttribute("point")
      session = $record.getAttribute("session")
      idbase = "_" & point & session

    for idPart in ["v", "s1", "s2"]:
      let 
        idStart = idbase & idPart & "0"
        idEnd = idbase & idPart & "1"
        idDiff = idbase & idPart & "d"
        idReduced = idbase & idPart & "r"
        idArp = idbase & "arp"
        idArp2 = idbase & "arp2"

      for i in ["0", "1"]:
        capture idPart, i, idbase, idStart, idEnd, idDiff, idReduced, 
                idArp, idArp2:
          @!(idbase & idPart & i).onChange = proc(ev: Event) =
            try:
              setDiffLe2mm idStart, idEnd, idDiff
              if idPart in ["s1", "s2"]:
                let 
                  redV = calcReductionS(
                    mean([idStart.floatVal, idEnd.floatVal]),
                    "sH".floatVal, "s0".floatVal)

                @!idReduced.innerHtml = fmt"{redV:.3f}"
              else:
                assert idPart == "v"
                let redV = mean([idStart.floatVal, idEnd.floatVal]) + 
                           "v0".floatVal
                @!idReduced.innerHtml = fmt"{redV:.3f}"
                
              let 
                vals = collect(newSeq):
                  for x in "v s1 s2".split():
                    "{idbase}{x}r".fmt.floatHtml
                arp = mean(vals)
                arp2 = arp - "v0".floatVal
              @!idArp.innerHtml = fmt"{arp:.3f}"
              @!idArp2.innerHtml = fmt"{arp2:.3f}"
            except ValueError:
              return

          @!(idbase & idPart & i).onChange(nil)
    


  

