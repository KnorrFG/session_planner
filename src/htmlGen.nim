#? stdtmpl(subsChar = '$', metaChar = '#')
#
#import tables, strutils
#import zero_functional
#import core
#
#
#proc makeSettingsSection(image: string): string =
<h2>Einstellungen</h2>
<div class="hLayout">
  <img width="40%" src="data:image/jpg;base64,$image" alt="">
  <table class="settings">
    <tr>
      <td><b>a: </b></td>
      <td>Höhe Antennenreferenzpunkt (ARP)</td>
    </tr>
    <tr>
      <td><b>v:</b></td>
      <td>Vertikale Messung; Messwert</td>
    </tr>
    <tr>
      <td><label for="v0"><b>v<sub>0</sub>:</b></td>
      <td>Vertikale Messung; Höhenoffset</label></td>
      <td><input type="number" step=0.001 id="v0" value="0,36"></td>
    </tr>
    <tr>
      <td><b>s:</b></td>
      <td>Schräge Messung; Messwert</td>
    </tr>
    <tr>
      <td><label for="s0"><b>s<sub>0</sub>:</b></td>
      <td>Schräge Messung; Höhenoffset</label></td>
      <td><input type="number" step=0.001 id="s0" value="0,035"></td>
    </tr>
    <tr>
      <td><label for="sH"><b>s<sub>H</sub>:</b></td>
      <td>Schräge Messung; horizontaler Offset</label></td>
      <td><input type="number" step=0.001 id="sH" value="0,19"></td>
    </tr>
  </table>
</div>
#end proc
#
#proc makeSessionTable(sessions: Sessions): string =
#  let nAntennas = sessions.values --> map(len it).max()
<div>
  <table class="sessionTable">
  <tr>
    <th>Session</th>
    #for i in 1..nAntennas:
      <th>${"GPS $1" % $i}</th>
    #end for
  </tr>
  # for name, points in sessions:
    <tr>
      <td>$name</td>
      # for i in 0 ..< nAntennas:
        #if i < points.len:
          <td>${points[i]}</td>
        #else:
          <td></td>
        #end if
      # end for
    </tr>
    # end for
  </table>
</div>
#end proc
#
#
#proc makePointRecord(point, session: string, even: bool): string =
  #func myId(s: string): string = "_" & point & session & s
  #end func
<div class="pointRec ${if even: "pbBefore" else: ""}" 
    point=$point session=$session>
  <div class="ident">
    <div class="identCell">
       <b>Punkt: </b>
       $point
     </div>
    <div class="idenCell">
      <b>Session: </b>
      $session
    </div>
  </div>
  <div class="contents">
    <div class="tabWithHeading padded">
      <div>Höhenablesung</div>
      <table class="box">
        <tr>
          <th></th>
          <th>v</th>
          <th>s1</th>
          <th>s2</th>
        </tr>
        <tr>
          <td>Start</td>
          <td><input id="${myId("v0")}" step=0.001 type="number"></td>
          <td><input id="${myId("s10")}" step=0.001 type="number"></td>
          <td><input id="${myId("s20")}" step=0.001 type="number"></td>
        </tr>
        <tr>
          <td>Ende</td>
          <td><input id="${myId("v1")}" step=0.001 type="number"></td>
          <td><input id="${myId("s11")}" step=0.001 type="number"></td>
          <td><input id="${myId("s21")}" step=0.001 type="number"></td>
        </tr>
        <tr>
          <td>${"Diff \u2264 2mm"}</td>
          <td><div id="${myId("vd")}"></div></td>
          <td><div id="${myId("s1d")}"></div></td>
          <td><div id="${myId("s2d")}"></div></td>
        </tr>
        <tr>
          <td>reduziert</td>
          <td><div id="${myId("vr")}"></div></td>
          <td><div id="${myId("s1r")}"></div></td>
          <td><div id="${myId("s2r")}"></div></td>
        </tr>
      </table>
    </div>
  </div>
  <div class="tabWithHeading upperline padded">
    <div>Beobachtungen</div>
    <table class="box">
      <tr>
        <th>Zeit</th>
        <th># Sats</th>
        <th>PDOP</th>
      </tr>
      <tr>
        <td><input type=""></td>
        <td><input type=""></td>
        <td><input type=""></td>
      </tr>
      <tr>
        <td><input type=""></td>
        <td><input type=""></td>
        <td><input type=""></td>
      </tr>
    </table>
  </div>
  <div class="hLayout upperline padded">
    <div>
      <div><b>Mittelwert Höhe ARP: </b></div>
      <div id="${myId("arp")}"></div>
    </div>
    <div>
      <div><b>Mittelwert ARP abzgl v0: </b></div>
      <div id="${myId("arp2")}"></div>
    </div>
  </div>
  <div class="hLayout upperline padded">
    <div>
      <input type="checkbox">
      <label for="">${"Kontrolle NRP \u2264 10 \u00B0"}</label>
    </div>
    <div>
      <input type="checkbox">
      <label for="">${"Kontrolle Zentrierung \u2264 2mm"}</label>
    </div>
  </div>
  <div class="vLayout upperline padded">
    Bemerkung:
    <textarea id="" name="" cols="30" rows="2"></textarea>
  </div>
</div>
#end proc
#
#
#proc makeAntennaInfoBlock(): string =
<table>
  <tr>
    <td>
      <label for="anntennablock1">Antenne (Typ, SNr)</label>
    </td>
    <td>
      <input id="anntennablock1" type="">
    </td>
  </tr>
  <tr>
    <td>
      <label for="anntennablock2">Empfänger</label>
    </td>
    <td>
      <input id="anntennablock2" type="">
    </td>
  </tr>
  <tr>
    <td>
      <label for="anntennablock3">Messjob</label>
    </td>
    <td>
      <input id="anntennablock3" type="">
    </td>
  </tr>
  <tr>
    <td>
      <label for="anntennablock4">Koordinatensystem</label>
    </td>
    <td>
      <input id="anntennablock4" type="" value="WGS84">
    </td>
  </tr>
  <tr>
    <td>
      <label for="anntennablock5">Bemerkung</label>
    </td>
    <td>
      <input id="anntennablock5" type="">
    </td>
  </tr>
  <tr>
    <td>
      <label for="anntennablock6">Geprüft</label>
    </td>
    <td>
      <input id="anntennablock6" type="">
    </td>
  </tr>
  <tr>
    <td>
      <label for="anntennablock7">Beobachter</label>
    </td>
    <td>
      <input id="anntennablock7" type="">
    </td>
  </tr>
</table>
#end proc
#
#proc makeHtml*(state: State, image: string, antennaIdx: int):string =
<!DOCTYPE html>
<html lang="de">
<head>
	<meta charset="UTF-8">
	<title>Beobachtungsprotokol</title>
  <style>
    ${"my.css".readFile()}
  </style>
  <script>
    ${"my.js".readFile()}
  </script>
</head>
<body onload="onLoad()">
<h1>Beobachtungsprotokol</h1>
<div class="txtOver">
$state.txtOverHtml
</div>
${makeSettingsSection(image)}
<h2>Session Planung</h2>
${makeSessionTable(state.graph.sessions)}
<h3>GPS ${antennaIdx + 1}</h3>
${makeAntennaInfoBlock()}
#var n = 0
#for session, points in state.graph.sessions:
  #if points.len > antennaIdx:
    ${makePointRecord(points[antennaIdx], session, n mod 2 == 0)}  
    #inc n
  #end if
#end for
</body>
</html>
#end proc
