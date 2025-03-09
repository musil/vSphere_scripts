# Connect to your vCenter server (if not already connected)
# Connect-VIServer -Server <VCENTER_IP_OR_FQDN>

# Retrieve all tags in the "Backup" category
$backupTags = Get-Tag -Category "Backup"

# Loop through each backup tag and remove its assignment from any VMs
foreach ($tag in $backupTags) {
    # Get tag assignments where the entity is a virtual machine
    $assignments = Get-TagAssignment -Tag $tag | Where-Object { $_.Entity -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl] }
    
    foreach ($assignment in $assignments) {
        Remove-TagAssignment -TagAssignment $assignment -Confirm:$false
        Write-Host "Removed tag '$($tag.Name)' from VM '$($assignment.Entity.Name)'."
    }
}