param(
    [string]$Root = "D:\docker-backup",
    [int]$Keep = 3
)

$Dest = Join-Path $Root (Get-Date -Format 'yyyy-MM-dd_HHmmss')

New-Item -ItemType Directory -Force -Path "$Dest\volumes" | Out-Null
New-Item -ItemType Directory -Force -Path "$Dest\images" | Out-Null

Write-Host "Backup su $Dest"

# Volumi (dati persistenti: DB, MinIO, ecc.)
$volumes = docker volume ls -q
foreach ($v in $volumes) {
    Write-Host "Volume: $v"
    docker run --rm -v "${v}:/data" -v "${Dest}\volumes:/backup" alpine `
        tar czf "/backup/$v.tar.gz" -C /data .
}

# Dump logico del Supabase di K-UI/BIDQ/K-UI-ADMIN: usa un bind mount
# (knoxa-ui\infra\supabase\volumes\db\data), quindi il tar dei volumi qui sopra
# NON lo copre. Persi gli utenti una volta per questo (2026-09-17).
Write-Host "Dump DB knoxa-ui-supabase-db..."
New-Item -ItemType Directory -Force -Path "$Dest\db" | Out-Null
docker exec knoxa-ui-supabase-db sh -c "pg_dumpall -U postgres | gzip" > "$Dest\db\knoxa-ui-supabase-dumpall.sql.gz"

# Immagini (tutte quelle presenti localmente, in un unico tar)
Write-Host "Immagini..."
docker save $(docker images -q) -o "$Dest\images\all-images.tar"

# Snapshot leggibile di container/immagini/compose per riferimento
docker ps -a --format "{{.Names}}`t{{.Image}}`t{{.Status}}" > "$Dest\containers.txt"
docker images > "$Dest\images-list.txt"

Write-Host "Fatto: $Dest"

# Storicizza solo gli ultimi $Keep backup
Get-ChildItem $Root -Directory |
    Sort-Object Name -Descending |
    Select-Object -Skip $Keep |
    ForEach-Object {
        Write-Host "Elimino backup vecchio: $($_.FullName)"
        Remove-Item $_.FullName -Recurse -Force
    }
