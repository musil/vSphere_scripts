# Connect to your vCenter server (if not already connected)
# Connect-VIServer -Server <VCENTER_IP_OR_FQDN>

# Import CSV file with two columns (without header in the file).
# Each line in the file should look like: "VM1", "TAG_NAME"

# Here we define headers: VMName and Tag.
$assignments = Import-Csv -Path "tags_assign_from_file.csv" -Header VMName, Tag

foreach ($item in $assignments) {
    # Retrieve the VM by its name
    $vm = Get-VM -Name $item.VMName

    if ($vm) {
        # Assign the tag to the VM
        New-TagAssignment -Entity $vm -Tag $item.Tag
        Write-Host "Assigned tag '$($item.Tag)' to VM '$($item.VMName)'."
    } else {
        Write-Host "VM '$($item.VMName)' not found."
    }
}