# Ensure you're connected to your vCenter or ESXi host
# Connect-VIServer -Server <your-vcenter-server> -User <username> -Password <password>

# MAC address to search for
$macAddress = "00:50:56:bb:40:e6"

# Get all VMs
$vms = Get-VM

# Filter VMs by network adapter's MAC address
$vmWithMac = $vms | Get-NetworkAdapter | Where-Object { $_.MacAddress -eq $macAddress } | Select-Object Parent, Name

if ($vmWithMac) {
    Write-Output "VM found with MAC Address $macAddress $($vmWithMac.Parent.Name)"
} else {
    Write-Output "No VM found with MAC Address $macAddress"
}
