$esxis=get-vmhost
foreach ($esxi in $esxis.Name) {
Get-VMHostNetwork -VMHost $esxi |Select HostName,DomainName,DnsAddress
}
