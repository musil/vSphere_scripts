# Usage: .\get-mac-address-function.ps1 -MacAddress "00:50:56:00:00:01"

function get-mac {
    # Define the MAC address input parameter
    param (
        [string]$MacAddress
    )
    
    # Normalize the MAC address format (optional)
    $NormalizedMacAddress = $MacAddress.ToLower()
    
    # Get all VMs
    $allVMs = Get-VM
    
    # Loop through each VM and check its network adapters for the MAC address
    foreach ($vm in $allVMs) {
        $networkAdapters = Get-NetworkAdapter -VM $vm
        foreach ($adapter in $networkAdapters) {
            if ($adapter.MacAddress.ToLower() -eq $NormalizedMacAddress) {
                Write-Host "VM Name: $($vm.Name)"
                return
            }
        }
    }
    
    # If no VM is found with the provided MAC address
    Write-Host "No VM found with MAC Address: $MacAddress"
    }