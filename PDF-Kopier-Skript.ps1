# PowerShell-Skript zum rekursiven Kopieren von PDF-Dateien
# Mit Datumsfiltration, Duplikatvermeidung und deutschen Kommentaren

# ===== KONFIGURATION =====
# Bitte den Quellordner hier eintragen (z.B. "C:\Meine_Dateien")
$Quellordner = "Z:\Gemeinsam\FÜR DATEV\Eingangsrechnungen\2026\Hochgeladen"

# Stichtag für die Dateifilterung (ab diesem Datum)
$Stichtag = Get-Date -Year 2026 -Month 9 -Day 15 -Hour 0 -Minute 0 -Second 0

# ===== VALIDIERUNG DES QUELLORDNERS =====
# Überprüfe, ob der Quellordner existiert und nicht leer ist
if (-not (Test-Path -Path $Quellordner -PathType Container)) {
    Write-Host "Fehler: Der Quellordner '$Quellordner' existiert nicht." -ForegroundColor Red
    exit
}

# Ermittle das übergeordnete Verzeichnis des Quellordners
$Elternverzeichnis = Split-Path -Path $Quellordner -Parent
if (-not $Elternverzeichnis) {
    Write-Host "Fehler: Konnte das übergeordnete Verzeichnis nicht bestimmen." -ForegroundColor Red
    exit
}

# Definiere den Zielordner "KOPIE" im Elternverzeichnis
$Zielordner = Join-Path -Path $Elternverzeichnis -ChildPath "KOPIE"

# ===== ZIELORDNER VORBEREITEN =====
# Erstelle den KOPIE-Ordner, falls er nicht existiert
if (-not (Test-Path -Path $Zielordner -PathType Container)) {
    Write-Host "Erstelle Zielordner: $Zielordner"
    New-Item -Path $Zielordner -ItemType Directory -Force | Out-Null
}

# ===== PDF-DATEIEN SAMMELN =====
# Suche rekursiv nach PDF-Dateien, die nach dem Stichtag erstellt wurden
# Schließe dabei den KOPIE-Ordner automatisch aus
Write-Host "Durchsuche Quellordner nach PDF-Dateien..."
$PDFDateien = Get-ChildItem -Path $Quellordner -Filter "*.pdf" -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object {
        # Filtere nach Erstellungszeit (CreationTime)
        $_.CreationTime -ge $Stichtag -and
        # Stelle sicher, dass die Datei nicht im KOPIE-Ordner liegt
        -not ($_.FullName -like "$Zielordner\*")
    }

Write-Host "Gefundene PDF-Dateien: $($PDFDateien.Count)"

# ===== DATEIEN KOPIEREN =====
$kopierteDateien = 0
$hashtable_existierendeDateien = @{}

# Iteriere über jede gefundene PDF-Datei
foreach ($datei in $PDFDateien) {
    # Initialisiere Zieldateiname mit dem ursprünglichen Namen
    $zieldateiname = $datei.Name
    $zieldateipfad = Join-Path -Path $Zielordner -ChildPath $zieldateiname
    
    # Zähler für Duplikatvermeidung
    $zaehler = 1
    
    # Überprüfe, ob die Datei bereits im Zielordner existiert
    while (Test-Path -Path $zieldateipfad -PathType Leaf) {
        # Dateiname mit Zähler erzeugen (z.B. "Datei_1.pdf")
        $namensatz = [System.IO.Path]::GetFileNameWithoutExtension($datei.Name)
        $erweiterung = [System.IO.Path]::GetExtension($datei.Name)
        $zieldateiname = "$namensatz`_$zaehler$erweiterung"
        $zieldateipfad = Join-Path -Path $Zielordner -ChildPath $zieldateiname
        $zaehler++
    }
    
    # Kopiere die Datei
    try {
        Copy-Item -Path $datei.FullName -Destination $zieldateipfad -Force -ErrorAction Stop
        Write-Host "Kopiert: $($datei.FullName) -> $zieldateipfad" -ForegroundColor Green
        $kopierteDateien++
    }
    catch {
        Write-Host "Fehler beim Kopieren von $($datei.FullName): $_" -ForegroundColor Red
    }
}

# ===== ABSCHLUSS =====
Write-Host ""
Write-Host "========== SKRIPT ABGESCHLOSSEN ==========" -ForegroundColor Cyan
Write-Host "Quellordner: $Quellordner" -ForegroundColor Cyan
Write-Host "Zielordner: $Zielordner" -ForegroundColor Cyan
Write-Host "Zeitraum: Ab 15.09.2026 00:00 Uhr bis heute" -ForegroundColor Cyan
Write-Host "Anzahl kopierter Dateien: $kopierteDateien" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan
