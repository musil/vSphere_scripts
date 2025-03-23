# Connect to your vCenter server (if not already connected)
# Connect-VIServer -Server <VCENTER_IP_OR_FQDN>

$esxis  = get-vmhost | Sort-Object

foreach ($esx in $esxis) {
    $key= @()
    $enc = @()
    if ($esx.ConnectionState -ne "Connected" -and $esx.ConnectionState -ne "Maintenance") {
        Write-Host ""
        Write-Host "================================================================================" -ForegroundColor Yellow
        Write-Host "🚫 SKIPPED HOST" -ForegroundColor Yellow
        Write-Host "Host                : $($esx.Name)" -ForegroundColor DarkYellow
        Write-Host "Reason              : Not powered on or disconnected." -ForegroundColor DarkYellow
        Write-Host "================================================================================" -ForegroundColor Yellow
        Write-Host ""
        continue
    }
    $esxcli = Get-EsxCli -VMHost $esx -V2
    try {
        $key = $esxcli.system.settings.encryption.recovery.list.Invoke()
        $enc =  $esxcli.system.settings.encryption.get.Invoke()

        Write-Host "================================================================================" -ForegroundColor DarkCyan
        Write-Host "🔹 ESXi Host        : $($esx.Name)" -ForegroundColor Cyan
        Write-Host "🔐 Recovery ID      : $($key.RecoveryID)" -ForegroundColor Green
        Write-Host "🗝️  Recovery Key     : $($key.Key)" -ForegroundColor Yellow
        Write-Host "🔒 Encryption Mode  : $($enc.Mode)" -ForegroundColor Magenta
        Write-Host "================================================================================" -ForegroundColor DarkCyan
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "================================================================================" -ForegroundColor DarkGray
        Write-Host "❌ ERROR for host    : $($esx.Name)" -ForegroundColor Red
        Write-Host "⚠️  Failed to get encryption key for $($esx.Name) ."
        Write-Host "🧨 Error details     : $_"
        Write-Host "================================================================================" -ForegroundColor DarkGray
        Write-Host ""
    }
}