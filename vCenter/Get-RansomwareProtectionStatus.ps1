function Get-RansomwareProtectionStatus {
    Param(
        [Parameter(Mandatory=$true, HelpMessage="Specify the VMHost")]
        $VMHost
    )

    process {

    # Get an ESXCLI object against this host
    $esxcli = Get-EsxCli -VMHost $VMHost -V2

    # Pull encryption settings (Secure Boot + execInstalledOnly enforcement)
    $enc = $esxcli.system.settings.encryption.get.Invoke()

    # Pull kernel settings and find execInstalledOnly flag
    $kern = $esxcli.system.settings.kernel.list.Invoke()
    $execFlag = $kern | Where-Object { $_.Name -eq 'execInstalledOnly' }

    $h=[PSCustomObject]@{
        HostName                                 = $VMHost
        EncryptionMode                           = $enc.Mode
        RequireSecureBoot                        = $enc.RequireSecureBoot
        RequireExecFromInstalledVIBs             = $enc.RequireExecutablesOnlyFromInstalledVIBs
        ExecInstalledOnlyBootOption_Configured   = $execFlag.Configured   # boot‐time default
        ExecInstalledOnlyBootOption_Runtime      = $execFlag.Runtime        # current runtime
    }

# Display the report
Clear-Host
Write-Host "🚀 Ransomware Protection Report" -ForegroundColor Magenta
Write-Host ('=' * 40) -ForegroundColor DarkMagenta
   

    Write-Host "Host: $($h.HostName)" -ForegroundColor Cyan
        
    Write-Host -NoNewline "  Encryption Mode : "
    if ($h.EncryptionMode -eq 'TPM') {
        Write-Host "TPM" -ForegroundColor Green
    } elseif ($h.EncryptionMode -eq 'NONE') {
        Write-Host "NONE" -ForegroundColor Red
    } else {
        Write-Host "Unknown ($($h.EncryptionMode))" -ForegroundColor Yellow
    }

    Write-Host -NoNewline "  Secure Boot     : "
    if ($h.RequireSecureBoot -eq $true) {
        Write-Host "Enabled ($($h.RequireSecureBoot))" -ForegroundColor Green 
    } else {
        Write-Host "Disabled ($($h.RequireSecureBoot))" -ForegroundColor Red
    }

    Write-Host -NoNewline "  Exec-Only VIBs  : "
    if ($h.RequireExecFromInstalledVIBs -eq $true) {
        Write-Host "Enforced ($($h.RequireExecFromInstalledVIBs))" -ForegroundColor Green
    } else {
        Write-Host "Not enforced ($($h.RequireExecFromInstalledVIBs))" -ForegroundColor Red
    }

    Write-Host -NoNewline "  ExecInstalledOnly (cfg) : "
    if ($h.ExecInstalledOnlyBootOption_Configured -eq $true) {
        Write-Host "True ($($h.ExecInstalledOnlyBootOption_Configured))" -ForegroundColor Green
    } else {
        Write-Host "False ($($h.ExecInstalledOnlyBootOption_Configured))" -ForegroundColor Red
    }

    Write-Host -NoNewline "  ExecInstalledOnly (run) : "
    if ($h.ExecInstalledOnlyBootOption_Runtime -eq $true) {
        Write-Host "True ($($h.ExecInstalledOnlyBootOption_Runtime))" -ForegroundColor Green
    } else {
        Write-Host "False ($($h.ExecInstalledOnlyBootOption_Runtime))" -ForegroundColor Red
    }

    Write-Host ('-' * 40) -ForegroundColor DarkGray


}
}

Get-RansomwareProtectionStatus $args[0] 
