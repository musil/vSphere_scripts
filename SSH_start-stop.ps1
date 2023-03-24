
$NEWHost = "ESXi_Server.lab.local"

# start SSH service
Get-VMHost -Name $NEWHost | Foreach
{
	Start-VMHostService -HostService ($_ | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" })
}


# stop SSH function
function ssh-stop ($NEWHost)
{
	Get-VMHost -Name $NEWHost | Foreach
	{
		Stop-VMHostService -HostService ($_ | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" })
	}
}