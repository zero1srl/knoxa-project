param(
    [Parameter(Mandatory=$true)]
    [string]$Source,           # es. D:\docker-backup\2026-09-17
    [string]$Volume = "all",   # nome volume specifico, oppure "all"
    [switch]$Images            # se presente, carica anche le immagini
)

if ($Images) {
    $imgTar = Join-Path $Source "images\all-images.tar"
    if (Test-Path $imgTar) {
        Write-Host "Carico immagini..."
        docker load -i $imgTar
    } else {
        Write-Warning "Non trovato: $imgTar"
    }
}

$volDir = Join-Path $Source "volumes"
if (-not (Test-Path $volDir)) {
    Write-Warning "Nessuna cartella volumi in $Source"
    exit
}

$files = if ($Volume -eq "all") {
    Get-ChildItem "$volDir\*.tar.gz"
} else {
    Get-ChildItem "$volDir\$Volume.tar.gz" -ErrorAction SilentlyContinue
}

if (-not $files) {
    Write-Warning "Nessun volume trovato da ripristinare (cercato: $Volume)"
    exit
}

foreach ($f in $files) {
    $name = $f.BaseName -replace '\.tar$',''
    Write-Host "Ripristino volume: $name"
    docker volume create $name | Out-Null
    docker run --rm -v "${name}:/data" -v "$($f.DirectoryName):/backup" alpine `
        tar xzf "/backup/$($f.Name)" -C /data
}

Write-Host "Fatto. Ricrea i container con docker-compose up (o docker run) per riattaccarli ai volumi."
