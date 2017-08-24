-- pastebin run -f cyF0yhXZ
-- von Nex4rius
-- https://github.com/Nex4rius/Nex4rius-Programme/

os.sleep(2)

local component       = require("component")
local fs              = require("filesystem")
local c               = require("computer")
local event           = require("event")
local term            = require("term")

local farben          = loadfile("/tank/farben.lua")()
local ersetzen        = loadfile("/tank/ersetzen.lua")()

local gpu             = component.getPrimary("gpu")
local m               = component.modem

local version, tankneu, energie

local port            = 918
local Sensorliste     = {}
local tank            = {}
local f               = {}
local o               = {}
local laeuft          = true
local nix             = true
local debug           = false
local Wartezeit       = 150
local letzteNachricht = c.uptime()

if fs.exists("/tank/version.txt") then
  local d = io.open ("/tank/version.txt", "r")
  version = d:read()
  d:close()
else
  version = "<FEHLER>"
end

if fs.exists("/tank/Sensorliste.lua") then
  Sensorliste = loadfile("/tank/Sensorliste.lua")()
end

function f.tankliste(signal)
  local dazu = true
  local ende = 0
  local hier, id, nachricht = signal[1], signal[3], signal[7]
  if hier then
    letzteNachricht = c.uptime()
    for i in pairs(tank) do
      if type(tank[i]) == "table" then
        if tank[i].id == id then
          tank[i].zeit = c.uptime()
          tank[i].inhalt = require("serialization").unserialize(nachricht)
          dazu = false
        end
      end
      ende = i
    end
    if dazu then
      ende = ende + 1
      tank[ende] = {}
      tank[ende].id = id
      tank[ende].zeit = c.uptime()
      tank[ende].inhalt = require("serialization").unserialize(nachricht)
    end
    local i = 0
    for screenid in component.list("screen") do
      i = i + 1
    end
    for screenid in component.list("screen") do
      if i > 1 then
        gpu.bind(screenid, false)
      end
      f.anzeigen(f.verarbeiten(tank), screenid)
    end
  else
    f.keineDaten()
  end
  for i in pairs(tank) do
    if c.uptime() - tank[i].zeit > Wartezeit * 2 then
      tank[i] = nil
    end
  end
end

function f.hinzu(name, label, menge, maxmenge)
  local weiter = true
  if name ~= "nil" then
    for i in pairs(tankneu) do
      if tankneu[i].name == name then
        tankneu[i].menge = tankneu[i].menge + menge
        tankneu[i].maxmenge = tankneu[i].maxmenge + maxmenge
        weiter = false
      end
    end
    if weiter then
      tankneu[tanknr] = {}
      tankneu[tanknr].name = name
      tankneu[tanknr].label = label
      tankneu[tanknr].menge = menge
      tankneu[tanknr].maxmenge = maxmenge
    end
  end
end

function f.verarbeiten(tank)
  tankneu = {}
  tanknr = 0
  for i in pairs(tank) do
    if type(tank[i]) == "table" then
      if type(tank[i].inhalt) == "table" then
        for j in pairs(tank[i].inhalt) do
          tanknr = tanknr + 1
          f.hinzu(tank[i].inhalt[j].name, tank[i].inhalt[j].label, tank[i].inhalt[j].menge, tank[i].inhalt[j].maxmenge)
        end
      end
    end
  end
  return tankneu
end

local function spairs(t, order)
  local keys = {}
  for k in pairs(t) do keys[#keys+1] = k end
  if order then
    table.sort(keys, function(a,b) return order(t, a, b) end)
  else
    table.sort(keys)
  end
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

function f.anzeigen(tankneu, screenid)
  local klein = false
  local screenid = screenid or gpu.getScreen()
  local _, hoch = component.proxy(screenid).getAspectRatio()
  if hoch <= 2 then
    klein = true
  end
  local x = 1
  local y = 1
  local leer = true
  local maxanzahl = 0
  for i in pairs(tankneu) do
    maxanzahl = maxanzahl + 1
    nix = false
  end
  local a, b = gpu.getResolution()
  if maxanzahl <= 16 and maxanzahl ~= 0 then
    if klein and maxanzahl > 5 then
      if a ~= 160 or b ~= maxanzahl then
        gpu.setResolution(160, maxanzahl)
      end
    else
      if a ~= 160 or b ~= maxanzahl * 3 then
        gpu.setResolution(160, maxanzahl * 3)
      end
    end
  else
    if klein and maxanzahl > 5 then
      if a ~= 160 or b ~= 16 then
        gpu.setResolution(160, 16)
      end
    else
      if a ~= 160 or b ~= 48 then
        gpu.setResolution(160, 48)
      end
    end
  end
  os.sleep(0.1)
  local anzahl = 0
  for i in spairs(tankneu, function(t,a,b) return tonumber(t[b].menge) < tonumber(t[a].menge) end) do
    anzahl = anzahl + 1
    local links, rechts, breite = -15, -25, 40
    if (32 - maxanzahl) >= anzahl and maxanzahl < 32 then
      links, rechts = 40, 40
      breite = 160
    elseif (64 - maxanzahl) >= anzahl and maxanzahl > 16 then
      links, rechts = 0, 0
      breite = 80
    end
    if anzahl == 17 or anzahl == 33 or anzahl == 49 then
      if maxanzahl > 48 and anzahl > 48 then
        x = 41
        if klein and maxanzahl > 5 then
          y = 1 + (64 - maxanzahl)
        else
          y = 1 + 3 * (64 - maxanzahl)
        end
        breite = 40
      elseif maxanzahl > 32 and anzahl > 32 then
        x = 121
        if klein and maxanzahl > 5 then
          y = 1 + (48 - maxanzahl)
        else
          y = 1 + 3 * (48 - maxanzahl)
        end
        breite = 40
      else
        x = 81
        if klein and maxanzahl > 5 then
          y = 1 + (32 - maxanzahl)
        else
          y = 1 + 3 * (32 - maxanzahl)
        end
      end
      if y < 1 then
        y = 1
      end
    end
    local name = string.gsub(tankneu[i].name, "%p", "")
    local label = f.zeichenErsetzen(string.gsub(tankneu[i].label, "%p", ""))
    local menge = tankneu[i].menge
    local maxmenge = tankneu[i].maxmenge
    local prozent = string.format("%.1f%%", menge / maxmenge * 100)
    if label == "fluidhelium3" then
      label = "Helium-3"
    end
    f.zeigeHier(x, y, label, name, menge, maxmenge, string.format("%s%s", string.rep(" ", 8 - string.len(prozent)), prozent), links, rechts, breite, string.sub(string.format(" %s", label), 1, 31), klein, maxanzahl)
    leer = false
    if klein and maxanzahl > 5 then
      y = y + 1
    else
      y = y + 3
    end
  end
  f.Farben(0xFFFFFF, 0x000000)
  for i = anzahl, 33 do
    gpu.set(x, y    , string.rep(" ", 80))
    if not (klein and maxanzahl > 5) then
      gpu.set(x, y + 1, string.rep(" ", 80))
      gpu.set(x, y + 2, string.rep(" ", 80))
    end
    if klein and maxanzahl > 5 then
      y = y + 1
    else
      y = y + 3
    end
  end
  if leer then
    keineDaten()
  end
end

function f.zeichenErsetzen(...)
  return string.gsub(..., "%a+", function (str) return ersetzen[str] end)
end

function f.zeigeHier(x, y, label, name, menge, maxmenge, prozent, links, rechts, breite, nachricht, klein, maxanzahl)
  if farben[name] == nil and debug then
    nachricht = string.format("%s  %s  >>report this liquid<<<  %smb / %smb  %s", name, label, menge, maxmenge, prozent)
    nachricht = split(nachricht .. string.rep(" ", breite - string.len(nachricht)))
  else
    local ausgabe = {}
    if breite == 40 then
      table.insert(ausgabe, string.sub(nachricht, 1, 37 - string.len(menge) - string.len(prozent)))
      table.insert(ausgabe, string.rep(" ", 37 - string.len(nachricht) - string.len(menge) - string.len(prozent)))
      table.insert(ausgabe, menge)
      table.insert(ausgabe, "mb")
      table.insert(ausgabe, prozent)
      table.insert(ausgabe, " ")
    else
      table.insert(ausgabe, string.sub(nachricht, 1, 25))
      table.insert(ausgabe, string.rep(" ", links + 38 - string.len(nachricht) - string.len(menge)))
      table.insert(ausgabe, menge)
      table.insert(ausgabe, "mb")
      table.insert(ausgabe, " / ")
      table.insert(ausgabe, maxmenge)
      table.insert(ausgabe, "mb")
      table.insert(ausgabe, string.rep(" ", rechts + 26 - string.len(maxmenge)))
      table.insert(ausgabe, prozent)
      table.insert(ausgabe, " ")
    end
    nachricht = split(table.concat(ausgabe))
  end
  if farben[name] == nil then
   name = "unbekannt"
  end
  f.Farben(farben[name][1], farben[name][2])
  local ende = 0
  for i = 1, math.ceil(breite * menge / maxmenge) do
    if klein and maxanzahl > 5 then
      gpu.set(x, y, string.format("%s", nachricht[i]), true)
    else
      gpu.set(x, y, string.format(" %s ", nachricht[i]), true)
    end
    x = x + 1
    ende = i
  end
  f.Farben(farben[name][3], farben[name][4])
  for i = 1, breite - math.ceil(breite * menge / maxmenge) do
    if klein and maxanzahl > 5  then
      gpu.set(x, y, string.format("%s", nachricht[i + ende]), true)
    else
      gpu.set(x, y, string.format(" %s ", nachricht[i + ende]), true)
    end
    x = x + 1
  end
end

function f.Farben(vorne, hinten)
  if type(vorne) == "number" then
    gpu.setForeground(vorne)
  else
    gpu.setForeground(0xFFFFFF)
  end
  if type(hinten) == "number" then
    gpu.setBackground(hinten)
  else
    gpu.setBackground(0x333333)
  end
end

function split(...)
  local output = {}
  for i = 1, string.len(...) do
    output[i] = string.sub(..., i, i)
  end
  return output
end

function test(screenid)
  os.sleep(0.1)
  local _, hoch = component.proxy(screenid).getAspectRatio()
  term.clear()
  if hoch <= 2 then
    gpu.setResolution(160, 16)
  else
    gpu.setResolution(160, 48)
  end
  os.sleep(0.1)
  local hex = {0x000000, 0x1F1F1F, 0x3F3F3F, 0x5F5F5F, 0x7F7F7F, 0x9F9F9F, 0xBFBFBF, 0xDFDFDF,
               0xFFFFFF, 0xDFFFDF, 0xBFFFBF, 0x9FFF9F, 0x7FFF7F, 0x5FFF5F, 0x3FFF3F, 0x1FFF1F,
               0x00FF00, 0x1FDF00, 0x3FBF00, 0x5F9F00, 0x7F7F00, 0x9F5F00, 0xBF3700, 0xDF1F00,
               0xFF0000, 0xDF001F, 0xBF003F, 0x9F005F, 0x7F007F, 0x5F009F, 0x3F00BF, 0x1F00DF,
               0x0000FF, 0x0000DF, 0x0000BF, 0x00009F, 0x00007F, 0x00005F, 0x00003F, 0x00001F,
               0x000000}
  for _, farbe in pairs(hex) do
    gpu.setBackground(farbe)
    os.sleep(0.1)
    term.clear()
  end
  gpu.setBackground(0x000000)
end

function f.text(a, b)
  if c.uptime() - letzteNachricht > Wartezeit then
    for screenid in component.list("screen") do
      gpu.bind(screenid)
      test(screenid)
      f.Farben(0xFFFFFF, 0x000000)
      if b then
        gpu.setResolution(gpu.maxResolution())
      else
        gpu.setResolution(string.len(a), 1)
      end
      os.sleep(0.1)
      gpu.set(1, 1, a)
    end
  end
end

function f.keineDaten()
  m.broadcast(port, "version")
  f.text("Keine Daten vorhanden")
  nix = true
end

function o.anmelden(signal)
  if nix then
    f.text(string.format("%s %s %s %s %s %s %s %s", signal[1] or "", signal[2] or "", signal[3] or "", signal[4] or "", signal[5] or "", signal[6] or "", signal[7] or "", signal[8] or ""), true)
  end
  local dazu = true
  for k, v in pairs(Sensorliste) do
    if v[1] == signal[3] then
      dazu = nil
      break
    end
  end
  if dazu then
    table.insert(Sensorliste, {signal[3], signal[7]])
  end
  local rest = {}
  table.insert(rest, "return {\n")
  for k, v in pairs(Sensorliste) do
    table.insert(rest, string.format("  {%s, %s},\n"), v[1], v[2])
  end
  table.insert(rest, "}")
  local d = io.open("/tank/Sensorliste.lua", "w")
  d:write(tablet.concat(rest)
  d:close()
end

function o.version(signal)
  o.anmelden(signal)
end

function o.speichern(signal)
end

function o.update(signal)
end

function o.tank(signal)
  o.tank = f.tankliste --nix extra bisher
  f.tankliste(signal)
end

function f.loop(signal)
  local signal = {...}
  f.text(signal[6])
  if o[signal[6]] then
    o[signal[6]](signal)
  end
end

function f.main()
  gpu.setForeground(0xFFFFFF)
  term.setCursor(1, 50)
  m.open(port)
  f.text("Warte auf Daten")
  m.broadcast(port, "version")
  event.listen("modem_message", f.loop)
  pcall(os.sleep, math.huge)
end

function beenden()
  event.ignore("modem_message", f.loop)
  for screenid in component.list("screen") do
    gpu.bind(screenid)
    os.sleep(0.1)
    f.Farben(0xFFFFFF, 0x000000)
    gpu.setResolution(gpu.maxResolution())
    os.sleep(0.1)
    term.clear()
  end
end

loadfile("/bin/label.lua")("-a", require("computer").getBootAddress(), "Tankanzeige")

local ergebnis, grund = pcall(f.main)

if not ergebnis then
  f.text("<FEHLER> f.main", true)
  f.text(grund, true)
  os.sleep(1)
end

print("Ausschalten")
beenden()
