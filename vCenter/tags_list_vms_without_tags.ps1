# Connect to your vCenter server (if not already connected)
# Connect-VIServer -Server <VCENTER_IP_OR_FQDN>

# Get all VMs
$vms = Get-VM

# Get all tags in the "Backup" category
$backupTags = Get-Tag -Category "Backup"

# Get all tag assignments for the backup tags and extract the associated VMs
$vmsWithBackupTag = Get-TagAssignment -Tag $backupTags | Select-Object -ExpandProperty Entity | Sort-Object -Unique

# Filter VMs that do not have any Backup tag assigned
$vmsWithoutBackup = $vms | Where-Object { $vmsWithBackupTag -notcontains $_ }

# Display the list of VMs without a Backup tag
$vmsWithoutBackup | Select-Object Name